//
//  BaseBottomSheetVC.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BottomSheetTransition.h"
#import "BottomSheetPresentationController.h"

NS_ASSUME_NONNULL_BEGIN

/// 底部弹窗高度档位
typedef NS_ENUM(NSInteger, BottomSheetPosition) {
    BottomSheetPositionLow,    // 最低档位
    BottomSheetPositionMedium, // 中间档位
    BottomSheetPositionHigh    // 最高档位（默认）
};

@interface BaseBottomSheetVC : UIViewController

/// 当前弹窗高度（顶部到屏幕底部的距离）
@property (nonatomic, assign, readonly) CGFloat viewHeight;

/// 三档位高度配置（需子类重写或初始化时设置）
/// 最低档高度（默认 100pt）
@property (nonatomic, assign) CGFloat lowPositionHeight;
/// 中间档高度（默认 300pt）
@property (nonatomic, assign) CGFloat mediumPositionHeight;
/// 最高档高度（默认 屏幕高度的 3/4）
@property (nonatomic, assign) CGFloat highPositionHeight;


/// 是否允许侧滑右侧关闭（默认 YES）
@property (nonatomic, assign) BOOL allowRightSwipeDismiss;

/// 是否允许点击空白区域关闭（默认 YES）
@property (nonatomic, assign) BOOL allowTapDismiss;

/// 触摸滚动视图时是否禁用控制器拖动（默认 YES，避免与 tableView 等冲突）
@property (nonatomic, assign) BOOL disablePanOnScrollView;

/// 输入框获取焦点时是否自动上移（默认 YES，避免键盘遮挡）
@property (nonatomic, assign) BOOL autoAdjustForKeyboard;

/// 初始化方法
- (instancetype)initWithPositions:(CGFloat)low medium:(CGFloat)medium high:(CGFloat)high;

/// 手动切换到指定档位
- (void)switchToPosition:(BottomSheetPosition)position animated:(BOOL)animated;

- (CGFloat)heightForPosition:(BottomSheetPosition)position;

/// 转场动画管理器
@property (nonatomic, strong) BottomSheetTransition *transition;

/// 背景遮罩
@property (nonatomic, strong) UIView *dimmingView;
/// 当前位置
@property (nonatomic, assign) BottomSheetPosition currentPosition;
/// 初始触摸位置
@property (nonatomic, assign) CGPoint initialTouchPoint;
/// 键盘高度
@property (nonatomic, assign) CGFloat keyboardHeight;
@end

NS_ASSUME_NONNULL_END
