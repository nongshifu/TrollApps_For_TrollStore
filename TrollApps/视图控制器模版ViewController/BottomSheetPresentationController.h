//
//  BottomSheetPresentationController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseBottomSheetVC.h"
NS_ASSUME_NONNULL_BEGIN

@interface BottomSheetPresentationController : UIPresentationController<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *dimmingView; // 背景遮罩
@property (nonatomic, weak) id<UIAdaptivePresentationControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
