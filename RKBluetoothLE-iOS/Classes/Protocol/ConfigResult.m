//
//  ConfigResult.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "ConfigResult.h"

@implementation ConfigResult

-(id)bytes2entity:(NSData*)data{
    
    data = ((ConfigResult*)[super bytes2entity:data]).org;
    
    if (data.length >= 1) {
        unsigned char success;
        [data getBytes:&success range:NSMakeRange(0, 1)];
        self.success = !success;
    }
    
    return self;
    
}

@end
