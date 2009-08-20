//
//  RMTileImageSet.m
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

#import "RMTileImageSet.h"
#import "RMTileImage.h"
#import "RMPixel.h"
#import "RMTileSource.h"

// For notification strings
#import "RMTileLoader.h"

#import "RMMercatorToTileProjection.h"

//#define NSLog(a,...)

@implementation RMTileImageSet

@synthesize delegate, tileSource;

-(id) initWithDelegate: (id) _delegate
{
	if (![super init])
		return nil;
	
	tileSource = nil;
	self.delegate = _delegate;
	images = [[NSCountedSet alloc] init];
	return self;
}


- (NSString *)description;
{
	return [images description];
}

-(void) dealloc
{
	[self removeAllTiles];
	[tileSource release];
	[images release];
	[super dealloc];
}

-(void)removeTile:(RMTile)tile forImage:(RMTileImage *)image
{
	//NSLog(@"removeTile forImage");

	NSAssert(!RMTileIsDummy(tile), @"attempted to remove dummy tile");
	if (RMTileIsDummy(tile))
	{
		RMLog(@"attempted to remove dummy tile...??");
		return;
	}
	
	RMTileImage *dummyTile = [RMTileImage dummyTile:tile];
	if ([images countForObject:dummyTile] == 1)
	{
		//NSLog(@"Nuking: %@",[image description]);
		[image setMarked:YES];
		[image cancelLoading];
		[image removeFromMap];
	} else {
		NSLog(@"Skipping: %@",[image description]);
	}
	[images removeObject:dummyTile];
}

-(void) removeTile: (RMTile) tile
{
	NSLog(@"removeTile: tile");

	if (RMTileIsDummy(tile))
	{
		NSLog(@"attempted to remove dummy tile...??");
		return;
	}
	RMTileImage *dummyTile = [RMTileImage dummyTile:tile];
	if ([images countForObject:dummyTile] == 1)
	{
		RMTileImage *image = [self imageWithTile:tile];
		//NSLog(@"Nuking: %@",[image description]);
		[image setMarked:YES];
		[image cancelLoading];
		[image removeFromMap];
	}
	[images removeObject:dummyTile];
}

-(void) removeTiles: (RMTileRect)rect
{	
	NSLog(@"TileImageSet removeTiles: rect");

	RMTileRect roundedRect = RMTileRectRound(rect);
	// The number of tiles we'll load in the vertical and horizontal directions
	int tileRegionWidth = (int)roundedRect.size.width;
	int tileRegionHeight =  (int)roundedRect.size.height;
	
	RMTile t;
	t.zoom = rect.origin.tile.zoom;
	
	id<RMMercatorToTileProjection> proj = [tileSource mercatorToTileProjection];
	
	for (t.x = roundedRect.origin.tile.x; t.x < roundedRect.origin.tile.x + tileRegionWidth; t.x++)
	{
		for (t.y = (roundedRect.origin.tile.y); t.y <= roundedRect.origin.tile.y + tileRegionHeight; t.y++)
		{
			RMTile normalisedTile = [proj normaliseTile: t];
			if (RMTileIsDummy(normalisedTile))
			{
				continue;				
			}
			
			[self removeTile:normalisedTile];
		}
	}
}

-(void) removeTilesOutsideOf: (RMTileRect)rect
{
	RMTileImage *img;
	RMTile tile;
	uint32_t x, y;
	uint32_t minx, maxx, miny, maxy;
	float min;
	int dz, imgDz, rectDz;
	short currentZoom = rect.origin.tile.zoom;

	min = rect.origin.tile.x + rect.origin.offset.x;
	minx = floorf(min);
	maxx = floorf(min + rect.size.width);
	min = rect.origin.tile.y + rect.origin.offset.y;
	miny = floorf(min);
	maxy = floorf(min + rect.size.height);

	
//NSLog(@"In %s, rect = {%u, %u}, %hi, %@; bounds == {%u..%u, %u..%u}.", __FUNCTION__, rect.origin.tile.x, rect.origin.tile.y, rect.origin.tile.zoom, NSStringFromCGRect(CGRectMake(rect.origin.offset.x, rect.origin.offset.y, rect.size.width, rect.size.height)), minx, maxx, miny, maxy);
	for(img in [images allObjects])
	{
		if (0 && [img marked]) {
			// this image got deleted elsewhere, so we ignore it
			continue;
		}
		tile = img.tile;
		x = tile.x;
		y = tile.y;
		dz = tile.zoom - currentZoom;
		if(dz < 0)
		{
			// Tile is too large for current zoom level
			imgDz = 0;
			rectDz = -dz;
		}
		else
		{
			// Tile is too small & detailed for current zoom level
			imgDz = dz;
			rectDz = 0;
		}
		if(
			x >> imgDz > maxx >> rectDz || x >> imgDz < minx >> rectDz ||
			y >> imgDz > maxy >> rectDz || y >> imgDz < miny >> rectDz
		) {
//NSLog(@"In %s, removing tile at {%u, %u}, %hi.", __FUNCTION__, tile.x, tile.y, tile.zoom);
			[self removeTile:tile forImage:img];
		} else 
		// we should want to prune other images if the current image matches the
		// zoom level and it is loaded, and we allowed it to stay on screen, 
		// in which case, we should nuke anything else that looks to be on its same
		// spot
#if 0
#warning choosing to prune competing tiles		
		if(dz == 0 && [img isLoaded])
		{
			[self removeCompetingTiles:tile usingZoom:currentZoom];
		}
#else 
#warning choosing to prune any tile that doesn't belong with this zoom
		if (dz != 0) {
			// tile doesn't match our zoom, delete it
			NSLog(@"Expecting nuke: %@",[img description]);
			[self removeTile:tile forImage:img];
		}
#endif		
	}
}

- (void)removeCompetingTiles:(RMTile)newTile usingZoom:(short)zoom
{
	RMTileImage *img;
	RMTile oldTile;
	int dz, newDz, oldDz;
	int removalCount = 0;
	// this is a search routine attempting to find the 
	// old tile that has the same x,y of the new tile
	// at a given zoom... if it finds the old tile it 
	// replaces it with the new tile... someone didn't
	// know what a hashtable was
	unsigned newAbsZ = abs(zoom-newTile.zoom);
	for(img in [images allObjects])
	{
		if ([img marked]) {
			// the matching tile was deleted, ignore it
			continue;
		}
		oldTile = img.tile;
		int oldAbsZ = abs(zoom-oldTile.zoom);
#ifdef OLD_AND_BUSTED
// if tiles load out of order, this means that the bad res tile
// is going to come in and skip over the good res tile... instead
// we want to walk through the tiles until we find our compatriot
// and then examine the two tiles, and discard the worse one	
		if(oldAbsZ <= newAbsZ)
		{
			continue;
		}
#endif		
		dz = oldTile.zoom - newTile.zoom;
		if(dz < 0){
			oldDz = 0;
			newDz = -dz;
		} else {
			oldDz = dz;
			newDz = 0;
		}
		if(oldTile.x >> oldDz == newTile.x >> newDz &&
		   oldTile.y >> oldDz == newTile.y >> newDz)
		{
			removalCount++;
#ifdef OLD_AND_BUSTED
			[self removeTile:oldTile];
#else
			// we need to compare the two tiles and discard the worse one
			if (oldAbsZ < newAbsZ){
				// discard new, old is closer to the zoom
				[self removeTile:newTile];
			} else if (oldAbsZ > newAbsZ) {
				[self removeTile:oldTile];
			} else {
				// we found ourselves, don't remove us
				// but continue to search
				continue;
			}
			// we should only remove on a one to one basis
			// so we don't need to keep looping through the whole
			// thing... furthermore we're going to mutate our
			// list while iterating it
			break;
#endif
		}
	}

//	NSLog(@"Removed %d from stack",removalCount);

}

-(void) removeAllTiles
{
	NSArray * imagelist = [images allObjects];
	for (RMTileImage * img in imagelist) {
    NSUInteger count = [images countForObject:img];
		for (NSUInteger i = 0; i < count; i++)
			[self removeTile: img.tile];
	}
}

/* Untested.
 -(BOOL) hasTile: (Tile) tile
 {
 NSEnumerator *enumerator = [images objectEnumerator];
 TileImage *object;
 
 while ((object = [enumerator nextObject])) {
 if (TilesEqual(tile, [object tile]))
 return YES;
 }
 
 return NO;
 }*/


-(void)addTile:(RMTile)tile at:(CGRect) screenLocation
{
	//	RMLog(@"addTile: %d %d", tile.x, tile.y);
	
	RMTileImage *dummyTile = [RMTileImage dummyTile:tile];
	RMTileImage *tileImage = [images member:dummyTile];
	
	if (tileImage != nil)
	{
#warning testing... so far so good, seems to fix everything		
		return;
		
		[tileImage setScreenLocation:screenLocation];
		[images addObject:dummyTile];
	}
	else
	{
		RMTileImage *image = [tileSource tileImage:tile];
		if (image != nil) {
			image.screenLocation = screenLocation;
			[images addObject:image];
			if (!RMTileIsDummy(image.tile))
			{
				[delegate tileAdded:tile WithImage:image];
			}
		}
	}
}

// Add tiles inside rect protected to bounds. Return rectangle containing bounds
// extended to full tile loading area
-(CGRect) addTiles: (RMTileRect)rect ToDisplayIn:(CGRect)bounds
{
//	RMLog(@"addTiles: %d %d - %f %f", rect.origin.tile.x, rect.origin.tile.y, rect.size.width, rect.size.height);
	
	RMTile t;
	t.zoom = rect.origin.tile.zoom;
	
	// ... Should be the same as equivalent calculation for height.
	double pixelsPerTile = bounds.size.width;
	pixelsPerTile /= rect.size.width;
	
	CGRect screenLocation;
	screenLocation.size.width = pixelsPerTile;
	screenLocation.size.height = pixelsPerTile;
	
	RMTileRect roundedRect = RMTileRectRound(rect);
	// The number of tiles we'll load in the vertical and horizontal directions
	int tileRegionWidth = (int)roundedRect.size.width;
	int tileRegionHeight = (int)roundedRect.size.height;
	
	id<RMMercatorToTileProjection> proj = [tileSource mercatorToTileProjection];
		
	for (t.x = roundedRect.origin.tile.x; t.x < roundedRect.origin.tile.x + tileRegionWidth; t.x++)
	{
		for (t.y = (roundedRect.origin.tile.y); t.y <= roundedRect.origin.tile.y + tileRegionHeight; t.y++)
		{
			RMTile normalisedTile = [proj normaliseTile: t];
			if (RMTileIsDummy(normalisedTile))
				continue;
			
			screenLocation.origin.x = bounds.origin.x + (t.x - (rect.origin.offset.x + rect.origin.tile.x)) * pixelsPerTile;
			screenLocation.origin.y = bounds.origin.y + (t.y - (rect.origin.offset.y + rect.origin.tile.y)) * pixelsPerTile;
			
			[self addTile:normalisedTile at:screenLocation];
		}
	}
	
	// Now we translate the loaded region back into screen space for loadedBounds.
	CGRect newLoadedBounds;
	newLoadedBounds.origin.x = bounds.origin.x - (rect.origin.offset.x * pixelsPerTile);
	newLoadedBounds.origin.y = bounds.origin.y - (rect.origin.offset.y * pixelsPerTile);	
	newLoadedBounds.size.width = tileRegionWidth * pixelsPerTile;
	newLoadedBounds.size.height = tileRegionHeight * pixelsPerTile;
	return newLoadedBounds;
}

-(RMTileImage*) imageWithTile: (RMTile) tile
{
	NSEnumerator *enumerator = [images objectEnumerator];
	RMTileImage *object;
	
	while ((object = [enumerator nextObject]))
	{
		if (RMTilesEqual(tile, [object tile]))
			return object;
	}
	
	return nil;
}

-(NSUInteger) count
{
	return [images count];
	
}

- (void)moveBy: (CGSize) delta
{
	for (RMTileImage *image in images)
	{
		[image moveBy: delta];
	}
}

- (void)zoomByFactor: (double) zoomFactor near:(CGPoint) center
{
	for (RMTileImage *image in images)
	{
		[image zoomByFactor:zoomFactor near:center];
	}
}

- (void) drawRect:(CGRect) rect
{
	for (RMTileImage *image in images)
	{
		[image draw];
	}
}

- (void) printDebuggingInformation
{
	float biggestSeamRight = 0.0f;
	float biggestSeamDown = 0.0f;
	
	for (RMTileImage *image in images)
	{
		CGRect location = [image screenLocation];
/*		RMLog(@"Image at %f, %f %f %f",
			  location.origin.x,
			  location.origin.y,
			  location.origin.x + location.size.width,
			  location.origin.y + location.size.height);
*/
		float seamRight = INFINITY;
		float seamDown = INFINITY;
		
		for (RMTileImage *other_image in images)
		{
			CGRect other_location = [other_image screenLocation];
			if (other_location.origin.x > location.origin.x)
				seamRight = MIN(seamRight, other_location.origin.x - (location.origin.x + location.size.width));
			if (other_location.origin.y > location.origin.y)
				seamDown = MIN(seamDown, other_location.origin.y - (location.origin.y + location.size.height));
		}
		
		if (seamRight != INFINITY)
			biggestSeamRight = MAX(biggestSeamRight, seamRight);
		
		if (seamDown != INFINITY)
			biggestSeamDown = MAX(biggestSeamDown, seamDown);
	}
	
	RMLog(@"Biggest seam right: %f  down: %f", biggestSeamRight, biggestSeamDown);
}

- (void)cancelLoading
{
	for (RMTileImage *image in images)
	{
		[image cancelLoading];
	}
}


@end
