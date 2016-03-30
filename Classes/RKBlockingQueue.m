//
//  RKBlockingQueue.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/30.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "RKBlockingQueue.h"

@interface RKBlockingQueue() {
    
    NSMutableArray* array;
    
}

@end

@implementation RKBlockingQueue

-(id)init
{
    if ( (self = [super init]) ) {
        array = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(id)dequeue
{
    if ([array count] > 0) {
        id object = [self peek];
        [array removeObjectAtIndex:0];
        return object;
    }
    
    return nil;
}

-(void)enqueue:(id)element
{
    [array addObject:element];
}

-(void)enqueueElementsFromArray:(NSArray*)arr
{
    [array addObjectsFromArray:arr];
}

-(id)peek
{
    if ([array count] > 0)
        return [array objectAtIndex:0];
    
    return nil;
}

-(NSInteger)size
{
    return [array count];
}

-(BOOL)isEmpty
{
    return [array count] == 0;
}

-(void)clear
{
    [array removeAllObjects];
}

-(void)add:(id)obj{
    
    [self enqueue:obj];
    if (obj == [self peek] && self.sem) {
        //如果是第一个元素则发出信号通知线程运行
        dispatch_semaphore_signal(self.sem);
    }
}

-(id)take{
    id obj = [self dequeue];
    if (obj == nil && self.sem) {
        dispatch_semaphore_wait(self.sem, DISPATCH_TIME_FOREVER);
    }
    return obj;
}


@end
