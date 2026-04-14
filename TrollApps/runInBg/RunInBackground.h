//
//  RunInBackground.h
//  libIntegrity
//
//  Created by niu_o0 on 2020/4/24.
//  Copyright © 2020 niu_o0. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RunInBackground : NSObject

+ (void)startBackgroundService; // 启动三合一保活
+ (void)stopBackgroundService;  // 停止

@end

NS_ASSUME_NONNULL_END
