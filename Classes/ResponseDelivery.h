//
//  ResponseDelivery.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Request.h"
#import "Runnable.h"

@protocol ResponseDelivery <NSObject>

/**
 * Parses a response from the network or cache and delivers it.
 */
-(void)postResponse:(Request*) request response:(id) response;

/**
 * Parses a response from the network or cache and delivers it. The provided
 * Runnable will be executed after delivery.
 */
-(void)postResponse:(Request*) request response:(id) response runnable:(id<Runnable>) runnable;

/**
 * Posts an error for the given request.
 */
-(void)postError:(Request*) request error:(NSError*) error;

@end