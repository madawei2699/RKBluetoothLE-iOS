//
//  VehicleStatus.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/5.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "VehicleStatus.h"


@implementation VehicleStatus

-(id)bytes2entity:(NSData*)data{
    
    VehicleStatus *mElectricCar = self;
    
    Byte dianyaValue[2];
    [data getBytes:&dianyaValue range:NSMakeRange(0, 2)];
    mElectricCar.voltage = [ByteConvert bytesToUshort:dianyaValue] / 100.0f;
    
    Byte dianliu[2];
    [data getBytes:&dianliu range:NSMakeRange(2, 2)];
    mElectricCar.electricCurrent = [ByteConvert bytesToUshort:dianliu] / 100.0f;
    
    Byte wendu[2];
    [data getBytes:&wendu range:NSMakeRange(4, 2)];
    mElectricCar.temperature = [ByteConvert bytesToUshort:wendu];;
    
    Byte sudu[2];
    [data getBytes:&sudu range:NSMakeRange(6, 2)];
    mElectricCar.speed = [ByteConvert bytesToUshort:sudu];
    
    Byte licheng[4];
    [data getBytes:&licheng range:NSMakeRange(8, 4)];
    mElectricCar.totalODO = [ByteConvert bytesToUint:licheng];
    
    if (data.length >= 14) {
        
        Byte statusBUF[2];
        [data getBytes:statusBUF range:NSMakeRange(12, 2)];
        
        int status = [ByteConvert bytesToUshort:statusBUF];
        
        if ([ByteConvert getBitValue:status index:0] == 0 && [ByteConvert getBitValue:status index:1] == 0) {
            mElectricCar.lockStatus = LOCKED;
        } else {
            mElectricCar.lockStatus = UNLOCKED;
        }
        
        if ([ByteConvert getBitValue:status index:2]  == 1) {
            mElectricCar.leftSignal = YES;
        } else {
            mElectricCar.leftSignal = NO;
        }
        if ([ByteConvert getBitValue:status index:3] == 1) {
            mElectricCar.rightSignal = YES;
        } else {
            mElectricCar.rightSignal = NO;
        }
        if ([ByteConvert getBitValue:status index:4] == 1) {
            mElectricCar.rearlightsSignal = YES;
        } else {
            mElectricCar.rearlightsSignal = NO;
        }
        if ([ByteConvert getBitValue:status index:5] == 1) {
            mElectricCar.backlightSignal = YES;
        } else {
            mElectricCar.backlightSignal = NO;
        }
        if ([ByteConvert getBitValue:status index:6] == 1) {
            mElectricCar.highBeam = YES;
        } else {
            mElectricCar.highBeam = NO;
        }
        if ([ByteConvert getBitValue:status index:7] == 1) {
            mElectricCar.lowBean = YES;
        } else {
            mElectricCar.lowBean = NO;
        }
        if ([ByteConvert getBitValue:status index:8] == 1) {
            mElectricCar.horn = YES;
        } else {
            mElectricCar.horn = NO;
        }
        if ([ByteConvert getBitValue:status index:9] == 1) {
            mElectricCar.brakeSignal = YES;
        } else {
            mElectricCar.brakeSignal = NO;
        }
    
        if ([ByteConvert getBitValue:status index:15] == 1) {
            mElectricCar.faultFlag = YES;
        } else {
            mElectricCar.faultFlag = NO;
        }
        
    }
    
    unsigned char statusBytes;
    [data getBytes:&statusBytes range:NSMakeRange(14, 1)];
    mElectricCar.electricPercent = statusBytes;
    
    unsigned char remainderRange;
    [data getBytes:&remainderRange range:NSMakeRange(15, 1)];
    mElectricCar.remainderRange = remainderRange;
    
    return self;
}

-(NSString *)description
{
    return [@{@"voltage":@(_voltage),
              @"temperature":@(_temperature),
              @"electricCurrent":@(_electricCurrent),
              @"speed":@(_speed),
              @"totalODO":@(_totalODO),
              @"lockStatus":@(_lockStatus),
              @"leftSignal":@(_leftSignal),
              @"rightSignal":@(_rightSignal),
              @"rearlightsSignal":@(_rearlightsSignal),
              @"backlightSignal":@(_backlightSignal),
              @"highBeam":@(_highBeam),
              @"lowBean":@(_lowBean),
              @"horn":@(_horn),
              @"brakeSignal":@(_brakeSignal),
              @"faultFlag":@(_faultFlag),
              @"electricPercent":@(_electricPercent),
              @"remainderRange":@(_remainderRange),} description];
    
}

@end
