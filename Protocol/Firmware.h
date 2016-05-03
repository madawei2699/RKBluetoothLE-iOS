//
//  Firmware.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/3.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Firmware : NSObject

@property (nonatomic,copy  ) NSString  *version;

@property (nonatomic,assign) NSInteger fileSize;

@property (nonatomic,assign) Byte      singlePackageSize;

@property (nonatomic,assign) NSInteger singleFrameSize;

@property (nonatomic,assign) BOOL      isForceUpgradeMode;

@property (nonatomic,copy  ) NSString  *md5;

@end
