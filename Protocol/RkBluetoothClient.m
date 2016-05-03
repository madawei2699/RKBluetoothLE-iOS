//
//  RkBluetoothClient.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/3.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RkBluetoothClient.h"
#import "RequestQueue.h"

@interface RkBluetoothClient()

@property (nonatomic,strong) BLEStack* ble;

@property (nonatomic,strong) RequestQueue *mRequestQueue;

@end


@implementation RkBluetoothClient

+(instancetype)shareClient{
    
    static RkBluetoothClient *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[RkBluetoothClient alloc]init];
    });
    return share;
    
}

-(instancetype)init{
    
    self = [super init];
    if (self) {
        
        _ble = [BLEStack shareClient];
        _mRequestQueue = [[RequestQueue alloc] initWithBluetooth:_ble];
        [_mRequestQueue start];
        
    }
    return self;
}

-(RACSignal*)observeConnectionStateChanges{
    return [self.ble bleConnectSignal];
}

-(void)disconnect{
    [self.ble closeBLE];
}

/**
 *  扫描设备
 *
 *  @param mScanFilter 设备过滤器
 *
 *  @return
 */
-(RACSignal*)scanBleDevices:(ScanFilter) mScanFilter{
    return [self.ble scanWitchFilter:mScanFilter];
}


-(RK410APIService*)createRk410ApiService{
    return [[RK410APIService alloc] initWithRequestQueue:self.mRequestQueue];
}

@end
