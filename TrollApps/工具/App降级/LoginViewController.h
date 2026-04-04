//
//  LoginViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2026/3/31.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoginViewController : DemoBaseViewController
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UISwitch *rememberSwitch;
@property (nonatomic, copy) void(^loginCompletion)(BOOL success, NSError *error);

// 加载保存的账号信息
- (void)loadSavedAccountInfo;
// 保存账号信息
- (void)saveAccountInfo:(NSString *)email password:(NSString *)password;
// 清除保存的账号信息
- (void)clearSavedAccountInfo;
@end

NS_ASSUME_NONNULL_END
