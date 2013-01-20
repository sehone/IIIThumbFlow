//
//  IIIFlowController.m
//  IIIThumbFlowDemo
//
//  Created by sehone on 12/22/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import "IIIFlowController.h"
#import "IIIBaseData.h"
#import "IIIUtil.h"
#import "SDImageCache+IIIThumb.h"


@interface IIIFlowController () {
    NSString *_basePath;
}
@property (strong, nonatomic)NSMutableArray *dataSource;
@property (strong, nonatomic)NSMutableArray *testA;
@end

@implementation IIIFlowController
@synthesize dataSource = _dataSource, testA;

int currentY = 0;

- (id)init
{
    self = [super init];
    if (self) {
        CGRect f = [UIScreen mainScreen].applicationFrame;
        self.view = [[IIIFlowView alloc] initWithFrame:f];
        self.view.flowDelegate = self;
        
        // WARNING: Don't set this account too large. This demo would create this
        // number of testing images on your test target device.
        int dataCount = 100;
        _basePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"flow"];
        // Create images if not exists
        IIIUtil *util = [[IIIUtil alloc] init];
        [util createImagesIfNotExists:dataCount atPath:_basePath];
        // First init datasource.
        IIIBaseData *d;
        self.dataSource = [NSMutableArray arrayWithCapacity:0];
        
        for (int i=0; i<16; i++) {
            d = [[IIIBaseData alloc] init];
            d.local_url = [_basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.jpg", i+1]];
            [self.dataSource addObject:d];
        }
        
        d = [[IIIBaseData alloc] init];
        d.web_url = @"http://ww2.sinaimg.cn/bmiddle/acb53f76gw1e0d3m71gtdj.jpg";
        [self.dataSource addObject:d];
        
        d = [[IIIBaseData alloc] init];
        d.web_url = @"http://ww4.sinaimg.cn/bmiddle/69c41da2tw1e0d3cx20rmj.jpg";
        [self.dataSource addObject:d];
        
        d = [[IIIBaseData alloc] init];
        d.web_url = @"http://ww2.sinaimg.cn/bmiddle/6124ef8ejw1e0bxt32xasj.jpg";
        [self.dataSource addObject:d];
        
        d = [[IIIBaseData alloc] init];
        d.web_url = @"http://ww2.sinaimg.cn/bmiddle/62187894jw1e0bh38ouw1j.jpg";
        [self.dataSource addObject:d];
        
        d = [[IIIBaseData alloc] init];
        d.web_url = @"http://ww4.sinaimg.cn/bmiddle/902a1a99jw1e0ctndd59dj.jpg";
        [self.dataSource addObject:d];
        
        d = [[IIIBaseData alloc] init];
        d.web_url = @"http://ww1.sinaimg.cn/bmiddle/66b3de17jw1e0cyskckksj.jpg";
        [self.dataSource addObject:d];
        
        
        for (int i=22; i<dataCount; i++) {
            d = [[IIIBaseData alloc] init];
            d.local_url = [_basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.jpg", i+1]];
            [self.dataSource addObject:d];
        }        
        
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view reloadData];
}




#pragma mark - IIIFlowView delegate required methods

- (NSInteger)numberOfColumns {
    return 3;
}


- (NSInteger)numberOfCells {
    return self.dataSource.count;
}


- (CGFloat)rateOfCache {
    return 10.0f;
}


- (IIIFlowCell *)flowView:(IIIFlowView *)flow cellAtIndex:(int)index {
    NSString *reuseId = @"CommonCell";
    IIIFlowCell *cell = [flow dequeueReusableCellWithId:reuseId];
    if (!cell) {
        cell = [[IIIFlowCell alloc] initWithReuseId:reuseId];
    }
    return cell;
}

- (IIIBaseData *)dataSourceAtIndex:(int)index {
    return [self.dataSource objectAtIndex:index];
}


#pragma mark - Optional IIIFlowView delegate methods

- (void)didSelectCellAtIndex:(int)index {
    UIImage *img;
    IIIBaseData *d = [self.dataSource objectAtIndex:index];
    img = [[SDImageCache sharedThumbImageCache] imageFromKey:d.local_url];
    if (!img) {
        img = [[SDImageCache sharedThumbImageCache] imageFromKey:d.web_url];
    }
    if (img) {
        CGRect f = [UIScreen mainScreen].applicationFrame;
        UIViewController *c = [[UIViewController alloc] init];
        c.view.frame = (CGRect){{0, 0}, f.size};
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:(CGRect){{0, 0}, f.size}];
        [c.view addSubview:sv];
        UIImageView *iv = [[UIImageView alloc] initWithImage:img];
        [sv addSubview:iv];
        iv.frame = CGRectMake(0, 0, f.size.width, f.size.width * img.size.height / img.size.width);
        [sv setContentSize:CGSizeMake(iv.frame.size.width, iv.frame.size.height+self.navigationController.navigationBar.bounds.size.height)];
        [self.navigationController pushViewController:c animated:YES];
    }
}

// optional
- (void)didDownloadedImage:(UIImage *)image atIndex:(int)index {
    IIIBaseData *d = [self.dataSource objectAtIndex:index];
    d.local_url = [_basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i_web.jpg", index+1]];
    NSData *imgData = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0f)];
    NSError *err;
    [imgData writeToFile:d.local_url options:NSDataWritingAtomic error:&err];
    if (err) {
        NSLog(@"Write image to file error: %@\nindex:%i", err.localizedDescription, index);
        d.local_url = nil;
    }
}

@end
