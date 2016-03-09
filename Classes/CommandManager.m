//
//  CommandManager.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/9.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "CommandManager.h"


@interface CommandManager ()

@property (nonatomic, strong) NSMutableArray<CCRunLoopContext*> *sources;

@end

@implementation CommandManager

+ (CommandManager *)sharedManager
{
    static CommandManager *sharedManagerInstance = nil;
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

- (void)fireAllCommands{
    
}

@end
