//
//  Bluetooth.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "BLERequest.h"

typedef BOOL (^ScanFilter)(CBPeripheral *peripheral);

@protocol Bluetooth <NSObject>

/**
 *  连接状态信号
 *
 *  @return
 */
-(RACSignal*) bleConnectSignal;

/**
 *  执行请求
 *
 *  @param request
 *
 *  @return
 */
- (RACSignal*) performRequest:(BLERequest*) request;

/**
 *  结束请求
 */
- (void)finish:(BLERequest*) request;

/**
 *  扫描
 *
 *  @param mScanFilter
 *
 *  @return
 */
- (RACSignal*) scanWitchFilter:(ScanFilter) mScanFilter;

/**
 *  停止扫描
 */
-(void)stopScan;

/**
 *  关闭连接
 */
- (void)closeBLE;


@end
