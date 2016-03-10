//
//  RKBLEClient.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKBLEProtocolManager.h"

@interface RKBLEClient : RKBLEProtocolManager

+ (instancetype)sharedClient;

@end
