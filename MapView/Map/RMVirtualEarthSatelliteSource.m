//
//  YSVirtualEarthSatelliteMapSource.m
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMVirtualEarthSatelliteSource.h"


@implementation RMVirtualEarthSatelliteSource

-(NSString*) urlForQuadKey: (NSString*) quadKey 
{
	NSString *mapType = @"h"; //overhead with labels
	NSString *mapExtension = @".png"; //extension
	//h = labels+overhead, g=234
	//TODO what is the ?g= hanging off the end 1 or 15?
	return [NSString stringWithFormat:@"http://tiles.virtualearth.net/tiles/%@%@%@?g=234", mapType, quadKey, mapExtension];
	
	return [NSString stringWithFormat:@"http://%@%d.ortho.tiles.virtualearth.net/tiles/%@%@%@?g=234", mapType, 3, mapType, quadKey, mapExtension];
}

-(NSString*) description
{
	return @"Microsoft VirtualEarth Satellite";
}

@end
