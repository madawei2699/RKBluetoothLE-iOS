//
//  Fault.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/5.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "Fault.h"

@implementation Fault

-(id)bytes2entity:(NSData*)data{
    
    //电机控制器/电机类 2
    //Bit 0-MOS故障  1：故障，0：无故障
    //Bit 1-运放故障  1：故障，0：无故障
    //Bit 2-缺相故障  1：故障，0：无故障
    //Bit 3-霍尔故障  1：故障，0：无故障
    //BIT4:堵转故障  1：故障，0：无故障
    //BIT5:总线故障  1：故障，0：无故障
    //BIT6:短路故障  1：故障，0：无故障
    //BIT7:过流故障  1：故障，0：无故障
    Byte dianji[2];
    [data getBytes:&dianji range:NSMakeRange(0, 2)];
    int kongzhiqi_dianji = [ByteConvert bytesToUshort:dianji];
    
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:0]  == 1) {
        self.MOS = YES;
    } else {
        self.MOS = NO;
    }
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:1]  == 1) {
        self.OPAMP = YES;
    } else {
        self.OPAMP = NO;
    }
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:2]  == 1) {
        self.phase = YES;
    } else {
        self.phase = NO;
    }
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:3]  == 1) {
        self.hall = YES;
    } else {
        self.hall = NO;
    }
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:4]  == 1) {
        self.lockRotor = YES;
    } else {
        self.lockRotor = NO;
    }
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:5]  == 1) {
        self.bus = YES;
    } else {
        self.bus = NO;
    }
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:6]  == 1) {
        self.shortCircuit = YES;
    } else {
        self.shortCircuit = NO;
    }
    if ([ByteConvert getBitValue:kongzhiqi_dianji index:7]  == 1) {
        self.overcurrent = YES;
    } else {
        self.overcurrent = NO;
    }
    
    
    //中控类
    //BIT0: 保留
    //BIT1：保留，电机参数未配置（不作为故障上报）
    //BIT2：EDR故障
    //BIT3：BLE故障
    //BIT4：GSENSOR故障
    
    unsigned char zhongkong;
    [data getBytes:&zhongkong range:NSMakeRange(2, 1)];
    if ([ByteConvert getBitValue:zhongkong index:2]  == 1) {
        self.EDR = YES;
    } else {
        self.EDR = NO;
    }
    if ([ByteConvert getBitValue:zhongkong index:3]  == 1) {
        self.BLE = YES;
    } else {
        self.BLE = NO;
    }
    if ([ByteConvert getBitValue:zhongkong index:4]  == 1) {
        self.gSensor = YES;
    } else {
        self.gSensor = NO;
    }
    
    //外设故障
    //BIT0：转把故障
    //BIT1：刹把故障
    //BIT2：电池电压过低
    unsigned char waishe;
    [data getBytes:&waishe range:NSMakeRange(3, 1)];
    if ([ByteConvert getBitValue:waishe index:0]  == 1) {
        self.rollingHandle = YES;
    } else {
        self.rollingHandle = NO;
    }
    if ([ByteConvert getBitValue:waishe index:1]  == 1) {
        self.brakeHandle = YES;
    } else {
        self.brakeHandle = NO;
    }
    if ([ByteConvert getBitValue:waishe index:2]  == 1) {
        self.voltage = YES;
    } else {
        self.voltage = NO;
    }
    
    //通讯故障
    //BIT0：接收误码
    //BIT1：发送无回应(ECU无响应)
    //BIT2：外接遥控器无回应
    //BIT3：GPS设备无响应
    unsigned char tongxu;
    [data getBytes:&tongxu range:NSMakeRange(4, 1)];
    if ([ByteConvert getBitValue:tongxu index:0]  == 1) {
        self.errorCode = YES;
    } else {
        self.errorCode = NO;
    }
    if ([ByteConvert getBitValue:tongxu index:1]  == 1) {
        self.nonResponseECU = YES;
    } else {
        self.nonResponseECU = NO;
    }
    if ([ByteConvert getBitValue:tongxu index:2]  == 1) {
        self.nonResponseRC = YES;
    } else {
        self.nonResponseRC = NO;
    }
    if ([ByteConvert getBitValue:tongxu index:3]  == 1) {
        self.nonResponseGPS = YES;
    } else {
        self.nonResponseGPS = NO;
    }
    
    //其他故障
    //左右转向按键同时按下会上报此故障
    unsigned char qita;
    [data getBytes:&qita range:NSMakeRange(5, 1)];
    if ([ByteConvert getBitValue:qita index:0]  == 1) {
        self.pressDown_L_R = YES;
    } else {
        self.pressDown_L_R = NO;
    }
    
    return self;
}

-(NSString *)description
{
    return [@{@"MOS":@(_MOS),
              @"OPAMP":@(_OPAMP),
              @"phase":@(_phase),
              @"hall":@(_hall),
              @"lockRotor":@(_lockRotor),
              @"bus":@(_bus),
              @"shortCircuit":@(_shortCircuit),
              @"overcurrent":@(_overcurrent),
              @"EDR":@(_EDR),
              @"BLE":@(_BLE),
              @"gSensor":@(_gSensor),
              @"rollingHandle":@(_rollingHandle),
              @"brakeHandle":@(_brakeHandle),
              @"voltage":@(_voltage),
              @"errorCode":@(_errorCode),
              @"nonResponseECU":@(_nonResponseECU),
              @"nonResponseRC":@(_nonResponseRC),
              @"nonResponseGPS":@(_nonResponseGPS),
              @"pressDown_L_R":@(_pressDown_L_R),} description];
    
}

@end
