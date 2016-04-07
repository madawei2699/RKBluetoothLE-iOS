//
//  DefaultBLEDataParseProtocol.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/4/7.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "DefaultBLEDataParseProtocol.h"

@implementation DefaultBLEDataParseProtocol
/**
 *  当前蓝牙交互协议连接成功后是否需要鉴权
 *
 *  @return yes: 需要 no:不需要
 */
-(BOOL)needAuthentication{
    
    return NO;
    
}

/**
 *  判读是否需要注册通知
 *
 *  @param service        服务
 *  @param characteristic 特征
 *
 *  @return yes: 需要 no:不需要
 */
-(BOOL)needSubscribeNotifyWithService:(NSString*)service characteristic:(NSString*)characteristic{
    
    return NO;
    
}

/**
 *  判断收到的蓝牙数据是否符合当前报文协议
 *
 *  @param request       当前任务
 *  @param characteristic 特征UUID String
 *
 *  @return yes: 符合 no:不符合
 */
-(BOOL)effectiveResponse:(BLERequest*)request characteristic:(NSString*)characteristic sourceChannel:(RKBLEResponseChannel)channel  value:(NSData*)value{
    
    if (request.method == RKBLEMethodRead) {
        if ([characteristic isEqualToString:request.characteristic] && channel == RKBLEResponseReadResult) {
            return YES;
        }
    } else if (request.method == RKBLEMethodWrite){
        if ([characteristic isEqualToString:request.characteristic] && channel == RKBLEResponseWriteResult) {
            return YES;
        }
    } else if (request.method == RKBLEMethodNotify){
        if ([characteristic isEqualToString:request.characteristic] && channel == RKBLEResponseNotify) {
            return YES;
        }
    }
    
    return NO;
    
}


/**
 *  获取鉴权处理任务
 *
 *  @param callBack
 */
- (void)createAuthProcessRequest:(void (^)(BLERequest* request,NSError* error))callBack peripheralName:(NSString*)_peripheralName{
    
    
    
}


/**
 *  是否为鉴权任务
 *
 *  @param request
 *
 *  @return
 */
- (BOOL)isAuthenticationRequest:(BLERequest*)request{
    
    return NO;
}

/**
 *  解析鉴权返回值判断是否鉴权成功
 *
 *  @param value 鉴权返回值
 *
 *  @return
 */
- (BOOL)authSuccess:(NSData*)value{
    
    return YES;
    
}

@end
