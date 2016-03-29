//
//  RequestQueue.h
//  RokyinfoBLEDemo
//
//  Created by 袁志健 on 16/3/29.
//  Copyright © 2016年 rokyinfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bluetooth.h"

@interface RequestQueue : NSObject


- (id)initWithBluetooth:(id<Bluetooth>)_Bluetooth;

- (void) start;

- (void) stop;

@end
