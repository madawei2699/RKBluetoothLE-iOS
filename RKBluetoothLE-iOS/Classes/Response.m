//
//  Response.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/30.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "Response.h"

@implementation Response

-(instancetype)initWithResult:(id)result error:(NSError*)error{
    self = [super init];
    if (self) {
        _result = result;
        _error = error;
    }
    return self;
}

+(Response*)success:(id)value{
    return [[Response alloc] initWithResult:value error:nil];
}

+(Response*)error:(NSError*)error{
    return [[Response alloc] initWithResult:nil error:error];
}

-(BOOL)isSuccess{
    return _error == nil;
}

-(void)dealloc{
    NSLog(@"~Response:dealloc");
}

@end
