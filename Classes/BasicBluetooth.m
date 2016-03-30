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


- (RACSignal*) performRequest:(Request*) request{
    
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
    
        @strongify(self)
//        [self requestAccessToAccountsWithType:self.twitterAccountType
//                                                   options:nil
//                                                completion:^(BOOL granted, NSError *error) {
//                                                    // 4 - handle the response
//                                                    if (!granted) {
//                                                        [subscriber sendError:accessError];
//                                                    } else { 
//                                                        [subscriber sendNext:nil]; 
//                                                        [subscriber sendCompleted]; 
//                                                    } 
//                                                }]; 
        return nil;
    }];
    
    return nil;
}

@end
