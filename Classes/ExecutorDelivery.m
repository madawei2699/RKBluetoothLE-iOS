//
//  ExecutorDelivery.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "ExecutorDelivery.h"

@implementation ExecutorDelivery

-(void)postResponse:(Request*) request response:(Response*) response{
    [self postResponse:request response:response  runnable:nil];
}

-(void)postResponse:(Request*) request response:(Response*) response runnable:(id<Runnable>) runnable{
  
    [request markDelivered];
    [request addMarker:@"post-response"];
    
    // If this request has canceled, finish it and don't deliver.
    if ([request isCanceled]) {
        [request finish:@"canceled-at-delivery"];
        return;
    }
    // Deliver a normal response or error, depending.
    if ([response isSuccess]) {
        [request deliverResponse:response.result];
    } else {
        [request deliverError:response.error];
    }
    
    [request finish:@"done"];
    // If we have been provided a post-delivery runnable, run it.
    if (runnable) {
        [runnable run];
    }
    
}

-(void)postError:(Request*) request error:(NSError*) error{
    
    [self postResponse:request response:[Response error:error]  runnable:nil];
    
}

@end
