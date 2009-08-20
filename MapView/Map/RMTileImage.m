//
//  RMTileImage.m
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
#import "RMGlobalConstants.h"
#import "RMTileImage.h"
#import "RMTileLoader.h"
#import "RMPixel.h"
#import "RMMapRenderer.h"

#import <QuartzCore/QuartzCore.h>

//#define NSLog(a,...) 

@implementation RMTileImage

@synthesize tile, layer, image;

@synthesize marked;

- (id) initWithTile: (RMTile)_tile
{
	if (![super init])
		return nil;
	
	tile = _tile;
	image = nil;
	layer = nil;
	screenLocation = CGRectZero;
		
	return self;
}
	

-(id)initWithTile:(RMTile) _tile fromFile: (NSString*) file
{
	if (![self initWithTile:_tile]){
		return nil;
	}
	image = [[UIImage alloc] initWithContentsOfFile:file];	
	return self;
}

- (void)removeFromMap;
{
//	NSLog(@"removeFromMap");
 [[layer superlayer] removeAllAnimations];
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
					 forKey:kCATransactionAnimationDuration];
	
	[CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
	
	[layer removeFromSuperlayer];
	
	
	[CATransaction commit];
	
	/*
#warning implement this cleaner 	
	[layer retain];
#define LAYER_CLEANUP_DELAY	0.01
	[layer performSelector:@selector(removeFromSuperlayer) withObject:nil
				afterDelay:LAYER_CLEANUP_DELAY];
	[layer performSelector:@selector(release) withObject:nil afterDelay:LAYER_CLEANUP_DELAY+1];
	 
	 */
}

- init
{
	[NSException raise:@"Invalid initialiser" format:@"Use the designated initialiser for TileImage"];
	[self release];
	return nil;
}

+ (RMTileImage*) dummyTile: (RMTile)tile
{
	return [[[self alloc] initWithTile:tile] autorelease];
}

- (void)dealloc
{
	// no point in trying to cancel here... if we were still
	// loading then the cache would have a reference to us
	// so we couldn't get into dealloc
	//	[self cancelLoading];
//	RMLog(@"Removing tile image %d %d %d", tile.x, tile.y, tile.zoom);
	
	[image release]; image = nil;
	[layer release]; layer = nil;
	[key release];
	key = nil;
	
	[super dealloc];
}

- (void)drawInRect:(CGRect)rect
{
	[image drawInRect:rect];
/*	if (image != NULL)
	{
		CGContextRef context = UIGraphicsGetCurrentContext();

		RMLog(@"image width = %f", CGImageGetWidth(image));
		//		CGContextClipToRect(context, rect);
		CGContextDrawImage(context, rect, image);
	}*/
}

-(void)draw
{
	[image drawInRect:screenLocation];
}

+ (RMTileImage*)imageForTile:(RMTile) _tile withURL: (NSString*)url
{
	return [[[RMTileImage alloc] initWithTile:_tile fromURL:url] autorelease];
}

+ (RMTileImage*)imageForTile:(RMTile) _tile fromFile: (NSString*)filename
{
	return [[[self alloc] initWithTile: _tile fromFile:filename] autorelease];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"((RMTileImage *)%p) %@: [%c%c%c] X=%d Y=%d zoom=%d",self,
			key,
			marked?'x':' ',
			isLoading?'+':' ',
			isLoaded?'*':' ',
			tile.x<<(18-tile.zoom),
			tile.y<<(18-tile.zoom),
			tile.zoom];
}

/*
+ (RMTileImage*)imageForTile:(RMTile) tile withData: (NSData*)data
{
	RMTileImage *image = [[RMTileImage alloc] initWithTile:tile];
	[image updateImageUsingData:data];
	return [image autorelease];
}
*/

-(void) cancelLoading
{
	if (isLoading) {
		[RMTileFactory cancelImage:key forClient:self];
	}
}

- (void)addToLayer:(CALayer *)superlayer
{
	[superlayer insertSublayer:layer atIndex:0];

/* CacheNT merge - not sure about this
	if (dataPending != nil)
	{
		[self updateImageUsingData:dataPending];
		[dataPending release];
		dataPending = nil;
		
//		RMLog(@"loadPendingData");
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:RMResumeExpensiveOperations object:nil];

	*/
}


- (void)setImage:(UIImage *)_image;
{
	if (!_image) {
		return;
	}
	isLoaded = YES;
	if (layer) {
		id delegate = [layer delegate];
		layer.delegate = nil;
		layer.contents = (id)[_image CGImage];
		layer.delegate = delegate;
		if ([delegate respondsToSelector:@selector(tileImageDidLoad:)]){
			[delegate performSelector:@selector(tileImageDidLoad:) withObject:self];
		}
	} else {
		image = [_image retain];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:RMMapImageLoadedNotification 
														object:self];
	
}


/* CacheNT merge - not sure if these and setImage need to be merged
 
- (void)updateImageUsingData: (NSData*) data
{
	if ([RMMapContents performExpensiveOperations] == NO)
	{
//		RMLog(@"storing data for later loading");
		[data retain];
		[dataPending release];
		dataPending = data;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPendingData:) name:RMResumeExpensiveOperations object:nil];
		return;
	}
	
	UIImage *tileImage = [[UIImage alloc] initWithData:data];
	
	if (layer == nil)
	{
		image = [tileImage retain];
	}
	else
	{
		CGImageRef cgImage = [tileImage CGImage];
		layer.contents = (id)cgImage;
	}
	
	[tileImage release];
	
	NSDictionary *d = [NSDictionary dictionaryWithObject:data forKey:@"data"];
	[[NSNotificationCenter defaultCenter] postNotificationName:RMMapImageLoadedNotification
														object:self
													  userInfo:d];
}
 */

- (BOOL)isLoaded
{
	return isLoaded;
/*	
	return image != nil
		|| (layer != nil && layer.contents != NULL);
*/ 
}

- (NSUInteger)hash
{
	return (NSUInteger)RMTileHash(tile);
}

- (BOOL)isEqual:(id)anObject
{
	if (![anObject isKindOfClass:[RMTileImage class]])
		return NO;

	return RMTilesEqual(tile, [(RMTileImage*)anObject tile]);
}




- (void)makeLayer
{
	if (layer == nil)
	{
		layer = [[CALayer alloc] init];
		layer.contents = nil;
		layer.anchorPoint = CGPointZero;
		layer.bounds = CGRectMake(0, 0, screenLocation.size.width, screenLocation.size.height);
		layer.position = screenLocation.origin;
		layer.edgeAntialiasingMask = 0;
		
//		RMLog(@"location %f %f", screenLocation.origin.x, screenLocation.origin.y);

	//		RMLog(@"layer made");
	}
	
	if (image != nil)
	{
		layer.contents = (id)[image CGImage];
		[image release];
		image = nil;
//		RMLog(@"layer contents set");
	}
}

- (void)moveBy: (CGSize) delta
{
	self.screenLocation = RMTranslateCGRectBy(screenLocation, delta);
}

- (void)zoomByFactor: (double) zoomFactor near:(CGPoint) center
{
	self.screenLocation = RMScaleCGRectAboutPoint(screenLocation, zoomFactor, center);
}

- (CGRect) screenLocation
{
	return screenLocation;
}

inline double fround(double n, unsigned d)
{
	return floor(n * pow(10., d) + .5) / pow(10., d);
}

- (void) setScreenLocation: (CGRect)newScreenLocation
{
//	RMLog(@"location moving from %f %f to %f %f", screenLocation.origin.x, screenLocation.origin.y, newScreenLocation.origin.x, newScreenLocation.origin.y);
	screenLocation = newScreenLocation;

//	screenLocation.origin.x = fround(screenLocation.origin.x,0);
//	screenLocation.origin.y = fround(screenLocation.origin.y,0);
	if (layer != nil)
	{
		//		layer.frame = screenLocation;
		layer.position = screenLocation.origin;
		layer.bounds = CGRectMake(0.0, 0.0, screenLocation.size.width, screenLocation.size.height);
	}
	
}

@synthesize proxy;

- (void)factoryDidLoad:(UIImage *)tileImage forRequest:(NSString *)requestedResource;
{
	isLoading = NO;
	[self setImage:tileImage];
}

- (id)initWithTile: (RMTile)_tile fromURL:(NSString*)urlStr
{
	if (![self initWithTile:_tile])
	return nil;
	key = [urlStr retain];
	image = [RMTileFactory requestImage:key forClient:self];
	if (image) {
		[image retain];
		isLoaded = YES;
	} else {
		isLoading = YES;
	}
	return self;
}

- (void)factoryDidFail:(NSString *)request;
{
	isLoading = NO;
}

@end
