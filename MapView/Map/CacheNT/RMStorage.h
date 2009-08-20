//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

#import <Foundation/Foundation.h>
#import "RMCacheEntry.h"

// This is a storage manager for the secondary cache. Its job is to take 
// key names which are string representations of URLs and uniquely reduce
// them, and store them, into files in the filesystem, while minimizing secondary
// storage access. 

// The general algorithm is as follows:

// 1. Inbound URLs are checked in the key table, if present, then the key
//    is returned as NSData. If not present, NSMutableData is created for the URL
//    key and returned.
//
// 2. Strings are mapped to files by hashing them down to a filename code. Clashes
//    are resolved by appending a sequence number to the filename. 
//    

// This object takes care of managing a maximum count of files in secondary
// storage, as well as pruning them when they reach a maximum. Pruning is done
// in batches, where a percentage (by default 15%) of the existing files are
// removed. Obviously if you set the percentage of pruning very high and the
// count very low, you could get some pretty bad behavior.


// this is the default maximum number of items stored in cold storage, when
// this number is hit, the LRU stored object will be removed. 
@interface RMStorage : NSObject <RMCacheDelegate> {
	// maps open data objects to keys
	NSMutableDictionary *requests;
	// our file workhorse
	NSFileManager *fileManager;
	
	// number of items we're holding
	NSUInteger count;
	
	// max we should hold
	NSUInteger max;
	
	// how many we should nuke when we clean up
	float pruneFraction;
	
	// The directory in which we reside. This is built from the NSCaches directory
	// and the above filename.
	NSString *directory;
	// This is the inverted directory, where we store the reverse mappings...
	NSString *inverted;
	// backing up the NSFileManager delegate
	id delegateStack;
	
	id <RMCacheDelegate> delegate;
}

@property (nonatomic,assign) id <RMCacheDelegate> delegate;

// This method will retrieve an NSData object from the filesystem that matches
// the requested key and return it. If the key is not in the filesystem,
// this method will create NSMutableData for the key and enter the key
// into the key table, and will return it ready to write. By checking the
// length of the object returned, you should treat it as mutable or immutable. 
// (A zero length data object will be mutable and ready to receive data from the
// network, and a data object with length will be ready to return to the caller)
// If the key has been previously requested, but not closed (i.e. there is
// a pending request from the network on this already), this method will return
// nil to prevent double-writes to the existing key.
- (void)loadCacheEntryForKey:(NSString *)key;

// this method will attempt to load the object from storage, if the entry was
// not in storage, the entry will have nil for its data. In which case you can
// call loadCacheEntry: and you will receive the data via callback when it's
// ready
- (RMCacheEntry *)storedCacheEntryForKey:(NSString *)key;
- (void)loadCacheEntry:(RMCacheEntry *)entry;

// Forces the cache to completely empty itself, deleting everything in secondary
// storage.
- (void)empty;

// Class methods to obtain directories.
+ (NSString *)pathForDocument:(NSString *)name;
+ (NSString *)pathForCache:(NSString *)name;
+ (NSString *)pathForResource:(NSString *)name inDirectory:(NSSearchPathDirectory)spd;



@end
