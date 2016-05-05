//
//  RKBLEDataTaskDispatcher.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEDispatcher.h"
#import "BLEStack.h"

static dispatch_semaphore_t sem;

@interface RKBLEDispatcher(){
    
    volatile BOOL mQuit;
    
    NSDate *startTimeMs;
    
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
                
                //---------------------------------------------loop to retry-------------------------------------------
                while (true) {
                    
                    // Parse the response here on the worker thread.
                    RACSignal* responseRACSignal = [self.bluetooth performRequest:request];
                    [[[responseRACSignal
                       subscribeOn:[RACScheduler mainThreadScheduler]]
                      timeout:[request getTimeoutS]
                      onScheduler:[RACScheduler mainThreadScheduler]]
                     subscribeNext:^(id x) {
                         
                         mBLEResponse = x;
                         
                         //唤醒线程
                         dispatch_semaphore_signal(sem);
                         
                     }
                     error:^(NSError *error) {
                         
                         bleError = error;
                         
                         if ([bleError.domain isEqualToString:RACSignalErrorDomain] && bleError.code == RACSignalErrorTimedOut) {
                             
                             bleError = [NSError errorWithDomain:BLEStackErrorDomain
                                                            code:BLEStackErrorTimeOut
                                                        userInfo:@{ NSLocalizedDescriptionKey: BLEStackErrorTimeOutDesc }];
                             [self.bluetooth finish:request];
                         }
                         
                         //唤醒线程
                         dispatch_semaphore_signal(sem);
                     }];
                    
                    startTimeMs = [NSDate date];
                    
                    //等待BLE处理结束如果不结束则一直等待
                    while (!mQuit && mBLEResponse == nil && bleError == nil) {
                        //等待信号，可以设置超时参数。该函数返回0表示得到通知，非0表示超时
                        if(dispatch_semaphore_wait (sem, dispatch_time ( DISPATCH_TIME_NOW , 60 * NSEC_PER_SEC )) != 0)
                        {
                            bleError = [NSError errorWithDomain:BLEStackErrorDomain
                                                           code:BLEStackErrorTimeOut
                                                       userInfo:@{ NSLocalizedDescriptionKey: BLEStackErrorTimeOutDesc }];
                        }
                    }
                    
                    mBLEResponse.bleTimeMs = -[startTimeMs timeIntervalSinceNow];
                    
                    if (mBLEResponse) {
                        break;
                    } else if([[request getRetryPolicy] retry:bleError]){
                        break;
                    } else {
                        bleError = nil;
                        [request addMarker:@"ble-retry"];
                    }
                    
                }
                //---------------------------------------------loop-------------------------------------------
                
                if (mQuit) {
                    return;
                }
                
                [request addMarker:@"ble-complete"];
                
                if (bleError) {
                    
                    [self.mDelivery postError:request error:bleError];
                    
                } else {
                    
                    Response *response = [request parseBLEResponse:mBLEResponse];
                    [request addMarker:@"ble-parse—complete"];
                    [request markDelivered];
                    
                    [self.mDelivery postResponse:request response:response];
                    
                }
                
                //处理特定指令需要间隔一段时间后才能发生下一条
                float mDelayTime = [[request getRetryPolicy] getDelayTime] - (-[startTimeMs timeIntervalSinceNow]);
                if ( mDelayTime > 0) {
                    [request addMarker:[NSString stringWithFormat:@"ble-delay%.3fs",mDelayTime]];
                    [NSThread sleepForTimeInterval:mDelayTime];
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
