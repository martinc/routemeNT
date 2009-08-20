//
//  YSNoNameMapSource.m
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMNoNameSource.h"


@implementation RMNoNameSource


-(NSString*) tileURL: (RMTile) tile
{
	return [NSString stringWithFormat:@"http://tile.cloudmade.com/fd093e52f0965d46bb1c6c6281022199/3/256/%d/%d/%d.png", tile.zoom, tile.x, tile.y];
}

-(NSString*) description
{
	return @"OSMNoName";
}

@end
