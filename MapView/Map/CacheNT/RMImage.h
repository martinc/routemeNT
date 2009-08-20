//
//  Created by samurai on 3/6/09.
//  Copyright 2009 quarrelso.me. All rights reserved. This code is hereby 
//  donated to the rote-me project, and is covered under the license terms
//  of the route-me project. There is no warrantee implied or granted. The 
//  author of this code is Darcy Brockbank. There is only one person in the 
//  world with this name, so google me if you need to contact me. I humbly 
//  request that this legal notice be kept on files of my authorship. 
// 

// this object is under development but is probably a dead end at least
// for now, i'm keeping it around for future possibilities though...
// the problem is that our tiles, at 256x256, are just unreasonably 
// large as that represents 64k pixels, and at 4 bytes per pixel 
// we're up to a quarter of a megabyte of memory use per tile. This
// would allow the default cache to hold 4 tiles instead of 100, and
// it is just too dear right now to consider as an option... as well
// apple has disabled some of the functions which would make creating
// a decompressed image, putting them into the private frameworks, 
// there are other ways around this but it makes no sense given the
// memory issues we're facing

#ifdef RM_EXPERIMENTAL__


#import <UIKit/UIKit.h>
#import "RMCacheEntry.h"

//
// A subclass of UIImage which makes it somewhat interchangeable with
// RMCacheEntry, at least for measuring size and tracking it in a data 
// cache... the protocol adopted is similar to querying an NSData object
// for its length in bytes.
//
// The particular nature of this object causes it to decompress the PNG
// or JPEG data that is stored in the NSData object being used to 
// initialize it. This is not normal, usually UIImages store the compressed
// version and decompress on the fly when drawing... this for us is 
// a problem because we have a lot of tiles, and since they are large
// tiles instead of small, we end up probably doing a lot of copies that
// are clipped out. So it is a lot of work, decompressing things which
// are never drawn. This kit gives an option to cache decompressed images
// for the map, which is what RMImage is. If using the decompressed option
// then images will be decompressed before handing off to the map view and
// managed by the primary cache. See RMTileFactory for details and rm-cache.h
// for the default key to change the default situation.


//
// A utility function to return the estimated decompressed size of an image.
// Returns the length in bytes required to store the image.
// 
extern size_t
RMImageGetLength(CGImageRef image);


@interface RMImage : UIImage <RMCacheable> {
	NSString *key;  // a key for the cache
	NSUInteger length;	 // our estimated length, which is calculated and then cached 
						 // since we are data-immutable
}

@property (nonatomic,retain) NSString *key;
@property (nonatomic,readonly) NSUInteger length;


// the default initializer calls initByImageSource:, this is the 
// proper way to initialize this object
- initWithData:(NSData *)data;

// this uses the graphics context to draw out and suck in a copy of 
// the image, which should be a decompressed bitmap. provided as an
// alternative
- initByDrawing:(NSData *)data;

// this uses a CGImageSource object to create the image and is the most
// efficient and honest way of making an uncompressed image
- initByImageSource:(NSData *)data;

// this attempts to read the NSData into an intermediary image and then
// use the intermediary as a source for itself, which should result
// in a decompressed bytestream... 
- initByProviderStacking:(NSData *)data;



@end

#endif
