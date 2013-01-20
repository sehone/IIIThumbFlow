//
//  IIIFlowCell.m
//  IIIThumbFlow
//
//  Created by sehone on 12/21/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import "IIIFlowCell.h"
#import "UIImage+IIIThumb.h"

@interface IIIFlowCell () {
}

@end

static CGFloat _cellPadding;

@implementation IIIFlowCell
@synthesize reuseId = _reuseId;
@synthesize image = _image;

- (id)initWithReuseId:(NSString *)idStr
{
    self = [super init];
    if (self) {
        // Initialization code
        self.reuseId = idStr;
        _cellPadding = iii_const_common_cell_padding;
        self.backgroundColor = iii_const_common_bg_color;
        self.frame = CGRectZero;
    }
    return self;
}

- (void)loadWithImage:(UIImage *)image cellWidth:(CGFloat)width {
    if (image) {
        // Set image view with thumb
        CGFloat imgWidth = width - _cellPadding * 2;
        CGFloat imgHeight = imgWidth * image.size.height / image.size.width;
        self.image = [[UIImageView alloc] initWithImage:image];
        self.image.frame = CGRectMake(_cellPadding, _cellPadding, imgWidth, imgHeight);
        [self addSubview:self.image];
        CGRect rect = self.frame;
        rect.size.width = width;
        rect.size.height = imgHeight + _cellPadding * 2;
        self.frame = rect;
    } else {
        NSLog(@"image nil when load cell.");
    }
}




- (void)unload {
    // Unload thumb
    [self.image removeFromSuperview];
    self.image = nil;
}



@end
