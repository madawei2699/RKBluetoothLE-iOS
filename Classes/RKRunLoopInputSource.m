//
//  RKRunLoopInputSource.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKRunLoopInputSource.h"
#import "CCRunLoopContextManager.h"

@interface RKRunLoopInputSource ()
{
    CFRunLoopSourceRef _runLoopSource;
    NSMutableArray *_commands;
}

@end

/* Run Loop Source Context的三个回调方法 */

// 当把当前的Run Loop Source添加到Run Loop中时，会回调这个方法。主线程管理该Input source，所以使用performSelectorOnMainThread通知主线程。主线程和当前线程的通信使用CCRunLoopContext对象来完成。
void runLoopSourceScheduleRoutine (void *info, CFRunLoopRef runLoopRef, CFStringRef mode)
{
    RKRunLoopInputSource *runLoopInputSource = (__bridge RKRunLoopInputSource *)info;
    CCRunLoopContext *runLoopContext = [[CCRunLoopContext alloc] initWithSource:runLoopInputSource runLoop:runLoopRef];
    [[CCRunLoopContextManager sharedManager] registerSource:runLoopContext];
    
}

// 当前Input source被告知需要处理事件的回调方法
void runLoopSourcePerformRoutine (void *info)
{
    RKRunLoopInputSource *runLoopInputSource = (__bridge RKRunLoopInputSource *)info;
    [runLoopInputSource inputSourceFired];
}

// 如果使用CFRunLoopSourceInvalidate函数把输入源从Run Loop里面移除的话,系统会回调该方法。我们在该方法中移除了主线程对当前Input source context的引用。
void runLoopSourceCancelRoutine (void *info, CFRunLoopRef runLoopRef, CFStringRef mode)
{
    RKRunLoopInputSource *runLoopInputSource = (__bridge RKRunLoopInputSource *)info;
    CCRunLoopContext *runLoopContext = [[CCRunLoopContext alloc] initWithSource:runLoopInputSource runLoop:runLoopRef];
    [[CCRunLoopContextManager sharedManager] removeSource:runLoopContext];
}

@implementation RKRunLoopInputSource

#pragma mark - Public

- (instancetype)init
{
    self = [super init];
    if (self) {
        CFRunLoopSourceContext context = {0, (__bridge void *)(self), NULL, NULL, NULL, NULL, NULL,
            &runLoopSourceScheduleRoutine,
            &runLoopSourceCancelRoutine,
            &runLoopSourcePerformRoutine};
        
        _runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
        
        _commands = [NSMutableArray array];
    }
    return self;
}

- (void)addToCurrentRunLoop
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, _runLoopSource, kCFRunLoopDefaultMode);
}

- (void)invalidate
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopRemoveSource(runLoop, _runLoopSource, kCFRunLoopDefaultMode);
}

- (void)inputSourceFired
{
    NSLog(@"Enter inputSourceFired");
    
    //取出数据进行处理
    
    
    NSLog(@"Exit inputSourceFired");
}

- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runLoop
{
    NSLog(@"Current Thread: %@", [NSThread currentThread]);
    
    CFRunLoopSourceSignal(_runLoopSource);
    CFRunLoopWakeUp(runLoop);
}

@end

@implementation CCRunLoopContext


- (instancetype)initWithSource:(RKRunLoopInputSource *)runLoopInputSource runLoop:(CFRunLoopRef)runLoop
{
    self = [super init];
    if (self) {
        _runLoopInputSource = runLoopInputSource;
        _runLoop = runLoop;
    }
    return self;
}

@end


