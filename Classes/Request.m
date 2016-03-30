//
//  Request.m
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "Request.h"

@interface Request(){
    
    NSInteger mSequence;
    
}

@end

@implementation Request

-(Request*)setSequence:(NSInteger)sequence{
    mSequence = sequence;
    return self;
}

-(NSInteger)getSequence{
    return mSequence;
}

@end
