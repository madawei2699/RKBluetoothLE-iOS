//
//  RKBLEProtocolManager.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKBLEProgress.h"



@interface RKBLEProtocolManager : NSObject

NS_ASSUME_NONNULL_BEGIN

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
//- (nullable RKBLEDataTask *)target:(NSDictionary*)target
//                            method:(RKBLEMethod)method
//                        parameters:(nullable NSData*)parameters
//                    connectProgress:(nullable void (^)(RKBLEProgress * connectProgress)) connectProgress
//                           success:(nullable void (^)(RKBLEDataTask * task, id _Nullable responseObject))success
//                           failure:(nullable void (^)(RKBLEDataTask * _Nullable task, NSError * error))failure;

NS_ASSUME_NONNULL_END


@end
