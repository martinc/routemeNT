#ifdef RM_EXPERIMENTAL__
//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 


#import "RMImage.h"
#import <ImageIO/CGImageSource.h>

size_t 
RMImageGetLength(CGImageRef image)
{
	size_t bpr = CGImageGetBytesPerRow(image);
	size_t height = CGImageGetHeight(image);
	size_t length =  bpr*height;
	return length;
}

@implementation RMImage

@synthesize key;

- (void)dealloc
{
	[key release];
	[super dealloc];
}

@dynamic length;

- (NSUInteger)length;
{
	if (length == 0) {
		// if our length is 0 then we will calculate it and cache it, if 
		// our length is still 0 after that, just means we will recalc in
		// the future... which is ok
		length = RMImageGetLength([self CGImage]);
	}
	return length;
}

- (void)_log;
{
	//size_t _length = [self length];
	//NSLog(@"RMImage decompressed to: %u bytes",_length);
}


// This attempts to result in a decompressed base image by using an existing
// data provider to read the data from another CGImage, this is supposed
// to generate a decompressed bytestream for the destination image
- initByProviderStacking:(NSData *)data
{
	CGImageRef source = [[UIImage imageWithData:data] CGImage];
	CGDataProviderRef provider = CGImageGetDataProvider(source);
	
	size_t width = CGImageGetWidth(source);
	size_t height = CGImageGetHeight(source);
	size_t bitsPerComponent = CGImageGetBitsPerComponent(source);
	size_t bitsPerPixel = CGImageGetBitsPerPixel(source);
	size_t bytesPerRow = CGImageGetBytesPerRow(source);
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(source);
	CGBitmapInfo info = CGImageGetBitmapInfo(source);
	CGFloat *decode = NULL;
	BOOL shouldInteroplate = NO;
	CGColorRenderingIntent intent = CGImageGetRenderingIntent(source);
	
	CGImageRef image = 
		CGImageCreate(width, 
					  height, 
					  bitsPerComponent, 
					  bitsPerPixel, 
					  bytesPerRow, 
					  colorSpace, 
					  info, 
					  provider, 
					  decode, 
					  shouldInteroplate, 
					  intent);
	
	self = [super initWithCGImage:image];
	[self _log];
	CFRelease(image);
	return self;
}


/*
 
 Apple locked this out of the default frameworks, code is ready to go 
 one day when we're allowed to do it... stupids.
 
 
// This method works (most efficiently of the bunch I think) by creating 
// a CGIImageSource which is configured during the image creation call
// to build an image which caches the decompressed data. This is the
// correct way to handle this situation
- initByImageSource:(NSData *)data
{
    // Load (or reload) the image
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    if (source) {
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
							 (id)kCFBooleanTrue, (id)kCGImageSourceShouldCache,
							 (id)kCFBooleanTrue, (id)kCGImageSourceShouldAllowFloat,
							 nil];
	
		CGImageRef image = CGImageSourceCreateImageAtIndex(source,0,(CFDictionaryRef)options);
    
		CFRelease(source);
		
		self = [super initWithCGImage:image];
		
		CFRelease(image);
		[self _log];
		
	} else {
		// images that fail to load in init are supposed to return nil
		[self autorelease];
		return nil;
	}
}
 
 */




// This method works by creating an image bitmap graphics context, drawing
// into the bitmap graphics context, and then reading the bitmap into a 
// new image, and using that for the initializer. This might be useful because
// it will force out the alpha channel (in theory) but if we're loading
// purposefully transparent tiles then we've kind of screwed up. 
- initByDrawing:(NSData *)data;
{

	CGImageRef source = [[UIImage imageWithData:data] CGImage];
	CGSize size = [self size];
	CGRect rect = CGRectMake(0,0,size.width,size.height);
	UIGraphicsBeginImageContext(size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawImage(context,rect,source);
	CFRelease(source);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self = [super initWithCGImage:image.CGImage];
	
	[image release];

	[self _log];
	return self;
}

- initByDrawingBitmap:(NSData *)data
{
	CGImageRef source = [[UIImage imageWithData:data] CGImage];
	CGSize size = [self size];
	CGRect rect = CGRectMake(0,0,size.width,size.height);
	UIGraphicsBeginImageContext(size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawImage(context,rect,source);
	CFRelease(source);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self = [super initWithCGImage:image.CGImage];
	
	[image release];
	
	[self _log];
	return self;
	
}
	

- initWithData:(NSData *)data
{
	// normally CGImages are stored in compressed mode, this is 
	// done to save space, and they are decompressed when drawn... this
	// causes a lot of CPU hammering when dragging around a map view,
	// and what this little dance here does is to create a decompressed
	// image from our existing image, and swap them... the decompressed
	// bitmap image will take up much more space but should draw
	// very fast. since we are highly concerned with speed in this 
	// situation and are caching and rearranging these tiles, it 
	// makes sense for us to provide an option which will improve the
	// user's scrolling... this 

	return [self initBySourceImage:data];
}


@end
#endif
