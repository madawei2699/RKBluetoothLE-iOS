//
//  UpgradeManager.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/4.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "RK410APIService.h"
#import "UpgradeProgress.h"

@interface UpgradeManager : NSObject

-(instancetype)initWithAPIService:(RK410APIService*) mRK410APIService;

/**
 *  升级
 *
 *  @param mFirmware
 *
 *  @return 
 */
-(RACSignal*)upgradeFirmware:(Firmware*)mFirmware;

@end
