//
//  RK410BluetoothProtocol.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/18.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Request.h"

//---------------------------服务------------------------------------------
// 车精灵服务
#define  SERVICE_SPIRIT_SYNC_DATA   @"9900"
// 蓝牙遥控器服务
#define  SERVICE_BT_KEY_CONFIG      @"9800"

//---------------------------特征------------------------------------------
//    鉴权码	SPIRIT_AUTH_CODE	0x9901	Write	16 BYTES(待验证的鉴权值）
#define SPIRIT_AUTH_CODE            @"9901"

//    同步数据	SPIRIT_SYNCDATA	0x9902	Read	14BYTES,参考：“机车电控车况参数”
#define SPIRIT_SYNCDATA             @"9902"

//    故障查询/上报	SPIRIT_FAULTDATA	0x9903	Read/Notify	6 bytes,参考 “机车故障参数”
#define SPIRIT_FAULTDATA            @"9903"

//    参数设置/查询	SPIRIT_WRT_PARAM	0x9904	Write	参考“BLE参数设置”
//#define SPIRIT_WRT_PARAM            @"9907"
#define SPIRIT_WRT_PARAM            @"9904"

//    参数设置结果查询	SPIRIT_PARAM_RST	0x9905	Read/Notify	对于WRT_PARAM的结果进行反馈
#define SPIRIT_PARAM_RST            @"9905"

//    钥匙控制	SPIRIT_KEYFUNC	0x9906	Write	参考4.6 “钥匙功能”
#define SPIRIT_KEYFUNC              @"9906"

//    模拟按键	SPIRIT_KEYPRESS	0x9907	Write	模拟按键
//#define SPIRIT_KEYPRESS             @"9907"

//    配一配设置
#define SPIRIT_SET_PARAM            @"9801"

#define RBL_BLE_FRAMEWORK_VER       0x0200


@interface RK410BluetoothProtocol : NSObject<BLEDataParseProtocol>




@end
