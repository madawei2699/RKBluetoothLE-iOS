//
//  RKBLEDataTask.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//


#import "BLEClient.h"

#import "RKBLEProgress.h"

@interface BLEClient(){

    //定义变量
    BabyBluetooth *baby;

}

@property (nonatomic,strong) BLEDataTask *bleDataTask;

@end

@implementation BLEClient

+ (instancetype)sharedClient {
    static BLEClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BLEClient alloc] init];
    });
    
    return _sharedClient;
}

- (void)connectToPeripheral{
    //初始化BabyBluetooth 蓝牙库
    if(baby == nil){
        baby = [BabyBluetooth shareBabyBluetooth];
        //设置蓝牙委托
        [self babyDelegate];
    }
    if (self.activePeripheral.state == CBPeripheralStateConnected) {
        
        if ([self.activePeripheral.name isEqualToString:self.bleDataTask.peripheralName]) {
           //不做处理表示当前需要连接的蓝牙设备已经在连接状态
        } else {
            [baby cancelAllPeripheralsConnection];
            //2 扫描、连接
            baby.scanForPeripherals().connectToPeripherals().begin().stop(5);
        }
        
    } else {
        
        [baby cancelAllPeripheralsConnection];
        //2 扫描、连接
        baby.scanForPeripherals().connectToPeripherals().begin().stop(5);
        
    }
    
}

//设置蓝牙委托
-(void)babyDelegate{
    
    __weak BLEClient *weekSelf = self;
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
    }];
    
    //过滤器
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName) {
        //设置查找规则是名称大于1 ， the search rule is peripheral.name length > 1
        if (self.bleDataTask.peripheralName.length > 0) {
            if (peripheralName.length >= 1 && [peripheralName isEqualToString:self.bleDataTask.peripheralName]) {
                return YES;
            }
        }
        return NO;
    }];
    
    //示例：
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"设备打开成功，开始扫描设备");
        }
        
    }];
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        NSLog(@"设备：%@--连接成功",peripheral.name);
        weekSelf.activePeripheral = peripheral;
        [self setNotify];
        [weekSelf execute:weekSelf.bleDataTask];
        
    }];
    
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"===service name:%@",service.UUID);
        if (peripheral) {
            
        }
    }];
    
    //设置获取到最新Characteristics值的block
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error){
        
        
        
    }];
    
    //设置写数据成功的block
    [baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        
        NSLog(@"setBlockOnDidWriteValueForCharacteristic characteristic:%@ and new value:%@",characteristic.UUID, characteristic.value);
        
    }];
    
    //设置设备连接失败的委托
    [baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
    }];
    
    //设置设备断开连接的委托
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
    }];

}

-(void)setNotify:(CBCharacteristic *)characteristic{

    //self.peripheral是一个CBPeripheral实例,self.characteristic是一个CBCharacteristic实例
    [baby notify:self.activePeripheral
  characteristic:characteristic
           block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
               //接收到值会进入这个方法
               NSLog(@"new value %@",characteristics.value);
               
               
           }];

}

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([UUID.UUIDString isEqualToString:s.UUID.UUIDString])
            return s;
    }
    //Service not found on this peripheral
    return nil;
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([UUID.UUIDString isEqualToString:c.UUID.UUIDString]) return c;
    }
    //Characteristic not found on this service
    return nil;
}

-(BLEClient*)execute:(BLEDataTask*)_BLEDataTask{
    
    self.bleDataTask = _BLEDataTask;
    
    [self connectToPeripheral];
    
    if (self.activePeripheral.state == CBPeripheralStateConnected) {
        
        CBUUID *uuid_service = [CBUUID UUIDWithString:self.bleDataTask.service];
        CBUUID *uuid_char = [CBUUID UUIDWithString:self.bleDataTask.characteristics];
        
        CBCharacteristic *mCBCharacteristic = [self findCharacteristicFromUUID:uuid_char service:[self findServiceFromUUID:uuid_service p:self.activePeripheral]];
        
        if (self.bleDataTask.method == RKBLEMethodRead) {
            
            [self.activePeripheral readValueForCharacteristic:mCBCharacteristic];
            
        } else if (self.bleDataTask.method == RKBLEMethodWrite){
            
            NSAssert(self.bleDataTask.data == nil, @"写方法下，写入数据不能为空");
            [self.activePeripheral writeValue:self.bleDataTask.data forCharacteristic:mCBCharacteristic type:CBCharacteristicWriteWithResponse];
            
        }
        
        
    }
    
    
    return self;
    
}



@end
