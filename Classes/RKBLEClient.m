//
//  RKBLE.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEClient.h"
#import "BasicBluetooth.h"
#import "RequestQueue.h"


@interface RKBLEClient()

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

-(id)init{

    self = [super init];
    if (self) {
        //创建蓝牙处理模块类
        BasicBluetooth *mBasicBluetooth = [[BasicBluetooth alloc] init];
        _mRequestQueue =  [[RequestQueue alloc] initWithBluetooth:mBasicBluetooth];
        [_mRequestQueue start];
    }
    return self;
}

-(void)performRequest:(Request*) request
                success:(void (^)( id responseObject))success
                failure:(void (^)(NSError* error))failure{
    request.mRequestSuccessBlock = success;
    request.mRequestErrorBlock = failure;
    [self.mRequestQueue add:request];
}

-(RACSignal*)performRequest:(Request*) request{
    
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
        
        return nil;
    }];
    
}



@end