//
//  URLRouter.m
//  TrollApps
//
//  Created by 十三哥 on 2026/4/19.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "URLRouter.h"
#import "KeychainTool.h"
#import "SVProgressHUD.h"
#import "NewProfileViewController.h"
#import "ShowOneAppViewController.h"
#import "UserProfileViewController.h"
#import "ShowOneOrderViewController.h"
#import "ShowOnePostViewController.h"
#import "ShowOneToolViewController.h"
#import "DownloadManagerViewController.h"
#import "SVProgressHUD.h"
#import "Config.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@implementation URLRouter

#pragma mark - 对外接口：传入 URL
+ (void)handleRouteURL:(NSURL *)url {
    if (!url) return;
    [self internalHandleURL:url];
}

#pragma mark - 对外接口：传入 字符串（重点！你要的就是这个）
+ (void)handleRouteURLString:(NSString *)urlString {
    if (!urlString || urlString.length == 0) return;
    
    // 自动过滤空格、换行
    NSString *trimmed = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // 自动补全协议（防止不是 http/https 也能解析）
    if (![trimmed containsString:@"://"]) {
        trimmed = [@"trollapps://" stringByAppendingString:trimmed];
    }
    
    // 转成 URL
    NSURL *url = [NSURL URLWithString:trimmed];
    if (!url) {
        NSLog(@"❌ 无法解析为URL：%@", trimmed);
        return;
    }
    
    [self internalHandleURL:url];
}

#pragma mark - 内部统一处理（核心逻辑）
+ (void)internalHandleURL:(NSURL *)url {
    //返回主线程UI操作
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *urlString = url.absoluteString;
        NSLog(@"🚦 路由处理: %@", urlString);
        
        // 👀 第一步：优先处理 file:// 文件导入（独立判断，不受 url_type 影响）
        if ([urlString hasPrefix:@"file://"]) {
            NSString *inboxDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Inbox"];
            if ([url.path hasPrefix:inboxDir]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    DownloadManagerViewController *dmVC = [DownloadManagerViewController sharedInstance];
                    [dmVC switchToDirectory:inboxDir];
                    
                    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                    while (topVC.presentedViewController) {
                        topVC = topVC.presentedViewController;
                    }
                    
                    if (![topVC isKindOfClass:[DownloadManagerViewController class]]) {
                        [topVC presentViewController:dmVC animated:YES completion:nil];
                    }
                });
            }
            return; // 文件处理完直接返回
        }
        
        NSString *url_type = [self getValueFromURLString:urlString key:@"url_type"];
        NSString *url_id = [self getValueFromURLString:urlString key:@"id"];
        NSLog(@"🚦 路由处理url_type: %@  url_id:%@", url_type,url_id);
        if(url_type){
            // 1. 打开帖子
            if ([urlString containsString:@"post_detail"] && url_id) {
                ShowOnePostViewController *vc = [ShowOnePostViewController new];
                vc.post_id = [url_id intValue];
                [[self topViewController] presentPanModal:vc];
            }
            // 2. 打开应用
            else if ([urlString containsString:@"app_detail"] && url.query) {
                ShowOneAppViewController *vc = [ShowOneAppViewController new];
                vc.app_id = [url_id intValue];
                [[self topViewController] presentPanModal:vc];
            }
            // 3. 打开用户
            else if ([urlString containsString:@"user_detail"] && url.query) {
                UserProfileViewController *vc = [UserProfileViewController new];
                vc.user_id = [url_id integerValue];
                [[self topViewController] presentPanModal:vc];
            }
            // 4. 打开工具
            else if ([urlString containsString:@"tool_detail"]) {
                ShowOneToolViewController *vc = [ShowOneToolViewController new];
                vc.tool_id = [url_id intValue];
                [[self topViewController] presentPanModal:vc];
            }
            // 5. 登录
            else if ([urlString containsString:@"login"]) {
                //调用登录函数
                NSString *token = [self getValueFromURLString:urlString key:@"token"];
                [self confirmLoginWithToken:token];
            }
            
            
            else {
                NSLog(@"❌ 未定义路由");
            }
        }
    });
    
    
}

#pragma mark - 业务逻辑
+ (void)handleGetUdidURL:(NSURL *)url {
    NSDictionary *params = [self parseURLQueryString:url.query];
    NSString *udid = params[@"udid"];
    if (udid.length > 5) {
        [KeychainTool saveString:udid forKey:TROLLAPPS_SAVE_UDID_KEY];
        [[NewProfileViewController sharedInstance] loadUserInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:@"登录信息已同步"];
            [SVProgressHUD dismissWithDelay:1.5];
        });
    }
}

+ (void)handleOpenOneAppURL:(NSURL *)url {
    NSDictionary *params = [self parseURLQueryString:url.query];
    NSString *appId = params[@"appId"];
    if (appId.integerValue > 0) {
        ShowOneAppViewController *vc = ShowOneAppViewController.new;
        vc.app_id = appId.integerValue;
        [[self topViewController] presentPanModal:vc];
    }
}

+ (void)handleOpenOneUserURL:(NSURL *)url {
    NSDictionary *params = [self parseURLQueryString:url.query];
    NSString *user_udid = params[@"user_udid"];
    if (user_udid) {
        UserProfileViewController *vc = UserProfileViewController.new;
        vc.user_udid = user_udid;
        [[self topViewController] presentPanModal:vc];
    }
}

+ (void)handlePackageSelectURL:(NSURL *)url {
    NSDictionary *params = [self parseURLQueryString:url.query];
    NSString *orderNo = params[@"mch_orderid"];
    ShowOneOrderViewController *vc = ShowOneOrderViewController.new;
    vc.targetOrderNo = orderNo;
    [[self topViewController] presentViewController:vc animated:YES completion:nil];
}


/**
 * 确认扫码登录
 * @param token 从URL中提取的登录token
 */
+ (void)confirmLoginWithToken:(NSString *)token {
    // 获取当前最顶层的视图控制器并弹出
    UIViewController *topVC = [self topViewController];
    if([topVC isKindOfClass:[UIAlertController class]])return;
    
    // 获取设备UDID
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if (!udid || udid.length == 0) {
        NSLog(@"❌ 无法获取设备UDID");
        [SVProgressHUD showErrorWithStatus:@"无法获取设备信息"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // 弹出确认框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"登录确认"
                                                                   message:@"是否确认在当前设备登录？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
        NSLog(@"用户取消登录");
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认登录"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
        [self doConfirmLoginWithToken:token udid:udid];
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:confirmAction];
    
    
    [topVC presentViewController:alert animated:YES completion:nil];
}

/**
 * 执行登录确认请求
 * @param token 登录token
 * @param udid 设备UDID
 */
+ (void)doConfirmLoginWithToken:(NSString *)token udid:(NSString *)udid {
    // 显示加载提示
    [SVProgressHUD showWithStatus:@"登录确认中..."];
    
    // 构建请求参数
    NSDictionary *params = @{
        @"token": token,
        @"udid": udid
    };
    
    // 调用confirm_login.php确认登录
    NSString *urlString = [NSString stringWithFormat:@"%@/auth/confirm_login.php", localURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&jsonError];
    if (jsonError) {
        NSLog(@"❌ JSON序列化失败: %@", jsonError);
        [SVProgressHUD showErrorWithStatus:@"请求失败"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    request.HTTPBody = jsonData;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"❌ 网络请求失败: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"网络错误"];
                [SVProgressHUD dismissWithDelay:2];
            });
            return;
        }
        
        NSError *parseError;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError) {
            NSLog(@"❌ JSON解析失败: %@", parseError);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"解析错误"];
                [SVProgressHUD dismissWithDelay:2];
            });
            return;
        }
        
        NSInteger code = [responseDict[@"code"] integerValue];
        NSString *msg = responseDict[@"msg"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == 200) {
                [SVProgressHUD showSuccessWithStatus:@"登录成功"];
                // 发送登录成功通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccessNotification" object:nil];
            } else {
                NSString *errorMsg = msg ?: @"登录失败";
                [SVProgressHUD showErrorWithStatus:errorMsg];
            }
            [SVProgressHUD dismissWithDelay:1.5];
        });
    }];
    
    [task resume];
}

/**
 * 获取当前显示的视图控制器
 * @return 当前最顶层的视图控制器
 */
+ (UIViewController *)topViewController {
    UIViewController *resultVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (resultVC.presentedViewController) {
        resultVC = resultVC.presentedViewController;
    }
    if ([resultVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navVC = (UINavigationController *)resultVC;
        resultVC = navVC.visibleViewController;
    }
    return resultVC;
}




#pragma mark - 工具


/**
 * 从URL字符串中提取指定key的值
 * @param urlString 完整的URL字符串
 * @param key 要提取的参数名
 * @return 参数值，如果不存在返回nil
 */
+ (nullable NSString *)getValueFromURLString:(NSString *)urlString key:(NSString *)key {
    if (!urlString || !key || urlString.length == 0 || key.length == 0) {
        return nil;
    }

    // 1. 尝试转成 URL
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return nil;
    }

    // 2. 用你已有的解析方法解析参数
    NSDictionary *params = [self parseURLQueryString:url.query];
    return params[key];
}

+ (NSDictionary *)parseURLQueryString:(NSString *)queryString {
    NSMutableDictionary *dict = NSMutableDictionary.dictionary;
    if (!queryString) return dict;
    for (NSString *part in [queryString componentsSeparatedByString:@"&"]) {
        NSArray *kv = [part componentsSeparatedByString:@"="];
        if (kv.count == 2) {
            NSString *k = [kv[0] stringByRemovingPercentEncoding];
            NSString *v = [kv[1] stringByRemovingPercentEncoding];
            if (k && v) dict[k] = v;
        }
    }
    return dict;
}




@end
