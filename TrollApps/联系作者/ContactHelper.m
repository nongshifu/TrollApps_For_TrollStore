//
//  ContactHelper.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/23.

#import "ContactHelper.h"
#import <SVProgressHUD/SVProgressHUD.h>

@implementation ContactHelper

/// 单例初始化
+ (instancetype)shared {
    static ContactHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ContactHelper alloc] init];
    });
    return instance;
}
- (void)showContactActionSheetWithUserInfo:(UserModel *)userInfo {
    [self showContactActionSheetWithUserInfo:userInfo title:@"联系作者"];
}
- (void)showContactActionSheetWithUserInfo:(UserModel *)userInfo title:(NSString *)title{
    [self showContactActionSheetWithUserInfo:userInfo baseViewController:[self getTopViewController] title:title];
}

/// 显示联系作者的操作菜单
- (void)showContactActionSheetWithUserInfo:(UserModel *)userInfo baseViewController:(nullable UIViewController *)baseVC title:(NSString*)title{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 1. 手机号（拨打电话）
    if (userInfo.phone.length == 11) {
        UIAlertAction *phoneAction = [UIAlertAction actionWithTitle:@"联系作者手机"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
            [self makePhoneCall:userInfo.phone];
        }];
        [alertController addAction:phoneAction];
    }
    
    // 2. Email（发送邮件）
    if (userInfo.email.length > 0 && [self isValidEmail:userInfo.email]) {
        UIAlertAction *emailAction = [UIAlertAction actionWithTitle:@"联系作者Email"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            [self sendEmailTo:userInfo.email];
        }];
        [alertController addAction:emailAction];
    }
    
    // 3. QQ（打开QQ聊天）
    if (userInfo.qq.length > 4) {
        UIAlertAction *qqAction = [UIAlertAction actionWithTitle:@"联系作者QQ"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
            [self openQQChat:userInfo.qq];
        }];
        [alertController addAction:qqAction];
    }
    
    // 4. 微信（提示复制微信号）
    if (userInfo.wechat.length > 4) {
        UIAlertAction *wechatAction = [UIAlertAction actionWithTitle:@"联系作者微信"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
            [self copyWechatID:userInfo.wechat];
        }];
        [alertController addAction:wechatAction];
    }
    
    // 5. TG（打开Telegram聊天）
    if (userInfo.tg.length > 4) {
        UIAlertAction *tgAction = [UIAlertAction actionWithTitle:@"联系作者TG"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
            [self openTelegramChat:userInfo.tg];
        }];
        [alertController addAction:tgAction];
    }
    
    // 取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    
    // 显示菜单（获取展示弹窗的控制器）
    UIViewController *presentingVC = baseVC ?: [self getTopViewController];
    [presentingVC presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 联系方式具体实现

// 拨打电话
- (void)makePhoneCall:(NSString *)phoneNumber {
    // 移除可能的空格或特殊字符
    NSString *cleanedPhone = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", cleanedPhone]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
        [[UIApplication sharedApplication] openURL:phoneURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开拨号界面"];
            }
        }];
    } else {
        [SVProgressHUD showErrorWithStatus:@"设备不支持拨打电话功能"];
    }
}

// 发送邮件
- (void)sendEmailTo:(NSString *)emailAddress {
    if (![self isValidEmail:emailAddress]) {
        [SVProgressHUD showErrorWithStatus:@"邮箱地址无效"];
        return;
    }
    
    NSURL *emailURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", emailAddress]];
    
    if ([[UIApplication sharedApplication] canOpenURL:emailURL]) {
        [[UIApplication sharedApplication] openURL:emailURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开邮件应用"];
            }
        }];
    } else {
        [SVProgressHUD showErrorWithStatus:@"未安装邮件应用"];
    }
}

// 打开QQ聊天（需要QQ客户端）
- (void)openQQChat:(NSString *)qqNumber {
    // QQ URL Scheme格式：mqq://im/chat?chat_type=wpa&uin=QQ号&version=1&src_type=web
    NSURL *qqURL = [NSURL URLWithString:[NSString stringWithFormat:@"mqq://im/chat?chat_type=wpa&uin=%@&version=1&src_type=web", qqNumber]];
    
    if ([[UIApplication sharedApplication] canOpenURL:qqURL]) {
        [[UIApplication sharedApplication] openURL:qqURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开QQ"];
            }
        }];
    } else {
        // 未安装QQ时提示复制QQ号
        [self copyTextToPasteboard:qqNumber tip:@"QQ号已复制，请手动添加好友"];
    }
}

// 复制微信号（微信没有直接聊天的URL Scheme，只能复制）
- (void)copyWechatID:(NSString *)wechatID {
    [self copyTextToPasteboard:wechatID tip:@"微信号已复制，请在微信中添加好友"];
}

// 打开Telegram聊天
- (void)openTelegramChat:(NSString *)tgUsername {
    // Telegram URL Scheme格式：tg://resolve?domain=用户名（不带@）
    NSString *cleanedUsername = [tgUsername stringByReplacingOccurrencesOfString:@"@" withString:@""];
    NSURL *tgURL = [NSURL URLWithString:[NSString stringWithFormat:@"tg://resolve?domain=%@", cleanedUsername]];
    
    if ([[UIApplication sharedApplication] canOpenURL:tgURL]) {
        [[UIApplication sharedApplication] openURL:tgURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开Telegram"];
            }
        }];
    } else {
        // 未安装Telegram时提示复制用户名
        [self copyTextToPasteboard:tgUsername tip:@"TG用户名已复制，请在Telegram中搜索"];
    }
}

#pragma mark - 工具方法

// 验证邮箱格式
- (BOOL)isValidEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

// 复制文本到剪贴板并提示
- (void)copyTextToPasteboard:(NSString *)text tip:(NSString *)tip {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;
    [SVProgressHUD showSuccessWithStatus:tip];
}

// 获取顶层视图控制器（用于弹窗展示）

- (UIViewController *)getTopViewController {
    UIViewController *topViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

@end
