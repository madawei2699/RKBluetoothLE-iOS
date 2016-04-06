//
//  RK410BluetoothProtocol.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/18.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RK410APIService.h"
#import "CocoaSecurity.h"
#import "RKBLEUtil.h"
#import "RKBLEClient.h"
#import "BLERequest.h"

//---------------------------服务------------------------------------------
// 车精灵服务
static NSString* const SERVICE_SPIRIT_SYNC_DATA = @"9900";
// 蓝牙遥控器服务
static NSString* const SERVICE_BT_KEY_CONFIG    = @"9800";

//---------------------------特征------------------------------------------
//    鉴权码	SPIRIT_AUTH_CODE	0x9901	Write	16 BYTES(待验证的鉴权值）
static NSString* const SPIRIT_AUTH_CODE         = @"9901";

//    同步数据	SPIRIT_SYNCDATA	0x9902	Read	14BYTES,参考：“机车电控车况参数”
static NSString* const SPIRIT_SYNCDATA          = @"9902";

//    故障查询/上报	SPIRIT_FAULTDATA	0x9903	Read/Notify	6 bytes,参考 “机车故障参数”
static NSString* const SPIRIT_FAULTDATA         = @"9903";

//    参数设置/查询	SPIRIT_WRT_PARAM	0x9904	Write	参考“BLE参数设置”
//#define SPIRIT_WRT_PARAM            @"9907"
static NSString* const SPIRIT_WRT_PARAM         = @"9904";

//    参数设置结果查询	SPIRIT_PARAM_RST	0x9905	Read/Notify	对于WRT_PARAM的结果进行反馈
static NSString* const SPIRIT_PARAM_RST         = @"9905";

//    钥匙控制	SPIRIT_KEYFUNC	0x9906	Write	参考4.6 “钥匙功能”
static NSString* const SPIRIT_KEYFUNC           = @"9906";

//    模拟按键	SPIRIT_KEYPRESS	0x9907	Write	模拟按键
//#define SPIRIT_KEYPRESS             @"9907"

//    配一配设置
static NSString* const SPIRIT_SET_PARAM         = @"9801";

//static int RBL_BLE_FRAMEWORK_VER                = 0x0200;

@interface BLEDataParseProtocolImpl : NSObject<BLEDataParseProtocol>

@end

@implementation BLEDataParseProtocolImpl

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
        } else if ([characteristic isEqualToString:SPIRIT_KEYFUNC]){
            return YES;
        }
        
    }
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
    
    return request.effectiveResponse(characteristic,channel,value);
    
}


/**
 *  获取鉴权处理任务
 *
 *  @param callBack
 */
- (void)createAuthProcessRequest:(void (^)(BLERequest* request,NSError* error))callBack peripheralName:(NSString*)_peripheralName{
    
    CocoaSecurityDecoder *mCocoaSecurityDecoder = [[CocoaSecurityDecoder alloc] init];
    NSData *authCode = [mCocoaSecurityDecoder base64:@"Q1NsmKbbaf9ut47RN6/3Xg=="];
    
    BLERequest *authRequest = [[BLERequest alloc] initWithReponseClass:nil target:[RKBLEUtil createTarget:_peripheralName service:SERVICE_SPIRIT_SYNC_DATA characteristic:SPIRIT_AUTH_CODE] method:RKBLEMethodWrite writeValue:authCode];
    authRequest.dataParseProtocol = self;
    authRequest.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:SPIRIT_AUTH_CODE] && channel == RKBLEResponseNotify) {
            return YES;
        } else {
            return NO;
        }
        
    };
    
    if (callBack) {
        callBack(authRequest,nil);
    }
    
}


/**
 *  是否为鉴权任务
 *
 *  @param request
 *
 *  @return
 */
- (BOOL)isAuthenticationRequest:(BLERequest*)request{
    
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


@interface RK410APIService(){
    BLEDataParseProtocolImpl *mBLEDataParseProtocolImpl;
    RKBLEClient *mRKBLEClient;
}

@end

@implementation RK410APIService

+(instancetype)shareService{
    
    static RK410APIService *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[RK410APIService alloc]init];
    });
    return share;
    
}

-(id)init{
    self = [super init];
    if (self) {
        mBLEDataParseProtocolImpl = [[BLEDataParseProtocolImpl alloc] init];
        mRKBLEClient = [[RKBLEClient alloc] init];
    }
    return self;
}

-(RACSignal*)lock:(NSString*)target{
    
    Byte values[1] = {0x00};
    BLERequest *request = [[BLERequest alloc] initWithReponseClass:nil
                                                      target:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:SPIRIT_KEYFUNC]
                                                      method:RKBLEMethodWrite
                                                  writeValue:[[NSData alloc] initWithBytes:&values length:sizeof(values)]];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:SPIRIT_KEYFUNC] && channel == RKBLEResponseNotify) {
            return YES;
        } else {
            return NO;
        }
        
    };
    
    return  [mRKBLEClient performRequest:request];
    
}

@end
