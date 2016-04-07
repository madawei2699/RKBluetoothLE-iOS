//
//  RKBLE.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEStack.h"

/**
 *  蓝牙库对外暴露API
 */
@interface RKBLEClient : NSObject

@property (nonatomic,strong) id<Bluetooth> ble;

/**
 *  必须使用单例创建对象
 *
 *  @return 
 */
+(instancetype)shareClient;

-(RACSignal*) performRequest:(BLERequest*) request;

@end
