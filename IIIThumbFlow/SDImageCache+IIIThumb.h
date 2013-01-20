//
//  SDImageCache+IIIThumb.h
//  IIIThumbFlow
//
//  Created by sehone on 12/22/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import "SDImageCache.h"

@interface SDImageCache (IIIThumb)

/*
 * Make some changes for thumb cache:
 * 1. Change cache age. This age should be set according specific app requirements.
 * 2. Change cache directory. Change the directory from 'Library/Caches' to
 *    'Application Support/iii_thumb'. This location should also be set according
 *    to app requirements.
 */
+ (SDImageCache *)sharedThumbImageCache;

@end
