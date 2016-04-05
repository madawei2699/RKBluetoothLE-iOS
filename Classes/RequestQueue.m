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
#import "BLERequest.h"
#import "RKBlockingQueue.h"

@interface RequestQueue(){
    
    id<Bluetooth> bluetooth;
    
    id<ResponseDelivery> mDelivery;
    
    RKBLEDispatcher *mDispatcher;
    
    RKBlockingQueue<BLERequest*> *mBluetoothQueue;
    
    NSMutableArray<BLERequest*> *mCurrentRequests;
    
    int sequence;
}


@end

@implementation RequestFilterImpl

-(BOOL)apply:(BLERequest*)request{
    return request.tag == self.tag;
}

@end

@implementation RequestQueue

- (id)initWithBluetooth:(id<Bluetooth>)_Bluetooth {
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        mCurrentRequests = [[NSMutableArray alloc] init];
        mBluetoothQueue = [[RKBlockingQueue alloc] init];
        bluetooth = _Bluetooth;
        mDelivery = [[ExecutorDelivery alloc] init];
    }
    
    return self;
}

-(NSInteger)getSequenceNumber{
    sequence++;
    if (sequence >= INT32_MAX) {
        sequence = 0;
    }
    return sequence;
}

- (void) start{
    [self stop];
    mDispatcher = [[RKBLEDispatcher alloc] initWithQueue:mBluetoothQueue bluetooth:bluetooth andDelivery:mDelivery];
    [mDispatcher start];
}

- (void) stop{
    if (mDispatcher) {
        [mDispatcher quit];
    }
}

-(BLERequest*)add:(BLERequest*)request{
    
    request.mRequestQueue = self;
    
    @synchronized (mCurrentRequests) {
        [mCurrentRequests addObject:request];
    }
    
    [request setSequence:[self getSequenceNumber]];
    [request addMarker:@"add-to-queue"];
    
    [mBluetoothQueue add:request];
    
    return request;
}

-(void)cancelAll{
    @synchronized (mCurrentRequests) {
        
        [mCurrentRequests.rac_sequence.signal subscribeNext:^(BLERequest *item) {
            
            [item cancel];
            
        }];
        
    }
}

-(void)cancelAllWithFilter:(id<RequestFilter>) filter{
    
    @synchronized (mCurrentRequests) {
        
        [mCurrentRequests.rac_sequence.signal subscribeNext:^(BLERequest *item) {
            
            if (filter && [filter apply:item]) {
                [item cancel];
            }
            
        }];
        
    }
}

-(void)cancelAllWithTag:(id) tag{
    
    RequestFilterImpl *mRequestFilterImpl = [[RequestFilterImpl alloc] init];
    mRequestFilterImpl.tag = tag;
    [self cancelAllWithFilter:mRequestFilterImpl];
    
}

-(void)finish:(BLERequest*)Request{
    
    @synchronized (mCurrentRequests) {
        [mCurrentRequests removeObject:Request];
    }
    
}

@end
