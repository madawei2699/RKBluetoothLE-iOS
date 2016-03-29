//
//  Request.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RequestQueue;
@interface Request : NSObject

@property(nonatomic,weak) RequestQueue * mRequestQueue;

-(Request*)setSequence:(NSInteger)sequence;
-(void)addMarker:(NSString*)mark;

@end
