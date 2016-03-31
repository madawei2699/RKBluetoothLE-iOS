//
//  Request.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "Request.h"
#import "RequestQueue.h"

static BOOL LOG_ENABLED = YES;

@interface Request(){
    
    NSInteger mSequence;
    
    BOOL mResponseDelivered;
    
    BOOL mCanceled;
    
    Class reponseEntityClass;
}

@end

@implementation Request

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

-(Request*)setSequence:(NSInteger)sequence{
    mSequence = sequence;
    return self;
}

-(NSInteger)getSequence{
    return mSequence;
}

-(void)addMarker:(NSString*)mark{
    if (LOG_ENABLED) {
        NSLog(@"tag:%@ %@",mark,[NSThread currentThread]);
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
    if (LOG_ENABLED) {
        NSLog(@"tag:%@ %@ finish",tag,[NSThread currentThread]);
    }
}

-(void)onFinish{
    self.mRequestSuccessBlock = nil;
    self.mRequestErrorBlock = nil;
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
        NSLog(@"Request:dealloc");
}

@end
