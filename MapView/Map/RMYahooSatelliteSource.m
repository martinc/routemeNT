//
//  YSYahooMapsSatelliteSource.m
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMYahooSatelliteSource.h"

@implementation RMYahooSatelliteSource

- (NSString *)formatString;
{
	return @"http://aerial.maps.yimg.com/ximg?v=1.9&t=a&s=256&x=%d&y=%d&z=%d&r=1&tilename=hybrid";
}

-(NSString*) description
{
	return @"YahooMapsSatellite";
}
@end
