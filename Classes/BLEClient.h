//
//  RKBLEDataTask.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BabyBluetooth/BabyBluetooth.h>
#import "BLEDataTask.h"


@interface BLEClient : NSObject

@property (nonatomic,strong) CBPeripheral *activePeripheral;

-(BLEClient*)execute:(BLEDataTask*)_BLEDataTask;

@end
