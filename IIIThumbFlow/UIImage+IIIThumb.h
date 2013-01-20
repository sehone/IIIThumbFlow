//
//  UIImage+IIIThumb.h
//  IIIThumbFlow
//
//  Created by sehone on 12/22/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import <UIKit/UIKit.h>
/*
 * Smaller this rate, the padding(white border) would be wider.
 * thumbPaddingWidth = thumbWidth / rate
 */
#define iii_thumb_padding_rate 20.0f

@interface UIImage (IIIThumb)

+ (UIImage *)thumbWithURL:(NSString *)url width:(CGFloat)width;
+ (UIImage *)thumbWithURL:(NSString *)url height:(CGFloat)height;
+ (UIImage *)thumbWithURL:(NSString *)url width:(CGFloat)width height:(CGFloat)height;

- (UIImage *)setThumbWithURL:(NSString *)url width:(CGFloat)width;
- (UIImage *)setThumbWithURL:(NSString *)url height:(CGFloat)height;
- (UIImage *)setThumbWithURL:(NSString *)url width:(CGFloat)width height:(CGFloat)height;

- (UIImage *)thumbWithWidth:(CGFloat)width;
- (UIImage *)thumbWithHeight:(CGFloat)height;
- (UIImage *)thumbWithWidth:(CGFloat)width height:(CGFloat)height;

@end
