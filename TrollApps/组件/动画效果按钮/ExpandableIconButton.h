//
//  ExpandableIconButton.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ButtonStateTapBlock)(BOOL isExpanded);

@interface ExpandableIconButton : UIView
/// 父容器视图
@property (nonatomic, strong) UIView *containerView;
/// 图标视图
@property (nonatomic, strong) UIImageView *iconImageView;
/// 标题标签
@property (nonatomic, strong) UILabel *titleLabel;
/// 图标图片
@property (nonatomic, strong) UIImage *iconImage;

/// 标题下的子视图容器视图
@property (nonatomic, strong) UIStackView *subViewContainerView;

/// 标题文本
@property (nonatomic, strong) NSString *title;
/// 背景颜色
@property (nonatomic, strong) UIColor *containerViewbackgroundColor;
/// 容器圆角半径 （如果不设置 (默认为跟随头像大小+totalPadding内内边距)/2  既缩小的时候为圆形图标）
@property (nonatomic, assign) CGFloat cornerRadius;
/// 图标和顶部左侧距离(默认 5)
@property (nonatomic, assign) CGFloat iconToTopInterval;
/// 图标圆角半径 （如果不设置 (默认为跟随头像大小/2  既缩圆形图标）
@property (nonatomic, assign) CGFloat iconRadius;
/// 动画持续时间（默认0.4秒）
@property (nonatomic, assign) CGFloat animationDuration;
/// 展开显示多少时间自动缩小(默认3秒)
@property (nonatomic, assign) CGFloat expandedShowDuration;
/// 当前是否展开状态
@property (nonatomic, assign) BOOL isExpanded;
/// 图标大小
@property (nonatomic, assign) CGFloat iconSize;
/// 文字最大宽度（默认300 *200）
@property (nonatomic, assign) CGSize titleMaxSize;


//是否圆形图标
@property (nonatomic, assign) BOOL isCircle;
/// 总内边距（默认10）
@property (nonatomic, assign) CGFloat totalPadding;
/// 展开状态下的点击回调
@property (nonatomic, copy) ButtonStateTapBlock didTapInExpandedState;
/// 非展开状态下的点击回调
@property (nonatomic, copy) ButtonStateTapBlock didTapInCollapsedState;
/// 展开完成回调
@property (nonatomic, copy) ButtonStateTapBlock didExpand;
/// 收缩完成回调
@property (nonatomic, copy) ButtonStateTapBlock didCollapse;
/// 是否允许拖动
@property (nonatomic, assign) BOOL isDraggable;
/// 是否允许旋转动画(默认YES)
@property (nonatomic, assign) BOOL rotatingAnimation;
/// 拖动手势
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
/// 开始拖动回调
@property (nonatomic, copy) void(^dragBeganBlock)(CGPoint location);
/// 拖动中回调
@property (nonatomic, copy) void(^draggingBlock)(CGPoint location);
/// 拖动结束回调
@property (nonatomic, copy) void(^dragEndedBlock)(CGPoint location);


/// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame icon:(UIImage *)icon title:(NSString *)title;

/// 手动触发展开/收缩
- (void)expand;
- (void)collapse;
- (void)toggleExpanded;

@end

NS_ASSUME_NONNULL_END
