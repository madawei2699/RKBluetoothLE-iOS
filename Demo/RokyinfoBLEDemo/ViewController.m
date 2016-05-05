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
#import "RK410APIService.h"
#import "RkBluetoothClient.h"
@interface ViewController (){
    
    RACDisposable *mRACDisposable ;
    
    RK410APIService* mRK410APIService ;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    mRK410APIService = [[RkBluetoothClient shareClient] createRk410ApiService];
    [mRK410APIService setPostAuthCodeBlock:^(NSString *peripheralName){
        CocoaSecurityDecoder *mCocoaSecurityDecoder = [[CocoaSecurityDecoder alloc] init];
        return [mCocoaSecurityDecoder base64:@"Q1NsmKbbaf9ut47RN6/3Xg=="];
    }];
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
    
    //    RACSignal *scanRACSignal = [[RKBLEClient shareClient].ble scanWitchFilter:^(CBPeripheral *peripheral){
    //        return YES;
    //    }];
    //
    //    mRACDisposable = [[scanRACSignal deliverOnMainThread]
    //                                     subscribeNext:^(CBPeripheral* peripheral) {
    //
    //                                         NSLog(@"----------------:%@",peripheral);
    //                                         [mRACDisposable dispose];
    //
    //
    //                                     }
    //                                     error:^(NSError *error) {
    //
    //                                         NSLog(@"----------------:%@",error);
    //
    //                                     }];
    
    //    RACSignal *mRACSignal = [[RK410APIService shareService] requestUpgrade:@"B00G20B6T3" withFirmware:nil];
    //    [[mRACSignal
    //      deliverOnMainThread]
    //     subscribeNext:^(NSData *response) {
    //
    //         NSLog(@"----------------:%@",response);
    //
    //     }
    //     error:^(NSError *error) {
    //
    //         NSLog(@"----------------:%@",error);
    //
    //     }];
    
    //    Firmware *mFirmware = [[Firmware alloc] init];
    //    mFirmware.version = @"1610.02";
    //    mFirmware.fileSize = 1258291;
    //    mFirmware.singlePackageSize = 1;
    //    mFirmware.singleFrameSize = 20;
    //    mFirmware.isForceUpgradeMode = YES;
    //
    //    RACSignal *mRACSignal = [[RK410APIService shareService] requestUpgrade:@"B00G20B6T3" withFirmware:mFirmware];
    //    [[mRACSignal
    //      deliverOnMainThread]
    //     subscribeNext:^(NSData *response) {
    //
    //         NSLog(@"----------------:%@",response);
    //
    //     }
    //     error:^(NSError *error) {
    //
    //         NSLog(@"----------------:%@",error);
    //
    //     }];
    //
    
    //
    //    mRACSignal = [[RK410APIService shareService] requestEndPackage:@"B00G20B6T3" withPackage:nil];
    //    [[mRACSignal
    //      deliverOnMainThread]
    //     subscribeNext:^(NSData *response) {
    //
    //         NSLog(@"----------------:%@",response);
    //
    //     }
    //     error:^(NSError *error) {
    //
    //         NSLog(@"----------------:%@",error);
    //
    //     }];
    //
    //
    //    mRACSignal = [[RK410APIService shareService] checkFileMD5 :@"B00G20B6T3" withFirmware:mFirmware];
    //    [[mRACSignal
    //      deliverOnMainThread]
    //     subscribeNext:^(NSData *response) {
    //
    //         NSLog(@"----------------:%@",response);
    //
    //     }
    //     error:^(NSError *error) {
    //
    //         NSLog(@"----------------:%@",error);
    //
    //     }];
    
    //    RACSignal *mRACSignal = [mRK410APIService requestUpgrade:@"B00G20B6T3" withFirmware:mFirmware];
    //    [[mRACSignal
    //      deliverOnMainThread]
    //     subscribeNext:^(NSData *response) {
    //
    //         NSLog(@"----------------:%@",response);
    //
    //     }
    //     error:^(NSError *error) {
    //
    //         NSLog(@"----------------:%@",error);
    //
    //     }];
    //
    //    mRACSignal = [mRK410APIService requestStartPackage:@"B00G20B6T3" withPackage:nil];
    //    [[mRACSignal
    //      deliverOnMainThread]
    //     subscribeNext:^(NSData *response) {
    //
    //         NSLog(@"----------------:%@",response);
    //
    //     }
    //     error:^(NSError *error) {
    //
    //         NSLog(@"----------------:%@",error);
    //
    //     }];
    //
    //
    //    for (int i = 1; i < 100; i++) {
    //
    //        RKFrame *mRKFrame = [[RKFrame alloc] init];
    //        Byte bytes[20] = {i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i};
    //        mRKFrame.data = [[NSData alloc] initWithBytes:bytes length:20];
    //
    //        [[[mRK410APIService sendData:@"B00G20B6T3" withFrame:mRKFrame]
    //          deliverOnMainThread]
    //         subscribeNext:^(NSData *response) {
    //
    //             NSLog(@"----------------:%@",response);
    //
    //         }
    //         error:^(NSError *error) {
    //
    //             NSLog(@"----------------:%@",error);
    //
    //         }];
    
    
    //           }
    
    //    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"File"ofType:@"rtf"];
    //    Firmware *mFirmware = [[Firmware alloc] init];
    //    mFirmware.version = @"1610.02";
    //    mFirmware.singlePackageSize = 16;
    //    mFirmware.singleFrameSize = 20;
    //    mFirmware.isForceUpgradeMode = YES;
    //    mFirmware.data =  [[NSData alloc]initWithContentsOfFile:filePath];
    //    mFirmware.fileSize = mFirmware.data.length;
    //    mFirmware.md5 = [CocoaSecurity md5WithData:mFirmware.data].hex;
    //    //获取文件路径
    //
    //    [mRK410APIService activateUpgrade:@"B00G20B6T3" withFirmware:mFirmware];
    
  
    
//    RACSignal *mRACSignal = [mRK410APIService openBox:@"B00G10B6F3"];
//    [[mRACSignal
//      deliverOnMainThread]
//     subscribeNext:^(RemoteControlResult *response) {
//         
//         NSLog(@"----------------:%d",response.success);
//         
//     }
//     error:^(NSError *error) {
//         
//         NSLog(@"----------------:%@",error);
//         
//     }];
    
    RACSignal *mRACSignal = [mRK410APIService getVehicleStatus:@"B00G10B6F3"];
    [[mRACSignal
      deliverOnMainThread]
     subscribeNext:^(VehicleStatus *response) {
         
         NSLog(@"----------------:%@",[response description]);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"----------------:%@",error);
         
     }];
    
    
    
}

@end
