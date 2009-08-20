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

///////////////////////////////////////////////////////////////// DEFAULT KEYS

// You can set and override these, for example, as follows:
//
// [[NSUserDefaults standardUserDefaults] setFloat:0.2 forKey:kRMKeyStoragePruneFraction];
//
// That will also store the default in the user defaults persistently. See
// the documentation on NSUserDefaults about setting up your default properties
// in a plist and loading them at launch time to override registration values.
//

// KEYS....

// The key and default value for the prune fraction. Set a value between
// 0 and 1. The default is 15% (0.15). Any attempts to set this above or
// below 0 and 1 will be clipped. The value is float. 

extern NSString * const kRMKeyStoragePruneFraction;

// This is the key used for NSUserDefaults to get the value for the cold storage
// max count. You can override it in the appropriate ways in NSUserDefaults. 
// Default value is 1,000 and the value is integer.

extern NSString * const kRMKeyStorageLimit;

// The key to control the default cache size. You can either set this 
// explicitly before startup, or any other way that NSUserDefaults says
// is appropriate for overriding a registered value. The number is an
// integer in bytes. The default is 1,000,000. Tiles can go between 100 bytes
// and 25,000 bytes aproximately depending on what they are showing. In
// practice a 25 image cache is going to cover about 500k of space, and
// be barely adequate for coverage

extern NSString * const kRMKeyPrimaryCacheMemoryLimit;

// Controls whether or not secondary cache reads are done in the main
// thread or offloaded into the worker thread. The default is YES.

extern NSString * const kRMKeySecondaryCacheImmediateRead; 

///////////////////////////////////////////////////////////////// ERROR UTILITIES

// Runs an alert panel for the error
extern void 
RMError(NSError *error);

// Runs an alert panel with a message
extern void 
RMAlert(NSString *message);

//////////////////////////////////////////////////////////////// FILESYSTEM UTILITIES

// Counts the number of items in a directory as efficiently as possible.
extern unsigned 
RMDirCount(const char *path);

// Prunes the oldest 'number' files from the mainPath, and if the file exists
// in mirrorPath, it will be deleted from this location as well. Age is based
// not on creation time, but on access time. Returns the number deleted.
extern unsigned
RMPrune(const char *mainPath, unsigned number);


//////////////////////////////////////////////////////////////// CATEGORIES


// Allows an NSString to hash to a 64 bit integer rather than the default
// 32 bit hash code. 

@interface NSString (RMHash64)
- (uint64_t) hash64;
- (NSString *)stringWithHash64;
@end


