//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

#import "RMTileFactory.h"
#import "RMPrimaryCache.h"
#import "RMImage.h"


@implementation RMTileFactory

// the workhorse tile factory instance underlying the class interface
static RMTileFactory *factory = nil;

// Notifications when tile loading has commenced and ended
#define kTILES_BEGAN_LOADING_NOTIFICATION @"kTILES_BEGAN_LOADING_NOTIFICATION"
#define kTILES_LOADED_NOTIFICATION @"kTILES_LOADED_NOTIFICATION"



// some convenience defines so that our defaults registration vector can be read
// without getting confused halfway to hell and back

#define b(a,b) [NSNumber numberWithBool:a], b
#define i(a,b) [NSNumber numberWithInteger:a], b
#define d(a,b) [NSNumber numberWithDouble:a], b
#define f(a,b) [NSNumber numberWithFloat:a], b


- (RMPrimaryCache *)_primaryCache;
{
	return primaryCache;
}

- (void)cacheEntryDidLoad:(RMCacheEntry *)entry;
{
#ifdef RM_CACHE_DEBUG	
	STAMP(entry,application.received);
	NSString *d = [entry description];
	NSLog(@"%@",d);
#endif	
	NSString *key = entry.key;
	id object = [dispatchTable objectForKey:key];
	
	UIImage *image = [[UIImage alloc] initWithData:entry.data];
	if ([object isKindOfClass:[NSMutableArray class]]){
		for (id client in object){
			[client factoryDidLoad:image forRequest:key];
		}
	} else {
		[object factoryDidLoad:image forRequest:key];
	}
	[dispatchTable removeObjectForKey:key];
	[primaryCache addObject:entry];
	[image release];
	
	
	int imagesLoadingCount = [dispatchTable count];
	if(!currentlyLoading && imagesLoadingCount != 0)
	{
		currentlyLoading = YES;
		[[NSNotificationCenter defaultCenter] postNotification:	
		 [NSNotification notificationWithName:kTILES_BEGAN_LOADING_NOTIFICATION object:nil]];

		
	}
	else if(currentlyLoading && [dispatchTable count] == 0)
	{
		currentlyLoading = NO;
		[[NSNotificationCenter defaultCenter] postNotification:	
		 [NSNotification notificationWithName:kTILES_LOADED_NOTIFICATION object:nil]];
		
	}
}

- (void)cacheEntryDidFail:(RMCacheEntry *)entry;
{
	NSString *key = entry.key;
	id object = [dispatchTable objectForKey:key];
	if ([object isKindOfClass:[NSMutableArray class]]){
		[object makeObjectsPerformSelector:@selector(factoryDidFail:)
								withObject:key];
	} else {
		[object factoryDidFail:key];
	}
	[dispatchTable removeObjectForKey:key];
}


- (void)_removeClient:(id <RMTileClient>)client forKey:(NSString *)key;
{
	id object = [dispatchTable objectForKey:key];
	if (object == client) {
		[dispatchTable removeObjectForKey:key];
	} else if ([object isKindOfClass:[NSArray class]]){
		[object removeObject:client];
		if (![object count]){
			[dispatchTable removeObjectForKey:key];
		}
	} 
	
	//RMLog(@"removeClient, pending item count is %d", [dispatchTable count]);

}


- (void)_addClient:(id <RMTileClient>)client forKey:(NSString *)key;
{
	id object = [dispatchTable objectForKey:key];
	if (object) {
		if (object == client){
			NSLog(@"%@ requested by same client %@",key,[(id)client description]);
		} else if ([object isKindOfClass:[NSMutableArray class]]){
		// this probably won't happen but might as well do it right...
		// if someone is already waiting for this URL, we turn the
		// dispatch table entry into an array and store them all
			[object addObject:client];
		} else {
			NSMutableArray *array = [NSMutableArray arrayWithObjects:object,client,nil];
			[dispatchTable setObject:array forKey:key];
		}
	} else {
		[dispatchTable setObject:client forKey:key];
	}
	
	//RMLog(@"addClient, pending item count is %d", [dispatchTable count]);
}

- (UIImage *)_imageForKey:(NSString *)key client:(id <RMTileClient>)client
{
	RMCacheEntry * response = nil;
	if (!(response = (id)[primaryCache objectForKey:key])){
		if (!(response = [secondaryCache cacheEntryForKey:key])){
			[self _addClient:client forKey:key];
			return nil;
		}
	}
	return [[[UIImage alloc] initWithData:response.data] autorelease];
}

- init;
{
	if ((self = [super init])){
		currentlyLoading = NO;
		primaryCache = [RMPrimaryCache new];
		secondaryCache = [RMSecondaryCache new];
		dispatchTable = [NSMutableDictionary new];
		[secondaryCache setDelegate:self];
	}
	return self;
}

- (void)dealloc
{
	[secondaryCache release];
	[dispatchTable release];
	[primaryCache release];
	[super dealloc];
}

////////////////////////////////////////////////////////// CLASS INTERFACE


+ (RMPrimaryCache *)primaryCache;
{
	return [factory _primaryCache];
}

+ (void)cancelImage:(NSString *)key forClient:(id <RMTileClient>)client;
{
	[factory _removeClient:client forKey:key];
}

+ (void)shutdown;
{
	[factory release];
	factory = nil;
}

+ (UIImage *)requestImage:(NSString *)key forClient:(id <RMTileClient>)client;
{
	if (!factory) {
		factory = [[self alloc] init];
	}
	return [factory _imageForKey:key client:client];
}


@end
