//
//  AppDelegate.m
//  CustomTabBarProduct
//
//
#import "AppDelegate.h"
#import "MyTabBarController.h"
#import "loadData.h"
#import "config.h"
#import "UserModel.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    MyTabBarController *tabBar = [[MyTabBarController alloc] init];
    self.sideMenuController = [[LGSideMenuController alloc] initWithRootViewController:tabBar leftViewController:nil rightViewController:nil];
    
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
    RCKitConfigCenter.message.disableMessageAlertSound = YES;
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
    

}
- (void)getUserInfoWithUserId:(NSString *)userId completion:(void(^)(RCUserInfo *userInfo))completion {
    //开发者调自己的服务器接口，根据 userID 异步请求用户信息
    NSLog(@"读取用户信息：%@",userId);
   
    [UserModel getUserInfoWithUserId:userId success:^(UserModel * _Nonnull userModel) {
        NSLog(@"读取用户信息：%@",userModel);
        if(userModel){
            
            NSString *avaurl = [NSString stringWithFormat:@"%@/%@?time=%ld",localURL,userModel.avatar,(long)[NSDate date].timeIntervalSince1970];
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


@end
