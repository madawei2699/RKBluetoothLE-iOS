//
//  main.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <NSLogger/NSLogger.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
        
//        LoggerSetViewerHost(NULL, (CFStringRef)@"192.168.16.103", (UInt32)50000);
//        LoggerStart(LoggerGetDefaultLogger());
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
