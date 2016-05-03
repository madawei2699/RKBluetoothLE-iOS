//
//  RkBluetoothClient.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/3.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEStack.h"
#import "RK410APIService.h"

@interface RkBluetoothClient : NSObject
/**
 *  必须使用单例创建对象
 *
 *  @return
 */
+(instancetype)shareClient;

-(RACSignal*)observeConnectionStateChanges;

-(void)disconnect;

-(RK410APIService*)createRk410ApiService;

@end
