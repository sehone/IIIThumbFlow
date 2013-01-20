//
//  IIIFlowViewDelegate.h
//  IIIThumbFlow
//
//  Created by sehone on 12/22/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>
@class IIIFlowCell;
@class IIIFlowView;

#define UP -1
#define DOWN 1
typedef int IIIDirection;

@protocol IIIFlowViewDelegate <NSObject>
@required
// Number of columns could be changed at runtime (then a reloadData is required
// for IIIFlowView).
- (NSInteger)numberOfColumns;

// Number of cells could be changed at runtime too (then a reloadData is required
// for IIIFlowView).
- (NSInteger)numberOfCells;

// IIIFlowView pre-loads images beyond the visible area.
// rateOfCache = preload height / visible height.
// If this rate is too small, users would usually scroll to edge of loaded images,
// it's a bad user experience. However, if it's too large, sometimes a reloadData
// might take too much time, which might affect the scroll animation. In addition,
// more preloaded images means more memory usage.
// Setting it from 5 to 10 is appropriate for one of the author's published apps.
// It's up to you, according to your app's specific requirements.
- (CGFloat)rateOfCache;

// Get reusable cell for flow view.
- (IIIFlowCell *)flowView:(IIIFlowView *)flow cellAtIndex:(int)index;

// Basic data source for loading image, you can extend or inherit the IIIBaseData
// to get more features.
- (IIIBaseData *)dataSourceAtIndex:(int)index;

@optional
// Return selected cell index.
// If no cell selected, return -1.
- (void)didSelectCellAtIndex:(int)index;

// If controller needs to save the downloaded original image, or some other handling
// work, do it in this method.
- (void)downloadImageSucceed:(UIImage *)image atIndex:(int)index;

- (void)downloadImageFailed:(NSError *)error atIndex:(int)index;

- (void)didScrolledWithDirection:(IIIDirection)direction;
@end
