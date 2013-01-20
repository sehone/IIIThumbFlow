//
//  IIIFlowView.h
//  IIIThumbFlow
//
//  Created by sehone on 12/21/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIIFlowCell.h"
#import "IIIFlowViewDelegate.h"
#import "SDWebImageDownloader.h"

static const NSString *INDEX_KEY = @"index";
static const CGFloat SAFE_SCROLL_LENGTH = 3500.0;

typedef struct {
    int index;
    CGFloat height;
} IIIFlowColumnHeight;

typedef struct {
    CGFloat top;
    CGFloat bottom;
} IIIFlowCacheScale;


@interface IIIFlowView : UIScrollView <UIScrollViewDelegate, SDWebImageDownloaderDelegate>
@property (strong, nonatomic) id<IIIFlowViewDelegate> flowDelegate;

- (IIIFlowCell *)dequeueReusableCellWithId: (NSString *)idStr;
- (void)unloadData;
- (void)reloadData;

@end




