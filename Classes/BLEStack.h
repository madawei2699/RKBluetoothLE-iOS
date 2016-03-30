//
//  BLEStack.h
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
    BLEStackErrorTimeOut    = 1,
    BLEStackErrorDisconnect = 2,
    BLEStackAuthError       = 3,
};

typedef NS_ENUM(NSInteger, RKBLEConnectState) {

    RKBLEStateDefault          = 0,
    RKBLEStateStart            = 1,
    RKBLEStateScanning         = 2,
    RKBLEStateConnecting       = 3,
    RKBLEStateConnected        = 4,
    RKBLEStateDisconnect       = 5,
    RKBLEStateFailure          = 6,

};

@class BLEStack;

//连接状态回调
typedef void (^RKConnectProgressBlock)(RKBLEConnectState mRKBLEState, NSError * error);
//处理成功
typedef void (^RKSuccessBlock)(Request *request, NSData* responseObject, NSError * error);
//处理失败
typedef void (^RKFailureBlock)(Request *request, NSData* responseObject, NSError * error);

@interface BLEStack : NSObject

@property (nonatomic,assign          ) NSInteger              requestSequence;

@property (nonatomic,copy            ) NSString               *peripheralName;

@property (nonatomic,copy            ) NSString               *service;

@property (nonatomic,copy            ) NSString               *characteristic;

@property (nonatomic,assign          ) RKBLEMethod            method;

@property (nonatomic,strong          ) NSData                 *writeValue;

@property (nonatomic,assign          ) RKBLEConnectState      BLEState;

@property (nonatomic,assign          ) CBCentralManagerState  CMState;

@property (nonatomic,copy            ) RKConnectProgressBlock connectProgressBlock;

@property (nonatomic,copy            ) RKSuccessBlock         successBlock;

@property (nonatomic,copy            ) RKSuccessBlock         failureBlock;

+ (instancetype)sharedInstance;

- (id)init;

/**
 *  执行请求
 *
 *  @param request
 */
-(void)performRequest:(Request*)request;

@end
