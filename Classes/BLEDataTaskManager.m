//
//  RKBLEProtocolManager.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLEDataTaskManager.h"
#import "RKBLEUtil.h"
#import "RKRunLoopThread.h"

@interface BLEDataTaskManager(){
    
    NSMutableArray<BLEDataTask*> *taskArray;
    
    BLEDataTask *currentTask;
    
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
    [self resume];
}

-(void)removeTask:(BLEDataTask* )task{
    [taskArray removeObject:task];
    [self resume];
}

-(void)resume{
    
    dispatch_async(taskQueue, ^{
        BLEDataTask *mBLEDataTask = [taskArray firstObject];
        if(mBLEDataTask && mBLEDataTask.TaskState == DataTaskStateSuspended){
            
            currentTask = mBLEDataTask;
            [mBLEDataTask execute];
            
        }
    });
    
    
    
}

@end
