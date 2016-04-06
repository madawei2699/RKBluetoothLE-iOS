//
//  RKBLE.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEClient.h"


NSString * const RKBLEConnectNotification    = @"RKBLEConnectNotification";

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
        //创建蓝牙处理模块类
        BLEStack *mBLEStack = [BLEStack shareClient];
        mBLEStack.connectProgressBlock = ^(RKBLEConnectState mRKBLEState,CBCentralManagerState mCMState, NSError * error){
            [[NSNotificationCenter defaultCenter] postNotificationName:RKBLEConnectNotification object:nil userInfo:error ?@{@"RKBLEConnectState":@(mRKBLEState),@"CBCentralManagerState":@(mCMState),@"NSError" : error} : @{@"RKBLEConnectState":@(mRKBLEState),@"CBCentralManagerState":@(mCMState)}
             ];
        };
        
        _mRequestQueue =  [[RequestQueue alloc] initWithBluetooth:mBLEStack];
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
        
        return nil;
        
    }];
    
}

-(RACSignal*) bleConnectSignal{
    return [[NSNotificationCenter defaultCenter] rac_addObserverForName:RKBLEConnectNotification object:nil];
}

-(void)closeBLE{
    [[BLEStack shareClient] closeBLE];
}

@end
