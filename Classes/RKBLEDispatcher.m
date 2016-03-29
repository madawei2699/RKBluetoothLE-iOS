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

@interface RKBLEDispatcher(){
    
    volatile BOOL mQuit;
    
    dispatch_semaphore_t sem;
}

@property(nonatomic,weak) NSMutableArray<Request*> *mQueue;

@property(nonatomic,weak) id<Bluetooth> bluetooth;

@property(nonatomic,weak) id<ResponseDelivery> mDelivery;

@end

@implementation RKBLEDispatcher

- (id)initWithQueue:(NSMutableArray<Request*>*)mQueue bluetooth:(id<Bluetooth>) bluetooth andDelivery:(id<ResponseDelivery>)mDelivery {
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        mQuit = NO;
        self.mQueue = mQueue;
        self.bluetooth = bluetooth;
        self.mDelivery = mDelivery;
    }
    return self;
}

-(void)start{

    sem = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //消费者队列
        while (!mQuit) {
            NSTimeInterval startTimeMs = [[NSDate date] timeIntervalSince1970];
            
//            if ([taskArray firstObject] == nil) {
//                NSLog(@"dispatch_semaphore_wait");
//                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
//            }
//            
//            BLEDataTask *mBLEDataTask = [taskArray firstObject];
//            if(mBLEDataTask && mBLEDataTask.TaskState == DataTaskStateSuspended){
//                
//                currentTask = mBLEDataTask;
//                [mBLEDataTask execute];
//                
//                
//            } else {
//                NSLog(@"dispatch_semaphore_wait:60 * NSEC_PER_SEC");
//                //等待信号，可以设置超时参数。该函数返回0表示得到通知，非0表示超时
//                if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW,  60 * NSEC_PER_SEC )) != 0){
//                    //删除处理超时的任务
//                    NSLog(@"dispatch_semaphore_wait:timeout");
//                    BLEDataTask* firstObject = [taskArray firstObject];
//                    if (firstObject) {
//                        [taskArray removeObject:firstObject];
//                        //通知UI更新
//                    }
//                }
//            }
            
        }
        
    });

}

@end
