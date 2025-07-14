// CustomContainerView.h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MiniButtonViewDelegate <NSObject>
///点击代理
- (void)buttonTappedWithTag:(NSInteger)tag title:(NSString *)title button:(UIButton*)button;
///长按代理
- (void)buttonLongPressedWithTag:(NSInteger)tag title:(NSString *)title button:(UIButton*)button;
///双击代理
- (void)buttonDoubleTappedWithTag:(NSInteger)tag title:(NSString *)title button:(UIButton*)button;
//开始滑动会触发这个代理
- (void)miniButtonViewDidStartSliding;
//停止滑动
- (void)miniButtonViewDidStopSliding;
@end

@interface MiniButtonView : UIScrollView<UIGestureRecognizerDelegate,UIScrollViewDelegate>
///代理
@property (nonatomic, weak) id<MiniButtonViewDelegate> buttonDelegate; // 使用不同的属性名称
///按钮数组
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
///标题数组不为空
@property (nonatomic, strong) NSMutableArray<NSString *> *titles;
///图标可为空 不为空数组长度必须和标题数组对应
@property (nonatomic, strong) NSArray<NSString *> *icons;

///按钮文字颜色数组 可为空 走默认
@property (nonatomic, strong) NSArray<UIColor *> *titleColors;
///默认按钮文字颜色
@property (nonatomic, strong) UIColor * titleColor;


///按钮图标颜色数组 可为空 走默认
@property (nonatomic, strong) NSArray<UIColor *> *iconColors;
///默认按钮图标颜色
@property (nonatomic, strong) UIColor * tintIconColor;
///默认整个背景颜色
@property (nonatomic, strong) UIColor * buttonBackageColor;


///背景颜色数组 可为空
@property (nonatomic, strong) NSArray<UIColor *> *buttonBackageColorArray;

///是否使用随机颜色 默认YES 颜色数组为空的时候 生效
@property (nonatomic, assign) BOOL isRandombuttonBackageColor;
///背景色透明度 默认1;
@property (nonatomic, assign) CGFloat buttonBackgroundColorAlpha;
/// 字体大小 默认15
@property (nonatomic, assign) CGFloat fontSize;
/// 子视图圆角
@property (nonatomic, assign) CGFloat buttonBcornerRadius;
/// 图标和标题的间距
@property (nonatomic, assign) CGFloat space;
/// 按钮间距
@property (nonatomic, assign) CGFloat buttonSpace;
///是否自动换行显示 默认NO 可在父视图宽度内左右滚动 设置为YES 则根据父视图宽度自动换行显示 并且更新 refreshHeight
@property (nonatomic, assign) BOOL autoLineBreak;
///UI更新动画时间 默认0.3
@property (nonatomic, assign) CGFloat animationTime;
/// 刷新视图换行后的总视图高度
@property (nonatomic, assign) CGFloat refreshHeight;
/// 刷新视图换行后的总视图宽度
@property (nonatomic, assign) CGFloat refreshWidth;
///是否隐藏滚动条 默认隐藏
@property (nonatomic, assign) BOOL hidesScrollIndicator;

///初始化一行按钮 传入按钮文字数组 图标数组可为空 字体大小默认15
- (instancetype)initWithStrings:(NSArray<NSString *> *)strings icons:(NSArray<NSString *> * _Nullable)icons fontSize:(CGFloat)size;

///刷新视图
- (BOOL)refreshLayout;

/// 更新按钮并刷新视图
- (void)updateButtonsWithStrings:(NSArray<NSString *> *)newStrings icons:(NSArray<NSString *> * _Nullable)newIcons;


@end

NS_ASSUME_NONNULL_END
