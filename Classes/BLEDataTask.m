//
//  BLEDataTask.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLEDataTask.h"
#import "RKBLEUtil.h"

#define DISCONNECT_STATE_TIME_OUT     8
#define CONNECTED_STATE_TIME_OUT      3
#define AUTHENTICATION_STATE_TIME_OUT 35

static BOOL bAuthOK = NO;



@interface BLEDataTask(){
    
    //定义变量
    BabyBluetooth   *baby;
    
    NSTimer         *mNSTimer;
    
    NSInteger       timeoutValue;
    
}

@property (nonatomic,strong) BLEDataTask * authenticationTask;

@end

@implementation BLEDataTask

- (id)initWithPeripheralName:(NSString*)peripheralName
                     service:(NSString*)service
              characteristic:(NSString*)characteristic
                      method:(RKBLEMethod)method
                  writeValue:(NSData*)writeValue{
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        _taskIdentifier = [[NSUUID UUID] UUIDString];
        _peripheralName = peripheralName;
        _service        = service;
        _characteristic = characteristic;
        _method         = method;
        _writeValue     = writeValue;
        _BLEState       = RKBLEStateDefault;
        _TaskState      = DataTaskStateSuspended;
        timeoutValue    = DISCONNECT_STATE_TIME_OUT;
    }
    
    return self;
}

- (void)setBLEState:(RKBLEState)mRKBLEState
{
    __weak BLEDataTask *weekSelf = self;
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
        weekSelf.connectProgressBlock(weekSelf,nil);
    }
    
    if (weekSelf.failureBlock) {
        //任务开始运行后，发现蓝牙连接断开或者蓝牙连接失败则发出通知任务执行失败
        if (weekSelf.TaskState == DataTaskStateRunning
            &&
            (_BLEState == RKBLEStateDisconnect || _BLEState == RKBLEStateFailure)) {
            
            [weekSelf failureTask:weekSelf withError:[NSError errorWithDomain:@"BLEDataTaskErrorDomain"
                                                                         code:BLEDataTaskErrorDisconnect
                                                                     userInfo:@{ NSLocalizedDescriptionKey: @"蓝牙连接断开" }]];
            
        }
    }
    
}

- (void)setTaskState:(RKBLEDataTaskState)mRKBLEDataTaskState{
    
    _TaskState      = mRKBLEDataTaskState;
    
    switch (_TaskState) {
        case DataTaskStateRunning:
            NSLog(@"\n");
            NSLog(@"\n");
            NSLog(@"---------------------BLEDataTask Start--------------------------");
            NSLog(@"任务：运行中...");
            break;
        case DataTaskStateSuspended:
            NSLog(@"任务：挂起任务，初始化缺省状态");
            break;
        case DataTaskStateCanceling:
            NSLog(@"任务：取消中...");
            break;
        case DataTaskStateCompleted:
            NSLog(@"任务：执行完毕");
            NSLog(@"---------------------BLEDataTask End-----------------------------");
            break;
        case DataTaskStateFailure:
            NSLog(@"任务：执行失败");
            NSLog(@"---------------------BLEDataTask End-----------------------------");
            break;
            
        default:
            break;
    }
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

-(void)startTask{
    
    self.TaskState = DataTaskStateRunning;
    
}

/**
 *  添加超时逻辑
 */
-(void)addTimeOutLogic{

    if (self.dataParseProtocol
        &&
        [self.dataParseProtocol needAuthentication] && ![self.dataParseProtocol isAuthenticationTask:self]
        &&
        bAuthOK == NO) {
        
        timeoutValue = AUTHENTICATION_STATE_TIME_OUT;
        
    } else if(self.BLEState == RKBLEStateConnected){
        
        timeoutValue = CONNECTED_STATE_TIME_OUT;
        
    } else {
        
        timeoutValue = DISCONNECT_STATE_TIME_OUT;
        
    }
    
    mNSTimer = [NSTimer timerWithTimeInterval:timeoutValue target:self selector:@selector(checkTimeOut:) userInfo:nil repeats:NO];
    [mNSTimer setFireDate: [[NSDate date]dateByAddingTimeInterval:timeoutValue]];
    [[NSRunLoop currentRunLoop] addTimer:mNSTimer forMode:NSRunLoopCommonModes];

}

- (void)checkTimeOut:(NSTimer *)timer
{
    [mNSTimer invalidate];
    if (self.TaskState != DataTaskStateCompleted && self.TaskState != DataTaskStateCanceling) {
        
        [self failureTask:self withError:[NSError errorWithDomain:@"BLEDataTaskErrorDomain"
                                                             code:BLEDataTaskErrorTimeOut
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
    
    __weak BLEDataTask *weekSelf = self;
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
                    
                    if (weekSelf.dataParseProtocol) {
                        if ([weekSelf.dataParseProtocol needSubscribeNotifyWithService:[service.UUID UUIDString] characteristic:[characteristic.UUID UUIDString]]) {
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
    
    __weak BLEDataTask *weekSelf = self;
    [baby notify:peripheral
  characteristic:characteristic
           block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
               
               NSLog(@">>>在特征%@接收到蓝牙上报数据：%@ ",characteristics.UUID,characteristics.value);
               if (weekSelf.authenticationTask) {
                   [weekSelf.authenticationTask parseResponse:characteristics channel:RKBLEResponseNotify];
               } else {
                   [weekSelf parseResponse:characteristics channel:RKBLEResponseNotify];
               }
               
               
           }];
    
}


/**
 *  执行任务
 *
 *  @param peripheral 需要处理的特征
 */
-(void)executeWithPeripheral:(CBPeripheral*) peripheral{
    
    __weak BLEDataTask *weekSelf = self;
    
    if (weekSelf.TaskState != DataTaskStateCompleted && peripheral.state == CBPeripheralStateConnected) {
        
        //数据交换协议需要鉴权
        if (weekSelf.dataParseProtocol
            &&
            [weekSelf.dataParseProtocol needAuthentication] && ![weekSelf.dataParseProtocol isAuthenticationTask:weekSelf]
            &&
            bAuthOK == NO
            ) {
            
            [weekSelf.dataParseProtocol createAhthProcessTask:^(BLEDataTask* authTask,NSError* error) {
                
                weekSelf.authenticationTask = authTask;
        
                if (authTask) {
                    
                    authTask.connectProgressBlock = weekSelf.connectProgressBlock;
                    authTask.successBlock = ^(BLEDataTask* task, id responseObject,NSError* _Nullable error){
                        
                        if ([task.dataParseProtocol authSuccess:responseObject]) {
                            //鉴权成功
                            bAuthOK = YES;
                            [weekSelf execute];
                            
                        } else {
                            
                            [weekSelf failureTask:weekSelf withError:error];
                            
                        }
                        
                    };
                    authTask.failureBlock = ^(BLEDataTask* task, id responseObject,NSError* _Nullable error){
                        
                        [weekSelf failureTask:weekSelf withError:error];
                        
                    };
                    
                    [authTask execute];
                    
                } else {
                    
                    [weekSelf failureTask:weekSelf withError:error];
                    
                }
                
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
    
    __weak BLEDataTask *weekSelf = self;
    
    if (weekSelf.TaskState != DataTaskStateCompleted) {
        //注入了数据协议处理类则使用注入的协议类进行判断处理
        if (weekSelf.dataParseProtocol) {
            
            if ([weekSelf.dataParseProtocol effectiveResponse: weekSelf characteristic: characteristic.UUID.UUIDString sourceChannel:channel]) {
                
                [weekSelf completeTask:weekSelf withCharacteristic:characteristic channel:channel];
                
            }
            
        } else {
            
            [weekSelf completeTask:weekSelf withCharacteristic:characteristic channel:channel];
            
        }
    }
    
}

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

-(void)completeTask:(BLEDataTask*) weekSelf withCharacteristic:(CBCharacteristic*) mCBCharacteristic channel:(RKBLEResponseChannel)channel{
    
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
    
    weekSelf.TaskState = DataTaskStateCompleted;
    if (weekSelf.successBlock) {
        weekSelf.successBlock(weekSelf,mCBCharacteristic.value,nil);
    }
    
    [weekSelf cleanUp:weekSelf];
    
}

-(void)failureTask:(BLEDataTask*) weekSelf withError:(NSError*) error{
    NSLog(@"任务：执行失败%@",[error localizedDescription]);
    
    weekSelf.TaskState = DataTaskStateFailure;
    if (weekSelf.failureBlock) {
        weekSelf.failureBlock(weekSelf,nil,error);
    }
    
    [weekSelf cleanUp:weekSelf];
    
}

-(void)cleanUp:(BLEDataTask*) weekSelf{
    //此处必须关闭定时器不然会有内存泄露
    [weekSelf->mNSTimer invalidate];
    weekSelf->mNSTimer = nil;
    
    weekSelf.authenticationTask = nil;
    
}

-(void)dealloc{
    
    NSLog(@"BLEDataTask:dealloc");
    
}

@end
