//
//  BaseUpgradeResponse.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/12.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BaseUpgradeResponse.h"

@implementation BaseUpgradeResponse

-(id)bytes2entity:(NSData*)data{
    
    unsigned char command;
    [data getBytes:&command range:NSMakeRange(0, 1)];
    self.command = command;
    
    unsigned char result;
    [data getBytes:&result range:NSMakeRange(1, 1)];
    self.result = result;
    
    return self;
}

-(BOOL)isHit:(NSData*)data{
    unsigned char command;
    [data getBytes:&command range:NSMakeRange(0, 1)];
    return command == [self getCommand];
}


-(int)getCommand{
    return -1;
}


@end
