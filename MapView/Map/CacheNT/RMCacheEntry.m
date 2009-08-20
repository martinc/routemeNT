//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

#import "RMCacheEntry.h"


@implementation RMCacheEntry

@synthesize filename,data,key,delegate;

#ifdef RM_CACHE_DEBUG
@dynamic timestamp;
- (RMCacheTimestamp *)timestamp
{
	return &timestamp;
}
- (void)setTimestamp:(RMCacheTimestamp *)tsptr;
{
	timestamp = *tsptr;
}
#endif


- (unsigned)length;
{
	return [data length];
}

- (NSString *)description;
{
	NSMutableString *string = 
	[NSMutableString stringWithFormat:@"++++{ bytes = %u, key = %@ }\n",
		[data length],
	 key];
#ifdef RM_CACHE_DEBUG
#define PRINT(tag) \
	if (timestamp.tag) [string appendFormat:@"  %s: %.4f\n",#tag,timestamp.tag-ref]	
	NSTimeInterval ref = timestamp.application.requested;
	PRINT(application.requested);
	PRINT(created);
	PRINT(filesystem.read);
	PRINT(network.requested);
	PRINT(network.received);
	PRINT(filesystem.written);
	PRINT(application.received);
	[string appendString:@"\n"];
#endif	 
	
	return string;
}

static NSString * const kRMCacheEntryResource = @"RMResource";
static NSString * const kRMCacheEntryData = @"RMData";

- initWithCoder:(NSCoder *)coder
{
	if ((self = [super init])){
		STAMP(self,created);
		key = [[coder decodeObjectForKey:kRMCacheEntryResource] retain];
		data = [[coder decodeObjectForKey:kRMCacheEntryData] retain];
		STAMP(self,filesystem.read);
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:key forKey:kRMCacheEntryResource];
	[coder encodeObject:data forKey:kRMCacheEntryData];
	STAMP(self,filesystem.written);
}

- (void)dealloc
{
	[filename release];
	[data release];
	[key release];
	[super dealloc];
}

- (void)load;
{
	[self loadFromNetwork:[self URL]];
}

- (NSURL *)URL;
{
#if PARANOIA_IS_THE_ANSWER
  // clean the string out of paranoia
  NSString *query = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#else
  NSString *query = key;
#endif
  NSURL *url = [NSURL URLWithString:query];
  return url;
}

- (void)loadFromNetwork:(NSURL *)url;
{
	//	startTime = time(0);
	NSURLRequest *req = [NSURLRequest requestWithURL:url
						 // we let it use the protocol cache policy in case there is
						 // some caching server between us and the final destination.
						 // we will override local caching later on
										 cachePolicy:NSURLRequestUseProtocolCachePolicy
									 timeoutInterval:30.0];
	
	STAMP(self,network.requested);
	if (![[NSURLConnection alloc] initWithRequest:req delegate:self]){
		NSLog(@"Unable to create NSURLConnection.");
		[delegate cacheEntryDidFail:self];
	}  else {
		// IMPLEMENT NETWORK ACTIVITY START
	}
}

/////////////////////////////////////////////////////////// NSURLConnection DELEGATE

// These methods are handled on the worker side of the thread boundary.

// we defeat all attempts to cache our requests in memory... we *are* a cache
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[data release];
	data = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incoming
{
	[data appendData:incoming];
}

- (void)connection:(NSURLConnection *)connection
didFailWithError:(NSError *)error
{
    [connection release];
	// IMPLEMENT NETWORK ACTIVITY STOP
	[data release];
	data = nil;
	[delegate cacheEntryDidFail:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// IMPLEMENT NETWORK ACTIVITY STOP
    // release the connection
    [connection release];
	connection = nil;
	// CACHE THE DATA 
	STAMP(self,network.received);
	[delegate cacheEntryDidLoad:self];
}


@end
