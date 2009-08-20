//
//  YSYahooMapsSource.m
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMYahooSource.h"
//#import "AppDelegate.h"

//http://aerial.maps.yimg.com/ximg?v=1.9&t=a&s=256&x=2412&y=1015&z=14&r=1
@implementation RMYahooSource

/* 
 *  YMapConfig.setRegTile(…+"&tilename=basemap&");
 * YMapConfig.setSatTile(…+"&tilename=aerial&");
 * YMapConfig.setHybTile(tileServerBaseURL+"&tilename=hybrid&");
*/

// Overview on the calculating....
//
// Differences from Google to Yahoo

// Yahoo Zoom = Google Zoom + 1
// Yahoo X = Google X
// Yahoo Y is in flipped co-ordinates, starting at the equator. 
//
// YY = GY 
// GZ^2 = number of tiles from north to south in total
// GY starts at 0 for north pole
// YY starts at 0 for equator
// YY = GZ^2 - GZ

// # tiles = 2^gzoom = 2^(yzoom-1)
// Zoom 0 = 1 tile
// Zoom 1 = 2 tile
// Zoom 2 = 4 tiles
// Zoom 3 = 8 tilens
// Zoom 4 = 16 tiles

// Example GZoom = 3 = 8 tiles
// Yahoo Y tiles would be ->    3  2  1  0 -1 -2 -3 -4
// Google Y tiles would be ->   0  1  2  3  4  5  6  7 

// Example GZoom = 4 = 16 tiles
// YY 7  6  5  4  3  2  1  0 -1 -2 ...
// GG 0  1  2  3  4  5  6  7  8  9 ...

// The mapping is YY = ((2^(gz-1))-1) -GY

// Test sample:

// http://mt1.google.com/mt?v=w2.89&hl=en&x=5&y=12&z=4&s=Gal
//
// YZ = GZ+1 = 4+1 = 5
// YX = GX = 5
// YY = (2^(GZ-1)-1) -GY  = (2^(4-1)-1) -12 = 8 - 1 - 12 = -5

// Calculate URL: (5,-5,5)
// http://us.tile.maps.yimg.com/tl?v=4.2&x=5&y=-5&z=5&r=1

// same image, QED

- (void)transformZoom:(NSUInteger *)zoom tileX:(NSInteger *)x tileY:(NSInteger *)y
{
	// The mapping is YY = ((2^(gz-1))-1) -GY
	NSUInteger gy = *y;
	double gz = (double)*zoom;
	*y = (NSUInteger)(pow(2.0,(gz-1.0)));
	*y = *y -1 -gy;
	
	// do this last! we need it for the previous calc
	*zoom = *zoom+1;
	// do nothing to X
}	


- (NSString *)formatString
{
	return @"http://us.tile.maps.yimg.com/tl?v=4.2&x=%d&y=%d&z=%d&r=1";
}
						

-(NSString*) tileURL: (RMTile) tile
{
//http://us.maps3.yimg.com/aerial.maps.yimg.com/ximg?v=1.9&t=a&s=256&x=1208&y=507&z=13&r=1
//http://us.maps1.yimg.com/us.tile.maps.yimg.com/tl?v=4.2&x=1205&y=507&z=13&r=1
// http://us.tile.maps.yimg.com/tl?v=4.2&x=151&y=73&z=10&r=1

	NSUInteger zoom = tile.zoom;
	NSInteger x = tile.x;
	NSInteger y = tile.y;
	[self transformZoom:&zoom tileX:&x tileY:&y];
	NSString *url = [NSString stringWithFormat:[self formatString], x, y, zoom];
	return url;
}

-(NSString*) description
{
	return @"YahooMaps";
}

@end
