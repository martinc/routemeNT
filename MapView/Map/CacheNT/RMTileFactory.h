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
#import "RMSecondaryCache.h"

@protocol RMTileClient <NSObject>
// you will get one response from the cache and then be automatically removed
- (void)factoryDidLoad:(UIImage *)image forRequest:(NSString *)requestedResource;
- (void)factoryDidFail:(NSString *)requestedResource;
@end

@class RMPrimaryCache;

@interface RMTileFactory : NSObject <RMCacheDelegate> {
	RMPrimaryCache *primaryCache;
	RMSecondaryCache *secondaryCache;
	NSMutableDictionary *dispatchTable;
	BOOL currentlyLoading;
}

// you request an image from the tile factory, and if it is able to vend it
// immediately it will, otherwise you will be called back on the TileDelegate 
// protocol
+ (UIImage *)requestImage:(NSString *)key forClient:(id <RMTileClient>)client;

// If you are still waiting for a tile and have no further need for it (i.e. need to
// deallocate), you call this to cancel the pending update.
+ (void)cancelImage:(NSString *)key forClient:(id <RMTileClient>)delegate;

// Stops all processing of requests, halts the cache and secondary thread. Do this
// prior to application termination and cleanup. The process is reversible by
// asking for a new image, which will start everything back up again.
+ (void)shutdown;

// If you need to tune the memory use of the primary cache at runtime, this is
// how you get it.
+ (RMPrimaryCache *)primaryCache;


@end
