//
//  Firmware.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/3.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "Firmware.h"

@implementation Firmware

-(BOOL)isEqual:(Firmware*)object{
    if ([object isKindOfClass:[Firmware class]]) {
        if ([self.ueSn isEqualToString:object.ueSn]
            && [self.version isEqualToString:object.version]
            && [self.md5 isEqualToString:object.md5]
            && self.fileSize == object.fileSize
            && self.singlePackageSize == object.singlePackageSize
            && self.singleFrameSize == object.singleFrameSize
            && self.isForceUpgradeMode == object.isForceUpgradeMode) {
            return YES;
        }else{
            return NO;
        }
    }
    return [super isEqual:object];
}

@end
