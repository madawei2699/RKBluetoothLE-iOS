//
//  BleLog.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/13.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BleLog.h"

static BOOL LOG_ENABLED = NO;
@implementation BleLog


+(void)addMarker:(NSString*)mark{
    
    if(LOG_ENABLED){
        
        NSString *threadMSG = [[NSThread currentThread] description];
        //        <NSThread: 0x15697f30>{number = 2, name = RKBLEDispatcher}
        
        NSString *matchedString1 = [threadMSG componentsSeparatedByString:@"{number = "][1];
        NSString *number = [matchedString1 componentsSeparatedByString:@","][0];
        NSString *name = [[matchedString1 componentsSeparatedByString:@","][1] substringFromIndex:8];
        name = [name substringToIndex:name.length - 1];
        
        NSLog(@"%@:[%4d] tag:%@",[[NSString stringWithUTF8String:__FILE__] lastPathComponent],number.intValue,mark);
    }
    
}

@end
