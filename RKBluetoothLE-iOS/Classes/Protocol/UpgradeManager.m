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
#import "BleLog.h"

NSString * const UpgradeManagerErrorDomain         = @"UpgradeManagerErrorDomain";

const NSInteger UpgradeManagerErrorRequestUpgrade = 1;
const NSInteger UpgradeManagerErrorRequestPackage = 2;
const NSInteger UpgradeManagerErrorSendData       = 3;
const NSInteger UpgradeManagerErrorFinishPackage  = 4;
const NSInteger UpgradeManagerErrorCheckMD5       = 5;


@interface UpgradeManager(){
    
}

@property(strong,nonatomic) RK410APIService* mRK410APIService;

@end

@implementation UpgradeManager

-(instancetype)initWithAPIService:(RK410APIService*) mRK410APIService{
    
    self = [super init];
    if (self) {
        
        _mRK410APIService = mRK410APIService;
        
    }
    return self;
}

-(RACSignal*)upgradeFirmware:(Firmware*)mFirmware{
    
    return [[[RACSignal return:mFirmware] flattenMap:^(Firmware* value){
        @weakify(self)
        return  [RACSignal createSignal:^RACDisposable *(id subscriber) {
            
            @strongify(self)
            [self upgradeOnBackgroundTarget:mFirmware.ueSn andFirmware:value andSubscriber:subscriber];
            
            return nil;
            
        }];
    }] subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault name:@"com.rokyinfo.UpgradeManager"]];
    
}

-(void)upgradeOnBackgroundTarget:(NSString*)target andFirmware:(Firmware*)mFirmware andSubscriber:(id<RACSubscriber>) subscriber{
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block NSError *curError = nil;
    __block RequestUpgradeResponse *curResponse = nil;
    //请求升级
    [BleLog addMarker:@"requestUpgrade"];
    RACSignal *mRACSignal = [self.mRK410APIService requestUpgrade:target withFirmware:mFirmware];
    [[mRACSignal
      deliverOnMainThread]
     subscribeNext:^(RequestUpgradeResponse *response) {
         
         curResponse = response;
         dispatch_semaphore_signal(sem);
         
     }
     error:^(NSError *error) {
         
         curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorRequestUpgrade userInfo:error.userInfo];
         dispatch_semaphore_signal(sem);
         
     }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    //处理升级请求结果
    if (curResponse == nil && curError == nil) {
        curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorRequestUpgrade userInfo:@{ NSLocalizedDescriptionKey:@"response == nil"}];
    }
    
    if (curError) {
        [BleLog addMarker:@"requestUpgrade:error"];
        
        [subscriber sendError:curError];
        return;
        
    } else {
        
        [subscriber sendNext:curResponse];
        
    }
    
    if (curResponse.result == 0){
        [BleLog addMarker:@"requestUpgrade:error result == 0"];
        [subscriber sendCompleted];
        return;
    }
    
    //处理拆分package
    int byteSinglePackageSize = 1024  * mFirmware.singlePackageSize;
    
    int curUploadLength = 0;
    //继续升级
    if (curResponse.result == 2) {
        curUploadLength = curResponse.downloadedLength;
    }
    
    NSData *data = [mFirmware.data subdataWithRange:NSMakeRange(curUploadLength, mFirmware.data.length - curUploadLength)];
    
    int packageCount = (int)(data.length/byteSinglePackageSize + ((data.length % byteSinglePackageSize) == 0 ? 0 : 1));
    
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
        [mFirmware.data  getBytes:crcPushMsg range:NSMakeRange(mRKPackage.uploadLength, mRKPackage.packageSize)];
        mRKPackage.crc = Get_Crc16(crcPushMsg,mRKPackage.packageSize);
        
        
        curError = nil;
        __block RequestPackageResponse *curRequestPackageResponse = nil;
        
        //请求发包
        [BleLog addMarker:[NSString stringWithFormat:@"requestStartPackage count:%d ,index:%d", packageCount,packageIndex]];
        [[[self.mRK410APIService requestStartPackage:target withPackage:mRKPackage]
          deliverOnMainThread]
         subscribeNext:^(RequestPackageResponse *response) {
             
             curRequestPackageResponse = response;
             dispatch_semaphore_signal(sem);
             
         }
         error:^(NSError *error) {
             
             curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorRequestPackage userInfo:error.userInfo];
             dispatch_semaphore_signal(sem);
             
         }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        //处理包请求结果
        if (curRequestPackageResponse == nil && curError == nil) {
            curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorRequestPackage userInfo:@{ NSLocalizedDescriptionKey:@"response == nil"}];
        }
        
        if (curError) {
            
            [BleLog addMarker:[NSString stringWithFormat:@"requestStartPackage count:%d ,index:%d error", packageCount,packageIndex]];
            
            [subscriber sendError:curError];
            return;
            
        } else {
            curRequestPackageResponse.packageCount = packageCount;
            curRequestPackageResponse.packageIndex = packageIndex;
            [subscriber sendNext:curRequestPackageResponse];
            
        }
        
        if (curRequestPackageResponse.result == 0){
            
            [BleLog addMarker:[NSString stringWithFormat:@"requestStartPackage count:%d ,index:%d error result == 0", packageCount,packageIndex]];
            [subscriber sendCompleted];
            return;
            
        }
        
        //处理拆分frame
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
            
            mRKFrame.data = [mFirmware.data subdataWithRange:NSMakeRange(mRKPackage.uploadLength + frameIndex * mFirmware.singleFrameSize, mRKFrame.frameSize)];
            
            curError = nil;
            
            //发送数据
            [BleLog addMarker:[NSString stringWithFormat:@"sendData count:%d ,index:%d", frameCount,frameIndex]];
            [[[self.mRK410APIService sendData:target withFrame:mRKFrame]
              deliverOnMainThread]
             subscribeNext:^(NSData *response) {
                 
                 
                 dispatch_semaphore_signal(sem);
                 
             }
             error:^(NSError *error) {
                 
                 curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorSendData userInfo:error.userInfo];
                 dispatch_semaphore_signal(sem);
                 
             }];
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            
            if (curError) {
                [BleLog addMarker:[NSString stringWithFormat:@"sendData count:%d ,index:%d error", frameCount,frameIndex]];
                [subscriber sendError:curError];
                return;
            }
        }
        
        [BleLog addMarker:[NSString stringWithFormat:@"requestEndPackage count:%d ,index:%d", packageCount,packageIndex]];
        
        curError = nil;
        __block FinishPackageResponse *mFinishPackageResponse = nil;
        [[[self.mRK410APIService requestEndPackage:target withPackage:mRKPackage]
          deliverOnMainThread]
         subscribeNext:^(FinishPackageResponse *response) {
             
             mFinishPackageResponse = response;
             dispatch_semaphore_signal(sem);
             
         }
         error:^(NSError *error) {
             
             curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorFinishPackage userInfo:error.userInfo];
             dispatch_semaphore_signal(sem);
             
         }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        //处理包请求结果
        if (mFinishPackageResponse == nil && curError == nil) {
            curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorFinishPackage userInfo:@{ NSLocalizedDescriptionKey:@"response == nil"}];
        }
        if (curError) {
            
            [BleLog addMarker:[NSString stringWithFormat:@"requestEndPackage count:%d ,index:%d error", packageCount,packageIndex]];
            
            [subscriber sendError:curError];
            return;
            
        } else {
            mFinishPackageResponse.packageCount = packageCount;
            mFinishPackageResponse.packageIndex = packageIndex;
            [subscriber sendNext:mFinishPackageResponse];
            
        }
        
        if (mFinishPackageResponse.result == 0){
            
            [BleLog addMarker:[NSString stringWithFormat:@"requestEndPackage count:%d ,index:%d error result == 0", packageCount,packageIndex]];
            
            [subscriber sendCompleted];
            return;
            
        }
        
        curUploadLength += mRKPackage.packageSize;
    }
    
    curError = nil;
    __block MD5CheckResponse *mMD5CheckResponse = nil;
    [BleLog addMarker:@"checkFileMD5"];
    
    [[[self.mRK410APIService checkFileMD5:target withFirmware:mFirmware]
      deliverOnMainThread]
     subscribeNext:^(MD5CheckResponse *response) {
         
         mMD5CheckResponse = response;
         dispatch_semaphore_signal(sem);
         
     }
     error:^(NSError *error) {
         
         curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorCheckMD5 userInfo:error.userInfo];
         dispatch_semaphore_signal(sem);
         
     }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    if (mMD5CheckResponse == nil && curError == nil) {
        curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorCheckMD5 userInfo:@{ NSLocalizedDescriptionKey:@"response == nil"}];
    }
    
    if (curError) {
        
        [BleLog addMarker:@"checkFileMD5:error"];
        [subscriber sendError:curError];
        return;
        
    } else {
        
        if (mMD5CheckResponse.result == 0){
            [BleLog addMarker:@"checkFileMD5:error result == 0"];
        }
        [subscriber sendNext:mMD5CheckResponse];
        [subscriber sendCompleted];
        
    }
    
}

@end
