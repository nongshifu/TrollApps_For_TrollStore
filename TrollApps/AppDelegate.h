//
//  AppDelegate.h
//  CustomTabBarProduct
//
//  Created by iMac-1 on 2019/4/26.
//

#import <UIKit/UIKit.h>
#import <LGSideMenuController/LGSideMenuController.h>
#import <RongIMKit/RongIMKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,RCIMClientReceiveMessageDelegate,RCIMUserInfoDataSource>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) LGSideMenuController *sideMenuController;
@end

