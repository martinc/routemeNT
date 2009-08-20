//
//  RMTileImage.h
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#else
	#import <Cocoa/Cocoa.h>
typedef NSImage UIImage;
#endif

#import "RMTileFactory.h"
#import "RMFoundation.h"
#import "RMTile.h"


@interface RMTileImage : NSObject <RMTileClient>{
	UIImage *image;
	// I know this is a bit nasty.
	RMTile tile;
	CGRect screenLocation;
	
	// this is our URL that maps us to our image
	NSString *key;
	/// \deprecated appears to be cruft
	int loadingPriorityCount;
	
	// loading proxy
	id proxy;
	BOOL isLoading;
	BOOL isLoaded;
	// this is a temporary workaround to a stupid implementation in the tile
	// laoder... the concept of dummy tiles and searching linearily constantly
	// for matching tiles has to die, instead we need to have a tile stack 
	// object that keeps tabs on various tiles for a certain location ... but 
	// for now to make things work correctly, we're going to fix the existing
	// stupidity and then implement to a proper solution
	BOOL marked;
	/// Used by cache
	NSDate *lastUsedTime;
	
	/// \bug placing the "layer" on the RMTileImage implicitly assumes that a particular RMTileImage will be used in only 
	/// one UIView. Might see some interesting crashes if you have two RMMapViews using the same tile source.
	// Only used when appropriate
	CALayer *layer;
}

@property (nonatomic,assign,getter=marked) BOOL marked;

- (id) initWithTile: (RMTile)tile;
- (id)initWithTile: (RMTile) _tile fromFile: (NSString*) filename;
- (id) initWithTile: (RMTile)tile fromURL:(NSString*)url;

+ (RMTileImage*) dummyTile: (RMTile)tile;

//- (id) increaseLoadingPriority;
//- (id) decreaseLoadingPriority;

+ (RMTileImage*)imageForTile: (RMTile) tile withURL: (NSString*)url;
+ (RMTileImage*)imageForTile: (RMTile) tile fromFile: (NSString*)filename;
// Need to re-implement this after CacheNT Merge
//+ (RMTileImage*)imageForTile: (RMTile) tile withData: (NSData*)data;

- (void)drawInRect:(CGRect)rect;
- (void)draw;

- (void)moveBy:(CGSize) delta;
- (void)zoomByFactor:(double) zoomFactor near:(CGPoint) center;
- (void)makeLayer;

- (void)cancelLoading;
- (BOOL)isLoaded;
// unplugs the image's layer from the superlayer
- (void)removeFromMap;

- (void)addToLayer:(CALayer *)superlayer;
- (void)setImage:(UIImage *)_image;
//- (void)updateImageUsingData: (NSData*) data;

@property (readwrite, assign) CGRect screenLocation;
@property (readonly, assign) RMTile tile;
@property (readonly) CALayer *layer;
@property (readonly) UIImage *image;
@property (assign, nonatomic) RMTileImage *proxy;



@end
