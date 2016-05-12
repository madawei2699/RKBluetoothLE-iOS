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
#import "DefaultRetryPolicy.h"

static  BOOL  LOG_ENABLED = YES;

@interface BLERequest(){
    
    NSInteger mSequence;
    
    BOOL mResponseDelivered;
    
    BOOL mCanceled;

    id<RetryPolicy> mRetryPolicy;
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
        
        _RKBLEpriority = NORMAL;
        mRetryPolicy = [[DefaultRetryPolicy alloc] init];
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

-(BLERequest *)setRetryPolicy:(id<RetryPolicy>)retryPolicy{
    mRetryPolicy = retryPolicy;
    return self;
}

-(void)addMarker:(NSString*)mark{
    if (LOG_ENABLED) {
        NSString *threadMSG = [[NSThread currentThread] description];
//        <NSThread: 0x15697f30>{number = 2, name = RKBLEDispatcher}
    
        NSString *matchedString1 = [threadMSG componentsSeparatedByString:@"{number = "][1];
        NSString *number = [matchedString1 componentsSeparatedByString:@","][0];
        NSString *name = [[matchedString1 componentsSeparatedByString:@","][1] substringFromIndex:8];
        name = [name substringToIndex:name.length - 1];
        
        NSLog(@"BLERequest life cycle:[%4d] tag:%@",number.intValue,mark);
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

-(int) getTimeoutS{
    return [mRetryPolicy getCurrentTimeoutS];
}

-(id<RetryPolicy>)getRetryPolicy{
    return mRetryPolicy;
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
