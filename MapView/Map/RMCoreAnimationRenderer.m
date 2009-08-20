//
//  RMCoreAnimationRenderer.m
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
#import "RMCoreAnimationRenderer.h"
#import <QuartzCore/QuartzCore.h>
#import "RMTile.h"
#import "RMTileLoader.h"
#import "RMPixel.h"
#import "RMTileImage.h"
#import "RMTileImageSet.h"

@implementation RMCoreAnimationRenderer

- (id) initWithContent: (RMMapContents *)_contents
{
	if (![super initWithContent:_contents])
		return nil;
	
	// NOTE: RMMapContents may still be initialising when this function
	//       is called. Be careful using any of methods - they might return
	//       strange data.

	layer = [[CAScrollLayer layer] retain];
	layer.anchorPoint = CGPointZero;
	layer.masksToBounds = YES;
	// If the frame is set incorrectly here, it will be fixed when setRenderer is called in RMMapContents
	layer.frame = [content screenBounds];
	layer.delegate = self;
	
	//lastSublayerCount = [layer.sublayers count];
	/*
#if 0	
	NSMutableDictionary *customActions = [NSMutableDictionary dictionaryWithDictionary:[layer actions]];

	[customActions setObject: forKey:@"sublayers"];
	layer.actions = customActions;
#endif
	 */
	
	// get a mutable version of the current actions dictionary
	customActions=[[NSMutableDictionary dictionaryWithDictionary:[layer actions]] retain];
	
	RMLog(@"actions are %@", customActions);
	
	// add the new action for sublayers
	[customActions setObject:[NSNull null] forKey:@"sublayers"];
	
	// set theLayer actions to the updated dictionary
	layer.actions=customActions;
	
	incomingLayers = [[NSMutableSet alloc] initWithCapacity:4];
	
	return self;
}

-(void) dealloc
{
	[fadein release];
	[layer release];
	[super dealloc];
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag;
{
	animating = NO;
}

- (void)animationDidStart:(CAAnimation *)animation;
{
	animating = YES;
}

// this method is consulted first ahead of everything
- (id<CAAction>)actionForLayer:(CALayer *)theLayer
                        forKey:(NSString *)key
{
	
	//if(theLayer == layer) RMLog(@"master layer");
	//RMLog(@"key is %@", key);
	//if(0){
	//if (!animating && animate && inserting) {
	//	if ([key isEqualToString:@"sublayers"] || 
			//	[key isEqualToString:kCAOnOrderIn] || 
			//	[key isEqualToString:kCAOnOrderOut] || 
			//	([key isEqualToString:@"onLayout"] && theLayer == layer) ||
	//		0
	//
	 
	//)
	/*
//	if ( [key isEqualToString:@"kCAOnOrderIn"] )
	if ( (!animating && animate && inserting) && [key isEqualToString:@"sublayers"] )
		{

		//	NSLog(@"incomingLayers has %d members and %@ the current layer", [incomingLayers count], [incomingLayers containsObject:theLayer]?@"contains" : @"does not contain");
		//	if([layer.sublayers count] > lastSublayerCount)
		//	{

			
				//NSLog(@"sublayers count %d", [layer.sublayers count]);
				//NSLog(@"allowed key: %@ for: %@",key,[theLayer description]);
				if (!fadein) {
					// this is copied anyway when we hand it in, so a
					// bit more memory overhead but probably better
					fadein = [[CATransition alloc] init];
					fadein.duration = 1.4;
					fadein.delegate = self;
					fadein.type = kCATransitionFade;
				}
				//lastSublayerCount = [layer.sublayers count];
				return fadein;
			//}
			//else lastSublayerCount = [layer.sublayers count];

		}
//	}
	 */

	// this kills the ongoing search for an animation, we don't want anything
	return (id)[NSNull null];
}
 

- (void)tileImageDidLoad:(RMTileImage *)image;
{
	[incomingLayers addObject:image.layer];
	inserting = YES;
	[layer insertSublayer:image.layer atIndex:0];
	inserting = NO;
	[incomingLayers removeObject:image.layer];

}

- (void)tileAdded: (RMTile) tile WithImage: (RMTileImage*) image
{
//	RMLog(@"tileAdded: %d %d %d at %f %f %f %f", tile.x, tile.y, tile.zoom, image.screenLocation.origin.x, image.screenLocation.origin.y,
//		  image.screenLocation.size.width, image.screenLocation.size.height);
	
//	RMLog(@"tileAdded");
	[image makeLayer];
	
	CALayer *sublayer = [image layer];
	
	sublayer.actions = customActions;
	[incomingLayers addObject:sublayer];

	sublayer.delegate = self;
	if ([image isLoaded]){
		inserting = YES;
		[layer insertSublayer:sublayer atIndex:0];
		inserting = NO;
	}
	
	[incomingLayers removeObject:sublayer];
	
//	[layer addSublayer:sublayer];
}

// this method is gone... its only purpose was to get a call from the TileImageSet
// saying that the tile was removed... so this method turned around and called 
// RMMapContents and said "please give me the TileImageSet... and the map contents
// sent back... the EXACT SAME OBJECT that called this method. Now this method
// with the object in hand, tells it to remove the image... insanity.
/*
 -(void) tileRemoved: (RMTile) tile

{
	RMTileImage *image = [[content imagesOnScreen] imageWithTile:tile];
	
//	RMLog(@"tileRemoved: %d %d %d at %f %f %f %f", tile.x, tile.y, tile.zoom, image.screenLocation.origin.x, image.screenLocation.origin.y,
//		  image.screenLocation.size.width, image.screenLocation.size.height);
	[image cancelLoading];
	[[image layer] removeFromSuperlayer];
 }
*/

- (void)setFrame:(CGRect)frame
{
	layer.frame = [content screenBounds];
}

- (CALayer*) layer
{
	return layer;
}

/*
- (void)moveBy: (CGSize) delta
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
					 forKey:kCATransactionAnimationDuration];
	
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[super moveBy:delta];
	[tileLoader moveBy:delta];

	[CATransaction commit];
}

- (void)zoomByFactor: (float) zoomFactor Near:(CGPoint) center
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
					 forKey:kCATransactionAnimationDuration];
	
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	[super zoomByFactor:zoomFactor Near:center];
	[tileLoader zoomByFactor:zoomFactor Near:center];
	
	[CATransaction commit];
}
*/

@end
