//
//  BLEDataProtocol.h
//  车精灵
//
//  Created by apple on 15/5/12.
//  Copyright (c) 2015年 无锡锐祺. All rights reserved.
//

#import <Foundation/Foundation.h>

#define  BT_SUCCESS             0
#define  BT_ERROR               1

#define  PARAM_READ             0
#define  PARAM_WRITE            1

#define  Authentication       0x00
#define  Reboot               0x01
#define  CarParameter         0x02
#define  BatteryParameter     0x03
#define  GSensor              0x04
#define  BT2_1                0x05
#define  BT4_0                0x06
#define  Governor             0x07
#define  DebugModel           0x08
#define  DriveConfig          0x09
#define  KeyList              0x0A
#define  AutoLock             0x0D
#define  SYNC_TIME            0x0E
#define  VERSION              0x0F
#define  MILEAGE              0x10
#define  JYFD                 0x11
//RK410 协议版本
#define  RK410_AUTH           0x00
#define  RK410_REBOOT         0x01
#define  RK410_MOTOR          0x02
#define  RK410_BATTERY        0x03
#define  RK410_ECU            0x04
#define  RK410_SYNC_TIME      0x09
#define  RK410_KEY_LIST       0x0C
#define  RK410_GEAR           0x0E
#define  RK410_MILEAGE        0x0F
#define  RK410_ELECTRIC_CU    0x12
#define  RK410_SPEED_CONFIG   0x13
#define  RK410_TURBO          0x14
#define  RK410_ENABLE_SERVICE 0x15
#define  RK410_VERSION        0xF1


//蓝牙遥控器配置
#define  BTKey_CarMac         0x01
#define  BTKey_AuthCode       0x02



@interface BLEDataProtocol : NSObject

@property(nonatomic,assign)NSInteger type;
@property(nonatomic,assign)int index;
@property(nonatomic,assign)int length;
@property(nonatomic,strong)NSData *org;


-(void)decode:(NSData *)data;
-(NSData *)encode;

-(NSData *)encodeRK410;
-(void)decodeRK410:(NSData *)data;

@end
