//
//  RKBLEProtocolManager.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEProtocolManager.h"

@implementation RKBLEProtocolManager


- (nullable RKBLEDataTask *)command:(NSInteger)command
                         parameters:(nullable id)parameters
                            success:(nullable void (^)(RKBLEDataTask *task, id _Nullable responseObject))success
                            failure:(nullable void (^)(RKBLEDataTask * _Nullable task, NSError *error))failure{
    RKBLEDataTask *mRKBLEDataTask = [[RKBLEDataTask alloc] init];
    [mRKBLEDataTask resume];
    return mRKBLEDataTask;
}

@end
