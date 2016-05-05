//
//  RokyinfoBLEDemoTests.m
//  RokyinfoBLEDemoTests
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CocoaSecurity.h"
#import "RkBluetoothClient.h"
@interface RokyinfoBLEDemoTests : XCTestCase{
    RK410APIService* mRK410APIService;
}

@end

@implementation RokyinfoBLEDemoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
     mRK410APIService = [[RkBluetoothClient shareClient] createRk410ApiService];
    [mRK410APIService setPostAuthCodeBlock:^(NSString *peripheralName){
        CocoaSecurityDecoder *mCocoaSecurityDecoder = [[CocoaSecurityDecoder alloc] init];
        return [mCocoaSecurityDecoder base64:@"Q1NsmKbbaf9ut47RN6/3Xg=="];
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    RACSignal *mRACSignal = [mRK410APIService getVehicleStatus:@"B00G10B6F3"];
    [[mRACSignal
      deliverOnMainThread]
     subscribeNext:^(VehicleStatus *response) {
         
         NSLog(@"subscribeNext:%@",[response description]);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"error:%@",error);
         
     }];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
