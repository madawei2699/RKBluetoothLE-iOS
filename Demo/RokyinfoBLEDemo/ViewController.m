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
    
    RACDisposable *mRACDisposable ;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RACSignal *mRACSignal = [[RK410APIService shareService] openBox:@"B00G10B6F3"];
    [[mRACSignal
      deliverOnMainThread]
     subscribeNext:^(KeyEventResponse *response) {
         
         NSLog(@"----------------:%d",response.success);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"----------------:%@",error);
         
     }];
    RACSignal *bleConnectSignal = [[RKBLEClient shareClient].ble bleConnectSignal];
    
    RACDisposable *mRACDisposable = [[bleConnectSignal
      subscribeOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x) {
         
         NSLog(@"----------------:%@",x);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"----------------:%@",error);
         
     }];
    [mRACDisposable dispose];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onClick:(id)sender{
    
//    RACSignal *mRACSignal = [[RK410APIService shareService] lock:@"B00G10B6F3"];
//    [[mRACSignal
//      subscribeOn:[RACScheduler mainThreadScheduler]]
//     subscribeNext:^(id x) {
//         
//         NSLog(@"----------------:%@",x);
//         
//     }
//     error:^(NSError *error) {
//         
//         NSLog(@"----------------:%@",error);
//         
//     }];
    
    RACSignal *scanRACSignal = [[RKBLEClient shareClient].ble scanWitchFilter:^(CBPeripheral *peripheral){
        return YES;
    }];
    
    mRACDisposable = [[scanRACSignal deliverOnMainThread]
                                     subscribeNext:^(id x) {
                                         
                                         NSLog(@"----------------:%@",x);
                                         [mRACDisposable dispose];
                                         
                                         
                                     }
                                     error:^(NSError *error) {
                                         
                                         NSLog(@"----------------:%@",error);
                                         
                                     }];
    
    
}

@end
