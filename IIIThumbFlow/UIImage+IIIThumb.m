//
//  UIImage+IIIThumb.m
//  IIIThumbFlow
//
//  Created by sehone on 12/22/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import "UIImage+IIIThumb.h"
#import "SDImageCache+IIIThumb.h"
#import <math.h>

@implementation UIImage (IIIThumb)


+ (UIImage *)thumbWithURL:(NSString *)url width:(CGFloat)width {
    return [UIImage thumbWithURL:url width:width height:0];
}

+ (UIImage *)thumbWithURL:(NSString *)url height:(CGFloat)height {
    return [UIImage thumbWithURL:url width:0 height:height];
}


+ (UIImage *)thumbWithURL:(NSString *)url width:(CGFloat)width height:(CGFloat)height {
    if (0 == width && 0 == height) {
        // Args incorrect, return
        return nil;
    }
    NSString *tKey = [UIImage thumbKeyWithURL:url width:width height:height];
    UIImage *cached = [[SDImageCache sharedThumbImageCache] imageFromKey:tKey];
    return cached ? cached : nil;
}

- (UIImage *)setThumbWithURL:(NSString *)url width:(CGFloat)width {
    return [self setThumbWithURL:url width:width height:0];
}

- (UIImage *)setThumbWithURL:(NSString *)url height:(CGFloat)height {
    return [self setThumbWithURL:url width:0 height:height];
}

- (UIImage *)setThumbWithURL:(NSString *)url width:(CGFloat)width height:(CGFloat)height {
    if (0 == width && 0 == height) {
        // Args incorrect, return
        return nil;
    }
    NSString *tKey = [UIImage thumbKeyWithURL:url width:width height:height];
    UIImage *thumb = [self thumbWithWidth:width height:height];
    [[SDImageCache sharedThumbImageCache] storeImage:thumb forKey:tKey];
    return thumb;
}


// Bind size with image local url
+ (NSString *)thumbKeyWithURL:(NSString *)url width:(CGFloat)width height:(CGFloat)height {
    return [NSString stringWithFormat:@"#%i#%i#%@", (int)round(width), (int)round(height), url];
}

- (UIImage *)thumbWithWidth:(CGFloat)width {
    return [self thumbWithWidth:width height:0];
}

- (UIImage *)thumbWithHeight:(CGFloat)height {
    return [self thumbWithWidth:0 height:height];
}

// Create thumb
- (UIImage *)thumbWithWidth:(CGFloat)width height:(CGFloat)height {
    CGFloat w, h;
    CGFloat r = self.size.width / self.size.height;
    if (0 == height) {
        // thumb with specific width, X2 for retina display
        w = width*2;
        h = w / r;
    } else if (0 == width) {
        // thumb with specific height
        h = height*2;
        w = h * r;
    } else {
        if (r <= width/height) {
            h = height*2;
            w = h * r;
        } else {
            w = width*2;
            h = w / r;
        }
    }
    // Draw thumb
    CGRect rect;
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    rect = CGRectMake(0, 0, w, h);
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(ctx, rect);
    CGFloat p = width / iii_thumb_padding_rate;
    [self drawInRect:CGRectMake(p, p, w-p*2, h-p*2)];
    UIImage *thumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumb;
}


@end
