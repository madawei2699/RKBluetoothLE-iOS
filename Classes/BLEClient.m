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

- (void)initBLE{
    //初始化BabyBluetooth 蓝牙库
    if(baby == nil){
        baby = [BabyBluetooth shareBabyBluetooth];
        //设置蓝牙委托
        [self babyDelegate];
    }
    if (self.activePeripheral
        &&
        [self.activePeripheral.name isEqualToString:self.bleDataTask.peripheralName]
        &&
        self.activePeripheral.state == CBPeripheralStateConnected) {
        
        //不做处理表示当前需要连接的蓝牙设备已经在连接状态
        
    } else {
        
        //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态
        if (self.activePeripheral) {
            
            baby.having(self.activePeripheral).connectToPeripherals().begin();
            
        } else {
            //2 扫描、连接
            baby.scanForPeripherals().connectToPeripherals().begin().stop(10);

        }
        
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
        [weekSelf execute:weekSelf.bleDataTask];
        
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

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([UUID.UUIDString isEqualToString:s.UUID.UUIDString])
            return s;
    }
    
    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([UUID.UUIDString isEqualToString:c.UUID.UUIDString]) return c;
    }
    
    return nil; //Characteristic not found on this service
}

-(BLEClient*)execute:(BLEDataTask*)_BLEDataTask{
    
    self.bleDataTask = _BLEDataTask;
    [self initBLE];
    
    CBUUID *uuid_service = [CBUUID UUIDWithString:self.bleDataTask.service];
    CBUUID *uuid_char = [CBUUID UUIDWithString:self.bleDataTask.characteristics];
    
    if (self.activePeripheral.state == CBPeripheralStateConnected) {
        
        CBCharacteristic *mCBCharacteristic = [self findCharacteristicFromUUID:uuid_char service:[self findServiceFromUUID:uuid_service p:self.activePeripheral]];
        
    }
    
    
    return self;
    
}



@end
