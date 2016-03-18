//
//  ViewController.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "ViewController.h"
#import "BLEDataTaskManager.h"
#import "CocoaSecurity.h"
#import "BLEDataProtocol.h"
#import "RKBLEClient.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    CocoaSecurityDecoder *mCocoaSecurityDecoder = [[CocoaSecurityDecoder alloc] init];
//    NSData *authCode = [mCocoaSecurityDecoder base64:@"Q1NsmKbbaf9ut47RN6/3Xg=="];
//    [[RKBLEClient sharedClient] target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9901"]
//                                        method:RKBLEMethodWrite
//                                    parameters:authCode
//                                       success:nil
//                                       failure:nil];
//
//    
//    [NSThread sleepForTimeInterval:5];
//    
//    for (int i = 0; i < 100 ;i++) {
//        
//        BLEDataProtocol *mBLEDataProtocol = [[BLEDataProtocol alloc] init];
//        mBLEDataProtocol.type = PARAM_WRITE;
//        mBLEDataProtocol.index = 0x30;
//        
//        Byte byte[] = {0x00,i,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff};
//        NSData *org = [NSData dataWithBytes:byte length:17];
//        
//        mBLEDataProtocol.org = org;
//    
//        [[BLEDataTaskManager sharedManager] target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"]
//                                            method:RKBLEMethodWrite
//                                        parameters:[mBLEDataProtocol encodeRK410]
//                                           success:nil
//                                           failure:nil];
//        
//    }
//    
    
            BLEDataProtocol *mBLEDataProtocol = [[BLEDataProtocol alloc] init];
            mBLEDataProtocol.type = PARAM_WRITE;
            mBLEDataProtocol.index = 0x30;
    
            Byte byte[] = {0x00,0,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff};
            NSData *org = [NSData dataWithBytes:byte length:17];
    
            mBLEDataProtocol.org = org;
    [[RKBLEClient sharedClient] target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"]
                                                 method:RKBLEMethodWrite
                                             parameters:[mBLEDataProtocol encodeRK410]
                                                success:nil
                                                failure:nil];
    
    [[RKBLEClient sharedClient] target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"]
                                method:RKBLEMethodWrite
                            parameters:[mBLEDataProtocol encodeRK410]
                               success:nil
                               failure:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
