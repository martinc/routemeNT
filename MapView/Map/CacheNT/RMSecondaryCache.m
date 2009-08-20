//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

#import "RMSecondaryCache.h"

NSString * const kRMKeySecondaryCacheImmediateRead = @"RMSecondaryCacheImmediateRead";
BOOL kRMDefaultSecondaryCacheImmediateRead = YES;


#define b(a,b) [NSNumber numberWithBool:a], b
#define i(a,b) [NSNumber numberWithInteger:a], b
#define d(a,b) [NSNumber numberWithDouble:a], b
#define f(a,b) [NSNumber numberWithFloat:a], b

@implementation RMSecondaryCache

// load up our instance variables that depend on the defaults subsystem
- (void)_processDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *vector =  
	[NSDictionary dictionaryWithObjectsAndKeys:
	 b(kRMDefaultSecondaryCacheImmediateRead,kRMKeySecondaryCacheImmediateRead),
	 nil];
	[defaults registerDefaults:vector];
	
	immediateRead = [defaults boolForKey:kRMKeySecondaryCacheImmediateRead];
}


///////////////////////////////////////////////////////////// PROPERTIES
@dynamic delegate;

- (id <RMCacheDelegate>)delegate;
{
	id delegate;
	@synchronized(self) {
		delegate = _delegate;
	}
	return delegate;
}

- (void)setDelegate:(id <RMCacheDelegate>) delegate;
{
	@synchronized(self){
		[delegate retain];
		[_delegate release];
		_delegate = delegate;
	}
}

- (CFRunLoopRef)runLoop;
{
	CFRunLoopRef value = NULL;
	@synchronized(self) {
		value = _runLoop;
	}
	return value;
}

- (void)setRunLoop:(CFRunLoopRef)runLoop;
{
	@synchronized(self) {
		if (runLoop) {
			CFRetain(runLoop);
		}
		if (_runLoop) {
			CFRelease(_runLoop);
		}
		_runLoop = runLoop;
	}
}

///////////////////////////////////////////////////////////////////// RUN LOOP

- (void)_threadRunLoop:parameter
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	// normally the OS creates this thread with a 0.5 priority, and the main
	// thread is a 1.0.... we're going to downgrade to be extra nice
	[NSThread setThreadPriority:0.25];

	NSLog(@"%@: Starting run loop.",thread);
self.runLoop = CFRunLoopGetCurrent();
	{
		BOOL done = NO;
		do
		{
#warning not clear if this shoudl be YES or NO right now, NO seems faster			
			SInt32    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 5, NO);
			if ((result == kCFRunLoopRunStopped) || (result == kCFRunLoopRunFinished))
			{
				done = YES;
			}
		}
		while (!done);
	}
	NSLog(@"%@: Exiting run loop.",thread);
	self.runLoop = NULL;
    [pool release];
	threadRunning = NO;
}


/////////////////////////////////////////////////////////////// BUILDUP / TEARDOWN

- (void)dealloc
{
	// halt current run loop processing if it is active
	[self stop];

	self.runLoop = NULL;
	self.delegate = nil;
	// stop internal access to the thread object before removing it, 
	// out of paranoia/courtesy
	id _thread = thread;
	thread = nil;
	[_thread release];
	
	[storage release];
	[super dealloc];
}

- init;
{
	if ((self = [super init])){
		[self _processDefaults];
		thread = [[NSThread alloc] initWithTarget:self 
										  selector:@selector(_threadRunLoop:) 
										   object:nil];
		storage = [RMStorage new];
		storage.delegate = self;
//#warning dumping cache on startup
//		[storage empty];
	}
	return self;
}

- (void)start;
{
	if (!threadRunning) {
		threadRunning = YES;
		[thread start];
	}
}

- (void)stop;
{
	if (threadRunning) {
		CFRunLoopRef runLoop = self.runLoop;
		if (runLoop) {
			CFRunLoopStop(runLoop);
		}
	}
}

///////////////////////////////////////////////////////////////// REQUESTS

- (void)cacheEntryDidLoad:(RMCacheEntry *)entry
{
#ifdef RM_CACHE_DEBUG
	RMCacheTimestamp *tptr = [entry timestamp];
	tptr->application.requested = stamp;
#endif	
	[(id)self.delegate performSelectorOnMainThread:@selector(cacheEntryDidLoad:)
							   withObject:entry
							waitUntilDone:NO];
}

- (void)cacheEntryDidFail:(RMCacheEntry *)entry
{
	[(id)self.delegate performSelectorOnMainThread:@selector(cacheEntryDidFail:)
							   withObject:entry
							waitUntilDone:NO];
}

- (void)empty;
{
	[self start];
	[storage performSelector:@selector(empty)
					onThread:thread
				  withObject:nil
			   waitUntilDone:NO];
}

// Call this method when you would like a network key fetched/returned/cached.
// The work will be done in a secondary thread, but your callback will return in
// your own thread. The key as NSString should be a properly formatted URL.
- (RMCacheEntry *)cacheEntryForKey:(NSString *)_key;
{
#ifdef RM_CACHE_DEBUG
	stamp = [NSDate timeIntervalSinceReferenceDate];
#endif	
	// hand over a fresh copy to be sure we don't get any silliness 
	if (immediateRead) {
		RMCacheEntry * entry = [storage storedCacheEntryForKey:_key];
		if (entry.data) {
			return entry;
		} else {
			[storage performSelector:@selector(loadCacheEntry:) 
						onThread:thread
						  withObject:entry
					   waitUntilDone:NO];
		}
	}
	NSString * key = [_key copy];
	// be sure we're running
	[self start];
	[storage performSelector:@selector(loadCacheEntryForKey:) 
				 onThread:thread
			   withObject:key
			waitUntilDone:NO];
	// the method above has retained key while it is being executed
	// over the wall so we can dump it
	[key release];

	// returning nil tells him that his object is not ready and he will
	// get a callback
	return nil;
}



@end
