//
// Created by Aaron Huttner on 4/22/13.
// Copyright (c) 2013 Gryphn. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface ImageCache : NSObject
-(id)init;

-(UIImage *)getImageFromCache:(NSString *)path;
-(void)clearCache;
-(void)addUIImageToCacheWithKey:(NSString *)path image:(UIImage*)image;

@end