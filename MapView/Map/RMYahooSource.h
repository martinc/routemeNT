//
//  YSYahooMapsSource.h
//  YellowSpacesFree
//
//  Created by samurai on 1/29/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMAbstractMercatorWebSource.h"

@interface RMYahooSource : RMAbstractMercatorWebSource <RMAbstractMercatorWebSource> {

}

// Yahoo Maps follows its own co-ordinate system. These methods will recalculate
// the tiles for use in the URL based on Yahoo's system, from the internal system
// (Google). Call this in subclasses before passing on co-ordinates into a URL.

- (void)transformZoom:(NSUInteger *)zoom tileX:(NSInteger *)x tileY:(NSInteger *)y;

// Alternatively, you can just override the format string, and the superclass will
// insert the variables in order of X, Y, ZOOM
- (NSString *)formatString;


@end
