//
//  CommandManager.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "CCRunLoopContextManager.h"


@interface CCRunLoopContextManager ()

@property (nonatomic, strong) NSMutableArray<CCRunLoopContext*> *sources;

@end

@implementation CCRunLoopContextManager

+ (CCRunLoopContextManager *)sharedManager
{
    static CCRunLoopContextManager *sharedManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedManagerInstance = [[self alloc] init];
    });
    return sharedManagerInstance;
}

- (void)registerSource:(CCRunLoopContext *)sourceContext
{
    if (!self.sources) {
        self.sources = [NSMutableArray array];
    }
    [self.sources addObject:sourceContext];
}

- (void)removeSource:(CCRunLoopContext *)sourceContext
{
    [self.sources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CCRunLoopContext *context = obj;
        if ([context isEqual:sourceContext]) {
            [self.sources removeObject:context];
            *stop = YES;
        }
    }];
}

- (void)addCommand:(NSInteger)command model:(id)data{
    
    CCRunLoopContext *runLoopContext = [self.sources objectAtIndex:0];
    RKRunLoopInputSource *inputSource = runLoopContext.runLoopInputSource;
    [inputSource fireAllCommandsOnRunLoop:runLoopContext.runLoop];
    
}


- (void)fireAllCommands{
    
    CCRunLoopContext *runLoopContext = [self.sources objectAtIndex:0];
    RKRunLoopInputSource *inputSource = runLoopContext.runLoopInputSource;
    [inputSource fireAllCommandsOnRunLoop:runLoopContext.runLoop];
    
}

@end
