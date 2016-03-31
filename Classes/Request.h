//
//  Request.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEResponse.h"
#import "Response.h"

typedef NS_ENUM(NSInteger, RKBLEMethod) {
    
    RKBLEMethodRead            = 0,
    RKBLEMethodWrite           = 1,
    
};

typedef NS_ENUM(NSInteger, RKBLEResponseChannel) {
    
    RKBLEResponseWriteResult   = 0,
    RKBLEResponseReadResult    = 1,
    RKBLEResponseNotify        = 2,
    
};


@protocol BLEDataEntityProtocol<NSObject>

-(NSData*)entityToByte;

-(id)byteToEntity:(NSData*)data;

@end


@class Request;
@protocol BLEDataParseProtocol<NSObject>

@required

/**
 *  当前蓝牙交互协议连接成功后是否需要鉴权
 *
 *  @return yes: 需要 no:不需要
 */
-(BOOL)needAuthentication;

/**
 *  判读是否需要注册通知
 *
 *  @param service        服务
 *  @param characteristic 特征
 *
 *  @return yes: 需要 no:不需要
 */
-(BOOL)needSubscribeNotifyWithService:(NSString*)service characteristic:(NSString*)characteristic;

/**
 *  判断收到的蓝牙数据是否符合当前报文协议
 *
 *  @param dataTask       当前请求
 *  @param characteristic 特征UUID String
 *
 *  @return yes: 符合 no:不符合
 */
-(BOOL)effectiveResponse:(Request*)Request characteristic:(NSString*)characteristic sourceChannel:(RKBLEResponseChannel)channel;


/**
 *  获取鉴权处理请求
 *
 *  @param callBack
 */
- (void)createAuthProcessRequest:(void (^)(Request* request,NSError* error))callBack peripheralName:(NSString*)_peripheralName;


/**
 *  是否为鉴权请求
 *
 *  @param dataTask
 *
 *  @return
 */
- (BOOL)isAuthenticationRequest:(Request*)request;

/**
 *  解析鉴权返回值判断是否鉴权成功
 *
 *  @param value 鉴权返回值
 *
 *  @return
 */
- (BOOL)authSuccess:(NSData*)value;

@end

typedef void (^RequestSuccessBlock)(id response);

typedef void (^RequestErrorBlock)(NSError * error);


@class RequestQueue;
@interface Request<ObjectType> : NSObject

@property (nonatomic,copy,readonly   ) NSString             *identifier;

@property (nonatomic,copy,readonly   ) NSString             *peripheralName;

@property (nonatomic,copy,readonly   ) NSString             *service;

@property (nonatomic,copy,readonly   ) NSString             *characteristic;

@property (nonatomic,assign,readonly ) RKBLEMethod          method;

@property (nonatomic,strong          ) NSData               *writeValue;

@property (nonatomic,strong          ) id<BLEDataParseProtocol> dataParseProtocol;

@property (nonatomic,copy            ) RequestSuccessBlock  mRequestSuccessBlock;

@property (nonatomic,copy            ) RequestErrorBlock    mRequestErrorBlock;

@property (nonatomic,weak            ) RequestQueue         *mRequestQueue;

@property (nonatomic,strong          ) id                   tag;

+(void)setLogEnable:(BOOL)enable;

-(instancetype)initWithReponseClass:(Class)reponseClass
target:(NSDictionary*)target
method:(RKBLEMethod) method
writeValue:(NSData*)writeValue;

-(Request*)setSequence:(NSInteger)sequence;

-(NSInteger)getSequence;

-(void)addMarker:(NSString*)mark;

-(void)cancel;

-(BOOL)isCanceled;

-(Response<ObjectType>*)parseNetworkResponse:(BLEResponse*)response;

-(void)deliverResponse:(ObjectType)response;

-(void)deliverError:(NSError*)error;

-(void)markDelivered;

-(BOOL)hasHadResponseDelivered;

-(void)finish:(NSString*)tag;

-(void)onFinish;

@end
