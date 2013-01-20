//
//  SDImageCache+IIIThumb.m
//  IIIThumbFlow
//
//  Created by sehone on 12/22/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import "SDImageCache+IIIThumb.h"

static SDImageCache *thumbInstance;
static NSInteger thumbMaxAge = 30 * 24 * 60 * 60; // one month
static NSString *thumbSubDirectory = @"iii_thumb";

@implementation SDImageCache (IIIThumb)

#pragma mark SDImageCache (class methods)

+ (SDImageCache *)sharedThumbImageCache
{
    if (thumbInstance == nil)
    {
        NSString *basePath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:thumbSubDirectory];
        thumbInstance = [[SDImageCache alloc] initWithBasePath:basePath cacheAge:thumbMaxAge];
    }
    
    return thumbInstance;
}

- (id)initWithBasePath:(NSString *)path cacheAge:(NSInteger)age
{
    if ((self = [super init]))
    {
        [SDImageCache setMaxCacheAge:age];
        
        // Init the memory cache
        memCache = [[NSCache alloc] init];
        memCache.name = @"ImageCache";
        
        // Init the disk cache
        diskCachePath = SDWIReturnRetained([path stringByAppendingPathComponent:@"ImageCache"]);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
        }
        
        // Init the operation queue
        cacheInQueue = [[NSOperationQueue alloc] init];
        cacheInQueue.maxConcurrentOperationCount = 1;
        cacheOutQueue = [[NSOperationQueue alloc] init];
        cacheOutQueue.maxConcurrentOperationCount = 1;
        
#if TARGET_OS_IPHONE
        // Subscribe to app events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
        UIDevice *device = [UIDevice currentDevice];
        if ([device respondsToSelector:@selector(isMultitaskingSupported)] && device.multitaskingSupported)
        {
            // When in background, clean memory in order to have less chance to be killed
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(clearMemory)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
        }
#endif
#endif
    }
    
    return self;
}

@end
