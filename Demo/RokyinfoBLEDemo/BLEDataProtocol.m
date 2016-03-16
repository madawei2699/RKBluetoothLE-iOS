//
//  BLEDataProtocol.m
//  车精灵
//
//  Created by apple on 15/5/12.
//  Copyright (c) 2015年 无锡锐祺. All rights reserved.
//

#import "BLEDataProtocol.h"

@implementation BLEDataProtocol

-(void)decode:(NSData *)data{
    
    if(data.length < 2){
        return;
    }
    
    unsigned char tempType;
    [data getBytes:&tempType range:NSMakeRange(0,1)];
    
    unsigned char tempIndex;
    [data getBytes:&tempIndex range:NSMakeRange(1,1)];
    
    self.type = tempType;
    self.index = tempIndex;
    
    if ((data.length-2) > 0) {
        unsigned char *buffer = malloc((data.length-2) * sizeof(unsigned char));
        [data getBytes:buffer range:NSMakeRange(2,data.length-2)];
        self.org = [[NSData alloc] initWithBytes:buffer length:data.length-2];
        free(buffer);
    }
    
}

-(NSData *)encode {
    
    Byte byte[] = {self.type,self.index};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:byte length:2];
    [data appendData:_org];
    return data;
    
}

-(NSData *)encodeRK410 {
    
    Byte byte[] = {self.type,self.index ,_org.length};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:byte length:3];
    [data appendData:_org];
    return data;
    
}

-(void)decodeRK410:(NSData *)data{
    
    if(data.length < 3){
        return;
    }
    
    unsigned char tempType;
    [data getBytes:&tempType range:NSMakeRange(0,1)];
    
    unsigned char tempIndex;
    [data getBytes:&tempIndex range:NSMakeRange(1,1)];
    
    unsigned char tempLength;
    [data getBytes:&tempLength range:NSMakeRange(2,1)];
    
    self.type = tempType;
    self.index = tempIndex;
    self.length = tempLength;
    
    if ((data.length - 3) > 0) {
        unsigned char *buffer = malloc((data.length - 3) * sizeof(unsigned char));
        [data getBytes:buffer range:NSMakeRange(3,data.length - 3)];
        self.org = [[NSData alloc] initWithBytes:buffer length:data.length - 3];
        free(buffer);
    }
    
}

@end
