//
//  RKBLEUtil.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEUtil.h"

@implementation RKBLEUtil

+(NSDictionary*)createTarget:(NSString*)peripheralName service:(NSString*)service characteristics:(NSString*)characteristics{

    return  @{@"peripheralName":peripheralName ,@"service":service ,@"characteristics":characteristics };
    
}

@end
