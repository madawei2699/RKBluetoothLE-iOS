//
//  FinishPackageResponse.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/12.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "FinishPackageResponse.h"

@implementation FinishPackageResponse

-(id)bytes2entity:(NSData*)data{
    
    [super bytes2entity:data];
    
    unsigned char reason;
    [data getBytes:&reason range:NSMakeRange(2, 1)];
    self.reason = reason;
    
    return self;
}

-(int)getCommand{
    return 0x03;
}

@end
