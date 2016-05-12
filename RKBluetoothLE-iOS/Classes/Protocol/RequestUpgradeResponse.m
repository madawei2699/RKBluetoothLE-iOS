//
//  RequestUpgradeResponse.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/12.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RequestUpgradeResponse.h"

@implementation RequestUpgradeResponse

-(id)bytes2entity:(NSData*)data{
    
    [super bytes2entity:data];
    
    Byte downloadedLength[4];
    [data getBytes:&downloadedLength range:NSMakeRange(4, 4)];
    self.downloadedLength = [ByteConvert bytesToUint:downloadedLength];
    
    return self;
}

-(int)getCommand{
    return 0x08;
}

@end
