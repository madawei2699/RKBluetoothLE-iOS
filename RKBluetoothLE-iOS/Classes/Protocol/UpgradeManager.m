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


NSString * const UpgradeManagerErrorDomain        = @"UpgradeManagerErrorDomain";

const NSInteger UpgradeManagerErrorRequestUpgrade = 1;
const NSInteger UpgradeManagerErrorRequestPackage = 2;
const NSInteger UpgradeManagerErrorSendData       = 3;
const NSInteger UpgradeManagerErrorFinishPackage  = 4;
const NSInteger UpgradeManagerErrorCheckMD5       = 5;


@interface UpgradeManager(){
    
    volatile BOOL mCanceled;
    volatile BOOL isRunning;
    
    dispatch_queue_t concurrentQueue;
    
}

@property(strong,nonatomic) RK410APIService* mRK410APIService;

@property(strong,nonatomic) RACBehaviorSubject *upgradeProgressSubject;

@property(strong,nonatomic) Firmware *mFirmware;

@end

@implementation UpgradeManager

-(instancetype)initWithAPIService:(RK410APIService*) mRK410APIService{
    
    self = [super init];
    if (self) {
        concurrentQueue = dispatch_queue_create("com.rokyinfo.UpgradeQueue", DISPATCH_QUEUE_SERIAL);
        _mRK410APIService = mRK410APIService;
        UpgradeProgress *mUpgradeProgress = [[UpgradeProgress alloc] init];
        mUpgradeProgress.runningStatus = UpgradeDefault;
        _upgradeProgressSubject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:mUpgradeProgress];
        
    }
    return self;
}

-(RACSignal*)upgradeFirmware:(Firmware*)__mFirmware{
    
    //没有运行或者更换了升级的固件信息则启动升级
    if (!isRunning || ![self.mFirmware isEqual:__mFirmware]) {
        
        if (isRunning) {
            mCanceled = YES;
        }
        self.mFirmware = __mFirmware;
        
        dispatch_async(concurrentQueue, ^{
            [[NSThread currentThread] setName:@"com.rokyinfo.UpgradeManager"];
            
            mCanceled = NO;
            isRunning = YES;
            [self upgradeOnBackground];
            isRunning = NO;
            
        });
        
    }
    
    @weakify(self)
    return [RACSignal
            defer:^{
                @strongify(self)
                return self.upgradeProgressSubject;
            }
            ];
    
}

-(void)cancelUpgrade{
    
    mCanceled = YES;
    
}

-(void)upgradeOnBackground{
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block NSError *curError = nil;
    __block RequestUpgradeResponse *curResponse = nil;
    
    UpgradeProgress *mUpgradeProgress = [[UpgradeProgress alloc] init];
    mUpgradeProgress.curFirmware = self.mFirmware;
    mUpgradeProgress.runningStatus =  UpgradeRunning;
    
    if (mCanceled) {
        mUpgradeProgress.runningStatus = UpgradeInterrupt;
        [self.upgradeProgressSubject sendNext:mUpgradeProgress];
        
        return;
    }
    //请求升级
    [BleLog addMarker:@"requestUpgrade"];
    [[self.mRK410APIService requestUpgrade:mUpgradeProgress.curFirmware.ueSn withFirmware:mUpgradeProgress.curFirmware]
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
    
    if (curResponse.result == 0){
        curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorRequestUpgrade userInfo:@{ NSLocalizedDescriptionKey:@"result == 0"}];
    }
    
    if (curError) {
        
        [BleLog addMarker:@"requestUpgrade:error"];
        mUpgradeProgress.runningStatus = UpgradeError;
        mUpgradeProgress.error = curError;
        [self.upgradeProgressSubject sendNext:mUpgradeProgress];
        
        return;
        
    } else {
        
        mUpgradeProgress.step = UpgradeRequestUpgrade;
        mUpgradeProgress.curRequestUpgradeResponse = curResponse;
        [self.upgradeProgressSubject sendNext:mUpgradeProgress];
        
    }
    
    //处理拆分package
    int byteSinglePackageSize = 1024  * mUpgradeProgress.curFirmware.singlePackageSize;
    
    int curUploadLength = 0;
    //继续升级
    if (curResponse.result == 2) {
        curUploadLength = curResponse.downloadedLength;
    }
    
    NSData *data = [mUpgradeProgress.curFirmware.data subdataWithRange:NSMakeRange(curUploadLength, mUpgradeProgress.curFirmware.data.length - curUploadLength)];
    
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
        [mUpgradeProgress.curFirmware.data  getBytes:crcPushMsg range:NSMakeRange(mRKPackage.uploadLength, mRKPackage.packageSize)];
        mRKPackage.crc = Get_Crc16(crcPushMsg,mRKPackage.packageSize);
        
        curError = nil;
        __block RequestPackageResponse *curRequestPackageResponse = nil;
        
        if (mCanceled) {
            mUpgradeProgress.runningStatus = UpgradeInterrupt;
            [self.upgradeProgressSubject sendNext:mUpgradeProgress];
            
            return;
        }
        //请求发包
        [BleLog addMarker:[NSString stringWithFormat:@"requestStartPackage count:%d ,index:%d", packageCount,packageIndex]];
        [[self.mRK410APIService requestStartPackage:mUpgradeProgress.curFirmware.ueSn withPackage:mRKPackage]
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
        
        if (curRequestPackageResponse.result == 0){
            
            curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorRequestPackage userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"result == 0,reason == %d",curRequestPackageResponse.reason]}];
            
        }
        
        if (curError) {
            
            [BleLog addMarker:[NSString stringWithFormat:@"requestStartPackage count:%d ,index:%d error", packageCount,packageIndex]];
            mUpgradeProgress.runningStatus = UpgradeError;
            mUpgradeProgress.error = curError;
            [self.upgradeProgressSubject sendNext:mUpgradeProgress];
            
            return;
            
        } else {
            
            curRequestPackageResponse.packageCount = packageCount;
            curRequestPackageResponse.packageIndex = packageIndex;
            
            mUpgradeProgress.step = UpgradeRequestPackage;
            mUpgradeProgress.curRequestPackageResponse = curRequestPackageResponse;
            [self.upgradeProgressSubject sendNext:mUpgradeProgress];
            
        }
        
        //处理拆分frame
        int frameCount = mRKPackage.packageSize/mUpgradeProgress.curFirmware.singleFrameSize + ((mRKPackage.packageSize % mUpgradeProgress.curFirmware.singleFrameSize) == 0 ? 0 : 1);
        for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
            
            RKFrame *mRKFrame = [[RKFrame alloc] init];
            
            if ((mRKPackage.packageSize % mUpgradeProgress.curFirmware.singleFrameSize) == 0) {
                mRKFrame.frameSize = mUpgradeProgress.curFirmware.singleFrameSize;
            } else {
                if (frameIndex < (frameCount - 1)) {
                    mRKFrame.frameSize = mUpgradeProgress.curFirmware.singleFrameSize;
                } else {
                    mRKFrame.frameSize = mRKPackage.packageSize % mUpgradeProgress.curFirmware.singleFrameSize;
                }
            }
            
            mRKFrame.data = [mUpgradeProgress.curFirmware.data subdataWithRange:NSMakeRange(mRKPackage.uploadLength + frameIndex * mUpgradeProgress.curFirmware.singleFrameSize, mRKFrame.frameSize)];
            
            curError = nil;
            
            if (mCanceled) {
                mUpgradeProgress.runningStatus = UpgradeInterrupt;
                [self.upgradeProgressSubject sendNext:mUpgradeProgress];
                
                return;
            }
            //发送数据
            [BleLog addMarker:[NSString stringWithFormat:@"sendData count:%d ,index:%d", frameCount,frameIndex]];
            [[self.mRK410APIService sendData:mUpgradeProgress.curFirmware.ueSn withFrame:mRKFrame]
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
                mUpgradeProgress.runningStatus = UpgradeError;
                mUpgradeProgress.error = curError;
                [self.upgradeProgressSubject sendNext:mUpgradeProgress];
                
                return;
            }
            
            long remainingLength =  mUpgradeProgress.curFirmware.data.length - (mRKPackage.uploadLength + frameIndex * mUpgradeProgress.curFirmware.singleFrameSize + mRKFrame.frameSize);
            
            double remainingTime = remainingLength/((float)mUpgradeProgress.curFirmware.singleFrameSize) * 0.1;
            
            mUpgradeProgress.remainingTime = (long)remainingTime;
            
            mUpgradeProgress.step = UpgradeSendFrame;
            mUpgradeProgress.percentage = (mRKPackage.uploadLength + frameIndex * mUpgradeProgress.curFirmware.singleFrameSize + mRKFrame.frameSize)/((double)mUpgradeProgress.curFirmware.data.length)*100;
            [self.upgradeProgressSubject sendNext:mUpgradeProgress];
        }
        
        curError = nil;
        __block FinishPackageResponse *mFinishPackageResponse = nil;
        
        if (mCanceled) {
            mUpgradeProgress.runningStatus = UpgradeInterrupt;
            [self.upgradeProgressSubject sendNext:mUpgradeProgress];
            
            return;
        }
        //请求校验本包
        [BleLog addMarker:[NSString stringWithFormat:@"requestEndPackage count:%d ,index:%d", packageCount,packageIndex]];
        [[self.mRK410APIService requestEndPackage:mUpgradeProgress.curFirmware.ueSn withPackage:mRKPackage]
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
        
        if (mFinishPackageResponse.result == 0){
            curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorFinishPackage userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"result == 0,reason == %d",mFinishPackageResponse.reason]}];
        }
        
        if (curError) {
            
            [BleLog addMarker:[NSString stringWithFormat:@"requestEndPackage count:%d ,index:%d error", packageCount,packageIndex]];
            mUpgradeProgress.runningStatus = UpgradeError;
            mUpgradeProgress.error = curError;
            [self.upgradeProgressSubject sendNext:mUpgradeProgress];
            
            return;
            
        } else {
            
            mFinishPackageResponse.packageCount = packageCount;
            mFinishPackageResponse.packageIndex = packageIndex;
            
            mUpgradeProgress.step = UpgradeFinishPackage;
            mUpgradeProgress.curFinishPackageResponse = mFinishPackageResponse;
            [self.upgradeProgressSubject sendNext:mUpgradeProgress];
            
        }
        
        curUploadLength += mRKPackage.packageSize;
    }
    
    curError = nil;
    __block MD5CheckResponse *mMD5CheckResponse = nil;
    
    if (mCanceled) {
        mUpgradeProgress.runningStatus = UpgradeInterrupt;
        [self.upgradeProgressSubject sendNext:mUpgradeProgress];
        
        return;
    }
    [BleLog addMarker:@"checkFileMD5"];
    [[self.mRK410APIService checkFileMD5:mUpgradeProgress.curFirmware.ueSn withFirmware:mUpgradeProgress.curFirmware]
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
    
    if (mMD5CheckResponse.result == 0){
        curError = [NSError errorWithDomain:UpgradeManagerErrorDomain code:UpgradeManagerErrorCheckMD5 userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"result == 0,reason == %d",mMD5CheckResponse.reason]}];
    }
    
    if (curError) {
        
        [BleLog addMarker:@"checkFileMD5:error"];
        mUpgradeProgress.runningStatus = UpgradeError;
        mUpgradeProgress.error = curError;
        [self.upgradeProgressSubject sendNext:mUpgradeProgress];
        
        return;
        
    } else {
        
        mUpgradeProgress.runningStatus = UpgradeDone;
        mUpgradeProgress.step = UpgradeCheckMD5;
        mUpgradeProgress.curMD5CheckResponse = mMD5CheckResponse;
        mUpgradeProgress.percentage = 100;
        [self.upgradeProgressSubject sendNext:mUpgradeProgress];
        
        return;
    }
    
}

-(void)dealloc{
    NSLog(@"UpgradeManager : dealloc");
}

@end
