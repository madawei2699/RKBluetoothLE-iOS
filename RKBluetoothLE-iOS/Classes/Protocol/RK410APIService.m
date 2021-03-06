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
#import "BLERequest.h"
#import "ByteConvert.h"
#import "UpgradeManager.h"
#import "DefaultRetryPolicy.h"


NSString * const RKBLEAuthResultNotification = @"RKBLEAuthResultNotification";
NSString * const RKBLEAuthResultStatus       = @"RKBLEAuthResultStatus";
NSString * const RKBLEAuthResultError        = @"RKBLEAuthResultError";

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

//    1.1	固件升级控制（0x9908）
static NSString* const FIRMWARE_UPGRADE         = @"9908";

//    1.1	固件数据通道(0x9909)
static NSString* const DATA_CHANNEL             = @"9909";

//    配一配设置
static NSString* const SPIRIT_SET_PARAM         = @"9801";

//static int RBL_BLE_FRAMEWORK_VER                = 0x0200;

@interface Rk410BleProtocolImpl : NSObject<BLEDataParseProtocol>

@property(nonatomic,copy)PostAuthCode postAuthCode;

@end

@implementation Rk410BleProtocolImpl

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
        } else if ([characteristic isEqualToString:SPIRIT_WRT_PARAM]){
            return YES;
        } else if ([characteristic isEqualToString:SPIRIT_PARAM_RST]){
            return YES;
        } else if ([characteristic isEqualToString:SPIRIT_KEYFUNC]){
            return YES;
        } else if ([characteristic isEqualToString:FIRMWARE_UPGRADE]){
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
    
    if (self.postAuthCode) {
        
        id authCode = self.postAuthCode(_peripheralName);
        
        if ([authCode isKindOfClass:[NSError class]]) {
            if (callBack) {
                callBack(nil,authCode);
            }
            return;
        }
        
        BLERequest *authRequest = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:_peripheralName
                                                                                     service:SERVICE_SPIRIT_SYNC_DATA
                                                                              characteristic:SPIRIT_AUTH_CODE]
                                                              method:RKBLEMethodWrite
                                                          writeValue:authCode];
        authRequest.dataParseProtocol = self;
        authRequest.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
            
            if ([characteristic isEqualToString:SPIRIT_AUTH_CODE] && channel == RKBLEResponseNotify) {
                return YES;
            } else {
                return NO;
            }
            
        };
        [authRequest setRetryPolicy:[[DefaultRetryPolicy alloc] initWithTimeout:15.0f delayTime:0.100f maxRetries:0]];
        if (callBack) {
            callBack(authRequest,nil);
        }
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
    
    BOOL authOK = NO;
    NSString *errorMsg = @"";
    //发出鉴权成功广播
    if (value.length > 0) {
        Byte state;
        [value getBytes:&state length:1];
        switch (state) {
            case 0x00:
                authOK = true;
                break;
            case 0x01:
                errorMsg = @"鉴权码错误";
                break;
            case 0x02:
                errorMsg = @"鉴权码过期";
                break;
            case 0x03:
                errorMsg = @"需要新的鉴权码";
                break;
            case 0x04:
                errorMsg = @"钥匙列表已满";
                break;
        }
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:RKBLEAuthResultNotification
     object:nil
     userInfo: @{RKBLEAuthResultStatus:@(authOK),RKBLEAuthResultError:[NSError errorWithDomain:BLEStackErrorDomain
                                                                                          code:BLEStackErrorAuth
                                                                                      userInfo:@{ NSLocalizedDescriptionKey: errorMsg }]}
     ];
    
    return authOK;
    
}

@end


@interface RK410APIService(){
    
    Rk410BleProtocolImpl *mBLEDataParseProtocolImpl;
    
    NSMutableArray<BLERequest*> *mCurrentRequests;
    
    UpgradeManager *mUpgradeManager;
    
}

@property (nonatomic,strong) RequestQueue *mRequestQueue;

@end

@implementation RK410APIService

#pragma mark -
#pragma mark life cycle

-(id)initWithRequestQueue:(RequestQueue *)mRequestQueue{
    self = [super init];
    if (self) {
        mBLEDataParseProtocolImpl = [[Rk410BleProtocolImpl alloc] init];
        _mRequestQueue = mRequestQueue;
    }
    return self;
}

-(void)setPostAuthCodeBlock:(PostAuthCode)postAuthCode{
    mBLEDataParseProtocolImpl.postAuthCode = postAuthCode;
}


#pragma mark -
#pragma mark 私有方法

-(void)performRequest:(BLERequest*) request
              success:(void (^)(id responseObject))success
              failure:(void (^)(NSError* error))failure{
    
    request.mRequestSuccessBlock = success;
    request.mRequestErrorBlock = failure;
    [self.mRequestQueue add:request];
    
    [mCurrentRequests removeObject:request];
}

-(RACSignal*)performRequest:(BLERequest*) request{
    
    [mCurrentRequests addObject:request];
    
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        
        @strongify(self)
        [self performRequest:request
                     success:^( id responseObject){
                         
                         [subscriber sendNext:responseObject];
                         [subscriber sendCompleted];
                     }
                     failure:^( NSError *error){
                         [subscriber sendError:error];
                     }];
        
        return [RACDisposable disposableWithBlock:^{
            if (![request hasHadResponseDelivered]) {
                [request cancel];
            }
            [mCurrentRequests removeObject:request];
        }];
        
    }];
    
}

/**
 *  鉴权结果信号
 *  RKBLEAuthResultStatus ：yes: 成功 no:失败
 *  RKBLEAuthResultError ：鉴权失败的错误对象
 *  @return NSNotification
 */
-(RACSignal*) authResultSignal{
    return [[NSNotificationCenter defaultCenter] rac_addObserverForName:RKBLEAuthResultNotification object:nil];
}

#pragma mark -
#pragma mark 遥控器控制类指令

typedef NS_ENUM(NSInteger, KeyEventType) {
    
    KeyEventTypeLock    = 0,
    KeyEventTypeUnlock  = 1,
    KeyEventTypeSearch  = 2,
    KeyEventTypeOpenBox = 3,
    
};

-(BLERequest*)createKeyEventRequest:(NSString*)target keyEventType:(KeyEventType)actionIndex{
    
    Byte requestParame[1] = {0x00};
    
    switch (actionIndex) {
        case KeyEventTypeLock:
            requestParame[0] = 0x00;
            break;
        case KeyEventTypeUnlock:
            requestParame[0] = 0x11;
            break;
        case KeyEventTypeSearch:
            requestParame[0] = 0x01;
            break;
        case KeyEventTypeOpenBox:
            requestParame[0] = 0x02;
            break;
            
        default:
            break;
    }
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:SPIRIT_KEYFUNC]
                                                      method:RKBLEMethodWrite
                                                  writeValue:[[NSData alloc] initWithBytes:&requestParame length:sizeof(requestParame)]];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:SPIRIT_KEYFUNC] && channel == RKBLEResponseNotify) {
            return YES;
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        RemoteControlResult *mKeyEventResponse = [[RemoteControlResult alloc] init];
        unsigned char state;
        [data getBytes:&state range:NSMakeRange(0, 1)];
        if (state == 0) {
            mKeyEventResponse.success = YES;
        } else {
            mKeyEventResponse.success = NO;
        }
        return mKeyEventResponse;
    };
    
    request.RKBLEpriority = IMMEDIATE;
    return request;
}

/**
 *  锁车
 *
 *  @param target
 *
 *  @return RemoteControlResult
 */
-(RACSignal*)lock:(NSString*)target{
    return  [self performRequest:[self createKeyEventRequest:target keyEventType:KeyEventTypeLock]];
}

/**
 *  解锁
 *
 *  @param target
 *
 *  @return RemoteControlResult
 */
-(RACSignal*)unlock:(NSString*)target{
    
    return  [self performRequest:[self createKeyEventRequest:target keyEventType:KeyEventTypeUnlock]];
}

/**
 *  寻车
 *
 *  @param target
 *
 *  @return RemoteControlResult
 */
-(RACSignal*)find:(NSString*)target{
    
    return  [self performRequest:[self createKeyEventRequest:target keyEventType:KeyEventTypeSearch]];
}

/**
 *  开启座桶
 *
 *  @param target
 *
 *  @return RemoteControlResult
 */
-(RACSignal*)openBox:(NSString*)target{
    
    return  [self performRequest:[self createKeyEventRequest:target keyEventType:KeyEventTypeOpenBox]];
}

#pragma mark -
#pragma mark 车况、故障查询

/**
 *  获取车况
 *
 *  @param target
 *
 *  @return VehicleStatus
 */
-(RACSignal*)getVehicleStatus:(NSString*)target{
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:SPIRIT_SYNCDATA]
                                                      method:RKBLEMethodRead
                                                  writeValue:nil];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:SPIRIT_SYNCDATA] && channel == RKBLEResponseReadResult) {
            if (value.length >= 16) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        VehicleStatus *mVehicleStatus = [[VehicleStatus alloc] init];
        return [mVehicleStatus bytes2entity:data];
        
    };
    
    request.RKBLEpriority = HIGH;
    
    return  [self performRequest:request];
    
}

/**
 *  获取故障
 *
 *  @param target
 *
 *  @return Fault
 */
-(RACSignal*)getFault:(NSString*)target{
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:SPIRIT_FAULTDATA]
                                                      method:RKBLEMethodRead
                                                  writeValue:nil];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:SPIRIT_FAULTDATA] && channel == RKBLEResponseNotify) {
            
            if (value.length >= 6) {
                return YES;
            } else {
                return NO;
            }
            
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return [[[Fault alloc] init] bytes2entity:data];
        
    };
    
    request.RKBLEpriority = HIGH;
    
    return  [self performRequest:request];
    
}

/**
 *  设置中控参数
 *
 *  @param target
 *  @param ECUParameter
 *
 *  @return ConfigResult
 */
-(RACSignal*)setECUParameter:(NSString*)target parameter:(ECUParameter*)_ECUParameter{
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:SPIRIT_WRT_PARAM]
                                                      method:RKBLEMethodWrite
                                                  writeValue:[_ECUParameter entity2bytes]];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if (([characteristic isEqualToString:SPIRIT_WRT_PARAM] || [characteristic isEqualToString:SPIRIT_PARAM_RST])&& channel == RKBLEResponseNotify) {
            return YES;
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return [[[ConfigResult alloc] init] bytes2entity:data];
        
    };
    
    request.RKBLEpriority = HIGH;
    
    return  [self performRequest:request];
    
}

/**
 *  获取中控参数
 *
 *  @param target
 *
 *  @return ECUParameter
 */
-(RACSignal*)getECUParameter:(NSString*)target{
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:SPIRIT_WRT_PARAM]
                                                      method:RKBLEMethodWrite
                                                  writeValue:[[ECUParameter alloc] createQueryCommand]];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if (([characteristic isEqualToString:SPIRIT_WRT_PARAM] || [characteristic isEqualToString:SPIRIT_PARAM_RST])&& channel == RKBLEResponseNotify) {
            return YES;
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return [[[ECUParameter alloc] init] bytes2entity:data];
        
    };
    
    request.RKBLEpriority = HIGH;
    
    return  [self performRequest:request];
    
}



#pragma mark -
#pragma mark 固件升级

/**
 *  请求升级
 *
 *  @param target
 *
 *  @return RequestUpgradeResponse
 */
-(RACSignal*)requestUpgrade:(NSString*)target withFirmware:(Firmware*)_Firmware{
    
    Byte year = (Byte)[_Firmware.version substringWithRange:NSMakeRange(0, 2)].intValue;
    Byte week = (Byte)[_Firmware.version substringWithRange:NSMakeRange(2, 2)].intValue;
    Byte buildCount = (Byte)([_Firmware.version componentsSeparatedByString:@"."][1]).intValue;;
    
    NSMutableData *writeValue =  [[NSMutableData alloc] init];
    Byte command[1] = {0x08};
    //指令
    [writeValue appendBytes:command length:1];
    //固件版本
    Byte version[4] = {year,week,buildCount,0xff};
    [writeValue appendBytes:version length:4];
    //文件长度
    [writeValue appendData:[[ByteConvert intToBytes:_Firmware.fileSize] subdataWithRange:NSMakeRange(1, 3)] ];
    //单包长度 单位kb
    Byte singlePackageSize[1] = {_Firmware.singlePackageSize};
    [writeValue appendBytes:singlePackageSize length:1];
    //单帧长度
    [writeValue appendData:[ByteConvert shortToBytes:_Firmware.singleFrameSize]];
    //是否强制升级
    Byte isForceUpgradeMode[1] = {_Firmware.isForceUpgradeMode ? 1 : 0};
    [writeValue appendBytes:isForceUpgradeMode length:1];
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:FIRMWARE_UPGRADE]
                                                      method:RKBLEMethodWrite
                                                  writeValue:writeValue];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:FIRMWARE_UPGRADE] && channel == RKBLEResponseNotify) {
            
            if (value.length >= 8 && [[[RequestUpgradeResponse alloc] init] isHit:value]) {
                return YES;
            } else {
                return NO;
            }
            
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return [[[RequestUpgradeResponse alloc] init] bytes2entity:data];
        
    };
    [request setRetryPolicy:[[DefaultRetryPolicy alloc] initWithTimeout:15.0f delayTime:0.100f maxRetries:0]];
    request.RKBLEpriority = NORMAL;
    
    return  [self performRequest:request];
}

/**
 *  请求开始传输包
 *
 *  @param target
 *  @param _RKPackage
 *
 *  @return RequestPackageResponse
 */
-(RACSignal*)requestStartPackage:(NSString*)target withPackage:(RKPackage*)_RKPackage{
    
    NSMutableData *writeValue =  [[NSMutableData alloc] init];
    Byte command[1] = {0x01};
    //指令
    [writeValue appendBytes:command length:1];
    //包号
    [writeValue appendData:[ByteConvert shortToBytes:_RKPackage.packageIndex]];
    //包大小
    [writeValue appendData:[ByteConvert intToBytes:_RKPackage.packageSize]];
    //已经上传文件长度
    [writeValue appendData:[ByteConvert intToBytes:_RKPackage.uploadLength]];
    
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:FIRMWARE_UPGRADE]
                                                      method:RKBLEMethodWrite
                                                  writeValue:writeValue];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:FIRMWARE_UPGRADE] && channel == RKBLEResponseNotify) {
            if (value.length >= 3 && [[[RequestPackageResponse alloc] init] isHit:value]) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return [[[RequestPackageResponse alloc] init] bytes2entity:data];
    };
    [request setRetryPolicy:[[DefaultRetryPolicy alloc] initWithTimeout:15.0f delayTime:0.100f maxRetries:0]];
    request.RKBLEpriority = NORMAL;
    
    return  [self performRequest:request];
}


/**
 *  请求结束传输包
 *
 *  @param target
 *  @param _RKPackage
 *
 *  @return FinishPackageResponse
 */
-(RACSignal*)requestEndPackage:(NSString*)target withPackage:(RKPackage*)_RKPackage{
    
    NSMutableData *writeValue =  [[NSMutableData alloc] init];
    Byte command[1] = {0x03};
    //指令
    [writeValue appendBytes:command length:1];
    //包号
    [writeValue appendData:[ByteConvert shortToBytes:_RKPackage.packageIndex]];
    //CRC校验
    [writeValue appendData:[ByteConvert shortToBytes:_RKPackage.crc]];
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:FIRMWARE_UPGRADE]
                                                      method:RKBLEMethodWrite
                                                  writeValue:writeValue];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:FIRMWARE_UPGRADE] && channel == RKBLEResponseNotify) {
            
            if (value.length >= 3 && [[[FinishPackageResponse alloc] init] isHit:value]) {
                return YES;
            } else {
                return NO;
            }

        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return  [[[FinishPackageResponse alloc] init] bytes2entity:data];
        
    };
    [request setRetryPolicy:[[DefaultRetryPolicy alloc] initWithTimeout:15.0f delayTime:0.100f maxRetries:0]];
    request.RKBLEpriority = NORMAL;
    
    return  [self performRequest:request];
}

/**
 *  升级文件MD5校验
 *
 *  @param target
 *  @param _RKPackage
 *
 *  @return MD5CheckResponse
 */
-(RACSignal*)checkFileMD5:(NSString*)target withFirmware:(Firmware*)_Firmware{
    
    NSMutableData *writeValue =  [[NSMutableData alloc] init];
    Byte command[1] = {0x05};
    //指令
    [writeValue appendBytes:command length:1];
    //MD5
    [writeValue appendData:[[[CocoaSecurityDecoder alloc] init] hex:_Firmware.md5]];
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:FIRMWARE_UPGRADE]
                                                      method:RKBLEMethodWrite
                                                  writeValue:writeValue];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:FIRMWARE_UPGRADE] && channel == RKBLEResponseNotify) {
            if (value.length >= 3 && [[[MD5CheckResponse alloc] init] isHit:value]) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return [[[MD5CheckResponse alloc] init] bytes2entity:data];
        
    };
    [request setRetryPolicy:[[DefaultRetryPolicy alloc] initWithTimeout:15.0f delayTime:0.100f maxRetries:0]];
    request.RKBLEpriority = NORMAL;
    
    return  [self performRequest:request];
}

/**
 *  发送数据
 *
 *  @param target
 *  @param _RKFrame
 *
 *  @return
 */
-(RACSignal*)sendData:(NSString*)target withFrame:(RKFrame*)_RKFrame{
    
    BLERequest *request = [[BLERequest alloc] initWithTarget:[RKBLEUtil createTarget:target
                                                                             service:SERVICE_SPIRIT_SYNC_DATA
                                                                      characteristic:DATA_CHANNEL]
                                                      method:RKBLEMethodWrite
                                                  writeValue:_RKFrame.data];
    
    request.dataParseProtocol = mBLEDataParseProtocolImpl;
    request.effectiveResponse = ^(NSString* characteristic,RKBLEResponseChannel channel,NSData* value){
        
        if ([characteristic isEqualToString:DATA_CHANNEL] && channel == RKBLEResponseWriteResult) {
            return YES;
        } else {
            return NO;
        }
        
    };
    request.parseBLEResponseData = (id) ^(NSData *data){
        
        return data;
    };
    
    request.RKBLEpriority = NORMAL;
    
    return  [self performRequest:request];
}


@end
