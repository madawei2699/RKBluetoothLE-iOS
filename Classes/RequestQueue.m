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
#import "RKBlockingQueue.h"

@interface RequestQueue(){
    
    id<Bluetooth> bluetooth;
    
    id<ResponseDelivery> mDelivery;
    
    RKBLEDispatcher *mDispatcher;
    
    RKBlockingQueue<Request*> *mBluetoothQueue;
    
    int sequence;
}


@end

@implementation RequestQueue

- (id)initWithBluetooth:(id<Bluetooth>)_Bluetooth {
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        mBluetoothQueue = [[RKBlockingQueue alloc] init];
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
    [request setSequence:[self getSequenceNumber]];
    [request addMarker:@"add-to-queue"];
    [mBluetoothQueue add:request];
    return request;
}

-(NSInteger)getSequenceNumber{
    sequence++;
    if (sequence >= INT32_MAX) {
        sequence = 0;
    }
    return sequence;
}

@end
