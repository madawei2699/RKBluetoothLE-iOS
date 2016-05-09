//
//  DefaultRetryPolicy.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/4/8.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "DefaultRetryPolicy.h"


/** The default socket timeout in seconds */
static const  float DEFAULT_TIMEOUT_S  = 3.0f;


static const  float DEFAULT_DELAY_TIME = 0.100f;

/** The default number of retries */
static const int DEFAULT_MAX_RETRIES   = 0;


@interface DefaultRetryPolicy (){

    /** The current timeout in seconds. */
    float mCurrentTimeoutS;
    
    float mDelayTime;
    
    /** The current retry count. */
    int mCurrentRetryCount;
    
    /** The maximum number of attempts. */
    int mMaxNumRetries;

}

@end

@implementation DefaultRetryPolicy

-(id)init{
    return [self initWithTimeout:DEFAULT_TIMEOUT_S delayTime:DEFAULT_DELAY_TIME maxRetries:DEFAULT_MAX_RETRIES];
}

-(id)initWithTimeout:(float)timeout delayTime:(float)delayTime maxRetries:(int)maxRetries{
    self = [super init];
    if (self) {
        mCurrentTimeoutS = timeout;
        mDelayTime = delayTime;
        mMaxNumRetries = maxRetries;
    }
    return self;
}

/**
 *  超时时间
 *
 *  @return
 */
-(float)getCurrentTimeoutS{
    return mCurrentTimeoutS;
}

/**
 *  两条指令请求的间隔时间
 *
 *  @return 间隔时间
 */
-(float)getDelayTime{
    return mDelayTime;
}

/**
 *  超时重试次数
 *
 *  @return
 */
-(int)getCurrentRetryCount{
    return mCurrentRetryCount;
}

/**
 *  重试
 *
 *  @return
 */
-(NSError*)retry:(NSError*)error{
    mCurrentRetryCount++;
    if (![self hasAttemptRemaining]) {
        return error;
    } else {
        return nil;
    }
}

-(BOOL)hasAttemptRemaining{
    return mCurrentRetryCount <= mMaxNumRetries;
}

@end
