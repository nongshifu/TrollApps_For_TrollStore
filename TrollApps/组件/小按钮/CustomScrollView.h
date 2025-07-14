//
//  CustomScrollView.h
//  SoulChat
//
//  Created by 十三哥 on 2024/11/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MyScrollViewDelegate <NSObject>

- (void)myScrollView:(UIView *)view didTapAtIndex:(NSInteger)index;

@end

@interface CustomScrollView : UIScrollView<UIGestureRecognizerDelegate,UIScrollViewDelegate>
///代理
@property (nonatomic, weak) id<MyScrollViewDelegate> MyScrollViewdelegate;

/// 子视图圆角
@property (nonatomic, assign) CGFloat buttonBcornerRadius;
/// 图标和标题的间距
@property (nonatomic, assign) CGFloat space;
/// 是否自动换行显示 默认NO 可在父视图宽度内左右滚动 设置为YES 则根据父视图宽度自动换行显示 并且更新 refreshHeight
@property (nonatomic, assign) BOOL autoLineBreak;
/// UI下标
@property (nonatomic, assign) NSInteger index;
/// 刷新视图换行后的总视图高度
@property (nonatomic, assign) CGFloat refreshHeight;
/// 是否隐藏滚动条 默认隐藏
@property (nonatomic, assign) BOOL hidesScrollIndicator;
///子视图数组
@property (nonatomic, strong) NSMutableArray * subviewArray;

@property (nonatomic, assign) BOOL isHandlingTouch; // 添加标志位
/// 添加子视图的方法
- (void)addSubview:(UIView *)view;
/// 添加子视图的方法 并且是否响应点击回调代理
- (void)addSubview:(UIView *)view isTap:(BOOL)isTap;
/// 删除子视图的方法
- (void)removeSubview:(UIView *)view;
/// 刷新视图布局的方法
- (void)refreshViewLayout;
/// 刷新视图布局的方法回调高度
- (void)refreshViewLayoutWithCompletion:(void (^)(CGFloat height))completion;
///返回高度
- (CGFloat)getHeight;
@end

NS_ASSUME_NONNULL_END
