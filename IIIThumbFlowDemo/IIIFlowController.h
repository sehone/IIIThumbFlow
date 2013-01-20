//
//  IIIFlowController.h
//  IIIThumbFlowDemo
//
//  Created by sehone on 12/22/12.
//  Copyright (c) 2012 sehone <sehone@gmail.com>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIIFlowView.h"

@interface IIIFlowController : UIViewController <IIIFlowViewDelegate>
@property (strong, nonatomic) IIIFlowView *view;
@end
