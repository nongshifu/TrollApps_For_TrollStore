//
//  DemoBaseNavigationController.m
//  NewSoulChat
//
//  Created by 十三哥 on 2025/3/23.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "DemoBaseNavigationController.h"
#import <HWPanModal/HWPanModal.h>
#import <Masonry/View+MASAdditions.h>

@interface DemoBaseNavigationController ()
@property (nonatomic, assign) BOOL allowEdgeInteractive; // 添加属性来存储是否允许左滑
@end

@implementation DemoBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor redColor];
}
#pragma mark - overridden to update panModal

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    [self hw_panModalSetNeedsLayoutUpdate];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *controller = [super popViewControllerAnimated:animated];
    [self hw_panModalSetNeedsLayoutUpdate];
    return controller;
}

- (NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *viewControllers = [super popToViewController:viewController animated:animated];
    [self hw_panModalSetNeedsLayoutUpdate];
    return viewControllers;
}

- (NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *viewControllers = [super popToRootViewControllerAnimated:animated];
    [self hw_panModalSetNeedsLayoutUpdate];
    return viewControllers;
}

#pragma mark - HWPanModalPresentable

- (CGFloat)topOffset {
    return 0;
}

- (NSTimeInterval)transitionDuration {
    return 0.4;
}

- (CGFloat)springDamping {
    return 1;
}

- (BOOL)shouldRoundTopCorners {
    return NO;
}

- (BOOL)showDragIndicator {
    return NO;
}

//允许左滑返回上一个diss
- (BOOL)allowScreenEdgeInteractive {
    return self.allowEdgeInteractive;
}

- (void)setAllowEdgeInteractive:(BOOL)allowEdgeInteractive {
    _allowEdgeInteractive = allowEdgeInteractive; // 使用 _allowEdgeInteractive 直接赋值，避免递归
}

- (CGFloat)maxAllowedDistanceToLeftScreenEdgeForPanInteraction {
    return 0;
}
- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    UIView *view  = panGestureRecognizer.view;
    if([view isKindOfClass:[UIScrollView class]] || [view isKindOfClass:[UITableView class]])return NO;
    

    // 默认返回 YES，允许拖拽
    return NO;
}

@end
