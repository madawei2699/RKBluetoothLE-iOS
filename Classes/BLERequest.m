//
//  Request.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLERequest.h"
#import "RequestQueue.h"
#import "DefaultBLEDataParseProtocol.h"

static  BOOL  LOG_ENABLED = YES;

@interface BLERequest(){
    
    NSInteger mSequence;
    
    BOOL mResponseDelivered;
    
    BOOL mCanceled;

}

@end

@implementation BLERequest

-(instancetype)initWithTarget:(NSDictionary*)target
                             method:(RKBLEMethod) method
                         writeValue:(NSData*)writeValue{

    self = [super init];
    if (self) {
        _peripheralName = target[@"peripheralName"];
        _service = target[@"service"];
        _characteristic = target[@"characteristic"];
        _method = method;
        _writeValue = writeValue;
        
        _dataParseProtocol = [[DefaultBLEDataParseProtocol alloc] init];
        _identifier = [[NSUUID UUID] UUIDString];
    }
    return self;

}

+(void)setLogEnable:(BOOL)enable{
    LOG_ENABLED = enable;
}

+(BOOL)logEnable{
    return LOG_ENABLED;
}

-(BLERequest*)setSequence:(NSInteger)sequence{
    mSequence = sequence;
    return self;
}

-(NSInteger)getSequence{
    return mSequence;
}

-(void)addMarker:(NSString*)mark{
    if (LOG_ENABLED) {
        NSLog(@"BLERequest life cycle:[%d] tag:%@",[[NSThread currentThread] isMainThread],mark);
    }
}

-(void)cancel{
    mCanceled = YES;
}

-(BOOL)isCanceled{
    return mCanceled;
}

-(void)deliverResponse:(id)response{
    if (self.mRequestSuccessBlock) {
        self.mRequestSuccessBlock(response);
    }
}

-(void)deliverError:(NSError*)error{
    if (self.mRequestErrorBlock) {
        self.mRequestErrorBlock(error);
    }
}

-(void)markDelivered{
    mResponseDelivered = YES;
}

-(BOOL)hasHadResponseDelivered{
    return mResponseDelivered;
}

-(void)finish:(NSString*)tag{
    if (self.mRequestQueue) {
        [self.mRequestQueue finish:self];
        [self onFinish];
    }
    [self addMarker:tag];
}

-(void)onFinish{
    self.mRequestSuccessBlock = nil;
    self.mRequestErrorBlock = nil;
    self.effectiveResponse = nil;
}

-(Response*)parseBLEResponse:(BLEResponse*)response{
    
    if (self.parseBLEResponseData) {
        id entity = self.parseBLEResponseData(response.data);
        if ([entity isKindOfClass:[NSError class]]) {
            return [Response error:entity];
        } else {
            return [Response success:entity];
        }
    } else {
        return [Response error:[NSError errorWithDomain:@"BLERequestDomain"
                                                   code:0
                                               userInfo:@{ NSLocalizedDescriptionKey: @"实体对象没有实现parseBLEResponseData block" }]];
    }
    
}

-(void)dealloc{
    if (LOG_ENABLED)
        NSLog(@"~BLERequest:dealloc");
}

@end
