//
//  URLRouter.h
//  TrollApps
//
//  Created by 十三哥 on 2026/4/19.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface URLRouter : NSObject
/// 处理标准 URL
+ (void)handleRouteURL:(NSURL *)url;

/// 处理字符串类型链接（聊天、二维码、剪贴板通用）
+ (void)handleRouteURLString:(NSString *)urlString;

/// 从 URL 字符串中获取指定参数的值（通用！）
+ (nullable NSString *)getValueFromURLString:(NSString *)urlString key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
