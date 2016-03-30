//
//  BasicBluetooth.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bluetooth.h"
#import "BLEStack.h"

@interface BasicBluetooth : NSObject<Bluetooth>

@property (nonatomic,copy  )RKConnectProgressBlock bleConnectStateBlock;

@end
