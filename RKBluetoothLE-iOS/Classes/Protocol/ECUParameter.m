//
//  ECUParameter.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "ECUParameter.h"
#import <CocoaSecurity/CocoaSecurity.h>

@implementation ECUParameter

-(NSData*)entity2bytes{
    
    self.method = PARAM_WRITE;
    self.command = RK410_ECU;
    
    Byte colorfulLightValue[3];
    
    [[[ByteConvert intToBytes:self.colorfulLight] subdataWithRange:NSMakeRange(1, 3)] getBytes:colorfulLightValue length:3];
    
    Byte data[] = {
        self.gSensor,
        self.alarmType,
        self.LCD_DisplayType,
        self.gearsSwitchType,
        self.autoSafety,
        self.lockType,
        self.speedLimitSwitch,
        self.defaultPwmSpeedLimit,
        self.hornVolume,
        self.childLock,
        self.screenCode,
        self.remoteControllerSupport,
        self.backlightEffect,
        colorfulLightValue[0],
        colorfulLightValue[1],
        colorfulLightValue[2],
        self.autoCloseLight};
    
    super.org = [[NSData alloc] initWithBytes:data length:sizeof(data)];
    
    return [super entity2bytes];
}


-(id)bytes2entity:(NSData*)data{
    
    data = ((BaseParameter*)[super bytes2entity:data]).org;
    
    if (data.length >= 1) {
        unsigned char gSensor;
        [data getBytes:&gSensor range:NSMakeRange(0, 1)];
        self.gSensor = gSensor;
    }
    
    if (data.length >= 2) {
        unsigned char alarmType;
        [data getBytes:&alarmType range:NSMakeRange(1, 1)];
        self.gSensor = alarmType;
    }
    
    if (data.length >= 3) {
        unsigned char LCD_DisplayType;
        [data getBytes:&LCD_DisplayType range:NSMakeRange(2, 1)];
        self.LCD_DisplayType = LCD_DisplayType;
    }
    
    if (data.length >= 4) {
        unsigned char gearsSwitchType;
        [data getBytes:&gearsSwitchType range:NSMakeRange(3, 1)];
        self.gearsSwitchType = gearsSwitchType;
    }
    
    if (data.length >= 5) {
        unsigned char autoSafety;
        [data getBytes:&autoSafety range:NSMakeRange(4, 1)];
        self.autoSafety = autoSafety;
    }
    
    if (data.length >= 6) {
        unsigned char lockType;
        [data getBytes:&lockType range:NSMakeRange(5, 1)];
        self.lockType = lockType;
    }
    
    if (data.length >= 7) {
        unsigned char speedLimitSwitch;
        [data getBytes:&speedLimitSwitch range:NSMakeRange(6, 1)];
        self.speedLimitSwitch = speedLimitSwitch;
    }
    
    if (data.length >= 8) {
        unsigned char defaultPwmSpeedLimit;
        [data getBytes:&defaultPwmSpeedLimit range:NSMakeRange(7, 1)];
        self.defaultPwmSpeedLimit = defaultPwmSpeedLimit;
    }
    
    if (data.length >= 9) {
        unsigned char hornVolume;
        [data getBytes:&hornVolume range:NSMakeRange(8, 1)];
        self.hornVolume = hornVolume;
    }
    
    if (data.length >= 10) {
        unsigned char childLock;
        [data getBytes:&childLock range:NSMakeRange(9, 1)];
        self.childLock = childLock;
    }
    
    if (data.length >= 11) {
        unsigned char screenCode;
        [data getBytes:&screenCode range:NSMakeRange(10, 1)];
        self.screenCode = screenCode;
    }
    
    if (data.length >= 12) {
        unsigned char remoteControllerSupport;
        [data getBytes:&remoteControllerSupport range:NSMakeRange(11, 1)];
        self.remoteControllerSupport = remoteControllerSupport;
    }
    
    if (data.length >= 13) {
        unsigned char backlightEffect;
        [data getBytes:&backlightEffect range:NSMakeRange(12, 1)];
        self.backlightEffect = backlightEffect;
    }
    
    if (data.length >= 16) {
        Byte colorfulLightValue[3];
        [data getBytes:colorfulLightValue range:NSMakeRange(13, 3)];
        Byte finalColorfulLightValue[] = {0,colorfulLightValue[0],colorfulLightValue[1],colorfulLightValue[2]};
        self.colorfulLight = [ByteConvert bytesToUint: finalColorfulLightValue];
    }
    
    
    if (data.length >= 17) {
        unsigned char autoCloseLight;
        [data getBytes:&autoCloseLight range:NSMakeRange(16, 1)];
        self.autoCloseLight = autoCloseLight;
    }
    
    return self;
}

-(NSData*)createQueryCommand{
    
    self.method = PARAM_READ;
    self.command = RK410_ECU;
    self.org = [[NSData alloc] init];
    return [super entity2bytes];
    
}

+(ECUParameter*)createDefault{
    ECUParameter *mECUParameter = [[ECUParameter alloc] init];
    mECUParameter.gSensor                 = 1;
    mECUParameter.alarmType               = 1;
    mECUParameter.LCD_DisplayType         = 0;
    mECUParameter.gearsSwitchType         = 0;
    mECUParameter.autoSafety              = 2;
    mECUParameter.lockType                = 1;
    mECUParameter.speedLimitSwitch        = 0;
    mECUParameter.defaultPwmSpeedLimit    = 50;
    mECUParameter.hornVolume              = 1;
    mECUParameter.childLock               = 1;
    mECUParameter.screenCode              = 0;
    mECUParameter.remoteControllerSupport = 1;
    mECUParameter.backlightEffect         = 0;
    mECUParameter.colorfulLight           = 0;
    mECUParameter.autoCloseLight          = 0;
    return mECUParameter;
}

-(NSString *)description
{
    return [@{@"gSensor":@(_gSensor),
              @"alarmType":@(_alarmType),
              @"LCD_DisplayType":@(_LCD_DisplayType),
              @"gearsSwitchType":@(_gearsSwitchType),
              @"autoSafety":@(_autoSafety),
              @"lockType":@(_lockType),
              @"speedLimitSwitch":@(_speedLimitSwitch),
              @"defaultPwmSpeedLimit":@(_defaultPwmSpeedLimit),
              @"hornVolume":@(_hornVolume),
              @"childLock":@(_childLock),
              @"screenCode":@(_screenCode),
              @"remoteControllerSupport":@(_remoteControllerSupport),
              @"backlightEffect":@(_backlightEffect),
              @"colorfulLight":[[CocoaSecurityEncoder alloc] hex:[ByteConvert intToBytes:self.colorfulLight] useLower:NO],
              @"autoCloseLight":@(_autoCloseLight),} description];
}

@end
