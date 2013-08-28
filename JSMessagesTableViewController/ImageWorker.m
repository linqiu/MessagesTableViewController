//
// Created by Aaron Huttner on 4/22/13.
// Copyright (c) 2013 Gryphn. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <ImageIO/ImageIO.h>
#import "ImageWorker.h"
#import "ImageCache.h"

#define MAX_RESIZE_TRIES 5
#define MAX_PHOTO_SIZE 100000
#define MAX_COMPRESSIONS_ALLOWED 0.3f
#define SCALE_CHANGE 0.5f

@interface ImageWorker ()
@property(strong, nonatomic) ImageCache *_imageCache;
@end

@implementation ImageWorker



- (id)initWithWidth:(NSInteger)width height:(NSInteger)height; {
    self = [super init];
    self.width = width;
    self.height = height;


    return self;
}

/*
* Might need to check for strong/weak references
*/
- (void)loadImageFromFilePath:(NSString *)path success:(void (^)(UIImage *))success {

    // If we are not passed in an image location then return
    if (!path) {
        return;
    }

    // Check to see if we already have this in the image cache
    UIImage *cachedImage;
    if (self._imageCache) {
        cachedImage = [self._imageCache getImageFromCache:path];
    }
    if (cachedImage) {
        success(cachedImage);
    } else if ([self cancelPotentialWork:path imageView:success]) {

        void(^loadImageBlock)();
        loadImageBlock = ^() {
            UIImage *image = [ImageWorker loadImageThumbnailFromFilePath:path width:self.width height:self.height];

            if (image && self._imageCache) {
                [self._imageCache addUIImageToCacheWithKey:path image:image];
            }

            // update imageView with loaded image
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    success(image);
                }
            });
        };

        dispatch_queue_t loadImageQueue = dispatch_queue_create("com.gryphn.securechat.loadImage", nil);
        dispatch_async(loadImageQueue, loadImageBlock);
    }
}

/**
* http://stackoverflow.com/questions/5860215/resizing-a-uiimage-without-loading-it-entirely-into-memory/5860390#5860390
*/
+ (UIImage *)loadImageThumbnailFromFilePath:(NSString *)path width:(NSInteger)width height:(NSInteger)height {
    NSData *imgData = [[NSFileManager defaultManager] contentsAtPath:path];

    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) imgData, NULL);
    if (!imageSource) {
        return nil;
    }

    NSInteger pixelSize = width > height ? width : height;

    CFDictionaryRef options = (__bridge CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
            (id) kCFBooleanTrue, (id) kCGImageSourceCreateThumbnailWithTransform,
            (id) kCFBooleanTrue, (id) kCGImageSourceCreateThumbnailFromImageIfAbsent,
            (id) [NSNumber numberWithFloat:pixelSize], (id) kCGImageSourceThumbnailMaxPixelSize,
            nil];

    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);

    UIImage *scaled = [UIImage imageWithCGImage:imgRef];

    CGImageRelease(imgRef);
    CFRelease(imageSource);

    return scaled;
}

//TODO implement dispatch_queue cancelation, this makes sure we are not processing the same UIImageView twice
//http://stackoverflow.com/questions/6737044/suspending-gcd-query-problem/6737719#6737719
- (Boolean)cancelPotentialWork:(NSString *)path imageView:(UIImageView *)imageView {

    return true;
}

- (void)addImageCache {
    self._imageCache = [[ImageCache alloc] init];
//    [self clearCache];
}

- (void)clearCache {
    if (self._imageCache) {
        void(^clearCacheBlock)() = ^{
            [self._imageCache clearCache];
        };

        dispatch_queue_t clearCacheQueue = dispatch_queue_create("com.gryphn.securechat.clearImageCache", nil);
        dispatch_async(clearCacheQueue, clearCacheBlock);
    }
}

+(NSString *)getUniqeFilePath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *imgDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"app_parts"];
    NSString *fileName = [[NSString stringWithFormat:@"app_part_%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0] stringByAppendingPathExtension:@"jpeg"];
    NSString *filePath = [imgDir stringByAppendingPathComponent:fileName];

    // create directory if it does not exist
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:imgDir withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
        NSLog(@"error created directory: %@", error);
    }

    return filePath;
}

+ (UIImage *)resizeImage:(UIImage *)image newSize:(CGSize)newSize orientation:(UIImageOrientation)orientation {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);

    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);

    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:1.0 orientation:orientation];

    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();

    return newImage;
}

+ (NSData *)compressImageForSendAndSave:(UIImage *)image {
    UIImage *workingImage = image;

    // turning image into NSData to test for size!
    NSData *imageData = UIImageJPEGRepresentation(workingImage, MAX_COMPRESSIONS_ALLOWED);

    // get initial size

    CGSize initSize;

    UIImageOrientation orientation = [workingImage imageOrientation];

    if ((orientation > 2 && orientation < 4) || (orientation > 5)) {
        initSize = CGSizeMake(workingImage.size.height, workingImage.size.width);
    }
    else {
        initSize = CGSizeMake(workingImage.size.width, workingImage.size.height);

    }

    CGSize resizeDim = CGSizeMake(initSize.width * SCALE_CHANGE, initSize.height * SCALE_CHANGE);
    // ratio is the CGFloat ratio of original image.

    // look at the size of that data

    // do the while loop to resize the image
    int retries = 0;

    NSUInteger dataSize = [imageData length];
    UIImage *imgCrop = [UIImage alloc];

    while (dataSize > MAX_PHOTO_SIZE && retries < MAX_RESIZE_TRIES) {
        imgCrop = [ImageWorker resizeImage:workingImage newSize:resizeDim orientation:orientation];

        imageData = UIImageJPEGRepresentation(imgCrop, MAX_COMPRESSIONS_ALLOWED);

        dataSize = [imageData length];

        // omg it's too big surprise surprise, let's resize this bizzle
        resizeDim = CGSizeMake(resizeDim.width * SCALE_CHANGE, resizeDim.height * SCALE_CHANGE);
        retries++;
    }

    return imageData;

}

@end