//
//  RKBLEClient.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/10.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBLEClient.h"

@implementation RKBLEClient

+ (instancetype)sharedClient {
    static RKBLEClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[RKBLEClient alloc] init];
    });
    
    return _sharedClient;
}
@end