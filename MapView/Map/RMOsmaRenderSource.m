//
//  YSOsmarenderMapSource.m
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMOsmaRenderSource.h"


@implementation RMOsmaRenderSource

-(NSString*) tileURL: (RMTile) tile
{
	return [NSString stringWithFormat:@"http://tah.openstreetmap.org/Tiles/tile/%d/%d/%d.png", tile.zoom, tile.x, tile.y];
}

-(NSString*) description
{
	return @"OSMOsmarender";
}

@end
