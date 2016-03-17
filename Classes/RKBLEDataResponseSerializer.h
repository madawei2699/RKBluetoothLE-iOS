//
//  RKBLEDataResponseSerializer.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/17.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BLEDataTask;
@protocol RKBLEDataResponseSerializer <NSObject>

- (nullable id)responseObjectForTask:(BLEDataTask *)task
                                data:(nullable NSData *)data
                               error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END