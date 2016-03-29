//
//  RequestQueue.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RequestQueue.h"
#import "RKBLEDispatcher.h"
#import "ExecutorDelivery.h"
#import "Request.h"

@interface RequestQueue(){
    
    id<Bluetooth> bluetooth;
    
    id<ResponseDelivery> mDelivery;
    
    RKBLEDispatcher *mDispatcher;
    
    NSMutableArray<Request*> *mBluetoothQueue;
    
}


@end

@implementation RequestQueue

- (id)initWithBluetooth:(id<Bluetooth>)_Bluetooth {
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        mBluetoothQueue = [[NSMutableArray alloc] init];
        bluetooth = _Bluetooth;
        mDelivery = [[ExecutorDelivery alloc] init];
    }
    
    return self;
}

- (void) start{
    [self stop];
    mDispatcher = [[RKBLEDispatcher alloc] init];
    [mDispatcher start];
}

- (void) stop{
    if (mDispatcher) {
        [mDispatcher quit];
    }
}

-(Request*)add:(Request*)request{
    request.mRequestQueue = self;
    [request setSequence:1];
    [request addMarker:@"add-to-queue"];
    [mBluetoothQueue addObject:request];
    return request;
}

@end
