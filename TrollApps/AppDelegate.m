//
//  AppDelegate.m
//  CustomTabBarProduct
//
//
#import "AppDelegate.h"

#import "loadData.h"
#import "config.h"
#import "UserModel.h"
#import "ToolMessage.h"
#import "ToolMessageCell.h"
#import "DownloadManagerViewController.h"
#import "NewProfileViewController.h"
#import "ShowOneAppViewController.h"
#import "UserProfileViewController.h"
#import "PaymentManager.h"
#import "ShowOneOrderViewController.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED NO // .M当前文件单独启用
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // 检查启动参数中是否有文件URL（如通过文件导入启动）
    NSURL *launchURL = launchOptions[UIApplicationLaunchOptionsURLKey];
    if (launchURL) {
        NSString *inboxDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Inbox"];
        if ([launchURL.path hasPrefix:inboxDir]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showDownloadManagerWithDir:inboxDir];
            });
        }
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.tabBarController = [[MyTabBarController alloc] init];
    self.sideMenuController = [[LGSideMenuController alloc] initWithRootViewController:self.tabBarController leftViewController:nil rightViewController:nil];
    
    self.window.rootViewController = self.sideMenuController;
    
    self.window.backgroundColor = [UIColor systemBackgroundColor];
    
    [self.window setRandomGradientBackgroundWithColorCount:3 alpha:0.05];
    
    [self.window addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleDark UIBlurEffectAlpha:0.99 ballalpha:0.5];
    
    
    [self.window makeKeyAndVisible];
    [self createRongIM];
    [loadData sharedInstance];
    
    
    return YES;
}

#pragma mark - 融云相关
//初始化融云
- (void)createRongIM{
    NSString *appKey = @"mgb7ka1nmog3g"; // example: bos9p5rlcm2ba
    RCInitOption *initOption = nil;
    [[RCCoreClient sharedCoreClient] initWithAppKey:appKey option:initOption];
    [RCCoreClient sharedCoreClient].logLevel = RC_Log_Level_Error;
    //设为选择媒体资源时包含视频文件
    RCKitConfigCenter.message.isMediaSelectorContainVideo = YES;
    //设为选择媒体资源时包含视频文件
    RCKitConfigCenter.message.isMediaSelectorContainVideo = YES;
    //视频时长最长120秒
    RCKitConfigCenter.message.sightRecordMaxDuration =120;
    //启用输入状态监听
    RCKitConfigCenter.message.enableTypingStatus = YES;
    //是否开启多端同步未读状态的功能，默认值是 YES
    RCKitConfigCenter.message.enableSyncReadStatus = YES;
    RCKitConfigCenter.message.showUnkownMessage = YES;
    RCKitConfigCenter.message.showUnkownMessageNotificaiton = YES;
    /// 是否开启消息@提醒功能（只支持群聊和讨论组, App需要实现群成员数据源groupMemberDataSource），默认值是 YES。
    RCKitConfigCenter.message.enableMessageMentioned = YES;
    /// 是否开启消息撤回功能，默认值是 YES。
    RCKitConfigCenter.message.enableMessageRecall = YES;
    //消息可撤回的最大时长（秒）
    RCKitConfigCenter.message.maxRecallDuration = 120;
    //是否支持选择相机视频
    RCKitConfigCenter.message.isMediaSelectorContainVideo = YES;
    /// 是否开启合并转发功能，默认值是NO，开启之后可以合并转发消息(目前只支持单聊和群聊)
    RCKitConfigCenter.message.enableSendCombineMessage = YES;
    /// 消息撤回后可重新编辑的时间，单位是秒，默认值是 300s。
    RCKitConfigCenter.message.reeditDuration = 60;
    //关闭本地通知声音
    RCKitConfigCenter.message.disableMessageAlertSound = NO;
    //是否禁用本地通知
    RCKitConfigCenter.message.disableMessageNotificaiton = NO;
    //阅后既焚功能
    RCKitConfigCenter.message.enableDestructMessage =YES;
    
    
    //头像显示默认为矩形，可修改为圆角显示。
    RCKitConfigCenter.ui.globalMessageAvatarStyle = RC_USER_AVATAR_CYCLE;
    RCKitConfigCenter.ui.globalConversationAvatarStyle = RC_USER_AVATAR_CYCLE;
    // 二级标题，默认 fontSize 为 17 (文本消息，引用消息内容，会话列表 title)
    RCKitConfigCenter.font.secondLevel = 20;
    RCKitConfigCenter.ui.enableDarkMode = YES;
    //适配主题色
    RCKitConfigCenter.ui.enableDarkMode = YES;
    //头像大小
    RCKitConfigCenter.ui.globalConversationPortraitSize = CGSizeMake(48, 48);
    //导航颜色
    RCKitConfigCenter.ui.globalNavigationBarTintColor = [UIColor labelColor];
    //设置会话类型默认标题
    RCKitConfigCenter.ui.globalConversationCollectionTitleDic = @{
//        @(ConversationType_PRIVATE): @"私信",
        @(ConversationType_SYSTEM): @"系统消息",
        @(ConversationType_CUSTOMERSERVICE): @"官方客服消息",
        @(ConversationType_PUSHSERVICE): @"推送服务消息",
        
    };
    
    // 二级标题，默认 fontSize 为 17 (文本消息，引用消息内容，会话列表 title)
    RCKitConfigCenter.font.secondLevel = 15;
    
    [RCCoreClient sharedCoreClient].logLevel = RC_Log_Level_Info;
    
    //接受消息代理
    [[RCCoreClient sharedCoreClient] addReceiveMessageDelegate:self];
    
    //启用用户信息托管
    //设置用户信息托管
    [RCIM sharedRCIM].userInfoDataSource = self;
    //启用用户信息托管
    [RCIM sharedRCIM].currentDataSourceType = RCDataSourceTypeInfoManagement;
    //发送消息携带用户信息
    [RCIM sharedRCIM].enableMessageAttachUserInfo = YES;
    //是否持久化缓存用户信息缓存
    [RCIM sharedRCIM].enablePersistentUserInfoCache = YES;
    //用户信息代理
    [RCIM sharedRCIM].userInfoDataSource = self;
    //注册自定义消息类型
    [[RCIM sharedRCIM] registerMessageType:[ToolMessage class]];

}

- (void)getUserInfoWithUserId:(NSString *)userId completion:(void(^)(RCUserInfo *userInfo))completion {
    //开发者调自己的服务器接口，根据 userID 异步请求用户信息
    NSLog(@"读取用户信息：%@",userId);
   
    [UserModel getUserInfoWithUserId:userId success:^(UserModel * _Nonnull userModel) {
        NSLog(@"读取用户信息：%@",userModel);
        if(userModel){
            
            
            NSString *avaurl = userModel.avatar;
            if(![avaurl containsString:@"http"]){
                avaurl = [NSString stringWithFormat:@"%@/%@",localURL,userModel.avatar];
            }
            NSLog(@"读取用户信息avaurl：%@",avaurl);
            RCUserInfo *userInfo = [[RCUserInfo alloc] initWithUserId:userId name:userModel.nickname portrait:avaurl];
            [[RCIM sharedRCIM] refreshUserInfoCache:userInfo withUserId:userId];
            if(userInfo){
                NSDictionary *userDic = [userModel yy_modelToJSONObject];
                if(userDic){
                    userInfo.extra = [userDic yy_modelToJSONString];
                }
                return completion(userInfo);
            }
        }
    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        return completion(nil);
    }];
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - 接收消息后
- (void)onReceived:(RCMessage *)message left:(int)left object:(id)object {
    NSLog(@"列表界面onReceived收到消息extra:%@",message.content.senderUserInfo.extra);
    if(left ==0){
        [self getTotalUnreadCount];
    }
    
    
}

- (void)getTotalUnreadCount{
    
    
    [[RCCoreClient sharedCoreClient] getTotalUnreadCountWith:^(int unreadCount) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"读取未读消息:%d",unreadCount);
            NSInteger targetTabIndex = 3; // 和上面的Tab索引保持一致
            if(unreadCount > 0){
                
                if (!self.tabBarController) return; // 防止空指针
                
                // 3. 关键：获取要设置红点的Tab（根据你的项目调整索引，例如：0=首页，1=聊天，2=我的）
                
                if (self.tabBarController.tabBar.items.count <= targetTabIndex) return; // 避免数组越界
                UITabBarItem *chatTabItem = self.tabBarController.tabBar.items[targetTabIndex];
                
                // 4. 设置系统红点（带未读数字，超过99显示“99+”）
                NSString *badgeText = (unreadCount > 99) ? @"99+" : [NSString stringWithFormat:@"%d", unreadCount];
                chatTabItem.badgeValue = badgeText;
                // 可选：自定义徽章颜色（默认红色，可改为其他色）
                chatTabItem.badgeColor = [UIColor redColor];
                
            } else {
                // 未读数量为0时，清除红点（需对应上面的Tab索引）
                
                if (!self.tabBarController) return;
                
                
                if (self.tabBarController.tabBar.items.count <= targetTabIndex) return;
                UITabBarItem *chatTabItem = self.tabBarController.tabBar.items[targetTabIndex];
                chatTabItem.badgeValue = nil; // 清除红点
            }
        });
    }];

}


// 1. 处理通过URL唤醒应用（文件导入+URL参数传递回调）
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSLog(@"openURL 被调用:%@", url.absoluteString);
    
    // 分支1：处理 URL 参数传递（如 udid、user_id 等，格式：TrollApps://?udid=xxx&user_id=xxx）
    if ([url.absoluteString containsString:@"getUdid"] && url.query) {
        // 解析 URL 查询参数（udid、user_id、token、status）
        NSDictionary *queryParams = [self parseURLQueryString:url.query];
        NSString *udid = queryParams[@"udid"];
        
        // 判断 udid 是否存在且有效
        if (udid && udid.length > 5) {
            NSLog(@"解析到有效 udid：%@，开始存储本地", udid);
            [KeychainTool saveString:udid forKey:TROLLAPPS_SAVE_UDID_KEY];
            
            [[NewProfileViewController sharedInstance] loadUserInfo];
            
            // 可选：提示用户登录成功
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"登录信息已同步"];
                [SVProgressHUD dismissWithDelay:1.5];
            });
        } else {
            NSLog(@"URL 中未包含有效 udid");
        }
    }
    // 分支2：原有逻辑 - 处理文件导入（Inbox 目录文件）
    else if ([url.path containsString:@"/Documents/Inbox/"]) {
        NSString *inboxDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Inbox"];
        // 延迟0.5秒（确保应用完全唤醒），再弹出控制器
        NSLog(@"解析到文件路径，弹出文件管理控制器");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showDownloadManagerWithDir:inboxDir];
        });
    }
    // 分支3：其他 URL 类型（忽略或提示）
    else if ([url.absoluteString containsString:@"openOneApp"] && url.query) {
        // 解析 URL 查询参数（udid、user_id、token、status）
        NSDictionary *queryParams = [self parseURLQueryString:url.query];
        NSString *appId = queryParams[@"appId"];
        NSLog(@"解析到 appId：%@", appId);
        // 判断 udid 是否存在且有效
        if (appId && [appId integerValue] > 0) {
            NSInteger app_id = [appId integerValue];
            NSLog(@"解析到有效 appId：%ld", app_id);
            ShowOneAppViewController *vc = [ShowOneAppViewController new];
            vc.app_id = app_id;
            [[vc.view getTopViewController] presentPanModal:vc];
        } else {
            NSLog(@"URL 中未包含有效 appId");
        }
    }
    // 分支4：其他 URL 类型（忽略或提示）
    else if ([url.absoluteString containsString:@"openOneUser"] && url.query) {
        // 解析 URL 查询参数（udid、user_id、token、status）
        NSDictionary *queryParams = [self parseURLQueryString:url.query];
        NSString *user_udid = queryParams[@"user_udid"];
        
        // 判断 udid 是否存在且有效
        if (user_udid && user_udid.length > 0) {
            
            NSLog(@"解析到有效 user_udid：%@", user_udid);
            UserProfileViewController *vc = [UserProfileViewController new];
            vc.user_udid = user_udid;
            [[vc.view getTopViewController] presentPanModal:vc];
        } else {
            NSLog(@"URL 中未包含有效 appId");
        }
    }else if([url.absoluteString containsString:@"trollapps://package/select"]){
        NSDictionary *queryParams = [self parseURLQueryString:url.query];
        NSString *mch_orderid = queryParams[@"mch_orderid"];
        ShowOneOrderViewController *vc = [ShowOneOrderViewController new];
        vc.targetOrderNo = mch_orderid;
        [[self getTopViewController] presentViewController:vc animated:YES completion:nil];
    }
    else {
        NSLog(@"未识别的 URL 类型：%@", url.absoluteString);
    }
    
    return YES;
}

#pragma mark - 辅助方法：解析 URL 查询参数（如 ?udid=xxx&user_id=xxx 转为字典）
- (NSDictionary *)parseURLQueryString:(NSString *)queryString {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (!queryString || queryString.length == 0) return params;
    
    // 分割 & 符号（多个参数）
    NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
    for (NSString *component in queryComponents) {
        // 分割 = 符号（键值对）
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            NSString *key = [keyValue[0] stringByRemovingPercentEncoding]; // 处理 URL 编码（如空格、特殊字符）
            NSString *value = [keyValue[1] stringByRemovingPercentEncoding];
            if (key && value) {
                params[key] = value;
            }
        }
    }
    return params;
}

#pragma mark - 辅助方法：持久化存储用户信息（根据你项目的模型调整字段）
- (void)saveUserInfoToLocal:(UserModel *)userInfo {
    if (!userInfo) return;
    
    // 方案1：用 NSUserDefaults 存储（简单高效，适合少量信息）
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (userInfo.udid) [defaults setObject:userInfo.udid forKey:@"kUserUDID"];
    if (userInfo.user_id > 0) [defaults setInteger:userInfo.user_id forKey:@"kUserID"];
    if (userInfo.token) [defaults setObject:userInfo.token forKey:@"kUserToken"];
    [defaults synchronize]; // 强制同步（确保立即存储）
    
    // 方案2：如果你的 UserModel 支持归档（yy_model、NSCoding），可存储整个模型（推荐）
    // 示例（yy_model 归档）：
    // NSString *userInfoJSON = [userInfo yy_modelToJSONString];
    // [defaults setObject:userInfoJSON forKey:@"kUserInfo"];
    // [defaults synchronize];
    
    NSLog(@"用户信息已持久化存储：udid=%@, user_id=%ld, token=%@", userInfo.udid, userInfo.user_id, userInfo.token);
}


// 3. 通用方法：弹出DownloadManagerViewController并切换目录
- (void)showDownloadManagerWithDir:(NSString *)dirPath {
    DownloadManagerViewController *dmVC = [DownloadManagerViewController sharedInstance];
    [dmVC switchToDirectory:dirPath];
    
    // 获取当前顶层控制器（适配导航栏/标签栏结构）
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    // 避免重复弹窗
    if (![topVC isKindOfClass:[DownloadManagerViewController class]]) {
        [topVC presentViewController:dmVC animated:YES completion:nil];
    }
}

#pragma mark - 获取顶层控制器（保留，用于弹框提示）
- (UIViewController *)getTopViewController {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}
@end
