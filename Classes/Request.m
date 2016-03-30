//
//  Request.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "Request.h"
#import "RequestQueue.h"

static BOOL LOG_ENABLED = NO;

@interface Request(){
    
    NSInteger mSequence;
    
    BOOL mResponseDelivered;
    
    BOOL mCanceled;
}

@end

@implementation Request

+(void)setLogEnable:(BOOL)enable{
    LOG_ENABLED = enable;
}

-(Request*)setSequence:(NSInteger)sequence{
    mSequence = sequence;
    return self;
}

-(NSInteger)getSequence{
    return mSequence;
}

-(void)addMarker:(NSString*)mark{
    if (LOG_ENABLED) {
        NSLog(@"tag:%@ NSThread:%@",mark,[NSThread currentThread]);
    }
}

-(void)markDelivered{
    mResponseDelivered = YES;
}

-(BOOL)hasHadResponseDelivered{
    return mResponseDelivered;
}

-(void)deliverResponse:(id)response{
    if (self.mRequestSuccessBlock) {
        self.mRequestSuccessBlock(response);
    }
}

-(BOOL)isCanceled{
    return mCanceled;
}

-(void)finish:(NSString*)tag{
    if (self.mRequestQueue) {
        [self.mRequestQueue finish:self];
        [self onFinish];
    }
    if (LOG_ENABLED) {
        NSLog(@"tag:%@ NSThread:%@ finish",tag,[NSThread currentThread]);
    }
}

-(void)onFinish{
    self.mRequestSuccessBlock = nil;
    self.mRequestErrorBlock = nil;
}

-(Response*)parseNetworkResponse:(BLEResponse*)response{
    
    return nil;
}

@end
