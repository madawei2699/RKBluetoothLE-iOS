//
//  BasicBluetooth.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "BasicBluetooth.h"

@interface BasicBluetooth(){
    

}

@end

@implementation BasicBluetooth


- (id)init{
    //调用父类的初始化方法
    self = [super init];
    
    if(self != nil){
        [BLEStack shareClient].connectProgressBlock = ^(RKBLEConnectState mRKBLEState, NSError * error){
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
        [self performRequest:request success:^(BLERequest* reqest, id responseObject){
            [subscriber sendNext:responseObject];
            [subscriber sendCompleted];
        } failure:^(BLERequest* reqest,NSError* error){
            [subscriber sendError:error];
        }];
        
        return nil;
        
    }];

}

-(void)finish{

    [[BLEStack shareClient] finish];

}

-(void)performRequest:(BLERequest*) request
              success:(void (^)(BLERequest* reqest, id responseObject))success
              failure:(void (^)(BLERequest* reqest, NSError* error))failure{
    
    [request addMarker:@"perform-Request"];
    [BLEStack shareClient].successBlock = success;
    [BLEStack shareClient].failureBlock = failure;
    [[BLEStack shareClient] performRequest:request];
    
}

@end
