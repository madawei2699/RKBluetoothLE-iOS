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

    RequestQueue *mRequestQueue;

}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    BLEDataProtocol *mBLEDataProtocol = [[BLEDataProtocol alloc] init];
//    mBLEDataProtocol.type = PARAM_WRITE;
//    mBLEDataProtocol.index = 0x30;
//    
//    Byte byte[] = {0x00,0,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff};
//    NSData *org = [NSData dataWithBytes:byte length:17];
//    
//    mBLEDataProtocol.org = org;
//
//    Request *mRequest = [[Request alloc] initWithReponseClass:nil target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"] method:RKBLEMethodWrite writeValue:[mBLEDataProtocol encodeRK410]];
//    mRequest.dataParseProtocol = [[RK410BluetoothProtocol alloc] init];
//    
//    mRequest.mRequestSuccessBlock = ^(id response){
//        NSLog(@"%@",@"mRequestSuccessBlock");
//    };
//    
//    mRequest.mRequestErrorBlock = ^(NSError * error){
//        NSLog(@"mRequestErrorBlock:%@",error);
//    };
//    mRequestQueue = [[RKBLEClient shareClient] ];
//    [mRequestQueue add:mRequest];
//    
//    mRequest = [[Request alloc] initWithReponseClass:nil target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"] method:RKBLEMethodWrite writeValue:[mBLEDataProtocol encodeRK410]];
//    mRequest.dataParseProtocol = [[RK410BluetoothProtocol alloc] init];
//    
//    [mRequestQueue add:mRequest];
//    
//    mRequest = [[Request alloc] initWithReponseClass:nil target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"] method:RKBLEMethodWrite writeValue:[mBLEDataProtocol encodeRK410]];
//    mRequest.dataParseProtocol = [[RK410BluetoothProtocol alloc] init];
//    
//    [mRequestQueue add:mRequest];
//    
//    mRequest = [[Request alloc] initWithReponseClass:nil target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"] method:RKBLEMethodWrite writeValue:[mBLEDataProtocol encodeRK410]];
//    mRequest.dataParseProtocol = [[RK410BluetoothProtocol alloc] init];
//    
//    [mRequestQueue add:mRequest];
    
    RACSignal *mRACSignal = [RK410APIService lock:@"B00G10B6F3"];
    [[mRACSignal
      subscribeOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x) {
         
         NSLog(@"subscribeNext:%@",x);
      
     }
     error:^(NSError *error) {
         
         NSLog(@"%@",error);
         
     }];
    
    RACSignal *mRACSignal1 = [RK410APIService lock:@"B00G10B6F3"];
    [[mRACSignal1
      subscribeOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x) {
         
         NSLog(@"subscribeNext:%@",x);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"%@",error);
         
     }];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
