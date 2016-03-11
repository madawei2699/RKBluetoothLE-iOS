//
//  RKBLEProtocolManager.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEProtocolManager.h"
#import "RKRunLoopThread.h"
#import "RKBLEUtil.h"

@interface RKBLEProtocolManager(){

    RKRunLoopThread *mRKRunLoopThread;

}



@end

@implementation RKBLEProtocolManager


- (void)initRunLoopThread{
    if (mRKRunLoopThread == nil) {
        mRKRunLoopThread = [[RKRunLoopThread alloc] init];
        [mRKRunLoopThread start];
    }
}

//- (nullable RKBLEDataTask *)target:(NSDictionary*)target
//                            method:(RKBLEMethod)method
//                        parameters:(nullable NSData*)parameters
//                   connectProgress:(nullable void (^)(RKBLEProgress * connectProgress)) connectProgress
//                           success:(nullable void (^)(RKBLEDataTask * task, id _Nullable responseObject))success
//                           failure:(nullable void (^)(RKBLEDataTask * _Nullable task, NSError * error))failure{
//
//    [self initRunLoopThread];
//
//    BLEClient *mRKBLEDataTask = [[BLEClient alloc] initWithPeripheralName:target[@"peripheralName"]];
//    
//
//
//
//    return mRKBLEDataTask;
//}


@end
