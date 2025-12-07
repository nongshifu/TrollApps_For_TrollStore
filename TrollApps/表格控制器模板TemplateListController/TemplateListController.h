//
//  TemplateListController.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/3/7.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "DemoBaseViewController.h"
#import <IGListKit/IGListKit.h>
#import "Config.h"
#import "TemplateSectionController.h"
#import "EmptyView.h"


NS_ASSUME_NONNULL_BEGIN

#define MUST_OVERRIDE __attribute__((unavailable("You must override this method in a subclass"))

@protocol TemplateListDelegate <NSObject>

/**
 * 当滚动视图滚动时调用此方法。
 *
 * @param offset 滚动视图的偏移量
 * @param isScrollingUp 表示滚动方向是否为向上滚动，YES 为向上滚动，NO 为向下滚动
 */
- (void)scrollViewDidScrollWithOffset:(CGFloat)offset isScrollingUp:(BOOL)isScrollingUp;

/**
 * 当用户开始拖动滚动视图时调用此方法。
 *
 * @param offsetY 滚动视图开始拖动时在 Y 轴上的偏移量
 */
- (void)scrollViewWillBeginDraggingWithOffset:(CGFloat)offsetY;

/**
 * 当用户结束拖动滚动视图时调用此方法。
 *
 * @param offsetY 滚动视图结束拖动时在 Y 轴上的偏移量
 * @param willDecelerate 表示滚动视图是否会继续减速滚动，YES 为会继续减速滚动，NO 为停止滚动
 */
- (void)scrollViewDidEndDraggingWithOffset:(CGFloat)offsetY willDecelerate:(BOOL)willDecelerate;

/**
 * 当滚动视图开始减速滚动时调用此方法。
 *
 * @param offsetY 滚动视图开始减速滚动时在 Y 轴上的偏移量
 */
- (void)scrollViewWillBeginDeceleratingWithOffset:(CGFloat)offsetY;

/**
 * 当滚动视图结束减速滚动时调用此方法。
 *
 * @param offsetY 滚动视图结束减速滚动时在 Y 轴上的偏移量
 */
- (void)scrollViewDidEndDeceleratingWithOffset:(CGFloat)offsetY;

/**
 * 当消息按钮被点击时调用此方法。
 *
 * @param buttonImageView 被点击的消息按钮对应的 UIImageView
 */
- (void)messageButtonDidTap:(UIImageView *)buttonImageView;

/**
 * 当左侧按钮被点击时调用此方法。
 *
 * @param buttonImageView 被点击的左侧按钮对应的 UIImageView
 */
- (void)leftButtonDidTap:(UIImageView *)buttonImageView;

/**
 * 当即将加载数据时调用此方法。
 *
 * @param page 即将加载数据的页码
 * @param dataSource 当前的数据源
 */
- (void)willLoadDataWithPage:(NSInteger)page currentDataSource:(NSArray *)dataSource;
@end


@interface TemplateListController : DemoBaseViewController<IGListAdapterDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) id<TemplateListDelegate> templateListDelegate;
/// 记录上一次的滚动位置
@property (nonatomic, assign) CGFloat lastContentOffset;
/// 当前滚动偏移量
@property (nonatomic, assign) CGFloat scrollY;
/// 返回顶部按钮
@property (nonatomic, strong) UIImageView *scrollToTopButton;
/// 消息按钮
@property (nonatomic, strong) UIImageView *messageButton;
/// 左下角按钮
@property (nonatomic, strong) UIImageView *leftButton;
/**
 传送数据
 */
@property (nonatomic, strong) id idObjc;
/**
 空视图
 */
@property (nonatomic, strong) EmptyView *emptyView;



#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page;

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object;


#pragma mark - 公共属性
@property (nonatomic, strong) UICollectionView *collectionView; // 集合视图
@property (nonatomic, strong) IGListAdapter *adapter; // IGListKit 适配器
@property (nonatomic, strong) NSMutableArray *dataSource; // 数据源
@property (nonatomic, assign) NSInteger page; // 当前页码
@property (nonatomic, strong) MJRefreshHeader *refreshHeader; // 下拉刷新控件
@property (nonatomic, strong) MJRefreshFooter *refreshFooter; // 上拉加载控件
@property (nonatomic, strong) NSString *uniqueIdentifier;//生成的控制器唯一标识符 负责缓存高度冲突
@property (nonatomic, assign) BOOL isScrollingUp;//滚动方向

#pragma mark - 公共方法

/**
 初始化 UI
 */
- (void)setupUI;
/**
 结束刷新状态（下拉刷新和上拉加载都会调用）
 */
- (void)endRefreshing;

/**
 标记没有更多数据（当最后一页时调用）
 */
- (void)handleNoMoreData;
/**
 配置刷新控件的通用方法

 @param headerTextDict 下拉刷新各状态文字字典
 @param footerTextDict 上拉加载各状态文字字典
 @param textColor 文字颜色
 @param textFont 文字字体
 @param isHeaderHiddenTime 是否隐藏下拉刷新时间
 */
- (void)configRefreshWithHeaderText:(nullable NSDictionary<NSNumber *, NSString *> *)headerTextDict
                         footerText:(nullable NSDictionary<NSNumber *, NSString *> *)footerTextDict
                          textColor:(nullable UIColor *)textColor
                           textFont:(nullable UIFont *)textFont
                 hideHeaderTime:(BOOL)isHeaderHiddenTime;

/**
 快速设置"没有更多数据"状态
 */
- (void)setFooterNoMoreDataWithText:(NSString *)text;

/**
 重置底部加载状态（当重新加载数据时调用）
 */
- (void)resetFooter;

/**
 滚动到列表顶部（带动画效果）
 */
- (void)scrollToTop;

/**
 重置刷新数据
 */
- (void)refreshLoadInitialData;

/**
 加载下一页
 */
- (void)loadMoreData;
/**
 重置刷新右下角按钮位置
 */
- (void)refreshTopAndMessageButtonViewUI;
/**
 刷新表格
 */
- (void)refreshTable;
/**
 更新空视图状态
 */
- (void)updateEmptyViewVisibility;

/// 声明隐藏竖向滚动条的属性及 setter 方法
@property (nonatomic, assign) BOOL hidesVerticalScrollIndicator;


/// 声明隐藏横向滚动条的属性及 setter 方法
@property (nonatomic, assign) BOOL hidesHorizontalScrollIndicator;



@end

NS_ASSUME_NONNULL_END
