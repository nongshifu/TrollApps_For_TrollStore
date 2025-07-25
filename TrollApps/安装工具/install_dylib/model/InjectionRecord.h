//
//  InjectionRecord.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InjectionRecord : NSObject<NSCoding>
@property (nonatomic, copy) NSString *appName;        // 应用名称
@property (nonatomic, copy) NSString *appBundleID;    // 应用BundleID
@property (nonatomic, copy) NSString *dylibPath;      // 注入的动态库路径
@property (nonatomic, strong) NSDate *injectionTime;  // 注入时间
@end

NS_ASSUME_NONNULL_END
