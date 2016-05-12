//
//  RequestPackageRespond.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/12.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseUpgradeResponse.h"

@interface RequestPackageResponse : BaseUpgradeResponse

//原因
@property (assign, nonatomic) Byte reason;

@end
