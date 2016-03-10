//
//  RKBLEProtocolManager.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKBLEDataTask.h"

@interface RKBLEProtocolManager : NSObject

NS_ASSUME_NONNULL_BEGIN

- (nullable RKBLEDataTask *)command:(NSInteger)command
                         parameters:(nullable id)parameters
                            success:(nullable void (^)(RKBLEDataTask * task, id _Nullable responseObject))success
                            failure:(nullable void (^)(RKBLEDataTask * _Nullable task, NSError * error))failure;

NS_ASSUME_NONNULL_END


@end
