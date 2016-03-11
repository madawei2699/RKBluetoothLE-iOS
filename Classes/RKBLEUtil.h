//
//  RKBLEUtil.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKBLEUtil : NSObject

+ (NSDictionary*) createTarget:(NSString*)peripheralName service:(NSString*)service characteristics:(NSString*)characteristics;

@end
