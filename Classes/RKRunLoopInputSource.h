//
//  RKRunLoopInputSource.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKRunLoopInputSource : NSObject

// 初始化和销毁
- (instancetype)init;
- (void)addToCurrentRunLoop;
- (void)invalidate;

// 处理事件
- (void)inputSourceFired;

- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runLoop;

@end

// 容器类，用来保存和传递数据
@interface CCRunLoopContext : NSObject

@property (nonatomic, readonly) CFRunLoopRef         runLoop;
@property (nonatomic, readonly) RKRunLoopInputSource *runLoopInputSource;

- (instancetype)initWithSource:(RKRunLoopInputSource *)runLoopInputSource runLoop:(CFRunLoopRef)runLoop;

@end
