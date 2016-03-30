//
//  BLEDataTask.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BabyBluetooth/BabyBluetooth.h>
#import "Request.h"


NS_ENUM(NSInteger)
{
    BLEDataTaskErrorTimeOut    = 1,
    BLEDataTaskErrorDisconnect = 2,
    BLEDataTaskAuthError       = 3,
};

typedef NS_ENUM(NSInteger, RKBLEState) {

    RKBLEStateDefault          = 0,
    RKBLEStateStart            = 1,
    RKBLEStateScanning         = 2,
    RKBLEStateConnecting       = 3,
    RKBLEStateConnected        = 4,
    RKBLEStateDisconnect       = 5,
    RKBLEStateFailure          = 6,

};

@class BLEDataTask;

//连接状态回调
typedef void (^RKConnectProgressBlock)(RKBLEState mRKBLEState, NSError * error);
//处理成功
typedef void (^RKSuccessBlock)(Request *request, NSData* responseObject, NSError * error);
//处理失败
typedef void (^RKFailureBlock)(Request *request, NSData* responseObject, NSError * error);

@interface BLEDataTask : NSObject

@property (nonatomic,assign) NSInteger             requestSequence;

@property (nonatomic,copy) NSString               *peripheralName;

@property (nonatomic,copy) NSString               *service;

@property (nonatomic,copy) NSString               *characteristic;

@property (nonatomic,assign) RKBLEMethod            method;

@property (nonatomic,strong          ) NSData                 *writeValue;

//@property (nonatomic,assign          ) RKBLEDataTaskState     TaskState;

@property (nonatomic,assign          ) RKBLEState             BLEState;

@property (nonatomic,assign          ) CBCentralManagerState  CMState;

@property (nonatomic,copy            ) RKConnectProgressBlock connectProgressBlock;

@property (nonatomic,copy            ) RKSuccessBlock         successBlock;

@property (nonatomic,copy            ) RKSuccessBlock         failureBlock;



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
- (id)init;

/**
 *  执行请求
 */
-(void)execute;

-(void)performRequest:(Request*)request;

@end
