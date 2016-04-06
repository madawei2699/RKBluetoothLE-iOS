//
//  BLEStack.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLEStack.h"
#import "RKBLEUtil.h"

NSString * const BLEStackErrorDomain         = @"BLEStackErrorDomain";

const NSInteger BLEStackErrorTimeOut         = 1;
const NSInteger BLEStackErrorDisconnect      = 2;
const NSInteger BLEStackErrorAuth            = 3;

NSString * const BLEStackErrorTimeOutDesc    = @"当前业务处理超时";
NSString * const BLEStackErrorDisconnectDesc = @"蓝牙连接断开";
NSString * const BLEStackErrorAuthDesc       = @"鉴权失败";

static BOOL bAuthOK = NO;

@interface BLEStack()<CBCentralManagerDelegate,CBPeripheralDelegate>{
    
    int                 CENTRAL_MANAGER_INIT_WAIT_TIMES;
    //已经连接的设备
    CBPeripheral        *activePeripheral;
    //主设备
    CBCentralManager    *centralManager;
    
}

@property (nonatomic,strong) BLERequest *request;

@property (nonatomic,strong) BLERequest *targetRequest;

@end

@implementation BLEStack

#pragma mark -
#pragma mark 初始化

+(instancetype)shareClient{
    
    static BLEStack *shareClient = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        
        shareClient = [[BLEStack alloc] init];
        
    });
    
    return shareClient;
}

- (id)init{
    
    self = [super init];
    
    if(self != nil){
        _BLEState       = RKBLEStateDefault;
        //创建串行队列
        dispatch_queue_t  queue = dispatch_queue_create("com.rokyinfo.BLEStack", NULL);
        centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:queue];
        
    }
    
    return self;
}

-(void)dealloc{
    
    NSLog(@"~BLEStack:dealloc");
    
}

#pragma mark -
#pragma mark 公共方法
-(RACSignal*)performRequest:(BLERequest*)request{
    
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        [[NSThread currentThread] setName:@"BLEStack"];
        
        @strongify(self)
        self.successBlock = ^(BLERequest* reqest, id responseObject){
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        };
        self.failureBlock = ^(BLERequest* reqest,NSError* error){
            [subscriber sendError:error];
        };
        
        [self execute:request];
        
        return nil;
        
    }];
    
}

-(void)finish{
    [self stopScan:nil];
    self.request = nil;
    self.targetRequest = nil;
}

- (void)closeBLE{
    
    [self stopScan:nil];
    [self cancelPeripheralConnection:activePeripheral];

}

#pragma mark -
#pragma mark 私有方法

- (void)setBLEState:(RKBLEConnectState)mRKBLEState error:(NSError*)error
{
    _BLEState = mRKBLEState;
    
    switch (_BLEState) {
        case RKBLEStateDefault:
            NSLog(@"BLEStack => 设备：缺省状态");
            break;
        case RKBLEStateStart:
            NSLog(@"BLEStack => 设备：准备连接");
            break;
        case RKBLEStateScanning:
            NSLog(@"BLEStack => 设备：打开设备成功，开始扫描设备");
            break;
        case RKBLEStateConnecting:
            NSLog(@"BLEStack => 设备：%@--连接中...",self.request.peripheralName);
            break;
        case RKBLEStateConnected:
            bAuthOK = NO;
            NSLog(@"BLEStack => 设备：%@--连接成功",self.request.peripheralName);
            break;
        case RKBLEStateDisconnect:
            NSLog(@"BLEStack => 设备：%@--断开连接",self.request.peripheralName);
            break;
        case RKBLEStateFailure:
            NSLog(@"BLEStack => 设备：%@--连接失败",self.request.peripheralName);
            break;
            
        default:
            break;
    }
    
    if (self.connectProgressBlock) {
        self.connectProgressBlock(_BLEState,_CMState,error);
    }
    
    if (self.failureBlock) {
        //任务开始运行后，发现蓝牙连接断开或者蓝牙连接失败则发出通知任务执行失败
        if (![self.request hasHadResponseDelivered] && (_BLEState == RKBLEStateDisconnect || _BLEState == RKBLEStateFailure)) {
            
            [self failureWithError:[NSError errorWithDomain:BLEStackErrorDomain
                                                       code:BLEStackErrorDisconnect
                                                   userInfo:@{ NSLocalizedDescriptionKey:BLEStackErrorDisconnectDesc }]];
            
        }
    }
    
}

-(void)execute:(BLERequest*)request{
    
    if([self isAuthRequest:request]){
        self.targetRequest = self.request;
    } else {
        self.targetRequest = nil;
    }
    
    self.request       = request;
    
    //连接蓝牙
    [self connectToPeripheral];
    //执行任务
    [self executeWithPeripheral:[activePeripheral.name isEqualToString:self.request.peripheralName] ? activePeripheral : nil];
}

/**
 *  连接蓝牙
 */
- (void)connectToPeripheral{
    
    CBPeripheral *peripheral =  [activePeripheral.name isEqualToString:self.request.peripheralName] ? activePeripheral : nil;
    
    if (peripheral.state == CBPeripheralStateConnected) {
        
        if (![peripheral.name isEqualToString:self.request.peripheralName]) {
            [self connectWithHaving:nil];
        }
    } else {
        
        if (peripheral && [peripheral.name isEqualToString:self.request.peripheralName]) {
            
            [self connectWithHaving:peripheral];
            
        } else {
            
            [self connectWithHaving:nil];
            
        }
        
    }
    
}

/**
 *  连接一个已经连接过的peripheral
 *
 *  @param peripheral
 */
-(void)connectWithHaving:(CBPeripheral *)peripheral{
    
    
    [self setBLEState:RKBLEStateStart error:nil];
    
    [self stopScan:nil];
    
    [self cancelPeripheralConnection:activePeripheral];
    
    [self start:peripheral];
    
    
}

/**
 *  执行任务
 *
 *  @param peripheral 需要处理的特征
 */
-(void)executeWithPeripheral:(CBPeripheral*) peripheral{
    
    if ( peripheral.state == CBPeripheralStateConnected && ![self.request hasHadResponseDelivered] ) {
        
        //数据交换协议需要鉴权
        if ([self isNeedAuth:self.request]) {
            
            [self.request.dataParseProtocol createAuthProcessRequest:^(BLERequest* authRequest,NSError* error) {
                
                [self execute:authRequest];
                
            } peripheralName:self.request.peripheralName];
            
        } else {
            
            CBUUID *uuid_service = [CBUUID UUIDWithString:self.request.service];
            CBUUID *uuid_char = [CBUUID UUIDWithString:self.request.characteristic];
            
            CBCharacteristic *mCBCharacteristic = [RKBLEUtil findCharacteristicFromUUID:uuid_char service:[RKBLEUtil findServiceFromUUID:uuid_service p:peripheral]];
            
            if (mCBCharacteristic == nil) {
                return;
            }
            
            if (self.request.method == RKBLEMethodRead) {
                
                NSLog(@"BLEStack => 读取特征:%@",mCBCharacteristic.UUID);
                [peripheral readValueForCharacteristic:mCBCharacteristic];
                
            } else if (self.request.method == RKBLEMethodWrite){
                
                NSLog(@"BLEStack => 写入特征:%@ 值：%@",mCBCharacteristic.UUID,self.request.writeValue);
                [peripheral writeValue:self.request.writeValue forCharacteristic:mCBCharacteristic type:CBCharacteristicWriteWithResponse];
                
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
    
    
    if (![self.request hasHadResponseDelivered]) {
        //注入了数据协议处理类则使用注入的协议类进行判断处理
        if (self.request.dataParseProtocol) {
            
            if ([self.request.dataParseProtocol effectiveResponse: self.request characteristic: characteristic.UUID.UUIDString sourceChannel:channel  value:characteristic.value]) {
                
                [self completeWithCharacteristic:characteristic channel:channel];
                
            }
            
        } else {
            
            [self completeWithCharacteristic:characteristic channel:channel];
            
        }
    }
    
}



/**
 *  请求成功
 *
 *  @param self
 *  @param mCBCharacteristic
 *  @param channel
 */
-(void)completeWithCharacteristic:(CBCharacteristic*) mCBCharacteristic channel:(RKBLEResponseChannel)channel{
    
    switch (channel) {
        case RKBLEResponseWriteResult:
            NSLog(@"BLEStack => 收到特征:%@写响应",mCBCharacteristic.UUID);
            break;
        case RKBLEResponseReadResult:
            NSLog(@"BLEStack => 收到特征:%@读取响应值：%@",mCBCharacteristic.UUID,mCBCharacteristic.value);
            break;
        case RKBLEResponseNotify:
            NSLog(@"BLEStack => 收到特征:%@通知上报值：%@",mCBCharacteristic.UUID,mCBCharacteristic.value);
            break;
        default:
            break;
    }
    if ([self isAuthRequest:self.request]){
        if ([self.request.dataParseProtocol authSuccess:mCBCharacteristic.value]) {
            
            bAuthOK = YES;
            //鉴权成功，开始执行目标任务
            [self execute:self.targetRequest];
            
        } else {
            
            [self failureWithError:[NSError errorWithDomain:BLEStackErrorDomain
                                                       code:BLEStackErrorAuth
                                                   userInfo:@{ NSLocalizedDescriptionKey: BLEStackErrorAuthDesc }]];
            
        }
        return;
    }
    
    if (self.successBlock) {
        self.successBlock(self.request,mCBCharacteristic.value ? mCBCharacteristic.value :[[NSData alloc] init]);
    }
    
    [self finish];
    
}

/**
 *  请求失败
 *
 *  @param self
 *  @param error
 */
-(void)failureWithError:(NSError*) error{
    
    if(self.targetRequest){
        self.request = self.targetRequest;
    }
    
    if (self.failureBlock) {
        self.failureBlock(self.request,error);
    }
    
    [self finish];
}





#pragma mark -
#pragma mark 协议辅助

/**
 *  判断请求是否为鉴权请求
 *
 *  @param self
 *
 *  @return
 */
-(BOOL)isAuthRequest:(BLERequest*)request{
    
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
 *  @param self
 *
 *  @return
 */
-(BOOL)isNeedAuth:(BLERequest*)request{
    
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


#pragma mark -
#pragma mark 连接管理

-(void)start:(CBPeripheral *)cachedPeripheral{
    if (centralManager.state == CBCentralManagerStatePoweredOn) {
        CENTRAL_MANAGER_INIT_WAIT_TIMES = 0;
        if (cachedPeripheral) {
            [centralManager connectPeripheral:cachedPeripheral options:nil];
        } else {
            [centralManager scanForPeripheralsWithServices:nil options:nil];
        }
        return;
    }
    //尝试重新等待CBCentralManager打开
    CENTRAL_MANAGER_INIT_WAIT_TIMES ++;
    if (CENTRAL_MANAGER_INIT_WAIT_TIMES >=5 ) {
        NSLog(@"BLEStack => 第%d次等待CBCentralManager 打开任然失败，请检查你蓝牙使用权限或检查设备问题。",CENTRAL_MANAGER_INIT_WAIT_TIMES);
        return;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self start:cachedPeripheral];
    });
    NSLog(@"BLEStack => 第%d次等待CBCentralManager打开",CENTRAL_MANAGER_INIT_WAIT_TIMES);
}

-(void)stopScan:(id)sender{
    NSLog(@"BLEStack => StopScan");
    [centralManager stopScan];
}

//断开设备连接
-(void)cancelPeripheralConnection:(CBPeripheral *)peripheral{
    if (peripheral) {
        [centralManager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark -
#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    _CMState = central.state;
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict{
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"BLEStack => discover:%@",peripheral.name);
    if([self.request.peripheralName isEqualToString:peripheral.name]) {
        [self stopScan:nil];
        [self setBLEState:RKBLEStateConnecting error:nil];
        
        activePeripheral = peripheral;
        [centralManager connectPeripheral:activePeripheral
                                  options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self setBLEState:RKBLEStateConnected error:nil];
    //设置委托
    activePeripheral = peripheral;
    [activePeripheral setDelegate:self];
    [activePeripheral discoverServices:nil];
    
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self setBLEState:RKBLEStateFailure error:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    if (error)
    {
        NSLog(@"BLEStack => didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
    [self setBLEState:RKBLEStateDisconnect error:error];
    
}

#pragma mark -
#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"BLEStack => didDiscoverServices for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
    
    //discover characteristics
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (error)
    {
        NSLog(@"BLEStack => error didDiscoverCharacteristicsForService for %@ with error: %@", service.UUID, [error localizedDescription]);
    }
    
    if (peripheral) {
        
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            
            if (characteristic.properties & CBCharacteristicPropertyNotify) {
                
                if (self.request.dataParseProtocol) {
                    if ([self.request.dataParseProtocol needSubscribeNotifyWithService:[service.UUID UUIDString] characteristic:[characteristic.UUID UUIDString]]) {
                        
                        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                        
                    }
                } else {
                    
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                    
                }
                
            }
            
            //发现和需要执行任务一样的特征后执行任务
            if ([[service.UUID UUIDString] isEqualToString:self.request.service]
                &&
                [[characteristic.UUID UUIDString] isEqualToString:self.request.characteristic]) {
                
                [self executeWithPeripheral:peripheral];
                
            }
            
        }
        
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error)
    {
        NSLog(@"BLEStack => error didUpdateValueForCharacteristic %@ with error: %@", characteristic.UUID, [error localizedDescription]);
    }
    
    if ((characteristic.properties & CBCharacteristicPropertyNotify)
        &&
        self.request.dataParseProtocol
        &&
        [self.request.dataParseProtocol needSubscribeNotifyWithService:[characteristic.service.UUID UUIDString] characteristic:[characteristic.UUID UUIDString]]) {
        
        [self parseResponse:characteristic channel:RKBLEResponseNotify];
        return;
        
    }
    
    [self parseResponse:characteristic channel:RKBLEResponseReadResult];
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error)
    {
        NSLog(@"BLEStack => error Discovered DescriptorsForCharacteristic for %@ with error: %@", characteristic.UUID, [error localizedDescription]);
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    
    
    if (error)
    {
        NSLog(@"BLEStack => error didUpdateValueForDescriptor  for %@ with error: %@", descriptor.UUID, [error localizedDescription]);
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    [self parseResponse:characteristic channel:RKBLEResponseWriteResult];
    
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    
    //    NSLog(@"BLEStack => didUpdateNotificationStateForCharacteristic");
    //    NSLog(@"BLEStack => uuid:%@,isNotifying:%@",characteristic.UUID,characteristic.isNotifying?@"isNotifying":@"Notifying");
    
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error{
    
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    
    
    //    NSLog(@"BLEStack => peripheralDidUpdateRSSI -> RSSI:%@",RSSI);
    
    
}

-(void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    
}

-(void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices{
    
}

@end
