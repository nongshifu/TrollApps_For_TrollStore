//
//  ContactHelper.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/23.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "config.h"
#import "UserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ContactHelper : NSObject
/// 单例实例
+ (instancetype)shared;

/// 显示联系作者的操作菜单
/// @param userInfo 包含联系方式的用户模型
/// @param baseVC 基础视图控制器（用于展示弹窗，传nil则自动获取顶层控制器）
/// @param title 弹窗标题
- (void)showContactActionSheetWithUserInfo:(UserModel *)userInfo baseViewController:(nullable UIViewController *)baseVC title:(nullable NSString*)title;

/// 显示联系作者的操作菜单
/// @param userInfo 包含联系方式的用户模型
/// @param title 弹窗标题
- (void)showContactActionSheetWithUserInfo:(UserModel *)userInfo title:(nullable NSString*)title;

/// 显示联系作者的操作菜单
/// @param userInfo 包含联系方式的用户模型
- (void)showContactActionSheetWithUserInfo:(UserModel *)userInfo;

/// 显示联系作者的操作菜单
/// @param udid 包含联系方式的用户udid
- (void)showContactActionSheetWithUserUdid:(NSString *)udid;

@end

NS_ASSUME_NONNULL_END
