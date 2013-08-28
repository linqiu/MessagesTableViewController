//
// Created by Aaron Huttner on 4/22/13.
// Copyright (c) 2013 Gryphn. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface ImageWorker : NSObject {

}
@property NSInteger height;
@property NSInteger width;

- (id)initWithWidth:(NSInteger)width height:(NSInteger)height;

- (void)loadImageFromFilePath:(NSString *)path success:(void (^)(UIImage *))success;

+ (UIImage *)loadImageThumbnailFromFilePath:(NSString *)path width:(NSInteger)width height:(NSInteger)height;

- (void)addImageCache;

- (void)clearCache;

+ (NSString *)getUniqeFilePath;

+ (UIImage *)resizeImage:(UIImage *)image newSize:(CGSize)newSize orientation:(UIImageOrientation)orientation;

+ (NSData *)compressImageForSendAndSave:(UIImage *)iamge;
@end