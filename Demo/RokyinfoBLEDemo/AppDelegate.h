//
//  AppDelegate.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RkBluetoothClient.h"

#define RK410APIServiceImpl ((AppDelegate*)[[UIApplication sharedApplication] delegate]).mRK410APIService

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) RkBluetoothClient *mRkBluetoothClient;

@property (strong, nonatomic) RK410APIService   *mRK410APIService;

@end

