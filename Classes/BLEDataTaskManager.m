//
//  RKBLEProtocolManager.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLEDataTaskManager.h"
#import "RKBLEUtil.h"

@interface BLEDataTaskManager(){
    
    NSMutableArray<BLEDataTask*> *taskArray;
    
    BLEDataTask *currentTask;
    
    dispatch_semaphore_t sem;
    
    dispatch_queue_t taskQueue;
    
}

@end

@implementation BLEDataTaskManager

+ (instancetype)sharedManager {
    
    static BLEDataTaskManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BLEDataTaskManager alloc] init];
    });
    
    return _sharedClient;
    
}

- (id)init{
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        taskArray = [[NSMutableArray alloc] init];
        taskQueue = dispatch_queue_create("BLEDataTaskManager", NULL);
        //创建信号量，可以设置信号量的资源数。0表示没有资源，调用dispatch_semaphore_wait会立即等待。
        sem = dispatch_semaphore_create(0);
        bool condition = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //消费者队列
            while (condition) {
                
                if ([taskArray firstObject] == nil) {
                    NSLog(@"dispatch_semaphore_wait");
                    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
                }
                
                BLEDataTask *mBLEDataTask = [taskArray firstObject];
                if(mBLEDataTask && mBLEDataTask.TaskState == DataTaskStateSuspended){
                    
                    currentTask = mBLEDataTask;
                    [mBLEDataTask execute];
                
                    
                } else {
                    NSLog(@"dispatch_semaphore_wait:60 * NSEC_PER_SEC");
                    //等待信号，可以设置超时参数。该函数返回0表示得到通知，非0表示超时
                    if (dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW,  60 * NSEC_PER_SEC )) != 0){
                        //删除处理超时的任务
                        NSLog(@"dispatch_semaphore_wait:timeout");
                        BLEDataTask* firstObject = [taskArray firstObject];
                        if (firstObject) {
                            [taskArray removeObject:firstObject];
                            //通知UI更新
                        }
                    }
                }
                
            }
            
        });
        
    }
    
    return self;
}

/**
 *  请求外围设备数据
 *
 *  @param target     eg. "@{@"peripheralName":peripheralName,@"service":service,@"characteristic":characteristic}"
 *  @param method     读写标记
 *  @param parameters 写入参数
 *  @param success    成功回调
 *  @param failure    失败回调
 *
 *  @return 蓝牙数据交换任务处理类
 */
- (nullable BLEDataTask*)target:(NSDictionary*)target
                         method:(RKBLEMethod)method
                     parameters:(nullable NSData*)parameters
                        success:(nullable void (^)(BLEDataTask* task, id responseObject,NSError* _Nullable error))success
                        failure:(nullable void (^)(BLEDataTask* task, id _Nullable responseObject,NSError* error))failure{
    
    BLEDataTask *mBLEDataTask = [[BLEDataTask alloc] initWithPeripheralName:target[@"peripheralName"]
                                                                    service:target[@"service"]
                                                             characteristic:target[@"characteristic"]
                                                                     method:method
                                                                 writeValue:parameters];
    mBLEDataTask.dataParseProtocol = self.dataParseProtocol;
    
    mBLEDataTask.connectProgressBlock = self.bleConnectStateBlock;
    
    mBLEDataTask.successBlock = ^(BLEDataTask* task, id responseObject,NSError* _Nullable error){
        
        if (success) {
            success(task,responseObject,error);
        }
        
        [self removeTask:task];
        
    };
    mBLEDataTask.failureBlock = ^(BLEDataTask* task, id responseObject,NSError* _Nullable error){
        
        if (failure) {
            failure(task,responseObject,error);
        }
        
        [self removeTask:task];
        
    };
    
    [self addTask:mBLEDataTask];
    
    return mBLEDataTask;
    
}

-(void)addTask:(BLEDataTask* )task{
    [taskArray addObject:task];
    //当前放入的对象为第一个对象则立即执行任务
    if ([taskArray firstObject] == task) {
        [self notify];
    }
}

-(void)removeTask:(BLEDataTask* )task{
    [taskArray removeObject:task];
    [self notify];
}

-(void)notify{
    
    bool running = YES;
    bool notifyOK = NO;
    
    int retryCount = 0;
    while (running) {
        //通知信号，如果等待线程被唤醒则返回非0，否则返回0
        if (!dispatch_semaphore_signal(sem))
        {
            sleep(1); //wait for a while
            retryCount++;
            if (retryCount >= 3) {
                running = NO;
            }
            continue;
        }
        //通知成功
        notifyOK = YES;
        running = NO;
    }
    NSLog(@"dispatch_semaphore_signal:%@",notifyOK ? @"success":@"failure");
    
}

@end
