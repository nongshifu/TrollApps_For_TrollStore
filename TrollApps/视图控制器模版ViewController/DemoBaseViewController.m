//
//  DemoBaseViewController.m
//  ZXNavigationBarDemo
//
//  Created by 李兆祥 on 2020/3/10.
//  Copyright © 2020 ZXLee. All rights reserved.
//


#import "DemoBaseViewController.h"
#import "Config.h"


@interface DemoBaseViewController ()

@end

@implementation DemoBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewIsGradientBackground = YES;
    // 设置背景颜色和透明度
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    //获取根控制器的IGSide对象
    self.rootSideMenuController = [self getRootLGSideMenuController];;
    //获当前控制器的IGSide对象
    self.sideMenuController = [self getLGSideMenuController];
    self.viewHeight = self.longFormHeight.height;
    // 主题发生了变化，进行相应处理
    self.zx_navBarBackgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.96];
    self.zx_navTintColor = [UIColor labelColor];
    self.zx_navStatusBarStyle = ZXNavStatusBarStyleDefault;
    self.zx_showNavHistoryStackContentView = YES;
    [self zx_setNavGradientBacFrom:[UIColor randomColorWithAlpha:0.3] to:[UIColor randomColorWithAlpha:0.3]];
    
    [self setBackgroundUI];
    [self topBackageView];
    
    // 获取 identifierForVendor
    self.idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    
    // 创建一个UITapGestureRecognizer
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardHide:)];
    // 设置成NO表示当前控件响应后会传播到其他控件上，默认为YES。
    self.tapGesture.cancelsTouchesInView = NO;
    // 将触摸事件添加到当前view
    [self.view addGestureRecognizer:self.tapGesture];
    
    //系统导航遮挡问题
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    
    
}

// 隐藏键盘的方法
- (void)keyboardHide:(UITapGestureRecognizer *)tap {
    if(_isTapViewToHideKeyboard){
        [self.view endEditing:YES];
    }
    
}

- (void)setIsTapViewToHideKeyboard:(BOOL)enableTapToHideKeyboard{
    _isTapViewToHideKeyboard = enableTapToHideKeyboard;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    NSLog(@"拖拽后视图高度:%f",self.viewHeight);
}

// 键盘隐藏和现实
- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    self.keyboardIsShow = NO;
    [self updateViewConstraints];
    NSLog(@"键盘隐藏");
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    self.keyboardHeight = keyboardHeight;
    self.keyboardIsShow = YES;
    [self updateViewConstraints];
    NSLog(@"键盘打开");
}

- (void)dealloc {
    // 移除通知观察者
    [[NSNotificationCenter defaultCenter] removeObserver:UIKeyboardWillShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIKeyboardWillHideNotification];
    
    
}

- (LGSideMenuController *)getLGSideMenuController {
    UIViewController *currentVC = self;
    while (currentVC) {
        if ([currentVC isKindOfClass:[LGSideMenuController class]]) {
            return (LGSideMenuController *)currentVC;
        }
        currentVC = currentVC.parentViewController;
    }
    return nil;
}

- (LGSideMenuController *)getRootLGSideMenuController {
    //设置回调
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    LGSideMenuController *LGSideMenu = (LGSideMenuController*)appDelegate.sideMenuController;
    if(LGSideMenu)return LGSideMenu;
    return nil;
}

#pragma mark - HWPanModalPresentable

- (PanModalHeight)longFormHeight {
    return PanModalHeightMake(PanModalHeightTypeContent, kHeight-150);
}

- (PanModalHeight)mediumFormHeight {
    return PanModalHeightMake(PanModalHeightTypeContent, 450);
}

- (PanModalHeight)shortFormHeight {
    return PanModalHeightMake(PanModalHeightTypeContent, 250);
}

- (PresentationState)originPresentationState {
    return PresentationStateLong;
}


- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取手势的位置
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
//    if (CGRectContainsPoint(self.collectionView.frame, loc)) {
//        return NO;
//    }
    // 遍历所有子视图，检查手势是否发生在滚动视图上
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]] && CGRectContainsPoint(subview.frame, loc)) {
            // 如果手势发生在滚动视图上，返回 NO，禁止拖拽
            
            return NO;
        }
    }

    // 默认返回 YES，允许拖拽
    return YES;
}

- (void)willRespondToPanModalGestureRecognizer:(nonnull UIPanGestureRecognizer *)panGestureRecognizer{
    NSLog(@"拖拽过程视图高度:%f",self.bottomYPos);
//    [UIView animateWithDuration:0.3 animations:^{
//        self.inputBoxView.alpha = 0;
//    }];
}

- (void)didEndRespondToPanModalGestureRecognizer:(nonnull UIPanGestureRecognizer *)panGestureRecognizer{
    
    if(self.hw_presentationState ==0){
        self.viewHeight = self.shortFormHeight.height;
    }else if(self.hw_presentationState ==1){
        self.viewHeight = self.mediumFormHeight.height;
    }else if(self.hw_presentationState ==2){
        self.viewHeight = self.longFormHeight.height;
    }
    [self updateViewConstraints];
    
   
}

//隐藏显示指示器
- (BOOL)showDragIndicator{
    return YES;
}

//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return YES;
}

//侧滑手势
- (BOOL)allowScreenEdgeInteractive{
    return YES;
}


//震动
+ (void)triggerVibration{
    // 创建UIImpactFeedbackGenerator对象
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    // 准备触发震动
    [generator prepare];
    
    // 触发震动
    [generator impactOccurred];
    // 释放UIImpactFeedbackGenerator对象
    generator = nil;
}

///累计更新红点
- (void)updateTabBarBadgeValueWithMessageCount:(NSInteger)messageCount atTabIndex:(NSInteger)tabIndex {
    UITabBarController *tabBarController = (UITabBarController *)self.navigationController.parentViewController;

    if (tabBarController) {
        UITabBar *tabBar = tabBarController.tabBar;
        UITabBarItem *item = [tabBar.items objectAtIndex:tabIndex];

        NSInteger currentCount = [item.badgeValue integerValue];
        NSInteger newCount = currentCount + messageCount;

        if (newCount < 0) {
            newCount = 0;
        } else if (newCount > 999) {
            newCount = 999;
        }

        if (newCount == 0) {
            item.badgeValue = nil;
        } else {
            item.badgeValue = [NSString stringWithFormat:@"%ld", (long)newCount];
        }
    }
}

///重设红点
- (void)setTabBarBadgeValueWithMessageCount:(NSInteger)messageCount atTabIndex:(NSInteger)tabIndex {
    UITabBarController *tabBarController = (UITabBarController *)self.navigationController.parentViewController;

    if (tabBarController) {
        UITabBar *tabBar = tabBarController.tabBar;
        UITabBarItem *item = [tabBar.items objectAtIndex:tabIndex];
        if (messageCount == 0) {
            item.badgeValue = nil;
        } else {
            item.badgeValue = [NSString stringWithFormat:@"%ld", (long)messageCount];
        }
       
    }
}

///设置红点文字
- (void)setTabBarBadgeValueWithMessageText:(NSString *)message atTabIndex:(NSInteger)tabIndex {
    UITabBarController *tabBarController = (UITabBarController *)self.navigationController.parentViewController;

    if (tabBarController) {
        UITabBar *tabBar = tabBarController.tabBar;
        UITabBarItem *item = [tabBar.items objectAtIndex:tabIndex];
        if (message == nil || [message isEqualToString:@""]) {
            item.badgeValue = nil;
        } else {
            item.badgeValue = message;
        }
    }
}

- (void)setViewIsGradientBackground:(BOOL)viewIsGradientBackground{
    _viewIsGradientBackground = viewIsGradientBackground;
}

- (void)topBackageView{
    
    //创建一个空视图渐变色
    self.gradientNavigationView =[[UIView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, 110)];
    self.gradientNavigationView.backgroundColor = [UIColor systemBackgroundColor];
    
    
    // 添加浮动小球
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        NSLog(@"切换到暗色模式");
        
        [self.gradientNavigationView addColorBallsWithCount:5 ballradius:150 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleDark UIBlurEffectAlpha:0.99 ballalpha:0.05];
        [self.gradientNavigationView setRandomGradientBackgroundWithColorCount:3 alpha:0.05];
    } else {
        NSLog(@"切换到亮色模式");
        
        [self.gradientNavigationView addColorBallsWithCount:15 ballradius:150 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleLight UIBlurEffectAlpha:0.99 ballalpha:0.02];
        [self.gradientNavigationView setRandomGradientBackgroundWithColorCount:3 alpha:0.15];
    }
    
    
    UIImage *image = [UIView convertViewToPNG:self.gradientNavigationView];
    
    //先判断下系统
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        appearance.backgroundImage = image;
        appearance.shadowImage = [UIImage new];
        appearance.shadowColor = nil;
        
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;
        
    }else{
        //顶部背景图
        [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        //清除分割线
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    }


}

- (void)setBackgroundUI {
    
    // 在其他类中
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIWindow *rootWindow = appDelegate.window;
    

    // 设置背景颜色和透明度
    
    rootWindow.backgroundColor = [UIColor systemBackgroundColor];
    
    // 添加浮动小球
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        NSLog(@"切换到暗色模式");
        if(self.viewIsGradientBackground){
            self.view.backgroundColor = [UIColor systemBackgroundColor];
            [self.view setRandomGradientBackgroundWithColorCount:3 alpha:0.05];
            [self.view addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleDark UIBlurEffectAlpha:0.99 ballalpha:0.5];
        }
        
    
        [rootWindow setRandomGradientBackgroundWithColorCount:3 alpha:0.05];
        [rootWindow addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleDark UIBlurEffectAlpha:0.99 ballalpha:0.3];
        
        
    } else {
        NSLog(@"切换到亮色模式");
        if(self.viewIsGradientBackground){
            self.view.backgroundColor = [UIColor systemBackgroundColor];
            [self.view setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
            [self.view addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleLight UIBlurEffectAlpha:0.99 ballalpha:0.3];
        }
        
    
        [rootWindow setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
        [rootWindow addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleLight UIBlurEffectAlpha:0.99 ballalpha:0.3];
    }
    
    
    
}

- (BOOL)isDarkMode {
    return self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    

    //是否禁用跟随主题修改背景色
    if(self.disableFollowingBackgroundColor) return;
    
    
    NSLog(@"界面模式发生变化");
    [self topBackageView];
    
    
    [self setBackgroundUI];
}


/// 兼容所有弹出方式的关闭函数
- (void)dismiss {
    // 1. 判断是否是HWPanModal弹出
    if ([self isPresentedByHWPanModal]) {
        NSLog(@"HWPanModal关闭：调用框架自带的关闭方法");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    // 2. 判断是否是系统模态弹出（关键修改点）
    else if (self.presentingViewController) {
        // 无论是否在导航栈中，只要是被模态弹出的，都用dismiss关闭
        NSLog(@"系统模态关闭：dismiss");
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    // 3. 系统push（在导航栈中且未被模态弹出）
    else if (self.navigationController) {
        NSLog(@"系统push关闭：pop返回上一页");
        [self.navigationController popViewControllerAnimated:YES];
        
    }
}

/**
 判断当前控制器是否由 HWPanModal 框架呈现
 @return YES: 通过 HWPanModal 呈现; NO: 系统默认方式呈现
 */
- (BOOL)isPresentedByHWPanModal {
    // 1. 排除非模态呈现（如 push 方式）
    if (self.presentingViewController == nil) {
        return NO;
    }
    
    // 2. 检查 presentationController 是否为 HWPanModalPresentationController 或子类
    UIPresentationController *presentationController = self.presentationController;
    if ([presentationController isKindOfClass:[NSClassFromString(@"HWPanModalPresentationController") class]]) {
        return YES;
    }
    
    // 3. 尝试通过私有方法获取 HWPanModal 控制器（兼容旧版本）
    if ([self respondsToSelector:@selector(hw_presentedVC)]) {
        id hwController = [self performSelector:@selector(hw_presentedVC)];
        if (hwController && [hwController isKindOfClass:[NSClassFromString(@"HWPanModalPresentationController") class]]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)showAlertFromViewController:(UIViewController *)viewController
                                  title:(NSString *)title
                                message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertWithConfirmationFromViewController:(UIViewController *)viewController
                                              title:(NSString *)title
                                            message:(NSString *)message
                                       confirmTitle:(NSString *)confirmTitle
                                        cancelTitle:(NSString *)cancelTitle
                                        onConfirmed:(void (^)(void))onConfirm
                                         onCancelled:(void (^)(void))onCancel {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
    if(confirmTitle){
        [alert addAction:[UIAlertAction actionWithTitle:confirmTitle
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            if (onConfirm) {
                onConfirm();
            }
        }]];
    }
    if(cancelTitle){
        [alert addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
            if (onCancel) {
                onCancel();
            }
        }]];
    }
    
    
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

// 获取视图所属的视图控制器的方法
- (UIViewController *)getviewController {
    UIResponder *nextResponder = self;
    while (nextResponder != nil) {
        nextResponder = nextResponder.nextResponder;
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

@end
