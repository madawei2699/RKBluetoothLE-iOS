//
//  BLEDataTask.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BabyBluetooth/BabyBluetooth.h>

NS_ENUM(NSInteger)
{
    BLEDataTaskErrorTimeOut    = 1,
    BLEDataTaskErrorDisconnect = 2,
};

typedef NS_ENUM(NSInteger, RKBLEMethod) {

    RKBLEMethodRead        = 0,
    RKBLEMethodWrite       = 1,

};

typedef NS_ENUM(NSInteger, RKBLEDataTaskState) {

    DataTaskStateRunning   = 0,
    DataTaskStateSuspended = 1,
    DataTaskStateCanceling = 2,
    DataTaskStateCompleted = 3,
    DataTaskStateFailure   = 4,

};

typedef NS_ENUM(NSInteger, RKBLEState) {

    RKBLEStateDefault      = 0,
    RKBLEStateStart        = 1,
    RKBLEStateScanning     = 2,
    RKBLEStateConnecting   = 3,
    RKBLEStateConnected    = 4,
    RKBLEStateDisconnect   = 5,
    RKBLEStateFailure      = 6,

};

@class BLEDataTask;

//连接状态回调
typedef void (^RKConnectProgressBlock)(BLEDataTask *mBLEDataTask, NSError * error);
//处理成功
typedef void (^RKSuccessBlock)(BLEDataTask *mBLEDataTask, NSData* responseObject, NSError * error);
//处理失败
typedef void (^RKFailureBlock)(BLEDataTask *mBLEDataTask, NSData* responseObject, NSError * error);

@protocol BLEDataParseProtocol <NSObject>

/**
 *  判断收到的蓝牙数据是否符合当前报文协议
 *
 *  @param dataTask       当前任务
 *  @param characteristic 特征UUID String
 *
 *  @return yes: 符合 no:不符合
 */
-(BOOL)effectiveResponse:(BLEDataTask*)dataTask characteristic:(NSString*)characteristic;

/**
 *  判读是否需要注册通知
 *
 *  @param service        服务
 *  @param characteristic 特征
 *
 *  @return yes: 需要 no:不需要
 */
-(BOOL)needSubscribeNotifyWithService:(NSString*)service characteristic:(NSString*)characteristic;

-(BOOL)callBackRunOnMainThread;

@end


@interface BLEDataTask : NSObject

@property (nonatomic,copy, readonly  ) NSString               *taskIdentifier;

@property (nonatomic,copy, readonly  ) NSString               *peripheralName;

@property (nonatomic,copy, readonly  ) NSString               *service;

@property (nonatomic,copy, readonly  ) NSString               *characteristic;

@property (nonatomic,assign ,readonly) RKBLEMethod            method;

@property (nonatomic,strong          ) NSData                 *writeValue;

@property (nonatomic,assign          ) RKBLEDataTaskState     TaskState;

@property (nonatomic,assign          ) RKBLEState             BLEState;

@property (nonatomic,copy            ) RKConnectProgressBlock connectProgressBlock;

@property (nonatomic,copy            ) RKSuccessBlock         successBlock;

@property (nonatomic,copy            ) RKSuccessBlock         failureBlock;

@property (nonatomic,weak            ) id<BLEDataParseProtocol> dataParseProtocol;

/**
 *  初始化BLEDataTask
 *
 *  @param peripheralName 连接的蓝牙名称
 *  @param service        服务
 *  @param characteristic 特征
 *  @param method         方法
 *  @param writeValue     写入的值
 *
 *  @return 当前对象
 */
- (id)initWithPeripheralName:(NSString*)peripheralName
                     service:(NSString*)service
              characteristic:(NSString*)characteristic
                      method:(RKBLEMethod)method
                  writeValue:(NSData*)writeValue;

/**
 *  执行任务
 */
-(void)execute;

@end
