//
//  RKBLEProgress.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface RKBLEProgress : NSObject

@property (nonatomic,assign) CBCentralManagerState state;

@end
