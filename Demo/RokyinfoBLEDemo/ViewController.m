//
//  ViewController.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "ViewController.h"
#import "CocoaSecurity.h"
#import "BLEDataProtocol.h"
#import "RKBLEUtil.h"
#import "RKBLEClient.h"
#import "RK410APIService.h"
@interface ViewController (){

    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RACSignal *mRACSignal = [[RK410APIService shareService] lock:@"B00G10B6F3"];
    [[mRACSignal
      subscribeOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x) {
         
         NSLog(@"----------------:%@",x);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"----------------:%@",error);
         
     }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
