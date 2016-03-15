//
//  RKBLEUtil.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEUtil.h"

@implementation RKBLEUtil

+(NSDictionary*)createTarget:(NSString*)peripheralName service:(NSString*)service characteristic:(NSString*)characteristic{

    return  @{@"peripheralName":peripheralName ,@"service":service ,@"characteristic":characteristic };
    
}

+(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([UUID.UUIDString isEqualToString:s.UUID.UUIDString])
            return s;
    }
    //Service not found on this peripheral
    return nil;
}

+(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([UUID.UUIDString isEqualToString:c.UUID.UUIDString])
            return c;
    }
    //Characteristic not found on this service
    return nil;
}

@end
