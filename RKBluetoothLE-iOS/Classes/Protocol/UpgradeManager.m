//
//  UpgradeManager.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/4.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "UpgradeManager.h"
#import "RKPackage.h"
#import "crc8_16.h"

static dispatch_queue_t  queue;

@interface UpgradeManager(){
    
    RACSubject *mRACSubject;
    
}



@end

@implementation UpgradeManager

-(instancetype)init{
    
    self = [super init];
    if (self) {
        
        if (queue == nil) {
            queue = dispatch_queue_create("com.rokyinfo.UpgradeManager", NULL);
        }
        mRACSubject = [RACSubject subject];
        
    }
    return self;
}

-(RACSignal*)upgradeTarget:(NSString*)target  withAPIService:(RK410APIService*) mRK410APIService andFirmware:(Firmware*)mFirmware{
    
    dispatch_async(queue, ^{
        
        [[NSThread currentThread] setName:@"UpgradeThread"];
        
        [self upgradeOnBackgroundTarget:target withAPIService:mRK410APIService andFirmware:mFirmware];
        
    });
    
    return mRACSubject;
    
}

-(void)upgradeOnBackgroundTarget:(NSString*)target  withAPIService:(RK410APIService*) mRK410APIService andFirmware:(Firmware*)mFirmware{
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    RACSignal *mRACSignal = [mRK410APIService requestUpgrade:target withFirmware:mFirmware];
    [[mRACSignal
      deliverOnMainThread]
     subscribeNext:^(NSData *response) {
         
         NSLog(@"--------requestUpgrade--------:%@",response);
         dispatch_semaphore_signal(sem);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"--------requestUpgrade--------:%@",error);
         dispatch_semaphore_signal(sem);
         
     }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    int byteSinglePackageSize = 1024  * mFirmware.singlePackageSize;
    
    NSData *data = mFirmware.data;
    
    int packageCount = (int)(data.length/byteSinglePackageSize + ((data.length % byteSinglePackageSize) == 0 ? 0 : 1));
    
    int curUploadLength = 0;
    for (int packageIndex = 0; packageIndex < packageCount; packageIndex++) {
        
        RKPackage *mRKPackage = [[RKPackage alloc] init];
        
        mRKPackage.packageIndex = packageIndex;
        if ((data.length % byteSinglePackageSize) == 0) {
            mRKPackage.packageSize = byteSinglePackageSize;
        } else {
            if (packageIndex < (packageCount - 1)) {
                mRKPackage.packageSize = byteSinglePackageSize;
            } else {
                mRKPackage.packageSize = data.length % byteSinglePackageSize;
            }
        }
        mRKPackage.uploadLength = curUploadLength;
        
        Byte crcPushMsg[mRKPackage.packageSize];
        [data  getBytes:crcPushMsg range:NSMakeRange(mRKPackage.uploadLength, mRKPackage.packageSize)];
        mRKPackage.crc = Get_Crc16(crcPushMsg,mRKPackage.packageSize);
        
        [[[mRK410APIService requestStartPackage:target withPackage:mRKPackage]
          deliverOnMainThread]
         subscribeNext:^(NSData *response) {
             
             NSLog(@"--------requestStartPackage--------:%@",response);
             dispatch_semaphore_signal(sem);
             
         }
         error:^(NSError *error) {
             
             NSLog(@"--------requestStartPackage--------:%@",error);
             dispatch_semaphore_signal(sem);
             
         }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        
        int frameCount = mRKPackage.packageSize/mFirmware.singleFrameSize + ((mRKPackage.packageSize % mFirmware.singleFrameSize) == 0 ? 0 : 1);
        for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
            
            RKFrame *mRKFrame = [[RKFrame alloc] init];
            
            if ((mRKPackage.packageSize % mFirmware.singleFrameSize) == 0) {
                mRKFrame.frameSize = mFirmware.singleFrameSize;
            } else {
                if (frameIndex < (frameCount - 1)) {
                    mRKFrame.frameSize = mFirmware.singleFrameSize;
                } else {
                    mRKFrame.frameSize = mRKPackage.packageSize % mFirmware.singleFrameSize;
                }
            }
            
            mRKFrame.data = [data subdataWithRange:NSMakeRange(mRKPackage.uploadLength + frameIndex * mFirmware.singleFrameSize, mRKFrame.frameSize)];
            
            [[[mRK410APIService sendData:target withFrame:mRKFrame]
              deliverOnMainThread]
             subscribeNext:^(NSData *response) {
                 
                 NSLog(@"-------sendData---------:%@",response);
                 dispatch_semaphore_signal(sem);
                 
             }
             error:^(NSError *error) {
                 
                 NSLog(@"-------sendData---------:%@",error);
                 dispatch_semaphore_signal(sem);
                 
             }];
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        }
        
        [[[mRK410APIService requestEndPackage:target withPackage:mRKPackage]
          deliverOnMainThread]
         subscribeNext:^(NSData *response) {
             
             NSLog(@"--------requestEndPackage--------:%@",response);
             dispatch_semaphore_signal(sem);
         }
         error:^(NSError *error) {
             
             NSLog(@"--------requestEndPackage--------:%@",error);
             dispatch_semaphore_signal(sem);
         }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        curUploadLength += mRKPackage.packageSize;
    }
    
    [[[mRK410APIService checkFileMD5:target withFirmware:mFirmware]
      deliverOnMainThread]
     subscribeNext:^(NSData *response) {
         
         NSLog(@"--------checkFileMD5--------:%@",response);
         dispatch_semaphore_signal(sem);
         
     }
     error:^(NSError *error) {
         
         NSLog(@"--------checkFileMD5-------:%@",error);
         dispatch_semaphore_signal(sem);
         
     }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}



@end
