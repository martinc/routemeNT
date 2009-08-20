//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

#import "rm-cache.h"
#import <UIKit/UIKit.h>
#import <unistd.h>
#import <dirent.h>
#import <sys/stat.h>

NSString * const kRMKeyStorageLimit = @"RMStorageLimit";
NSString * const kRMKeyStoragePruneFraction = @"RMStoragePruneFraction";

void RMError(NSError *error)
{
    NSString *message = [NSString stringWithFormat:@"Error! %@ %@",
                         [error localizedDescription],
                         [error localizedFailureReason]];
    
    RMAlert(message);
}


void RMAlert(NSString *message)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"URLCache" 
                                                    message:message
                                                   delegate:nil 
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles: nil];
    [alert show];
    [alert release];
}

///////////////////////////////////////////////////////////// FILESYSTEM UTILS

// probably the fastest way of getting the count of what is in the directory currently
// we could hold the count and archive it, but this would bring up the possibility
// of an error causing a mismatch between filesystem and our count... so it is safer,
// though slower, to just iterate the cache when we start up and get our count at this
// point...
unsigned 
RMDirCount(const char *path)
{
	unsigned count = 0;
	struct dirent d,*dp;
	DIR *dirp = opendir(path);
	if (dirp) {
		while ((readdir_r(dirp,&d,&dp)) == 0 && dp){
			count++;
		}
		(void)closedir(dirp);
	}
	// remove the two special files "." and ".."
	return count-2;
}

typedef struct {
	char *path;
	struct stat sb;
} RMFileEntry;

static CFComparisonResult 
RMStatCompare(const void *ptr1, const void *ptr2, void *info)
{
	const RMFileEntry *d1 = ptr1;
	const RMFileEntry *d2 = ptr2;
	if (d1->sb.st_atimespec.tv_sec < d2->sb.st_atimespec.tv_sec){
		return kCFCompareLessThan;
	} else if (d1->sb.st_atimespec.tv_sec > d2->sb.st_atimespec.tv_sec){
		return kCFCompareGreaterThan;
	} else if (d1->sb.st_atimespec.tv_nsec < d2->sb.st_atimespec.tv_nsec){
		return kCFCompareLessThan;
	} else if (d1->sb.st_atimespec.tv_nsec > d2->sb.st_atimespec.tv_nsec){
		return kCFCompareGreaterThan;
	} else {
		return kCFCompareEqualTo;
	}
}

static inline RMFileEntry *
RMFileEntryCreate(struct dirent *dp, struct stat *sb)
{
	RMFileEntry *fe = malloc(sizeof(RMFileEntry));
	fe->sb = *sb;
	fe->path = malloc(dp->d_namlen+1);
	strcpy(fe->path,dp->d_name);
	return fe;
}

static inline void
RMFileEntryRelease(RMFileEntry *fe)
{
	free(fe->path);
	free(fe);
}

// Prunes the oldest 'number' files from the mainPath, and if the file exists
// in mirrorPath, it will be deleted from this location as well. Age is based
// not on creation time, but on access time. Returns the number deleted.

// What we're trying to do here is make a run through and in minimum space and
// time select the pruning set. We need to preserve the filenames in order to
// pass them to unlink() and we need the stat information to get the last access
// times. This can possibly be done better with getattrlist() and its ilk but
// the API for them is an utter mess and I'm first worried about correctness.
// Ideally stat() etc., are implemented on top of the filesystem in the most
// efficient way possible anyway... I hope.
unsigned
RMPrune(const char *mainPath, unsigned number)
{
	CFBinaryHeapCallBacks cb = {
		0,NULL,NULL,NULL,RMStatCompare
	};
	CFBinaryHeapRef heap = CFBinaryHeapCreate(0,number,&cb,0);
	unsigned count = 0;
	struct dirent d,*dp;
	struct stat current;
	RMFileEntry *fe;
	NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	NSLog(@"Pruning %u, wish me luck...",number);
	DIR *dirp = opendir(mainPath);
	if (dirp) {
		while ((readdir_r(dirp,&d,&dp)) == 0){
			if (stat(dp->d_name,&current)==0){
				if (count<number) {
					fe = RMFileEntryCreate(dp,&current);
					// we just add it to the heap
					CFBinaryHeapAddValue(heap,fe);
				} else {
					// check current vs. the top
					fe = (RMFileEntry *)CFBinaryHeapGetMinimum(heap);
					if (RMStatCompare(fe,&current,0) == kCFCompareLessThan){
						// pop the top, and insert current
						CFBinaryHeapRemoveMinimumValue(heap);
						RMFileEntryRelease(fe);
						fe = RMFileEntryCreate(dp,&current);
						CFBinaryHeapAddValue(heap,fe);
					}
				}
			}
			count++;
		}
		(void)closedir(dirp);
		count = 0;
		// the heap is now populated with the items we have to prune, now we will remove them
		while ((fe = (RMFileEntry *)CFBinaryHeapGetMinimum(heap))){
			CFBinaryHeapRemoveMinimumValue(heap);
			if (unlink(fe->path)!=0){
				NSLog(@"unlink() = %d, %s",errno,strerror(errno));
			} else {
				count++;
			}
			RMFileEntryRelease(fe);
		}
	}
	NSLog(@"Prune completed in %.4f seconds.",[NSDate timeIntervalSinceReferenceDate]-time);
	return count;
}


/////////////////////////////////////////////////////////////// CATEGORIES

@implementation NSString (RMHash64)

// fast string hashing... in my experience, the actual calculation of the
// hash function often outweighs the distribution, so ideally you want fast
// on both, but to not overweigh on trying to get the perfect distribution
// over a nice quick function to calculate it
static inline uint32_t
RMStringHash32Imp(const char *p)
{
    register uint32_t hash = 0;
    register uint32_t factor = 0;
    if (p) {
#define assign if (!(factor=(unsigned)(*p++))) break
		while(1) {
			assign;
			hash ^= factor;
			assign;
			hash *= factor;
		}
    }
#undef assign    
    return hash;
}

static inline uint32_t
RMStringHash32(CFStringRef rep)
{
	// try getting directly, should work but no guarantee
	CFStringEncoding e = CFStringGetFastestEncoding(rep);
	const char *p = CFStringGetCStringPtr(rep,e);
	if (p) {
		return RMStringHash32Imp(p);
	} else {
		unsigned len = CFStringGetLength(rep)+1;
		char buf[len];
		CFStringGetFileSystemRepresentation(rep,buf,len);
		return RMStringHash32Imp(buf);
	}
}

- (uint64_t) hash64;
{
	CFStringRef rep = (CFStringRef)self;
	// we will hash twice with two different algorithms, and then
	// use this to create a 64 bit unsigned which will be pretty hard
	// to clash on... both of these are 32 bit hashes, but we will
	// pretend to make no assumptions with the CFHash, so this will
	// work correctly if it changes to 64 bits on some platform or other,
	// though the hash code type is typedefed specifically to a 32 bit
	// entity.
	uint64_t hash64 = CFHash(rep);
	uint64_t hash32 = RMStringHash32(rep);
	hash64 ^= (hash32 << 32);
	return hash64;
}

- (NSString *)stringWithHash64;
{
	uint64_t hash64 = [self hash64];
	return [NSString stringWithFormat:@"%qx",hash64];
}

@end



