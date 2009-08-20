//
//  YSCycleMapSource.m
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMCycleSource.h"


@implementation RMCycleSource

-(NSString*) tileURL: (RMTile) tile
{
	// a.
	return [NSString stringWithFormat:@"http://andy.sandbox.cloudmade.com/tiles/cycle/%d/%d/%d.png", tile.zoom, tile.x, tile.y];
}

-(NSString*) description
{
	return @"OSMCycle";
}

@end
