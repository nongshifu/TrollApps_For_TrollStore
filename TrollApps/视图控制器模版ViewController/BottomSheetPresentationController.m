//
//  BottomSheetPresentationController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "BottomSheetPresentationController.h"

@implementation BottomSheetPresentationController


- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(nullable UIViewController *)presentingViewController {
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if (self) {
        
    }
    return self;
}


#pragma mark - 布局子视图
- (void)containerViewWillLayoutSubviews {
    [super containerViewWillLayoutSubviews];
    
    // 直接使用外部传递的 dimmingView（已带手势）
    if (self.dimmingView) {
        self.dimmingView.frame = self.containerView.bounds;
        // 打印遮罩信息
        NSLog(@"遮罩 frame: %@，是否在容器中: %@",
              NSStringFromCGRect(self.dimmingView.frame),
              [self.dimmingView.superview isEqual:self.containerView] ? @"是" : @"否");
    }
    
    // 底部弹窗布局（保持不变）
    BaseBottomSheetVC *sheetVC = (BaseBottomSheetVC *)self.presentedViewController;
    CGFloat targetHeight = [sheetVC heightForPosition:sheetVC.currentPosition];
    self.presentedView.frame = CGRectMake(
        0,
        self.containerView.bounds.size.height - targetHeight,
        self.containerView.bounds.size.width,
        targetHeight
    );
}


#pragma mark - 转场生命周期
- (void)presentationTransitionWillBegin {
    [super presentationTransitionWillBegin];
    
    // 添加外部传递的 dimmingView 到容器（已带手势）
    if (self.dimmingView && self.containerView) {
        [self.containerView insertSubview:self.dimmingView atIndex:0];
        
        
        // 遮罩渐显动画（与弹窗同步）
        id<UIViewControllerTransitionCoordinator> coordinator = self.presentingViewController.transitionCoordinator;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            self.dimmingView.alpha = 0.5; // 显示遮罩
        } completion:nil];
    }
}


- (void)dismissalTransitionWillBegin {
    [super dismissalTransitionWillBegin];
    
    // 遮罩渐隐动画
    id<UIViewControllerTransitionCoordinator> coordinator = self.presentingViewController.transitionCoordinator;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.dimmingView.alpha = 0.0; // 隐藏遮罩
    } completion:nil];
}

#pragma mark - 自适应布局（支持旋转）
- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    BaseBottomSheetVC *sheetVC = (BaseBottomSheetVC *)self.presentedViewController;
    return CGSizeMake(parentSize.width, [sheetVC heightForPosition:sheetVC.currentPosition]);
}

- (BOOL)shouldPresentInFullscreen {
    return NO; // 非全屏展示（允许看到背后的控制器）
}

@end
