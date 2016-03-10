//
//  CommandManager.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRunLoopInputSource.h"

@interface CommandManager : NSObject

+ (CommandManager *)sharedManager;

- (void)registerSource:(CCRunLoopContext *)sourceContext;

- (void)removeSource:(CCRunLoopContext *)sourceContext;

// 其他线程注册事件
- (void)addCommand:(NSInteger) command model:(id) data;

- (void)fireAllCommands;

@end
