//
//  RKBLE.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLE.h"
#import "BasicBluetooth.h"
#import "RequestQueue.h"

@implementation RKBLE

+(RequestQueue*)newRequestQueue{
    //创建蓝牙处理模块类
    BasicBluetooth *mBasicBluetooth = [[BasicBluetooth alloc] init];
    RequestQueue *mRequestQueue =  [[RequestQueue alloc] initWithBluetooth:mBasicBluetooth];
    
    return mRequestQueue;
}

@end
