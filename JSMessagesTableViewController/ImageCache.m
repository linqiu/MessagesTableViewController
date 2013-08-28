//
// Created by Aaron Huttner on 4/22/13.
// Copyright (c) 2013 Gryphn. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ImageCache.h"


@implementation ImageCache {

}
static NSUInteger *const CACHE_SIZE = 20;

NSCache *_imageCache;

-(id)init{
    _imageCache = [[NSCache alloc] init];
    [_imageCache setCountLimit:CACHE_SIZE];

    return self;
}

-(UIImage *)getImageFromCache:(NSString *)path {
    return [_imageCache objectForKey:path];

}

-(void)clearCache{
    [_imageCache removeAllObjects];
}

-(void)addUIImageToCacheWithKey:(NSString *)path image:(UIImage*)image {
    [_imageCache setObject:image forKey:path];
}

@end