//
//  Request.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BLERequest.h"
#import "RequestQueue.h"

static  BOOL  LOG_ENABLED = YES;

@interface BLERequest(){
    
    NSInteger mSequence;
    
    BOOL mResponseDelivered;
    
    BOOL mCanceled;
    
    Class reponseEntityClass;
}

@end

@implementation BLERequest

-(instancetype)initWithReponseClass:(Class)reponseClass
                             target:(NSDictionary*)target
                             method:(RKBLEMethod) method
                         writeValue:(NSData*)writeValue{

    self = [super init];
    if (self) {
        reponseEntityClass = reponseClass;
        _peripheralName = target[@"peripheralName"];
        _service = target[@"service"];
        _characteristic = target[@"characteristic"];
        _method = method;
        _writeValue = writeValue;
        
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

-(Response*)parseNetworkResponse:(BLEResponse*)response{
    
    id target = [[reponseEntityClass alloc] init];
    SEL action = @selector(byteToEntity:);
    
    if (target == nil) {
        
        return [Response error:[NSError errorWithDomain:@"BLERequestDomain"
                                                   code:0
                                               userInfo:@{ NSLocalizedDescriptionKey: @"实体对象创建失败" }]];
    }
    
    if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [Response success:[target performSelector:action withObject:response.data]];
#pragma clang diagnostic pop
    }
    
    return [Response error:[NSError errorWithDomain:@"BLERequestDomain"
                                               code:0
                                           userInfo:@{ NSLocalizedDescriptionKey: @"实体对象没有实现BLEDataEntityProtocol协议" }]];
}

-(void)dealloc{
    if (LOG_ENABLED)
        NSLog(@"~BLERequest:dealloc");
}

@end
