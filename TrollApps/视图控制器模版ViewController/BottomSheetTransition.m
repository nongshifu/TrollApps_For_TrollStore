//
//  BottomSheetTransition.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "BottomSheetTransition.h"
#import "BaseBottomSheetVC.h"
#import "BottomSheetPresentationController.h"

@implementation BottomSheetTransition

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *containerView = transitionContext.containerView;
    
    // 使用安全的屏幕 bounds 获取方式（兼容横竖屏和分屏）
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat screenHeight = screenBounds.size.height;
    
    if (self.isPresenting) {
        [containerView addSubview:toVC.view];
        BaseBottomSheetVC *sheetVC = (BaseBottomSheetVC *)toVC;
        
        // 初始位置（屏幕底部外侧）
        CGFloat height = [sheetVC heightForPosition:sheetVC.currentPosition];
        // 创建可变的 frame 副本
        CGRect targetFrame = CGRectMake(0, screenHeight, containerView.bounds.size.width, height);
        toVC.view.frame = targetFrame;
        
        // 动画到目标位置
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.5
                            options:0
                         animations:^{
            // 修改 frame 时先创建新的 CGRect
            toVC.view.frame = CGRectMake(
                0,
                screenHeight - height,  // 计算正确的 Y 坐标
                containerView.bounds.size.width,
                height
            );
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    } else {
        // 消失动画
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            // 同样通过创建新 CGRect 来修改位置
            fromVC.view.frame = CGRectMake(
                0,
                screenHeight,  // 滑到屏幕底部外侧
                fromVC.view.bounds.size.width,
                fromVC.view.bounds.size.height
            );
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }
}

@end
