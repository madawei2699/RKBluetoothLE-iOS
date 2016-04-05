//
//  RKBLEDataTaskDispatcher.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEDispatcher.h"

static dispatch_semaphore_t sem;

@interface RKBLEDispatcher(){
    
    volatile BOOL mQuit;
    
}

@property(nonatomic,weak) RKBlockingQueue<BLERequest*> *mQueue;

@property(nonatomic,weak) id<Bluetooth> bluetooth;

@property(nonatomic,weak) id<ResponseDelivery> mDelivery;

@end

@implementation RKBLEDispatcher

- (id)initWithQueue:(RKBlockingQueue<BLERequest*>*)mQueue bluetooth:(id<Bluetooth>) bluetooth andDelivery:(id<ResponseDelivery>)mDelivery {
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        mQuit = NO;
        sem = dispatch_semaphore_create(0);
        self.mQueue = mQueue;
        self.bluetooth = bluetooth;
        self.mDelivery = mDelivery;
        
        self.mQueue.sem = sem;
    }
    return self;
}

-(void)start{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[NSThread currentThread] setName:@"RKBLEDispatcher"];
        
        while (!mQuit) {
            
            @autoreleasepool {
                BLERequest *request = [self.mQueue take];
                
                if (mQuit) {
                    return;
                }
                
                if (request == nil) {
                    continue;
                }
                
                [request addMarker:@"ble-queue-take"];
                if ([request isCanceled]) {
                    [request finish:@"ble-discard-cancelled"];
                    continue;
                }
                
                __block BLEResponse *mBLEResponse = nil;
                __block NSError *bleError = nil;
                // Parse the response here on the worker thread.
                RACSignal* responseRACSignal = [self.bluetooth performRequest:request];
                [[responseRACSignal
                  subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]]
                 subscribeNext:^(id x) {
                     mBLEResponse = x;
                     //唤醒线程
                     dispatch_semaphore_signal(sem);
                 }
                 error:^(NSError *error) {
                     bleError = error;
                     //唤醒线程
                     dispatch_semaphore_signal(sem);
                 }];
                
                //等待BLE处理结束如果不结束则一直等待
                while (!mQuit && mBLEResponse == nil && bleError == nil) {
                    //等待信号，可以设置超时参数。该函数返回0表示得到通知，非0表示超时
                    if(dispatch_semaphore_wait (sem, dispatch_time ( DISPATCH_TIME_NOW , 5 * NSEC_PER_SEC )) != 0)
                    {
                        bleError = [NSError errorWithDomain:@"BLEStackErrorDomain"
                                                       code:1
                                                   userInfo:@{ NSLocalizedDescriptionKey: @"当前业务处理超时" }];
                    }
                }
                
                if (mQuit) {
                    return;
                }
                
                [request addMarker:@"ble-complete"];
                
                if (bleError) {
                    
                    [self.mDelivery postError:request error:bleError];
                    
                } else {
                    
                    Response *response = [request parseNetworkResponse:mBLEResponse];
                    [request addMarker:@"ble-parse—complete"];
                    [request markDelivered];
                    
                    [self.mDelivery postResponse:request response:response];
                    
                }
                
            }
        }
        
    });
    
}

-(void)quit{
    mQuit = YES;
    dispatch_semaphore_signal(sem);
}

@end
