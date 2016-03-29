//
//  Bluetooth.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "Request.h"

@protocol Bluetooth <NSObject>

- (RACSignal*) performRequest:(Request*) request;

@end
