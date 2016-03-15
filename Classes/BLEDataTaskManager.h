//
//  RKBLEProtocolManager.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEDataTask.h"


@interface BLEDataTaskManager : NSObject

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic,copy)RKConnectProgressBlock bleConnectStateBlock;

+ (instancetype)sharedManager;

- (void)resume;

/**
 *  请求外围设备数据
 *
 *  @param target     eg. "peripheralName:service/Characteristics"
 *  @param method     读写标记
 *  @param parameters 写入参数
 *  @param success    成功回调
 *  @param failure    失败回调
 *
 *  @return 蓝牙数据交换任务处理类
 */
- (nullable BLEDataTask*)target:(NSDictionary*)target
                         method:(RKBLEMethod)method
                     parameters:(nullable NSData*)parameters
                        success:(nullable void (^)(BLEDataTask* task, id responseObject,NSError* _Nullable error))success
                        failure:(nullable void (^)(BLEDataTask* task, id _Nullable responseObject,NSError* error))failure;


NS_ASSUME_NONNULL_END


@end
