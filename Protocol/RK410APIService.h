//
//  RK410BluetoothProtocol.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/18.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RK410APIService : NSObject

+(instancetype)shareService;

/**
 *  锁车
 *
 *  @param target
 *
 *  @return
 */
-(RACSignal*)lock:(NSString*)target;


/**
 *  解锁
 *
 *  @param target
 *
 *  @return
 */
-(RACSignal*)unlock:(NSString*)target;

/**
 *  寻车
 *
 *  @param target
 *
 *  @return
 */
-(RACSignal*)search:(NSString*)target;

/**
 *  开启座桶
 *
 *  @param target
 *
 *  @return
 */
-(RACSignal*)openBox:(NSString*)target;

@end
