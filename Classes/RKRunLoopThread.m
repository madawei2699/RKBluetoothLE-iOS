//
//  RKRunLoopThread.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKRunLoopThread.h"
#import "RKRunLoopInputSource.h"

@interface RKRunLoopThread ()

@property (nonatomic, strong) RKRunLoopInputSource *customInputSource;

@end

@implementation RKRunLoopThread
- (void)main
{
    self.name = @"RKRunLoopThread";
    @autoreleasepool {
        NSLog(@"RKRunLoopThread Enter");
        
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        
        self.customInputSource = [[RKRunLoopInputSource alloc] init];
        [self.customInputSource addToCurrentRunLoop];
        
        while (!self.cancelled) {
            NSLog(@"Enter Run Loop");
            
            [self finishOtherTask];
            
            [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            
            NSLog(@"Exit Run Loop");
        }
        
        NSLog(@"RKRunLoopThread Exit");
    }
}

- (void)finishOtherTask
{
    NSLog(@"Begin finishOtherTask");
    NSLog(@"🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹");
    NSLog(@"🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹");
    NSLog(@"End finishOtherTask");
}

@end
