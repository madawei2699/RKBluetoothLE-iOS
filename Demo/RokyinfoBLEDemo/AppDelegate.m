//
//  AppDelegate.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "AppDelegate.h"
#import "CocoaSecurity.h"
#import "IQKeyboardManager.h"
#import <NSLogger/NSLogger.h>

//    Q1NsmKbbaf+mfktSpyNJ5w==
//    B00G10B6F3

//    uEFmx5HRQ23oH1vy5yKIxw==
//    B00GFT30J4

//    icFqEzLDMAxWBGj/+2QB9w==
//    T0011B00E0

//    M8Cjz3SFrA3R0LAzBB9xGA==
//    B00GDV5DZ3

//    yo4ZfMHGFumRnMsKL0OsRg==
//    B00GFQA6S3

//    M8Cjz3SFrA2XBefwzj/1Ug==
//    B00GDV5DZ3

@interface AppDelegate (){

    RACDisposable *authResultSignalDisposable;

}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [IQKeyboardManager sharedManager].enable = YES;
    
    self.mRkBluetoothClient = [RkBluetoothClient shareClient];
    self.mRK410APIService = [self.mRkBluetoothClient createRk410ApiService];
    self.mUpgradeManager = [[UpgradeManager alloc] initWithAPIService:self.mRK410APIService];
    [self.mRK410APIService setPostAuthCodeBlock:^(NSString *peripheralName){
        CocoaSecurityDecoder *mCocoaSecurityDecoder = [[CocoaSecurityDecoder alloc] init];
        return [mCocoaSecurityDecoder base64:@"Q1NsmKbbaf+mfktSpyNJ5w=="];
    }];
    
    authResultSignalDisposable = [[[self.mRK410APIService authResultSignal] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNotification *response) {
         //鉴权成功
         if(response.userInfo[RKBLEAuthResultStatus]){
             NSLog(@"鉴权成功");
             //更新本地标志位，标示下一次鉴权使用FF鉴权
             
         } else {
             //鉴权失败
             NSLog(@"鉴权失败");
            //更新本地标志位，标示下一次鉴权使用鉴权码鉴权
         }
     }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [authResultSignalDisposable dispose];
}

@end
