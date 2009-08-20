//
//  YSOpenAerialMapSource.m
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMOpenAerialSource.h"


@implementation RMOpenAerialSource

//http://tile.openaerialmap.org/tiles/1.0.0/openaerialmap-900913/0/0/0.jpg

-(NSString*) tileURL: (RMTile) tile
{
	return [NSString stringWithFormat:@"http://tile.openaerialmap.org/tiles/1.0.0/openaerialmap-900913/%d/%d/%d.jpg", tile.zoom, tile.x, tile.y];
}

-(NSString*) description
{
	return @"OpenAerialMap";
}

@end
