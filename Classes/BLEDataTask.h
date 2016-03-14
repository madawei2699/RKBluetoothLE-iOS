//
//  BLEDataTask.h
//  RokyinfoBLEDemo
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RKBLEMethod) {
    
    RKBLEMethodRead             = 0,
    RKBLEMethodWrite            = 1,
    
};

typedef NS_ENUM(NSInteger, RKBLEDataTaskState) {
    
    RKBLEDataTaskStateRunning   = 0,
    RKBLEDataTaskStateSuspended = 1,
    RKBLEDataTaskStateCanceling = 2,
    RKBLEDataTaskStateCompleted = 3,
    
};

@interface BLEDataTask : NSObject

@property (nonatomic,copy    ) NSString           *taskIdentifier;

@property (nonatomic,assign  ) RKBLEMethod        method;

@property (nonatomic,assign  ) RKBLEDataTaskState state;

@property (nonatomic,copy    ) NSString           *service;

@property (nonatomic,copy    ) NSString           *characteristics;

@property (nonatomic,copy    ) NSString           *peripheralName;

@property (nonatomic,strong  ) NSData             *data;

@end
