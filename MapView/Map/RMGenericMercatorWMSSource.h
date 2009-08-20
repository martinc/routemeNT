
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import "RMLatLong.h"
#import "RMAbstractMercatorWebSource.h"

typedef struct { 
	CGPoint ul; 
	CGPoint lr; 
} CGXYRect; 

@interface RMGenericMercatorWMSSource : RMAbstractMercatorWebSource <RMAbstractMercatorWebSource> {
	NSMutableDictionary *wmsParameters;
	NSString *urlTemplate;
	CGFloat initialResolution, originShift;
}

- (RMGenericMercatorWMSSource *)initWithBaseUrl:(NSString *)baseUrl parameters:(NSDictionary *)params;

- (CGPoint)LatLonToMeters:(CLLocationCoordinate2D)latlon;
- (float)ResolutionAtZoom:(int)zoom;
- (CGPoint)PixelsToMeters:(int)px PixelY:(int)py atZoom:(int)zoom;
- (CLLocationCoordinate2D)MetersToLatLon:(CGPoint)meters;
- (CGXYRect)TileBounds:(RMTile)tile;
//- (RMLatLongBounds)TileLatLonBounds:(RMTile)tile;

@end
