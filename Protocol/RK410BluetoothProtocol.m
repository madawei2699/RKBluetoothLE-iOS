//
//  RK410BluetoothProtocol.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/18.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RK410BluetoothProtocol.h"
#import "CocoaSecurity.h"

@implementation RK410BluetoothProtocol

/**
 *  当前蓝牙交互协议连接成功后是否需要鉴权
 *
 *  @return yes: 需要 no:不需要
 */
-(BOOL)needAuthentication{

    return YES;
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
    
    if ([service isEqualToString:SERVICE_SPIRIT_SYNC_DATA]) {
        
        if ([characteristic isEqualToString:SPIRIT_AUTH_CODE]) {
            return YES;
        } else if ([characteristic isEqualToString:SPIRIT_FAULTDATA]) {
            return YES;
        } else if ([characteristic isEqualToString:SPIRIT_PARAM_RST]){
            return YES;
        }
        
    }
    return NO;
}

/**
 *  判断收到的蓝牙数据是否符合当前报文协议
 *
 *  @param dataTask       当前任务
 *  @param characteristic 特征UUID String
 *
 *  @return yes: 符合 no:不符合
 */
-(BOOL)effectiveResponse:(Request*)dataTask characteristic:(NSString*)characteristic sourceChannel:(RKBLEResponseChannel)channel{
    
    if (dataTask.method == RKBLEMethodWrite) {
        
        if ([dataTask.characteristic isEqualToString:SPIRIT_AUTH_CODE]) {
            
            if ([characteristic isEqualToString:SPIRIT_AUTH_CODE] && channel == RKBLEResponseNotify) {
                return YES;
            }
            
        } else if([dataTask.characteristic isEqualToString:SPIRIT_WRT_PARAM]){
            
        
            if ([characteristic isEqualToString:SPIRIT_WRT_PARAM] && channel == RKBLEResponseWriteResult) {
                return YES;
            }
            
            
        }
        
    }
    return NO;
}


/**
 *  获取鉴权处理任务
 *
 *  @param callBack
 */
- (void)createAuthProcessRequest:(void (^)(Request* request,NSError* error))callBack peripheralName:(NSString*)_peripheralName{
    
    CocoaSecurityDecoder *mCocoaSecurityDecoder = [[CocoaSecurityDecoder alloc] init];
    NSData *authCode = [mCocoaSecurityDecoder base64:@"Q1NsmKbbaf9ut47RN6/3Xg=="];
    
//    BLEDataTask *mBLEDataTask = [[BLEDataTask alloc] initWithPeripheralName:_peripheralName
//                                                                    service:SERVICE_SPIRIT_SYNC_DATA
//                                                             characteristic:SPIRIT_AUTH_CODE
//                                                                     method:RKBLEMethodWrite
//                                                                 writeValue:authCode];
//    mBLEDataTask.dataParseProtocol = self;
    
    Request *request = [[Request alloc] init];
    
    if (callBack) {
        callBack(request,nil);
    }
}


/**
 *  是否为鉴权任务
 *
 *  @param dataTask
 *
 *  @return
 */
- (BOOL)isAuthenticationRequest:(Request*)request{
    
    if ([request.service isEqualToString:SERVICE_SPIRIT_SYNC_DATA] && [request.characteristic isEqualToString:SPIRIT_AUTH_CODE]) {
        return YES;
    }
    
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
