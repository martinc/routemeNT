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
#import <UIKit/UIKit.h>

// 
// Protocol for objects who want to receive cache updates to implement. 
// Cached items are handed around similar to being in a bucket brigade,
// so one delegate implementing one level of caching can simply turn
// around and hand back to its delegate. These updates originate with
// the object itself coming out of the network, and then with the
// storage object unarchiving, the secondary cache handing back to the
// tile factory and the tile factory handing over to the primary cache. 
// The protocol is simple and allows easy communicaton between objects.
// 
@class RMCacheEntry;
@protocol RMCacheDelegate <NSObject>
- (void)cacheEntryDidLoad:(RMCacheEntry *)sender;
- (void)cacheEntryDidFail:(RMCacheEntry *)sender;
@end


// the protocol which is used by cache handlers to manipulate a 
// cached object... for the most part this is a high level 
// protocol as the low level caches are concerned with cache
// entries, but the high level cache handlers may decode the 
// cache entry data and hold cached objects of different classes
// who are represented in the data object, instead of the cache
// entry themselves

@protocol RMCacheable <NSObject>

// returns the key string that points to the origin of this
// object, it is generally used as a unique key identifying this
// object, and locating it or verifying it does not exist in a
// cache
- (NSString *)key;
- (void)setKey:(NSString *)urlAsString;

// counts the length in bytes of the object, this is used by 
// high level caches mostly in order to maintain high water 
// marks in the cache in terms of memory use, since no two
// keys will have the same memory footprint, it's important
// for a cache to operate on memory use rather than a hard count
- (NSUInteger)length;

@end


// A structure used to timestamp the RMCacheEntry object as it is handed
// about, it is put into use only if the kit is compiled with RM_CACHE_DEBUG
// defined. If so, then all of the timestamp macros in the kit will come
// alive and a report on the lifespan of the cache entry can be obtained 
// through -[RMCacheEntry description]. 
// 
typedef struct {
		NSTimeInterval created;
		struct {
			NSTimeInterval read;
			NSTimeInterval written;
		} filesystem;
		struct {
			NSTimeInterval requested;
			NSTimeInterval received;
		} network;
		struct {
			NSTimeInterval requested;
			NSTimeInterval received;
		} application;
} RMCacheTimestamp;

//
// The cache entry object represents a single chunk of data that has been fetched
// from a URL based key (could be disk or network, doesn't really matter,
// though for now the underlying implementation is only using network as a source).
//
// The cache entry object makes no care or worry about what kind of data it holds
// or what it took from the internet. Therefore this could be used to implement
// a URL cache holding any MIME type encountered on the internet, simply point it
// to a URL, and receive back data. The higher levels, such as the tile factory
// class, understand what they are requesting and so handle the data accordingly.
// If you interface directly with the secondary cache you can insert any URL type
// that you care to get a response for, and you will be able to cache and receive
// back the data. 

@interface RMCacheEntry : NSObject <NSCoding,RMCacheable> {
	NSString *key;					// a URL in string form, mapping us to our data 
	NSMutableData *data;				// the data we have or will get 
	NSString *filename;					// where we are stored in the filesystem,
										// this ivar is set to nil by the secondary
										// cache once it leaves its domain
	id <RMCacheDelegate> delegate;		// whomever will receive the notificaton
										// that this object updated from the internet
										// generally this is the storage object
#ifdef RM_CACHE_DEBUG				
	RMCacheTimestamp timestamp;			// debugging lifetime timing reports
#endif
}

// if you enable this macro, you can get a report of the time that various events
// ocurred in the lifetime of the cache object
#ifdef RM_CACHE_DEBUG
// these stamps are set within the secondary cache
#  define STAMP(object,flag) (object.timestamp)->flag = [NSDate timeIntervalSinceReferenceDate]
#  define STAMPWITH(object,flag,ti) (object.timestamp)->flag = ti
@property (nonatomic,assign) RMCacheTimestamp *timestamp;
#else
// if debugging is off the code vanishes... LIKE MAGIC
#  define STAMP(a,b) 
#  define STAMPWITH(a,b,c)
#endif

// properties
@property (nonatomic,retain) NSString *key;
@property (nonatomic,retain) NSData *data;
@property (nonatomic,retain) NSString *filename;
@property (nonatomic,assign) id<RMCacheDelegate> delegate;


// this is the default loader called by the secondary cache... you can
// override it to implement your own logic, the default loader simply
// calls [self loadFromNetwork:[self URL]], which gives you the ability
// to override at three levels to establish a change in behavior for
// the subclass while maintaining superclass functionality. 
- (void)load;

// Called to create a URL from the key string. You can override this
// if you want to implement custom behavior based on parsing the URL
// string. The default behavior is just to escape encode the string and
// attempt to get a URL out of it. 
- (NSURL *)URL;

// causes the cache entry object to load its data from the passed in
// URL. This is normally called from the load function, based on the
// URL returned by the url method.
- (void)loadFromNetwork:(NSURL *)url;

// returns the length of the data this cache entry holds
- (NSUInteger)length;

@end
