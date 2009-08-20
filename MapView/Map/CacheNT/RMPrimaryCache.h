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

// This object has its guts implemented in C for high performance. 

// The datastructure employed is a mixed hashtable / linked list. The 
// hashtable gives O(1) lookup for inclusion testing / search of the 
// linked list. The linked list gives O(1) delete anywhere in the list 
// (once found) and O(1) addition to any known part of the list. Keeping
// track of the head and tail means that new additions can be added
// at the head O(1) and old items can be popped from the tail at O(1).
// Overall this gives an O(1) datastructure which is appropriate for
// maintaining least recently used information regarding a cache. Every
// time a cached object is referenced, the object is moved to the head
// of the linked list. Every time a new object is to enter, the oldest
// is popped off the end.

// The linked list also maintains a recycling bin for its cells, to
// avoid being caught up constantly in malloc/free, since the basic
// mode of operation here is to add and delete, in and out. Reuse
// brings low overhead and high performance in this regard.

// Lastly, the data structure monitors the size of the objects being
// added and keeps a running total. Should the size pass over the
// maximum space limits allowed, the cache will pop itself until 
// the limits are met.

// This object keeps the cache in NSData form rather than as UIImages.
// The reason is that PNG Images are compressed and the internal 
// representation of UIImage is unknown, but likely a bitmap. We
// can cache substantially more images in a given memory space
// if we keep them as PNG and let the decompression happen as they
// are dropped into the map view.

// linked list datastructure for the cache
typedef struct __RMCache RMCache;

// the primary cache is a cache delegate, taking its RMCacheEntry updates
// from the RMTileFactory that manipulates it
@interface RMPrimaryCache : NSObject
{
	NSUInteger memoryLimit;
	RMCache *cache;
}

// changing the memory limit will cause the cache to immediately 
// size itself down to respect the new limit if necessary
@property (nonatomic,assign) NSUInteger memoryLimit;

// returns nil, or the cached image for the key
- (id <RMCacheable>)objectForKey:(NSString *)key;
- (void)addObject:(id <RMCacheable>)entry;

// empties the cache
- (void)empty;

@end
