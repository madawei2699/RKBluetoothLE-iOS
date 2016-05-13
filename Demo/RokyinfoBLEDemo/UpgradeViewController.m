//
//  UpgradeViewController.m
//  RokyinfoBLEDemo
//
//  Created by apple on 16/5/13.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import "UpgradeViewController.h"
#import "AppDelegate.h"
#import "UpgradeManager.h"
#import "CocoaSecurity.h"

#define BUILD_FILE_MODEL 1

@interface UpgradeViewController (){
    
    UpgradeManager *mUpgradeManager;
    
}

@property(weak,nonatomic)IBOutlet UITextField *fileSize;
@property(weak,nonatomic)IBOutlet UITextField *version;
@property(weak,nonatomic)IBOutlet UITextField *singlePackageSize;
@property(weak,nonatomic)IBOutlet UISwitch *isForceUpgradeMode;

@property(weak,nonatomic)IBOutlet UILabel *message;

@property(weak,nonatomic)IBOutlet UILabel *time;

@end

@implementation UpgradeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    mUpgradeManager = [[UpgradeManager alloc] initWithAPIService:RK410APIServiceImpl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onStartUpgrade:(id)sender{
    
    if(self.fileSize.text.length == 0 || self.version.text.length == 0 || self.singlePackageSize.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入参数" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil] show];
        return;
    }
    
    NSMutableData *mNSData = [[NSMutableData alloc] init];
    
    BOOL notZF = NO;
    int maxCount = self.fileSize.text.intValue *1024 / 20;
    if (((self.fileSize.text.intValue *1024) % 20) != 0) {
        maxCount += 1;
        notZF = YES;
    }
    
    for(int i = 0;i < maxCount;i++){
        
        if (i == (maxCount-1) && notZF) {
            int length = ((self.fileSize.text.intValue *1024) % 20);
            Byte bytes[length];
            for(int k;k < length;k++){
                bytes[k] = i;
            }
            [mNSData appendBytes:bytes length:length];
        } else {
            Byte bytes[20] = {i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i};
            [mNSData appendBytes:bytes length:20];
        }
        
        
    }
    
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"File"ofType:@"rtf"];
    Firmware *mFirmware = [[Firmware alloc] init];
    mFirmware.version = self.version.text;
    mFirmware.ueSn = @"B00G10B6F3";
    mFirmware.singlePackageSize = self.singlePackageSize.text.intValue;
    mFirmware.singleFrameSize = 20;
    mFirmware.isForceUpgradeMode = self.isForceUpgradeMode.isOn;
#ifdef BUILD_FILE_MODEL
    mFirmware.data = mNSData;
#else
    mFirmware.data =  [NSData dataWithContentsOfFile:filePath] ;
#endif
    mFirmware.fileSize = mFirmware.data.length;
    mFirmware.md5 = [CocoaSecurity md5WithData:mFirmware.data].hex;
    
    __block NSDate *current = [NSDate date];
    self.time.text = [NSString stringWithFormat:@"用时：%d 秒",0] ;
    RACDisposable *mRACDisposable = [[RACSignal interval:1 onScheduler:[RACScheduler currentScheduler]] subscribeNext:^(id x) {
        
        self.time.text = [NSString stringWithFormat:@"用时：%d 秒",abs((int)[current timeIntervalSinceNow])] ;
        
    } ];
    self.message.textColor = [UIColor blackColor];
    self.message.text = @"开始升级，请求升级";
    [[[mUpgradeManager upgradeFirmware:mFirmware] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id response) {
         
         self.message.textColor = [UIColor blackColor];
         
         if ([response isKindOfClass:[RequestUpgradeResponse class]]) {
             
             
             NSString *tips = @"";
             switch (((RequestUpgradeResponse*)response).result) {
                 case 0:
                     tips = @"不升级";
                     self.message.textColor = [UIColor redColor];
                     break;
                 case 1:
                     tips = @"全新升级";
                     break;
                 case 2:
                     tips = @"继续升级";
                     break;
                     
                 default:
                     break;
             }
             self.message.text = [NSString stringWithFormat:@"%@%@",@"收到请求升级响应:",tips];
             
         } else if ([response isKindOfClass:[RequestPackageResponse class]]) {
             
             NSString *tips1 = @"";
             NSString *tips2 = @"";
             switch (((RequestPackageResponse*)response).result) {
                 case 0:
                     tips1 = @"错误";
                     self.message.textColor = [UIColor redColor];
                     break;
                 case 1:
                     tips1 = @"正常";
                     break;
                     
                 default:
                     break;
             }
             
             switch (((RequestPackageResponse*)response).reason) {
                 case 0:
                     tips2 = @"正常";
                     break;
                 case 1:
                     tips2 = @"CRC错误";
                     
                     break;
                     
                 default:
                     break;
             }
             self.message.text = [NSString stringWithFormat:@"%@ index:%d count:%d:%@:%@\n开始发送本包数据..." ,@"收到请求传输包响应",((RequestPackageResponse*)response).packageIndex,((RequestPackageResponse*)response).packageCount,tips1,tips2];
             
         } else if ([response isKindOfClass:[FinishPackageResponse class]]) {
             
             NSString *tips1 = @"";
             NSString *tips2 = @"";
             switch (((FinishPackageResponse*)response).result) {
                 case 0:
                     tips1 = @"错误";
                     self.message.textColor = [UIColor redColor];
                     break;
                 case 1:
                     tips1 = @"正常";
                     
                     break;
                     
                 default:
                     break;
             }
             
             switch (((FinishPackageResponse*)response).reason) {
                 case 0:
                     tips2 = @"无错误";
                     break;
                 case 1:
                     tips2 = @"包CRC错误";
                     
                     break;
                 case 3:
                     tips2 = @"写FLASH错误";
                     break;
                 case 4:
                     tips2 = @"接收数据和包数据不符";
                     
                     break;
                 case 5:
                     tips2 = @"packet id不符";
                     
                     break;
                     
                 default:
                     break;
             }
             self.message.text = [NSString stringWithFormat:@"%@ index:%d count:%d:%@:%@" ,@"收到请求传输包响应",((FinishPackageResponse*)response).packageIndex,((FinishPackageResponse*)response).packageCount,tips1,tips2];
             
         }  else if ([response isKindOfClass:[MD5CheckResponse class]]) {
             
             NSString *tips1 = @"";
             NSString *tips2 = @"";
             switch (((MD5CheckResponse*)response).result) {
                     
                 case 0:
                     tips1 = @"不更新";
                     self.message.textColor = [UIColor redColor];
                     break;
                 case 1:
                     tips1 = @"同意更新";
                     self.message.textColor = [UIColor greenColor];
                     break;
                     
                 default:
                     break;
             }
             
             switch (((MD5CheckResponse*)response).reason) {
                 case 0:
                     tips2 = @"无问题";
                     break;
                 case 1:
                     tips2 = @"MD5验证失败";
                     
                     break;
                     
                 default:
                     break;
             }
             
             self.message.text = [NSString stringWithFormat:@"%@%@%@",@"MD5校验结果:",tips1,tips2];
         }
         
     }
     error:^(NSError *error) {
         
         self.message.textColor = [UIColor redColor];
         self.message.text = [error localizedDescription];
         
         [mRACDisposable dispose];
         
         
     }
     completed:^(){
         
         [mRACDisposable dispose];
         
     }];
    
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
