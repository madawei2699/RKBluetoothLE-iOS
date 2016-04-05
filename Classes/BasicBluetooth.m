//
//  BasicBluetooth.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BasicBluetooth.h"


@interface BasicBluetooth(){
    
    BLEStack *mBLEStack;
    
}

@end

@implementation BasicBluetooth


- (id)init{
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        mBLEStack = [[BLEStack alloc] init];
        mBLEStack.connectProgressBlock = ^(RKBLEConnectState mRKBLEState, NSError * error){
            //蓝牙连接回调
        };
    }
    
    return self;
}

- (RACSignal*) performRequest:(BLERequest*) request{
    
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        [[NSThread currentThread] setName:@"BasicBluetooth"];
        @strongify(self)
        [self performRequest:request success:^(BLERequest* reqest, id responseObject,NSError* error){
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(BLERequest* reqest, id responseObject,NSError* error){
            [subscriber sendError:error];
        }];
        
        return nil;
        
    }];

}

-(void)performRequest:(BLERequest*) request
              success:(void (^)(BLERequest* reqest, id responseObject,NSError* error))success
              failure:(void (^)(BLERequest* reqest, id responseObject,NSError* error))failure{
    
    mBLEStack.successBlock = success;
    mBLEStack.failureBlock = failure;
    [request addMarker:@"perform-Request"];
    [mBLEStack performRequest:request];
    
}

@end
