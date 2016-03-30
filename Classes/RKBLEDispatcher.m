//
//  RKBLEDataTaskDispatcher.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEDispatcher.h"
#import "Request.h"
#import "Bluetooth.h"
#import "ResponseDelivery.h"
#import "RKBlockingQueue.h"
#import "BLEResponse.h"

@interface RKBLEDispatcher(){
    
    volatile BOOL mQuit;
    
    dispatch_semaphore_t sem;
}

@property(nonatomic,weak) RKBlockingQueue<Request*> *mQueue;

@property(nonatomic,weak) id<Bluetooth> bluetooth;

@property(nonatomic,weak) id<ResponseDelivery> mDelivery;

@end

@implementation RKBLEDispatcher

- (id)initWithQueue:(RKBlockingQueue<Request*>*)mQueue bluetooth:(id<Bluetooth>) bluetooth andDelivery:(id<ResponseDelivery>)mDelivery {
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
        
        while (!mQuit) {
            
            Request *request = [self.mQueue take];
            
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
                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
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
        
    });

}

-(void)quit{
    mQuit = YES;
    dispatch_semaphore_signal(sem);
}

@end