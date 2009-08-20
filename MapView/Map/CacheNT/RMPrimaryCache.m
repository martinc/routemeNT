//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

#import "RMPrimaryCache.h"
#import "RMTileImage.h"

// default keys and values

NSString * const kRMKeyPrimaryCacheMemoryLimit = @"RMPrimaryCacheSize";
NSUInteger kRMDefaultPrimaryCacheMemoryLimit = 1000000;



// a cell in our cache structure, which is a double linked list
typedef struct __RMCacheCell {
	struct __RMCacheCell *left;
	struct __RMCacheCell *right;	
	id cached;    // object we're caching
	int32_t length; // the size of the data it holds
}  RMCacheCell;

// the DLL master structure
struct __RMCache {
	RMCacheCell *start;   // head of the list
	RMCacheCell *end;     // tail of the list
	unsigned count;       // number of items we hold
	unsigned length;        // total size of memory the cells cache
	RMCacheCell *bin;     // a recycling bin to put used cells on
	CFMutableDictionaryRef mapping;  // maps the key to a cache cell
} ;

@implementation RMPrimaryCache


// some convenience defines so that our defaults registration vector can be read
// without getting confused halfway to hell and back

#define b(a,b) [NSNumber numberWithBool:a], b
#define i(a,b) [NSNumber numberWithInteger:a], b
#define d(a,b) [NSNumber numberWithDouble:a], b
#define f(a,b) [NSNumber numberWithFloat:a], b

///////////////////////////////////////////////////////////////// CACHE DATASTRUCTURE

// for use in a CFDictionary to compare two cache cells
static Boolean 
RMCacheCellEqual(const void *value1,const void *value2)
{
	return ((RMCacheCell *)value1)->cached == ((RMCacheCell *)value2)->cached;
}

// creates a new cache cell, pulling it from the recycle bin if necessary
static inline RMCacheCell *
RMCacheNewCell(RMCache *self)
{
	RMCacheCell *cell;
	if (self->bin) {
		cell = self->bin;
		memset(cell,'\0',sizeof(*cell));
		self->bin = self->bin->right;
	} else {
		cell = calloc(1,sizeof(RMCacheCell));	
	}
	return cell;
}

// places a cell onto the recycle bin
static inline void
RMCacheRecycleCell(RMCache *self, RMCacheCell *cell)
{
	cell->right = self->bin;
	self->bin = cell;
}

// removes an arbitrary entry from the cache
static void
RMCacheRemove(RMCache *self, NSString *key)
{
	RMCacheCell * cell = (void *)CFDictionaryGetValue(self->mapping,key);
	CFDictionaryRemoveValue(self->mapping,key);
	
	RMCacheCell *left = cell->left;
	RMCacheCell *right = cell->right;
	if (left) {
		left->right = right;
	} else {
		self->start = right;
	}
	if (right){
		right->left = left;
	} else {
		self->end = left;
	}
	self->count--;
	self->length -= cell->length;
	[cell->cached release];
	RMCacheRecycleCell(self,cell);
}

// adds a new cell to the cache and retains the item
static inline void
RMCacheAdd(RMCache *self, id cached)
{
	NSString *key = [cached key];
	if (CFDictionaryContainsKey(self->mapping,key)){
		RMCacheRemove(self,key);
	}
	RMCacheCell *cell = RMCacheNewCell(self);
	cell->cached = [cached retain];
	cell->length = [cached length];
	self->length += cell->length;
	self->count++;
	if (!self->end) {
		self->end = cell;
	} else {
		// if there is an end then there is a start
		self->start->left = cell;
	}
	cell->right = self->start;
	self->start = cell;
	CFDictionaryAddValue(self->mapping,key,cell);
}

// removes the last cell in the cache and releases
// its contents
static inline BOOL
RMCachePop(RMCache *self)
{
	BOOL value = NO;
	RMCacheCell *cell = self->end;
	if (cell){
		id cached = cell->cached;
		self->length -= cell->length;
		self->count--;
		self->end = cell->left;
		if (!self->end) {
			self->start = 0;
		} else {
			self->end->right = 0;
		}
		RMCacheRecycleCell(self,cell);
		CFDictionaryRemoveValue(self->mapping,[cached key]);
		[cached release];
		value = YES;
	}
	return value;
}

// removes a cell from an arbitrary position and establishes
// it at the head of the list.
static inline void
RMCacheMoveCellToStart(RMCache *self, RMCacheCell *cell)
{
	RMCacheCell *left = cell->left;
	if (left) {
		// snip it out
		RMCacheCell *right = cell->right;
		if (right) {
			right->left = left;
		} else {
			self->end = left;
		}
		left->right = right;
		// stick it on the front
		self->start->left = cell;
		cell->right = self->start;
		cell->left = 0;
		self->start= cell;
	}
}

// empties the cache and releases the contents... 
static inline void
RMCacheEmpty(RMCache *self)
{
	while(RMCachePop(self));
}

// frees the memory associated with the cache
// structure, and empties the cache, releasing 
// the contents
static inline void
RMCacheFree(RMCache *self)
{
	RMCacheEmpty(self);
	RMCacheCell *cell = self->bin;
	while (cell) {
		self->bin = cell->right;
		free(cell);
		cell = self->bin;
	}
	free(self);
}

// returns the object in the cache matching the key,
// or returns nil... if the lookup is successful, the
// object in the cache is moved to the head to implement
// LRU sorting... constant time operations.
static inline id
RMCacheGetValue(RMCache *self, NSString *key)
{
	RMCacheCell *value = (RMCacheCell *)CFDictionaryGetValue(self->mapping,key);
	if (value) {
		RMCacheMoveCellToStart(self,value);
		return value->cached;
	} else {
		return nil;
	}
}

// creates a new RMCache object
static inline RMCache *
RMCacheNew(void)
{
	RMCache *self = calloc(1,sizeof(RMCache));	
	CFDictionaryValueCallBacks cb = {
		0,NULL,NULL,NULL,RMCacheCellEqual
	};
	self->mapping = CFDictionaryCreateMutable(0,0,&kCFTypeDictionaryKeyCallBacks,&cb);
	return self;
}

// Partially empties the cache, up until it hits its memory limit, items
// in the cache are released
static inline void 
RMCachePurgeToLimit(RMCache *self, unsigned memoryLimit)
{
	// check sizes
	while (self->length > memoryLimit){
		RMCachePop(self);
	}
}

///////////////////////////////////////////////////////////////////// OBJECT


@dynamic memoryLimit;

- (NSUInteger)memoryLimit;
{
	return memoryLimit;
}


- (void)setMemoryLimit:(NSUInteger)newLimit;
{
	memoryLimit = newLimit;
	RMCachePurgeToLimit(cache,memoryLimit);
}

// load up our instance variables that depend on the defaults subsystem
- (void)_processDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *vector =  
	[NSDictionary dictionaryWithObjectsAndKeys:
	 i(kRMDefaultPrimaryCacheMemoryLimit,kRMKeyPrimaryCacheMemoryLimit),
	 nil];
	[defaults registerDefaults:vector];
	
	memoryLimit = [defaults integerForKey:kRMKeyPrimaryCacheMemoryLimit];
}

// duh
- init;
{
	if ((self = [super init])){
		[self _processDefaults];
		cache = RMCacheNew();
	}
	return self;
}

// returns nil or the image if it is in the cache...

- (id <RMCacheable>)objectForKey:(NSString *)key;
{
	return RMCacheGetValue(cache,key);
}

- (void)addObject:(id <RMCacheable>)entry;
{
	RMCacheAdd(cache,entry);
	RMCachePurgeToLimit(cache,self->memoryLimit);
}


- (void)empty;
{
	RMCacheEmpty(cache);
}

- (void)dealloc;
{
	RMCacheFree(cache);
	[super dealloc];
}

@end
