//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

#import "RMStorage.h"
#import "rm-cache.h"
#import <UIKit/UIKit.h>
#import <Foundation/NSPathUtilities.h>

#define b(a,b) [NSNumber numberWithBool:a], b
#define i(a,b) [NSNumber numberWithInteger:a], b
#define d(a,b) [NSNumber numberWithDouble:a], b
#define f(a,b) [NSNumber numberWithFloat:a], b

// we try to not make our path name overly generic in name in case
// the application developer is going to have a namespace clash with us...
// the exact name doesn't really matter
NSString * kRMStorageCache = @"__RMCache";

NSUInteger kRMDefaultStorageLimit = 2000;
double kRMDefaultStoragePruneFraction = 0.15;

@implementation RMStorage

@synthesize delegate;


- (double)pruneFraction;
{
	return pruneFraction;
}

- (void)setPruneFraction:(double)num
{
	// stop someone from doing something that will get us injured
	if (num<0.0) {
		pruneFraction = 0.0;
	} else if (num > 1.0) {
		pruneFraction = 1.0;
	} else {
		pruneFraction = num;
	}
}

// load up our instance variables that depend on the defaults subsystem
- (void)_processDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *vector =  
	[NSDictionary dictionaryWithObjectsAndKeys:
	 i(kRMDefaultStorageLimit,kRMKeyStorageLimit),
	 f(kRMDefaultStoragePruneFraction,kRMKeyStoragePruneFraction),
	 nil];
	[defaults registerDefaults:vector];
	
	max = [defaults integerForKey:kRMKeyStorageLimit];
	[self setPruneFraction:[defaults doubleForKey:kRMKeyStoragePruneFraction]];
}

// this is a shared object, kind of stupidly... it sends messages to its delegate
// based on errors, which means that we may have some competition for it... therefore
// we are going to have to juggle the delegate to play nice with the rest of the system
- (void)_pushd;
{
	delegateStack = [fileManager delegate];
	[fileManager setDelegate:self];
}

- (void)_popd;
{
	[fileManager setDelegate:delegateStack];
	delegateStack = nil;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error linkingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
	return YES;
}

- (NSString *)_constructCache:(NSString *)name
{
    /* create path to cache directory inside the application's Documents directory */
	NSError *error;
	NSString *path = [RMStorage pathForCache:name];
	BOOL isDirectory = NO;
	BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
	
	[self _pushd];
    /* check for existence of cache directory */
    if (exists && !isDirectory) {
		// delete it, and create a new one, this is kind of paranoid assuming
		// someone may have made a file with our name in it, but might as well
		// be careful
		if (![fileManager removeItemAtPath:path error:&error]){
			RMError(error);
		}
		exists = NO;
	} 
	
	if (!exists) {
		if (![fileManager createDirectoryAtPath:path
                    withIntermediateDirectories:YES
                                     attributes:nil 
                                          error:&error]) 
		{
			RMError(error);
		}
    }
	return path;
}

- (void)_load;
{
	// now we are down to counting the number of requests in the file... the 
	// "Apple Way" consists of allocating several thousand NSStrings in an
	// array, returning them to us, and letting us count the array... obviously,
	// and hilariously stupid. So for this we will revert to the UNIX way.
	CFIndex len = [directory length]+1;
	char buf[len];
	CFStringGetFileSystemRepresentation((CFStringRef)directory,buf,len);
	count = RMDirCount(buf);
}

- init;
{
	if (!(self = [super init])){
		return nil;
	}
	[self _processDefaults];
	requests = [NSMutableDictionary new];
	fileManager = [[NSFileManager defaultManager] retain];
	directory = [[self _constructCache:kRMStorageCache] retain];
	[self _load];
	return self;
}

- (void)dealloc;
{
	[requests release];
	[fileManager release];
	[directory release];
	[super dealloc];
}

- (void)empty
{
	NSError *error;
    if (![fileManager removeItemAtPath:directory error:&error]) {
        RMError(error);
    }
	[directory release];
	directory = nil;
	directory = [[self _constructCache:kRMStorageCache] retain];
}    

// This is where the magic happens... we are first going to make a big
// attempt to avoid filename clashes by 64 bit hashing. 
- (RMCacheEntry *)storedCacheEntryForKey:(NSString *)key;
{
	RMCacheEntry *entry = nil;
	uint64_t hash = [key hash64];
	NSMutableString *datafile = [directory mutableCopy];
	
	[datafile appendFormat:@"/%qx",hash];
	
	while ([fileManager fileExistsAtPath:datafile]){
		// we need to verify it against the inverted file, there are
		// 18,0000,000,000,000,000,000 possibilities in the hash above
		// so we are not likely to have to probe very often, so we're
		// not super concerned about a miss and reading extra data, 
		// this should, SHOULD, *should*, _should_, almost never, ever
		// happen.
		entry = [NSKeyedUnarchiver unarchiveObjectWithFile:datafile];
		if ([entry.key isEqualToString:key]){
			// we verified this is the correct file
			return entry;
		}
		// if we got here, we hit the lottery, we need to linear probe for the
		// next one..., append a . to resolve the name clash and go back to the
		// loop beginning...
		[datafile appendString:@"."];
	}
		// we broke the loop, which means we have a filename for the key
		// and it doesn't exist, so we will create it and hook it up, and 
		// set it going 
	entry = [[RMCacheEntry new] autorelease];
	entry.key = key;
	entry.filename = datafile;
	return entry;
}



- (void)_prune;
{
		// time to prune
		double pc = pruneFraction * max;
		NSUInteger pruneCount = pc;
		count -= pruneCount;
		// we could fork a thread here, but given concurrency, it might
		// be better to just delay our other tasks while we prune the cache
		// we do this in bulk and won't be doing it very often, so it should
		// likely be ok
		NSUInteger removed = RMPrune([directory fileSystemRepresentation],pruneCount);
		if (removed != pruneCount){
			NSLog(@"RMPrune() returned %u when requested %u",removed,pruneCount);
		}
	
}

- (void)_attemptPrune;
{
	if (count >= max) {
		[self _prune];
	}
}

// This method will retrieve an NSData object from the filesystem that matches
// the requested key and return it. If the key is not in the filesystem,
// this method will create NSMutableData for the key and enter the key
// into the key table, and will return it ready to write. By checking the
// length of the object returned, you should treat it as mutable or immutable. 
// (A zero length data object will be mutable and ready to receive data from the
// network, and a data object with length will be ready to return to the caller)

- (void)loadCacheEntry:(RMCacheEntry *)entry;
{
	// we will retain this through the network cycle
	[entry retain];
	[requests setObject:entry forKey:entry.key];
	entry.delegate = self;
	// this will signal us back when it has completed the 
	// network load
	[entry load];
}

- (void)loadCacheEntryForKey:(NSString *)key;
{
	RMCacheEntry *entry = [requests objectForKey:key];
	if (entry) {
		// we already have an open data for this key, this means
		// we have something on the go for this data object already.
		return;
	}
	// we have no knowledge of the key, so we will load or 
	// create one
	entry = [self storedCacheEntryForKey:key];

	if ((entry.data)){
		// we have data loaded from the cache, so we can
		// signal our delegate that the entry loaded
		[delegate cacheEntryDidLoad:entry];
	} else {
		[self loadCacheEntry:entry];
	}
}


// Tells the cold storage object to archive the given contents into the filesystem.
// The data object should previously have been retrieved by dataForKey: and
// written into by the network callbacks. If the data is still zero length when
// closed, the matching key in the key table will be discarded.
- (void)cacheEntryDidLoad:(RMCacheEntry *)entry
{
	[NSKeyedArchiver archiveRootObject:entry toFile:entry.filename];
	entry.filename = nil;
	[requests removeObjectForKey:entry.key];
	[delegate cacheEntryDidLoad:entry];
	[entry autorelease];
}

- (void)cacheEntryDidFail:(RMCacheEntry *)entry
{
	entry.filename = nil;
	[delegate cacheEntryDidFail:entry];
	[requests removeObjectForKey:entry.key];
	[entry autorelease];
}


+ (NSString *)pathForResource:(NSString *)name inDirectory:(NSSearchPathDirectory)spd
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(spd, NSUserDomainMask, YES);
	NSString *documents = [paths objectAtIndex:0] ;
	NSString *archivePath = [documents stringByAppendingPathComponent:name];
	return archivePath;	
}

+ (NSString *)pathForDocument:(NSString *)name;
{
	return [self pathForResource:name inDirectory:NSDocumentDirectory];
}

+ (NSString *)pathForCache:(NSString *)name;
{
	return [self pathForResource:name inDirectory:NSCachesDirectory];
}


@end
