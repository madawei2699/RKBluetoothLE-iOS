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
    
    RACSubject *discontinueSubject;
    
}

@property(strong,nonatomic) RK410APIService* mRK410APIService;

@property(strong,nonatomic) RACSignal *mRACSignal;

@property(strong,nonatomic) Firmware *mFirmware;

@end

@implementation UpgradeManager

-(instancetype)initWithAPIService:(RK410APIService*) mRK410APIService{
    
    self = [super init];
    if (self) {
        
        _mRK410APIService = mRK410APIService;
        discontinueSubject = [RACSubject subject];
        
    }
    return self;
}

-(RACSignal*)upgradeFirmware:(Firmware*)__mFirmware{
    
    if (self.mRACSignal && self.mFirmware && [self.mFirmware isEqual:__mFirmware]) {
        return self.mRACSignal;
    } else {
        
        if (self.mRACSignal) {
            [discontinueSubject sendNext:nil];
        }
        self.mFirmware = __mFirmware;
    }
    
    @weakify(self)
    self.mRACSignal = [[[[RACSignal createSignal:^RACDisposable *(id subscriber) {
        
        @strongify(self)
        [self upgradeOnBackground:subscriber];
        
        return [RACDisposable disposableWithBlock:^{
            
            self.mFirmware = nil;
            self.mRACSignal = nil;
            
        }];
        
    }] subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault name:@"com.rokyinfo.UpgradeManager"]]takeUntil:discontinueSubject] replayLazily] ;
    
    return self.mRACSignal;
    
}

-(void)upgradeOnBackground:(id<RACSubscriber>) subscriber{
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block NSError *curError = nil;
    __block RequestUpgradeResponse *curResponse = nil;
    //请求升级
    [BleLog addMarker:@"requestUpgrade"];
    UpgradeProgress *mUpgradeProgress = [[UpgradeProgress alloc] init];
    mUpgradeProgress.curFirmware = self.mFirmware;
    
    [[self.mRK410APIService requestUpgrade:self.mFirmware.ueSn withFirmware:self.mFirmware]
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
        [subscriber sendError:curError];
        
        return;
        
    } else {
        
        mUpgradeProgress.step = UpgradeRequestUpgrade;
        mUpgradeProgress.curRequestUpgradeResponse = curResponse;
        [subscriber sendNext:mUpgradeProgress];
        
    }
    
    //处理拆分package
    int byteSinglePackageSize = 1024  * self.mFirmware.singlePackageSize;
    
    int curUploadLength = 0;
    //继续升级
    if (curResponse.result == 2) {
        curUploadLength = curResponse.downloadedLength;
    }
    
    NSData *data = [self.mFirmware.data subdataWithRange:NSMakeRange(curUploadLength, self.mFirmware.data.length - curUploadLength)];
    
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
        [self.mFirmware.data  getBytes:crcPushMsg range:NSMakeRange(mRKPackage.uploadLength, mRKPackage.packageSize)];
        mRKPackage.crc = Get_Crc16(crcPushMsg,mRKPackage.packageSize);
        
        curError = nil;
        __block RequestPackageResponse *curRequestPackageResponse = nil;
        
        //请求发包
        [BleLog addMarker:[NSString stringWithFormat:@"requestStartPackage count:%d ,index:%d", packageCount,packageIndex]];
        [[self.mRK410APIService requestStartPackage:self.mFirmware.ueSn withPackage:mRKPackage]
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
            
            [subscriber sendError:curError];
            
            return;
            
        } else {
            
            curRequestPackageResponse.packageCount = packageCount;
            curRequestPackageResponse.packageIndex = packageIndex;
            
            mUpgradeProgress.step = UpgradeRequestPackage;
            mUpgradeProgress.curRequestPackageResponse = curRequestPackageResponse;
            [subscriber sendNext:mUpgradeProgress];
            
        }
        
        //处理拆分frame
        int frameCount = mRKPackage.packageSize/self.mFirmware.singleFrameSize + ((mRKPackage.packageSize % self.mFirmware.singleFrameSize) == 0 ? 0 : 1);
        for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
            
            RKFrame *mRKFrame = [[RKFrame alloc] init];
            
            if ((mRKPackage.packageSize % self.mFirmware.singleFrameSize) == 0) {
                mRKFrame.frameSize = self.mFirmware.singleFrameSize;
            } else {
                if (frameIndex < (frameCount - 1)) {
                    mRKFrame.frameSize = self.mFirmware.singleFrameSize;
                } else {
                    mRKFrame.frameSize = mRKPackage.packageSize % self.mFirmware.singleFrameSize;
                }
            }
            
            mRKFrame.data = [self.mFirmware.data subdataWithRange:NSMakeRange(mRKPackage.uploadLength + frameIndex * self.mFirmware.singleFrameSize, mRKFrame.frameSize)];
            
            curError = nil;
            
            //发送数据
            [BleLog addMarker:[NSString stringWithFormat:@"sendData count:%d ,index:%d", frameCount,frameIndex]];
            [[self.mRK410APIService sendData:self.mFirmware.ueSn withFrame:mRKFrame]
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
            
            mUpgradeProgress.step = UpgradeSendFrame;
            mUpgradeProgress.percentage = (mRKPackage.uploadLength + frameIndex * self.mFirmware.singleFrameSize + mRKFrame.frameSize)/((double)self.mFirmware.data.length)*100;
            [subscriber sendNext:mUpgradeProgress];
        }
        
        [BleLog addMarker:[NSString stringWithFormat:@"requestEndPackage count:%d ,index:%d", packageCount,packageIndex]];
        
        curError = nil;
        __block FinishPackageResponse *mFinishPackageResponse = nil;
        [[self.mRK410APIService requestEndPackage:self.mFirmware.ueSn withPackage:mRKPackage]
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
            
            [subscriber sendError:curError];
            
            return;
            
        } else {
            
            mFinishPackageResponse.packageCount = packageCount;
            mFinishPackageResponse.packageIndex = packageIndex;
            
            mUpgradeProgress.step = UpgradeFinishPackage;
            mUpgradeProgress.curFinishPackageResponse = mFinishPackageResponse;
            [subscriber sendNext:mUpgradeProgress];
            
        }
        
        curUploadLength += mRKPackage.packageSize;
    }
    
    curError = nil;
    __block MD5CheckResponse *mMD5CheckResponse = nil;
    [BleLog addMarker:@"checkFileMD5"];
    
    [[self.mRK410APIService checkFileMD5:self.mFirmware.ueSn withFirmware:self.mFirmware]
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
        [subscriber sendError:curError];
        
        return;
        
    } else {
        
        mUpgradeProgress.step = UpgradeCheckMD5;
        mUpgradeProgress.curMD5CheckResponse = mMD5CheckResponse;
        mUpgradeProgress.percentage = 100;
        [subscriber sendNext:mUpgradeProgress];
        [subscriber sendCompleted];
        
    }
    
    
}

-(void)dealloc{
    NSLog(@"UpgradeManager : dealloc");
}

@end
