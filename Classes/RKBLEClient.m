//
//  RKBLE.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEClient.h"
#import "RequestQueue.h"



@interface RKBLEClient(){
    
    NSMutableArray<BLERequest*> *mCurrentRequests;
    
}

@property (nonatomic,strong) RequestQueue *mRequestQueue;

@end

@implementation RKBLEClient

+(instancetype)shareClient{
    static RKBLEClient *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[RKBLEClient alloc]init];
    });
    return share;
}

-(instancetype)init{
    
    self = [super init];
    if (self) {
        mCurrentRequests = [[NSMutableArray alloc] init];
        _ble = [BLEStack shareClient];
        _mRequestQueue = [[RequestQueue alloc] initWithBluetooth:_ble];
        [_mRequestQueue start];
    }
    return self;
}

-(void)performRequest:(BLERequest*) request
              success:(void (^)(id responseObject))success
              failure:(void (^)(NSError* error))failure{
    
    request.mRequestSuccessBlock = success;
    request.mRequestErrorBlock = failure;
    [self.mRequestQueue add:request];
    
    [mCurrentRequests removeObject:request];
}

-(RACSignal*)performRequest:(BLERequest*) request{
    
    [mCurrentRequests addObject:request];
    
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        
        @strongify(self)
        [self performRequest:request
                     success:^( id responseObject){
                         
                         [subscriber sendNext:responseObject];
                         [subscriber sendCompleted];
                     }
                     failure:^( NSError *error){
                         [subscriber sendError:error];
                     }];
        
        return [RACDisposable disposableWithBlock:^{
            [mCurrentRequests removeObject:request];
        }];
        
    }];
    
}

@end
