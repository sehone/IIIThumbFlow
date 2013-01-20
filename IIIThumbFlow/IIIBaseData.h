//
//  IIIBaseData.h
//  IIIThumbFlow
//
//  Created by sehone on 12/21/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IIIBaseData : NSObject
// Path for local image
@property (strong, nonatomic) NSString *local_url;
// URL for web image
@property (strong, nonatomic) NSString *web_url;

@end
