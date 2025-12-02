//
//  DemoBaseViewController.h
//  ZXNavigationBarDemo
//
//  Created by 李兆祥 on 2020/3/10.
//  Copyright © 2020 ZXLee. All rights reserved.
//

#import "ZXNavigationBarController.h"
#import "DemoBaseNavigationController.h"
#import "config.h"

#import <IGListKit/IGListKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface DemoBaseViewController : ZXNavigationBarController <HWPanModalPresentable>
///当前控制器的侧面控制器对象
@property (nonatomic, strong) LGSideMenuController *sideMenuController;
///app根导航控制器的侧面控制器对象
@property (nonatomic, strong) LGSideMenuController *rootSideMenuController;

///视图总高度
@property (nonatomic, assign) CGFloat viewHeight;
///是否禁用跟随主题修改背景色
@property (nonatomic, assign) BOOL disableFollowingBackgroundColor;
/// 是否允许点击视图隐藏键盘（默认NO）
@property (nonatomic, assign) BOOL isTapViewToHideKeyboard;
/// 点击手势识别器
@property (nonatomic, strong, nullable) UITapGestureRecognizer *tapGesture;
///键盘高度
@property (nonatomic, assign) CGFloat keyboardHeight;
///键盘是否打开
@property (nonatomic, assign) BOOL keyboardIsShow;
///idfv
@property (nonatomic, strong) NSString * idfv;
///是否使用渐变背景
@property (nonatomic, assign) BOOL viewIsGradientBackground;
///导航的渐变视图
@property (nonatomic, strong) UIView * gradientNavigationView;


///设置红点文字
- (void)setTabBarBadgeValueWithMessageText:(NSString *)message atTabIndex:(NSInteger)tabIndex;
///重设红点
- (void)setTabBarBadgeValueWithMessageCount:(NSInteger)messageCount atTabIndex:(NSInteger)tabIndex;
///累计更新红点
- (void)updateTabBarBadgeValueWithMessageCount:(NSInteger)messageCount atTabIndex:(NSInteger)tabIndex;
///设置导航背景色
- (void)topBackageView;
///设置视图背景色
- (void)setBackgroundUI;
///震动
+ (void)triggerVibration;
///约束视图高度
- (void)updateViewConstraints;
///显示悬浮菜单
- (void)showThemeSettingsMenu;
///主题变化时调用
- (void)themeDidChange;

///获取当前控制器的侧面控制器对象
- (LGSideMenuController *)getLGSideMenuController;
///获取APP根导航控制器的侧面控制器对象
- (LGSideMenuController *)getRootLGSideMenuController;

- (void)keyboardHide:(UITapGestureRecognizer *)tap;
///是否黑暗色
- (BOOL)isDarkMode;

- (void)dismiss;
/**
 判断当前控制器是否由 HWPanModal 框架呈现
 @return YES: 通过 HWPanModal 呈现; NO: 系统默认方式呈现
 */
- (BOOL)isPresentedByHWPanModal;
/**
 视图显示后会调用
 */
- (void)setupViewConstraints;

/// 显示基本警告框（带标题和消息）
- (void)showAlertFromViewController:(UIViewController *)viewController
                                  title:(NSString *)title
                                message:(NSString *)message;

/// 显示带确认回调的警告框
- (void)showAlertWithConfirmationFromViewController:(UIViewController *)viewController
                                              title:(NSString *)title
                                            message:(NSString *)message
                                       confirmTitle:(NSString * _Nullable)confirmTitle
                                        cancelTitle:(NSString * _Nullable)cancelTitle
                                        onConfirmed:(void (^)(void))onConfirm
                                        onCancelled:(void (^)(void))onCancel;
                                  
@end

NS_ASSUME_NONNULL_END
