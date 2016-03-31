//
//  RokyinfoBLEDemoTests.m
//  RokyinfoBLEDemoTests
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CocoaSecurity.h"
#import "BLEDataProtocol.h"
#import "RKBLEClient.h"

@interface RokyinfoBLEDemoTests : XCTestCase

@end

@implementation RokyinfoBLEDemoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    
//    BLEDataProtocol *mBLEDataProtocol = [[BLEDataProtocol alloc] init];
//    mBLEDataProtocol.type = PARAM_WRITE;
//    mBLEDataProtocol.index = 0x30;
//    
//    Byte byte[] = {0x00,0,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff};
//    NSData *org = [NSData dataWithBytes:byte length:17];
//    
//    mBLEDataProtocol.org = org;
//    [[RKBLEClient sharedClient] target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"]
//                                method:RKBLEMethodWrite
//                            parameters:[mBLEDataProtocol encodeRK410]
//                               success:nil
//                               failure:nil];
//    
//    [[RKBLEClient sharedClient] target:[RKBLEUtil createTarget:@"B00G10B6F3" service:@"9900" characteristic:@"9904"]
//                                method:RKBLEMethodWrite
//                            parameters:[mBLEDataProtocol encodeRK410]
//                               success:nil
//                               failure:nil];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
