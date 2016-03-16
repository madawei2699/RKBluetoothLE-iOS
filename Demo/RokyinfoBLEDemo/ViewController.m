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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//
    CocoaSecurityDecoder *mCocoaSecurityDecoder = [[CocoaSecurityDecoder alloc] init];
    NSData *authCode = [mCocoaSecurityDecoder base64:@"M8Cjz3SFrA3ylNHkE734Vg=="];
    // Do any additional setup after loading the view, typically from a nib.
    [[BLEDataTaskManager sharedManager] target:[RKBLEUtil createTarget:@"B00GDV5DZ3" service:@"9900" characteristic:@"9901"]
                                        method:RKBLEMethodWrite
                                    parameters:authCode
                                       success:nil
                                       failure:nil];
    NSLog(@"currentThread:%@",[NSThread currentThread]);
    
        [NSThread sleepForTimeInterval:5];
    
    for (int i = 0; i < 1000 ;i++) {
        
        BLEDataProtocol *mBLEDataProtocol = [[BLEDataProtocol alloc] init];
        mBLEDataProtocol.type = PARAM_WRITE;
        mBLEDataProtocol.index = 0x30;
        
        Byte byte[] = {0x00,i,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff};
        NSData *org = [NSData dataWithBytes:byte length:17];
        
        mBLEDataProtocol.org = org;
    
//        [NSThread sleepForTimeInterval:0.050];
        
        [[BLEDataTaskManager sharedManager] target:[RKBLEUtil createTarget:@"B00GDV5DZ3" service:@"9900" characteristic:@"9904"]
                                            method:RKBLEMethodWrite
                                        parameters:[mBLEDataProtocol encodeRK410]
                                           success:nil
                                           failure:nil];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
