//
//  RequestQueue.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bluetooth.h"
#import "Request.h"

@protocol RequestFilter<NSObject>

-(BOOL)apply:(Request*)request;

@end

@interface RequestFilterImpl : NSObject<RequestFilter>

@property (nonatomic,strong) id tag;

@end

@interface RequestQueue : NSObject

-(id)initWithBluetooth:(id<Bluetooth>)_Bluetooth;

-(Request*)add:(Request*)request;

-(void)start;

-(void)stop;

-(void)finish:(Request*)Request;

-(void)cancelAll;

-(void)cancelAllWithFilter:(id<RequestFilter>) filter;

-(void)cancelAllWithTag:(id) tag;

@end
