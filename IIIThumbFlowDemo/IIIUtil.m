//
//  IIIUtil.m
//  IIIThumbFlowDemo
//
//  Created by sehone on 12/29/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import "IIIUtil.h"

#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

@implementation IIIUtil


- (void)createImagesIfNotExists:(int)num atPath:(NSString *)path {
    int baseLength = 320;
    // colors
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:0];
    [a addObject:RGBA(120, 171, 130, 1)];
    [a addObject:RGBA(194, 204, 151, 1)];
    [a addObject:RGBA(160, 171, 128, 1)];
    [a addObject:RGBA(187, 201, 148, 1)];
    [a addObject:RGBA(151, 176, 121, 1)];
    [a addObject:RGBA(153, 164, 121, 1)];
    [a addObject:RGBA(230, 200, 78, 1)];
    [a addObject:RGBA(92, 141, 109, 1)];
    [a addObject:RGBA(160, 189, 158, 1)];
    [a addObject:RGBA(188, 191, 104, 1)];
    [a addObject:RGBA(235, 202, 73, 1)];
    [a addObject:RGBA(79, 164, 201, 1)];
    [a addObject:RGBA(54, 150, 175, 1)];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    // create if not exists
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *imgName;
    NSString *imgURL;
    NSString *markNum;
    UIImage *img;
    NSData *imgData;
    NSError *err;
    int width, height, fontSize;
    CGPoint markPoint;
    CGRect rect;
    UIColor *color;
    for (int i=0; i<num; i++) {
        // draw image if not exists
        imgName = [NSString stringWithFormat:@"%i.jpg", i+1];
        imgURL = [path stringByAppendingPathComponent:imgName];
        if (![fm fileExistsAtPath:imgURL]) {
            // create image with random size
            width = baseLength * ((arc4random() % 30 + 10) / 20.0f); // baseLength * [0.5, 2.0)
            height = baseLength * ((arc4random() % 20 + 10) / 10.0f); // baseLength * [1.0, 4.0)
            color = [a objectAtIndex:(arc4random() % a.count)];
            const CGFloat *colorComps = CGColorGetComponents(color.CGColor);
            
            markNum = [NSString stringWithFormat:@"%i", i+1];
            rect = CGRectMake(0, 0, width, height);
            fontSize = width / 5;
            markPoint = CGPointMake(fontSize/2, fontSize/2);
            
            UIGraphicsBeginImageContext(CGSizeMake(width, height));
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            CGContextSetRGBFillColor(ctx, colorComps[0], colorComps[1], colorComps[2], colorComps[3]);
            CGContextFillRect(ctx, rect);
            CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
            [markNum drawAtPoint:markPoint withFont:[UIFont systemFontOfSize:fontSize]];
            img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            imgData = [NSData dataWithData:UIImageJPEGRepresentation(img, 1.0f)];
            [imgData writeToFile:imgURL options:NSDataWritingAtomic error:&err];
            if (err) {
                NSLog(@"Create image file error: %@\nimage:%@", err.localizedDescription, imgName);
            } else {
                NSLog(@"Create image file done: %@", imgName);
            }
        }
    }
}

- (UIImage *)createImageWithWidth:(int)width Height:(int)height Color:(UIColor *)color {
    size_t area = width * height;
    size_t compPerPix = 4;  // rgba
    uint8_t pixelData[area * compPerPix];
    const CGFloat *colorComps = CGColorGetComponents(color.CGColor);
    for (size_t i=0; i<area; i++) {
        size_t offset = i * compPerPix;
        pixelData[offset] = colorComps[0]*255;
        pixelData[offset+1] = colorComps[1]*255;
        pixelData[offset+2] = colorComps[2]*255;
        pixelData[offset+3] = colorComps[3]*255;
    }
    
    size_t bitsPerComp = 8;
    size_t bytesPerRow = ((bitsPerComp * width) / 8) * compPerPix;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(&pixelData, width, height, bitsPerComp, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    // create image
    CGImageRef image = CGBitmapContextCreateImage(ctx);
    return [[UIImage alloc] initWithCGImage:image];
}



@end
