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
#import "rm-cache.h"
#import "RMStorage.h"
#import "RMCacheEntry.h"

// This object implements a secondary storage cache that runs in a separate thread.
// You access it from the main thread using the published interface, rather than
// signalling it over the thread boundary. It takes care of that for you.


@interface RMSecondaryCache : NSObject <RMCacheDelegate> {
	// ivars to be accessed from one side of the thread boundary only,
	// no mutex locking
	RMStorage *storage;
	NSThread *thread;

	// inter-thread variables... these need to be accessed via properties
	// for mutex reasons
	CFRunLoopRef _runLoop;
	id <RMCacheDelegate> _delegate;
	BOOL immediateRead;
	BOOL threadRunning;
#ifdef RM_CACHE_DEBUG	
	NSTimeInterval stamp;
#endif	
}

// The recipient of cache updates.
@property (assign) id <RMCacheDelegate> delegate;


// Stops the run loop from running, and causes the worker thread to exit asynchronously.
// Normally you will not have to do this, as it will happen automatically during dealloc,
// but this interface is provided in case cache start/stop is required in the future.
// The worker thread starts automatically.
- (void)stop;


// empties out the cache on the disk
- (void)empty;

// Call this method when you would like a network key fetched/returned/cached.
// The work will be done in a secondary thread, but your callback will return in
// the main thread. If the secondary cache has been configured to load entries in
// the main thread, and it was able to load the entry, this method will return the
// loaded item. Otherwise it will return nil and you should expect a callback.
- (RMCacheEntry *)cacheEntryForKey:(NSString *)key; 

@end
