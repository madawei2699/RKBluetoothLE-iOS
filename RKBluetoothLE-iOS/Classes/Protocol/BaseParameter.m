//
//  BaseParameter.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BaseParameter.h"

@implementation BaseParameter

-(NSData*)entity2bytes{
    
    Byte byte[] = {self.method,self.command ,_org.length};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:byte length:3];
    [data appendData:_org];
    return data;
    
}


-(id)bytes2entity:(NSData*)data{
    
    if(data.length < 3){
        return nil;
    }
    
    unsigned char tempType;
    [data getBytes:&tempType range:NSMakeRange(0,1)];
    
    unsigned char tempIndex;
    [data getBytes:&tempIndex range:NSMakeRange(1,1)];
    
    unsigned char tempLength;
    [data getBytes:&tempLength range:NSMakeRange(2,1)];
    
    self.method = tempType;
    self.command = tempIndex;
    self.length = tempLength;
    
    if ((data.length - 3) > 0) {
        unsigned char *buffer = malloc((data.length - 3) * sizeof(unsigned char));
        [data getBytes:buffer range:NSMakeRange(3,data.length - 3)];
        self.org = [[NSData alloc] initWithBytes:buffer length:data.length - 3];
        free(buffer);
    }
    
    return self;
}

-(NSData*)createQueryCommand{
    return nil;
}

@end
