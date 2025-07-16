//
//  Config.h
//  SoulChat
//
//  Created by 十三哥 on 2023/12/15.
// UIImageView+HXExtension

/*
获取顶部状态栏高度的宏 这个宏返回当前设备顶部状态栏的高度。通常在需要考虑顶部布局时使用，例如调整视图的位置以避免被状态栏遮挡。
 */
#define get_TOP_STATUS_BAR_HEIGHT ([[UIApplication sharedApplication] windows].firstObject.windowScene.statusBarManager.statusBarFrame.size.height)
/*
获取导航栏高度的宏（通常标准高度是44，但可以根据实际设置有所不同）注释：这个宏定义了一个标准的导航栏高度为 44.0，可根据实际设计进行调整。在布局中用于确定与导航栏相关的视图位置和大小。
 */
#define get_TOP_NAVIGATION_BAR_HEIGHT 44.0

/// 获取底部标签控制器高度
#define get_BOTTOM_TAB_BAR_HEIGHT \
({ \
    CGFloat _tabBarHeight = 0; \
    if ((self.tabBarController) && (self.tabBarController.tabBar) && (self.tabBarController.tabBar.isHidden == NO)) { \
        _tabBarHeight = self.tabBarController.tabBar.frame.size.height; \
    } \
    _tabBarHeight; \
})
/// 获取底部安全区域高度（包括底部栏，如果有）的宏  注释：这个宏返回设备底部安全区域的高度，主要用于处理 iPhone X 及后续设备的底部手势区域和可能存在的底部栏。确保视图在不同设备上正确布局，不会被底部区域遮挡。
#define get_BOTTOM_SAFE_AREA_HEIGHT ([[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0? [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom : 0)

//主域名
#define localURL @"https://niceiphone.com"

//系统组件
#import "AppDelegate.h"
#import <objc/runtime.h>
#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

//第三方开源库组件
#import <Masonry/Masonry.h>
#import <AFNetworking/AFNetworking.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <HWPanModal/HWPanModal.h>
#import <MJRefresh/MJRefresh.h>
#import <IGListKit/IGListKit.h>
#import <LGSideMenuController/LGSideMenuController.h>
#import <ZXingObjC/ZXingObjC.h>
#import <SDWebImage/SDWebImage.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>

//自开发组件
#import "TimeTool.h"
#import "UIView.h"
#import "UIColor.h"
#import "KeychainTool.h"
#import "TimeTool.h"
#import "NetworkClient.h"
#import "ExpandableIconButton.h"//旋转发布按钮
#import "UIImage+Extensions.h"

//第三方
#import "HXPhotoPicker.h"
#import "YYModel.h"
#import "HWPanModalPresentationController.h"
#import "Demo9Model.h"


NS_ASSUME_NONNULL_BEGIN

///整个屏幕
#define kScreen [UIScreen mainScreen]
///整个屏幕高度
#define kWidth  [UIScreen mainScreen].bounds.size.width
///整个屏幕宽度
#define kHeight [UIScreen mainScreen].bounds.size.height



@interface config : NSObject<UIViewControllerTransitioningDelegate>




@end


NS_ASSUME_NONNULL_END
