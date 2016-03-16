//
//  BLEDataTask.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLEDataTask.h"
#import "RKBLEUtil.h"

#define TIME_OUT  15

@interface BLEDataTask(){
    
    //定义变量
    BabyBluetooth *baby;
    
    NSTimer *mNSTimer;
    
}

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
    }
    
    return self;
}

- (void)setBLEState:(RKBLEState)mRKBLEState
{
    __weak BLEDataTask *weekSelf = self;
    _BLEState = mRKBLEState;
    
    switch (_BLEState) {
        case RKBLEStateDefault:
            NSLog(@"缺省状态");
            break;
        case RKBLEStateStart:
            NSLog(@"准备连接");
            break;
        case RKBLEStateScanning:
            NSLog(@"打开设备成功，开始扫描设备");
            break;
        case RKBLEStateConnecting:
            NSLog(@"设备：%@--连接中...",self.peripheralName);
            break;
        case RKBLEStateConnected:
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
        if ((_BLEState == RKBLEStateDisconnect || _BLEState == RKBLEStateFailure)
            &&
            weekSelf.TaskState != DataTaskStateCompleted) {
            
            self.TaskState = DataTaskStateFailure;
            
            weekSelf.failureBlock(weekSelf,nil,[NSError errorWithDomain:@"BLEDataTaskErrorDomain"
                                                                   code:BLEDataTaskErrorDisconnect
                                                               userInfo:@{ NSLocalizedDescriptionKey: @"蓝牙连接断开" }]);
            
        }
    }
    
}

-(void)execute{
    
    //开始任务
    [self startTask];
    //连接蓝牙
    [self connectToPeripheral];
    //执行任务
    [self executeWithPeripheral:[baby findConnectedPeripheral:self.peripheralName]];
    
}

-(void)startTask{
    
    self.TaskState = DataTaskStateRunning;
    mNSTimer = [NSTimer scheduledTimerWithTimeInterval:TIME_OUT target:self selector:@selector(checkTimeOut:) userInfo:nil repeats:NO];
    
}

- (void)checkTimeOut:(NSTimer *)timer
{
    [mNSTimer invalidate];
    if (self.TaskState != DataTaskStateCompleted && self.TaskState != DataTaskStateCanceling) {
        
        self.TaskState = DataTaskStateFailure;
        
        NSLog(@"checkTimeOut:");
        
        if (self.failureBlock) {
            
            self.failureBlock(self,nil,[NSError errorWithDomain:@"BLEDataTaskErrorDomain"
                                                           code:BLEDataTaskErrorTimeOut
                                                       userInfo:@{ NSLocalizedDescriptionKey: @"当前业务处理超时" }]);
            
        }
        
    }
    
}

- (void)connectToPeripheral{
    
    baby = [BabyBluetooth shareBabyBluetooth];
    //设置蓝牙委托
    [self babyDelegate];
    
    CBPeripheral *peripheral = [baby findConnectedPeripheral:self.peripheralName];
    
    if (peripheral.state == CBPeripheralStateConnected) {
        
        if ([peripheral.name isEqualToString:self.peripheralName]) {
            //不做处理表示当前需要连接的蓝牙设备已经在连接状态
            self.BLEState = RKBLEStateConnected;
            
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



//设置蓝牙委托
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
        if (peripheralName.length >= 1 && [peripheralName isEqualToString:self.peripheralName]) {
            weekSelf.BLEState = RKBLEStateConnecting;
            return YES;
        }
        return NO;
        
    }];
    
    //设备状态改变的委托
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        
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
        [weekSelf parseResponse:characteristic];
    }];
    
    //设置获取到最新Characteristics值的block
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error){
        
        [weekSelf parseResponse:characteristic];
        
    }];
    
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        
        if (peripheral) {
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                NSLog(@"==========service name:%@ ,characteristic name:%@",service.UUID,characteristic.UUID);
                if (characteristic.properties & CBCharacteristicPropertyNotify) {
                    
                    if (self.dataParseProtocol && [self.dataParseProtocol needSubscribeNotifyWithService:[service.UUID UUIDString] characteristic:[characteristic.UUID UUIDString]]) {
                        [weekSelf setNotify:peripheral characteristic:characteristic];
                    }
                    
                    
                }
            }
            if ([[service.UUID UUIDString] isEqualToString:@"9900"]) {
                //执行任务
                [weekSelf executeWithPeripheral:peripheral];
                
                
            }
            
        }
        
    }];
    
}

-(void)setNotify:(CBPeripheral *)peripheral characteristic:(CBCharacteristic*)characteristic {
    
    __weak BLEDataTask *weekSelf = self;
    [baby notify:peripheral
  characteristic:characteristic
           block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
               
               [weekSelf parseResponse:characteristics];
               
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
            
            NSLog(@"<<<写入特征:%@ 值：%@",weekSelf.writeValue,mCBCharacteristic.UUID);
            [peripheral writeValue:weekSelf.writeValue forCharacteristic:mCBCharacteristic type:CBCharacteristicWriteWithResponse];
            
        }
        
    }
}

/**
 *  处理蓝牙返回数据
 *
 *  @param characteristic 特征
 */
-(void)parseResponse:(CBCharacteristic *)characteristic{
    
    __weak BLEDataTask *weekSelf = self;
    
    if (weekSelf.TaskState != DataTaskStateCompleted) {
        //注入了数据协议处理类则使用注入的协议类进行判断处理
        if (weekSelf.dataParseProtocol) {
            
            if ([weekSelf.dataParseProtocol effectiveResponse: weekSelf characteristic: characteristic.UUID.UUIDString]) {
                
                [weekSelf completeTask:weekSelf withData:characteristic.value];
                
            }
            
        } else {
            
            [weekSelf completeTask:weekSelf withData:characteristic.value];
            
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

-(void)completeTask:(BLEDataTask*) weekSelf withData:(NSData*) value{
    weekSelf.TaskState = DataTaskStateCompleted;
    if (weekSelf.successBlock) {
        weekSelf.successBlock(weekSelf,value,nil);
    }
}

-(void)failureTask:(BLEDataTask*) weekSelf withError:(NSError*) error{
    weekSelf.TaskState = DataTaskStateFailure;
    if (weekSelf.successBlock) {
        weekSelf.successBlock(weekSelf,nil,error);
    }
}

@end
