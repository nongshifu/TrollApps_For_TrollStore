//
//  AppDelegate.h
//  CustomTabBarProduct
//
//  Created by iMac-1 on 2019/4/26.
//

#import <UIKit/UIKit.h>
#import <LGSideMenuController/LGSideMenuController.h>
#import <RongIMKit/RongIMKit.h>
#import "MyTabBarController.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate,RCIMClientReceiveMessageDelegate,RCIMUserInfoDataSource>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) LGSideMenuController *sideMenuController;
// 暴露自定义TabBar控制器（MyTabBarController）
@property (nonatomic, strong) UITabBarController *tabBarController;
- (void)getTotalUnreadCount;
@end

