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
    if (weekSelf.connectProgressBlock) {
        
        weekSelf.connectProgressBlock(weekSelf,nil);
        
    }
    
    if (weekSelf.failureBlock) {
        if ((_BLEState == RKBLEStateDisconnect || _BLEState == RKBLEStateFailure)
            &&
            weekSelf.TaskState != DataTaskStateCompleted) {
            
            self.TaskState = DataTaskStateCompleted;
            
            weekSelf.failureBlock(weekSelf,nil,[NSError errorWithDomain:BLEDataTaskErrorDomain
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
        
        self.TaskState = DataTaskStateCompleted;
        
        if (self.failureBlock) {
            
            self.failureBlock(self,nil,[NSError errorWithDomain:BLEDataTaskErrorDomain
                                                           code:BLEDataTaskErrorTimeOut
                                                       userInfo:@{ NSLocalizedDescriptionKey: @"当前业务处理超时" }]);
            
        }
        
    }
    
}

- (void)connectToPeripheral{
    
    //初始化BabyBluetooth 蓝牙库
    if(baby == nil){
        
        baby = [BabyBluetooth shareBabyBluetooth];
        //设置蓝牙委托
        [self babyDelegate];
        
    }
    
    CBPeripheral *peripheral = [baby findConnectedPeripheral:self.peripheralName];
    
    if (peripheral.state == CBPeripheralStateConnected) {
        
        if ([peripheral.name isEqualToString:self.peripheralName]) {
            //不做处理表示当前需要连接的蓝牙设备已经在连接状态
        } else {
            
            [baby cancelScan];
            [baby cancelAllPeripheralsConnection];
            baby.scanForPeripherals().connectToPeripherals().discoverServices().discoverCharacteristics().begin();
            
            self.BLEState = RKBLEStateScanning;
            
        }
        
    } else {
        
        if (peripheral && [peripheral.name isEqualToString:self.peripheralName]) {
            
            [baby cancelScan];
            baby.having(peripheral).connectToPeripherals().discoverServices().discoverCharacteristics().begin();
            
            self.BLEState = RKBLEStateConnecting;
            
        } else {
            
            [baby cancelScan];
            [baby cancelAllPeripheralsConnection];
            baby.scanForPeripherals().connectToPeripherals().discoverServices().discoverCharacteristics().begin();
            
            self.BLEState = RKBLEStateScanning;
            
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
    
    //示例：
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"设备打开成功，开始扫描设备");
            weekSelf.BLEState = RKBLEStateScanning;
            
        } else {
            
            weekSelf.BLEState = RKBLEStateFailure;
            
        }
        
    }];
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        NSLog(@"设备：%@--连接成功",peripheral.name);
        weekSelf.BLEState = RKBLEStateConnected;
        
    }];
    
    //设置设备连接失败的委托
    [baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
        weekSelf.BLEState = RKBLEStateFailure;
    }];
    
    //设置设备断开连接的委托
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
        weekSelf.BLEState = RKBLEStateDisconnect;
    }];
    
    //设置写数据成功的block
    [baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        
        NSLog(@"setBlockOnDidWriteValueForCharacteristic characteristic:%@ and new value:%@",characteristic.UUID, characteristic.value);
        
    }];
    
    //设置获取到最新Characteristics值的block
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error){
        
        //读取值回调
        [weekSelf parseResponseDataWithCharacteristic:characteristic];
        
    }];
    
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        
        if (peripheral) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                NSLog(@"==========service name:%@ ,characteristic name:%@",service.UUID,characteristic.UUID);
                if (characteristic.properties & CBCharacteristicPropertyNotify) {
                    NSLog(@"CBCharacteristicPropertyNotify:%@",characteristic.UUID);
                    [weekSelf setNotify:peripheral characteristic:characteristic];
                }
            }
            //执行任务
            [weekSelf executeWithPeripheral:peripheral];
        }
        
    }];
    
}

-(void)setNotify:(CBPeripheral *)peripheral characteristic:(CBCharacteristic*)characteristic {
    
    __weak BLEDataTask *weekSelf = self;
    [baby notify:peripheral
  characteristic:characteristic
           block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
               //接收到值会进入这个方法
               NSLog(@"new value %@",characteristics.value);
               [weekSelf parseResponseDataWithCharacteristic:characteristics];
               
           }];
    
}



-(void)executeWithPeripheral:(CBPeripheral*) peripheral{
    
    __weak BLEDataTask *weekSelf = self;
    
    if (weekSelf.TaskState != DataTaskStateCompleted && peripheral.state == CBPeripheralStateConnected) {
        
        CBUUID *uuid_service = [CBUUID UUIDWithString:weekSelf.service];
        CBUUID *uuid_char = [CBUUID UUIDWithString:weekSelf.characteristic];
        
        CBCharacteristic *mCBCharacteristic = [RKBLEUtil findCharacteristicFromUUID:uuid_char service:[RKBLEUtil findServiceFromUUID:uuid_service p:peripheral]];
        
        if (weekSelf.method == RKBLEMethodRead) {
            
            [peripheral readValueForCharacteristic:mCBCharacteristic];
            
        } else if (weekSelf.method == RKBLEMethodWrite){
            
            NSAssert(weekSelf.writeValue == nil, @"写方法下，写入数据不能为空");
            [peripheral writeValue:weekSelf.writeValue forCharacteristic:mCBCharacteristic type:CBCharacteristicWriteWithResponse];
            
        }
        
    }
}


-(void)parseResponseDataWithCharacteristic:(CBCharacteristic *)characteristic{
    
    __weak BLEDataTask *weekSelf = self;
    
    //注入了数据协议处理类则使用注入的协议类进行判断处理
    if (weekSelf.dataParseProtocol) {
        
        if ([weekSelf.dataParseProtocol effectiveResponse:weekSelf characteristic: characteristic.UUID.UUIDString]) {
            
            weekSelf.TaskState = DataTaskStateCompleted;
            //任务处理成功结束回调
            if (weekSelf.successBlock) {
                weekSelf.successBlock(weekSelf,characteristic.value,nil);
            }
            
        }
        
    } else {
        
        weekSelf.TaskState = DataTaskStateCompleted;
        
        //任务处理成功结束回调
        if (weekSelf.successBlock) {
            weekSelf.successBlock(weekSelf,characteristic.value,nil);
        }
    }
    
}

@end
