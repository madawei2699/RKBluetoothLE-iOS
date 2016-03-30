//
//  BLEStack.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLEStack.h"
#import "RKBLEUtil.h"

#define DISCONNECT_STATE_TIME_OUT     8
#define CONNECTED_STATE_TIME_OUT      3
#define AUTHENTICATION_STATE_TIME_OUT 35

static BOOL bAuthOK = NO;

@interface BLEStack(){
    
    //定义变量
    BabyBluetooth   *baby;
    
    NSTimer         *mNSTimer;
    
    NSInteger       timeoutValue;
    
}

@property (nonatomic,strong) Request *request;

@property (nonatomic,strong) Request *targetRequest;

@end

@implementation BLEStack

+ (instancetype)sharedInstance {
    
    static BLEStack *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BLEStack alloc] init];
    });
    
    return _sharedClient;
    
}

- (id)init{
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        _BLEState       = RKBLEStateDefault;
        timeoutValue    = DISCONNECT_STATE_TIME_OUT;
    }
    
    return self;
}

- (void)setBLEState:(RKBLEConnectState)mRKBLEState
{
    __weak BLEStack *weekSelf = self;
    _BLEState = mRKBLEState;
    
    switch (_BLEState) {
        case RKBLEStateDefault:
            NSLog(@"设备：缺省状态");
            break;
        case RKBLEStateStart:
            NSLog(@"设备：准备连接");
            break;
        case RKBLEStateScanning:
            NSLog(@"设备：打开设备成功，开始扫描设备");
            break;
        case RKBLEStateConnecting:
            NSLog(@"设备：%@--连接中...",self.peripheralName);
            break;
        case RKBLEStateConnected:
            bAuthOK = NO;
            NSLog(@"设备：%@--连接成功",self.peripheralName);
            break;
        case RKBLEStateDisconnect:
            NSLog(@"设备：%@--断开连接",self.peripheralName);
            break;
        case RKBLEStateFailure:
            NSLog(@"设备：%@--连接失败",self.peripheralName);
            break;
            
        default:
            break;
    }
    
    if (weekSelf.connectProgressBlock) {
        weekSelf.connectProgressBlock(_BLEState,nil);
    }
    
    if (weekSelf.failureBlock) {
        //任务开始运行后，发现蓝牙连接断开或者蓝牙连接失败则发出通知任务执行失败
        if (![weekSelf.request hasHadResponseDelivered] && (_BLEState == RKBLEStateDisconnect || _BLEState == RKBLEStateFailure)) {
            
            [weekSelf failureTask:weekSelf withError:[NSError errorWithDomain:@"BLEStackErrorDomain"
                                                                         code:BLEStackErrorDisconnect
                                                                     userInfo:@{ NSLocalizedDescriptionKey: @"蓝牙连接断开" }]];
            
        }
    }
    
}

-(void)performRequest:(Request*)request{
    
    if([self isAuthRequest:request]){
        self.targetRequest = self.request;
    } else {
        self.targetRequest = nil;
    }
    
    self.request     = request;

    _requestSequence = [self.request getSequence];
    _peripheralName  = self.request.peripheralName;
    _service         = self.request.service;
    _characteristic  = self.request.characteristic;
    _method          = self.request.method;
    _writeValue      = self.request.writeValue;
    
    [self execute];
}

-(void)execute{
    //开始任务
    [self startTask];
    //连接蓝牙
    [self connectToPeripheral];
    //添加超时判断逻辑
    [self addTimeOutLogic];
    //执行任务
    [self executeWithPeripheral:[baby findConnectedPeripheral:self.peripheralName]];
}

/**
 *  开始任务
 */
-(void)startTask{
    
}

/**
 *  添加超时逻辑
 */
-(void)addTimeOutLogic{

    if ([self isNeedAuth:self.request]) {

        timeoutValue = AUTHENTICATION_STATE_TIME_OUT;

    } else if(self.BLEState == RKBLEStateConnected){

        timeoutValue = CONNECTED_STATE_TIME_OUT;

    } else {

        timeoutValue = DISCONNECT_STATE_TIME_OUT;

    }
    if (mNSTimer) {
        [mNSTimer invalidate];
        mNSTimer = nil;
    }
    mNSTimer = [NSTimer timerWithTimeInterval:timeoutValue target:self selector:@selector(checkTimeOut:) userInfo:nil repeats:NO];
    [mNSTimer setFireDate: [[NSDate date]dateByAddingTimeInterval:timeoutValue]];
    [[NSRunLoop currentRunLoop] addTimer:mNSTimer forMode:NSRunLoopCommonModes];

}

/**
 *  超时处理
 *
 *  @param timer
 */
- (void)checkTimeOut:(NSTimer *)timer
{
    [mNSTimer invalidate];
    if (![self.request hasHadResponseDelivered]) {
    
        [self failureTask:self withError:[NSError errorWithDomain:@"BLEStackErrorDomain"
                                                             code:BLEStackErrorTimeOut
                                                         userInfo:@{ NSLocalizedDescriptionKey: @"当前业务处理超时" }]];
    }
}

/**
 *  连接蓝牙
 */
- (void)connectToPeripheral{
    
    baby = [BabyBluetooth shareBabyBluetooth];
    //设置蓝牙委托
    [self babyDelegate];
    
    CBPeripheral *peripheral = [baby findConnectedPeripheral:self.peripheralName];
    
    if (peripheral.state == CBPeripheralStateConnected) {
        
        if ([peripheral.name isEqualToString:self.peripheralName]) {
            //不做处理表示当前需要连接的蓝牙设备已经在连接状态
            _BLEState = RKBLEStateConnected;
            
        } else {
            
            [self connectWithHaving:nil];
            
        }
        
    } else {
        
        if (peripheral && [peripheral.name isEqualToString:self.peripheralName]) {
            
            [self connectWithHaving:peripheral];
            
        } else {
            
            [self connectWithHaving:nil];
            
        }
        
    }
    
}



/**
 *  设置蓝牙委托
 */
-(void)babyDelegate{
    
    __weak BLEStack *weekSelf = self;
    __weak BabyBluetooth *weekBaby = baby;
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        NSLog(@"搜索到了设备:%@",peripheral.name);
        if([peripheral.name isEqualToString:weekSelf.peripheralName]){
            NSLog(@"停止扫描");
            [weekBaby cancelScan];
        }
        
    }];
    
    //设置连接设备的过滤器
    [baby setFilterOnConnetToPeripherals:^BOOL(NSString *peripheralName) {
        
        //设置查找规则是名称大于1 ， the search rule is peripheral.name length > 1
        if (peripheralName.length >= 1 && [peripheralName isEqualToString:weekSelf.peripheralName]) {
            weekSelf.BLEState = RKBLEStateConnecting;
            return YES;
        }
        return NO;
        
    }];
    
    //设备状态改变的委托
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        
        weekSelf.CMState = central.state;
        if (central.state == CBCentralManagerStatePoweredOn) {
            weekSelf.BLEState = RKBLEStateScanning;
        } else {
            weekSelf.BLEState = RKBLEStateFailure;
        }
        
    }];
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        weekSelf.BLEState = RKBLEStateConnected;
        
    }];
    
    //设置设备连接失败的委托
    [baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        
        weekSelf.BLEState = RKBLEStateFailure;
        
    }];
    
    //设置设备断开连接的委托
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        
        weekSelf.BLEState = RKBLEStateDisconnect;
        
    }];
    
    //设置写数据成功的block
    [baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        
        [weekSelf parseResponse:characteristic channel:RKBLEResponseWriteResult];
        
    }];
    
    //设置获取到最新Characteristics值的block
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error){
        
        [weekSelf parseResponse:characteristic channel:RKBLEResponseReadResult];
        
    }];
    
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        
        if (peripheral) {
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                NSLog(@"==========service name:%@ ,characteristic name:%@",service.UUID,characteristic.UUID);
                if (characteristic.properties & CBCharacteristicPropertyNotify) {
                    
                    if (weekSelf.request.dataParseProtocol) {
                        if ([weekSelf.request.dataParseProtocol needSubscribeNotifyWithService:[service.UUID UUIDString] characteristic:[characteristic.UUID UUIDString]]) {
                            [weekSelf setNotify:peripheral characteristic:characteristic];
                        }
                    } else {
                        [weekSelf setNotify:peripheral characteristic:characteristic];
                    }
                    
                }
                
                //发现和需要执行任务一样的特征后执行任务
                if ([[service.UUID UUIDString] isEqualToString:weekSelf.service]
                    &&
                    [[characteristic.UUID UUIDString] isEqualToString:weekSelf.characteristic]) {
                    
                    [weekSelf executeWithPeripheral:peripheral];
                    
                }
                
            }
            
        }
        
    }];
}

/**
 *  订阅通知
 *
 *  @param peripheral
 *  @param characteristic
 */
-(void)setNotify:(CBPeripheral *)peripheral characteristic:(CBCharacteristic*)characteristic {
    
    __weak BLEStack *weekSelf = self;
    [baby
     notify:peripheral
     characteristic:characteristic
     block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        
         NSLog(@">>>在特征%@接收到蓝牙上报数据：%@ ",characteristics.UUID,characteristics.value);
        [weekSelf parseResponse:characteristics channel:RKBLEResponseNotify];
         
    }];
    
}


/**
 *  执行任务
 *
 *  @param peripheral 需要处理的特征
 */
-(void)executeWithPeripheral:(CBPeripheral*) peripheral{
    
    __weak BLEStack *weekSelf = self;
    
    if ( peripheral.state == CBPeripheralStateConnected && ![weekSelf.request hasHadResponseDelivered] ) {
        
        //数据交换协议需要鉴权
        if ([weekSelf isNeedAuth:weekSelf.request]) {
            
            [weekSelf.request.dataParseProtocol createAuthProcessRequest:^(Request* authRequest,NSError* error) {
                
                [weekSelf performRequest:authRequest];

            } peripheralName:weekSelf.peripheralName];
            
        } else {
            
            CBUUID *uuid_service = [CBUUID UUIDWithString:weekSelf.service];
            CBUUID *uuid_char = [CBUUID UUIDWithString:weekSelf.characteristic];
            
            CBCharacteristic *mCBCharacteristic = [RKBLEUtil findCharacteristicFromUUID:uuid_char service:[RKBLEUtil findServiceFromUUID:uuid_service p:peripheral]];
            
            if (mCBCharacteristic == nil) {
                return;
            }
            
            if (weekSelf.method == RKBLEMethodRead) {
                
                NSLog(@"<<<读取特征:%@",mCBCharacteristic.UUID);
                [peripheral readValueForCharacteristic:mCBCharacteristic];
                
            } else if (weekSelf.method == RKBLEMethodWrite){
                
                NSLog(@"<<<写入特征:%@ 值：%@",mCBCharacteristic.UUID,weekSelf.writeValue);
                [peripheral writeValue:weekSelf.writeValue forCharacteristic:mCBCharacteristic type:CBCharacteristicWriteWithResponse];
                
            }
            
        }
        
    }
}

/**
 *  处理蓝牙返回数据
 *
 *  @param characteristic 特征
 */
-(void)parseResponse:(CBCharacteristic *)characteristic channel:(RKBLEResponseChannel)channel{
    
    __weak BLEStack *weekSelf = self;
    
    if (![weekSelf.request hasHadResponseDelivered]) {
        //注入了数据协议处理类则使用注入的协议类进行判断处理
        if (weekSelf.request.dataParseProtocol) {
            
            if ([weekSelf.request.dataParseProtocol effectiveResponse: weekSelf.request characteristic: characteristic.UUID.UUIDString sourceChannel:channel]) {
                
                [weekSelf completeTask:weekSelf withCharacteristic:characteristic channel:channel];
                
            }
            
        } else {
            
            [weekSelf completeTask:weekSelf withCharacteristic:characteristic channel:channel];
            
        }
    }
    
}

/**
 *  连接一个已经连接过的peripheral
 *
 *  @param peripheral
 */
-(void)connectWithHaving:(CBPeripheral *)peripheral{
    
    self.BLEState = RKBLEStateStart;
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    if (peripheral) {
        baby.having(peripheral).connectToPeripherals().discoverServices().discoverCharacteristics().begin();
    } else {
        baby.scanForPeripherals().connectToPeripherals().discoverServices().discoverCharacteristics().begin();
    }
    
}

/**
 *  请求成功
 *
 *  @param weekSelf
 *  @param mCBCharacteristic
 *  @param channel
 */
-(void)completeTask:(BLEStack*) weekSelf withCharacteristic:(CBCharacteristic*) mCBCharacteristic channel:(RKBLEResponseChannel)channel{
    
    switch (channel) {
        case RKBLEResponseWriteResult:
            NSLog(@">>>收到特征:%@写响应",mCBCharacteristic.UUID);
            break;
        case RKBLEResponseReadResult:
            NSLog(@">>>收到特征:%@读取响应值：%@",mCBCharacteristic.UUID,mCBCharacteristic.value);
            break;
        case RKBLEResponseNotify:
            NSLog(@">>>收到特征:%@通知上报值：%@",mCBCharacteristic.UUID,mCBCharacteristic.value);
            break;
        default:
            break;
    }
    if ([weekSelf isAuthRequest:weekSelf.request]){
        if ([weekSelf.request.dataParseProtocol authSuccess:mCBCharacteristic.value]) {
            
            bAuthOK = YES;
            //鉴权成功，开始执行目标任务
            [weekSelf performRequest:weekSelf.targetRequest];
            
        } else {
            
            [weekSelf failureTask:weekSelf withError:[NSError errorWithDomain:@"BLEStackErrorDomain"
                                                                         code:BLEStackAuthError
                                                                     userInfo:@{ NSLocalizedDescriptionKey: @"鉴权失败" }]];
            
        }
        return;
    }
    
    if (weekSelf.successBlock) {
        weekSelf.successBlock(weekSelf.request,mCBCharacteristic.value,nil);
    }
    
    [weekSelf cleanUp:weekSelf];
    
}

/**
 *  请求失败
 *
 *  @param weekSelf
 *  @param error
 */
-(void)failureTask:(BLEStack*) weekSelf withError:(NSError*) error{
    NSLog(@"任务：执行失败%@",[error localizedDescription]);
    if(weekSelf.targetRequest){
        weekSelf.request = weekSelf.targetRequest;
    }
    
    if (weekSelf.failureBlock) {
        weekSelf.failureBlock(weekSelf.request,nil,error);
    }
    
    [weekSelf cleanUp:weekSelf];
}

/**
 *  判断请求是否为鉴权请求
 *
 *  @param weekSelf
 *
 *  @return
 */
-(BOOL)isAuthRequest:(Request*)request{

    if (request.dataParseProtocol
        &&
       [request.dataParseProtocol isAuthenticationRequest:request]
        ){
        
        return YES;
        
    } else {
        
        return NO;
        
    }
}

/**
 *  判断是否需要鉴权
 *
 *  @param weekSelf
 *
 *  @return
 */
-(BOOL)isNeedAuth:(Request*)request{

    if (request.dataParseProtocol
        &&
        [request.dataParseProtocol needAuthentication] && ![request.dataParseProtocol isAuthenticationRequest:request]
        &&
        bAuthOK == NO){
        
        return YES;
        
    } else {
        
        return NO;
        
    }
    
}

/**
 *  清除为当前超时定时器
 *
 *  @param weekSelf
 */
-(void)cleanUp:(BLEStack*) weekSelf{
    //此处必须关闭定时器不然会有内存泄露
    [weekSelf->mNSTimer invalidate];
    weekSelf->mNSTimer = nil;
    
    weekSelf.request = nil;
    weekSelf.targetRequest = nil;
}

-(void)dealloc{
    
    NSLog(@"BLEStack:dealloc");
    
}

@end
