//
//  RKBLE.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RequestQueue.h"
#import "BLEStack.h"

@interface RKBLEClient : NSObject

+(instancetype)shareClient;

-(instancetype)init;

-(RACSignal*) performRequest:(BLERequest*) request;

-(RACSignal*) bleConnectSignal;

- (void)closeBLE;

@end
