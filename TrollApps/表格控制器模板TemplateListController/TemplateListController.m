//
//  TemplateListController.m
//  NewSoulChat
//
//  Created by 十三哥 on 2025/3/7.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "TemplateListController.h"
#import <MJRefresh/MJRefresh.h>

//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface TemplateListController ()



@end

@implementation TemplateListController

#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = [NSMutableArray array];
    // 初始化 lastContentOffset
    self.lastContentOffset = 0;
    // 生成唯一标识符
    self.uniqueIdentifier = [[NSUUID UUID] UUIDString];
    
    [self setupUI];
    [self setupRefresh];

}


#pragma mark - 初始化 UI
- (void)setupUI {
    
    // 集合视图
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.estimatedItemSize = CGSizeMake(self.view.bounds.size.width, 100); // 设置预估高度
    //横向布局
//    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
   
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    
    [self.view addSubview:self.collectionView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view); // 完全覆盖 tableView
    }];
    
    
    // 使用 Auto Layout 设置 UICollectionView 的约束
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;

    // IGListKit 适配器
    IGListAdapterUpdater *updater = [[IGListAdapterUpdater alloc] init];
    self.adapter = [[IGListAdapter alloc] initWithUpdater:updater viewController:self];
    
    self.adapter.collectionView = self.collectionView;
    self.adapter.dataSource = self;
    self.adapter.scrollViewDelegate = self;
    
    
    // 初始化空视图
    _emptyView = [[EmptyView alloc] initWithFrame:CGRectZero];
    // 自定义空视图内容
    [_emptyView configureWithImage:[UIImage systemImageNamed:@"list.bullet.rectangle"]
                           title:@"暂无数据"
                     buttonTitle:@"刷新"];
    
    // 添加按钮点击事件
    [_emptyView.actionButton addTarget:self
                                action:@selector(refreshLoadInitialData)
                      forControlEvents:UIControlEventTouchUpInside];
    
    [self updateEmptyViewVisibility];
    
    
    // 返回顶部按钮
    self.scrollToTopButton = [UIImageView new];
    self.scrollToTopButton.image = [UIImage systemImageNamed:@"chevron.up.circle"];
    self.scrollToTopButton.contentMode = UIViewContentModeScaleAspectFill;
    self.scrollToTopButton.frame = CGRectMake(self.view.frame.size.width - 50,
                                              self.view.frame.size.height - 45, 35, 35);
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToTop:)];
    tapGesture.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.scrollToTopButton.userInteractionEnabled = YES;
    [self.scrollToTopButton addGestureRecognizer:tapGesture];
    
    self.scrollToTopButton.alpha = 0;
    [self.view addSubview:self.scrollToTopButton];
    [self.view bringSubviewToFront:self.scrollToTopButton];
    
    // 返回顶部按钮
    self.messageButton = [UIImageView new];
    self.messageButton.image = [UIImage systemImageNamed:@"envelope.circle"];
    self.messageButton.contentMode = UIViewContentModeScaleAspectFill;
    self.messageButton.frame = CGRectMake(self.view.frame.size.width - 50,
                                          self.view.frame.size.height - 45, 35, 35);
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(meessageButtonTap:)];
    tapGesture2.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.messageButton.userInteractionEnabled = YES;
    [self.messageButton addGestureRecognizer:tapGesture2];
    
    self.messageButton.alpha = 0;
    [self.view addSubview:self.messageButton];
    [self.view bringSubviewToFront:self.messageButton];
    
    // 左下角按钮
    self.leftButton = [UIImageView new];
    
    self.leftButton.contentMode = UIViewContentModeScaleAspectFill;
    self.leftButton.frame = CGRectMake(20,
                                          self.view.frame.size.height - 45, 35, 35);
    UITapGestureRecognizer *leftButtontapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftButtonTap:)];
    leftButtontapGesture.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.leftButton.userInteractionEnabled = YES;
    [self.leftButton addGestureRecognizer:leftButtontapGesture];
    
    self.leftButton.alpha = 0;
    [self.view addSubview:self.leftButton];
    [self.view bringSubviewToFront:self.leftButton];
}



#pragma mark - 刷新控件配置
// 更新空视图状态
- (void)updateEmptyViewVisibility {
    
    [_emptyView updateConstraints];
}

- (void)setupRefresh {
    __weak typeof(self) weakSelf = self;
    self.refreshHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        //删除数据源
        [weakSelf.dataSource removeAllObjects];
        //刷新
        [weakSelf refreshLoadInitialData];
        
    }];
    
    self.refreshFooter = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weakSelf loadMoreData];
        if ([weakSelf.templateListDelegate respondsToSelector:@selector(willLoadDataWithPage:currentDataSource:)]) {
            [weakSelf.templateListDelegate willLoadDataWithPage:weakSelf.page currentDataSource:weakSelf.dataSource];
        }
    }];
    
    self.collectionView.mj_header = self.refreshHeader;
    self.collectionView.mj_footer = self.refreshFooter;
}

- (void)refreshTopAndMessageButtonViewUI {
    [self.view bringSubviewToFront:self.scrollToTopButton];
    [self.view bringSubviewToFront:self.messageButton];
    
    self.scrollToTopButton.frame = CGRectMake(CGRectGetMaxX(self.collectionView.frame) - 50,
                                              CGRectGetMaxY(self.collectionView.frame) - 45, 35, 35);
    self.messageButton.frame = CGRectMake(CGRectGetMaxX(self.collectionView.frame) - 50,
                                              CGRectGetMaxY(self.collectionView.frame) - 45, 35, 35);
    self.leftButton.frame = CGRectMake(20,
                                              CGRectGetMaxY(self.collectionView.frame) - 45, 35, 35);
    
}

// 实现隐藏竖向滚动条的 setter 方法
- (void)setHidesVerticalScrollIndicator:(BOOL)hidesVerticalScrollIndicator {
    _hidesVerticalScrollIndicator = hidesVerticalScrollIndicator;
    self.collectionView.showsVerticalScrollIndicator = !hidesVerticalScrollIndicator;
}

// 实现隐藏横向滚动条的 setter 方法
- (void)setHidesHorizontalScrollIndicator:(BOOL)hidesHorizontalScrollIndicator {
    _hidesHorizontalScrollIndicator = hidesHorizontalScrollIndicator;
    self.collectionView.showsHorizontalScrollIndicator = !hidesHorizontalScrollIndicator;
}


#pragma mark - 刷新数据加载
- (void)refreshLoadInitialData {
    if(self.dataSource.count>0){
        [self.dataSource removeAllObjects];
        
    }
    
    self.page = 1;
    [self loadDataWithPage:self.page];
    // 调用代理方法
    if ([self.templateListDelegate respondsToSelector:@selector(willLoadDataWithPage:currentDataSource:)]) {
        [self.templateListDelegate willLoadDataWithPage:self.page currentDataSource:self.dataSource];
    }
    [self updateEmptyViewVisibility];
    
}

- (void)loadMoreData{
    if(self.dataSource.count>0){
        self.page++; // 页码自增
    }
    [self loadDataWithPage:self.page];
    [self updateEmptyViewVisibility];
}

- (void)refreshTable{
    [self endRefreshing];
    //刷新
    [self.adapter performUpdatesAnimated:YES completion:^(BOOL finished) {
        [self updateEmptyViewVisibility];
    }];
    
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self refreshTopAndMessageButtonViewUI];
    
}


#pragma mark - IGListAdapterDataSource
- (NSArray<id<IGListDiffable>> *)objectsForListAdapter:(IGListAdapter *)listAdapter {
    
    return self.dataSource;
}

- (IGListSectionController *)listAdapter:(IGListAdapter *)listAdapter sectionControllerForObject:(id)object {
    return [self templateSectionControllerForObject:object];
}

- (UIView *)emptyViewForListAdapter:(IGListAdapter *)listAdapter {
    return _emptyView; // 返回自定义空视图
}




#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"开始滚动");
    self.messageButton.alpha = 0;
    
    CGFloat offsetY = scrollView.contentOffset.y;
    
    self.scrollY = offsetY; // 暴露给子类使用
    
    // 显示/隐藏返回顶部按钮
    [UIView animateWithDuration:0.3 animations:^{
        self.scrollToTopButton.alpha = offsetY > 500 ? 1 : 0;
        
    }];
    // 计算滚动方向
    self.isScrollingUp = offsetY > self.lastContentOffset;
    
    // 调用代理方法
    if ([self.templateListDelegate respondsToSelector:@selector(scrollViewDidScrollWithOffset:isScrollingUp:)]) {
        [self.templateListDelegate scrollViewDidScrollWithOffset:offsetY isScrollingUp:self.isScrollingUp];
    }
    // 更新 lastContentOffset
    self.lastContentOffset = offsetY;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    if ([self.templateListDelegate respondsToSelector:@selector(scrollViewWillBeginDraggingWithOffset:)]) {
        [self.templateListDelegate scrollViewWillBeginDraggingWithOffset:offsetY];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat offsetY = scrollView.contentOffset.y;
    if ([self.templateListDelegate respondsToSelector:@selector(scrollViewDidEndDraggingWithOffset:willDecelerate:)]) {
        [self.templateListDelegate scrollViewDidEndDraggingWithOffset:offsetY willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if ([self.templateListDelegate respondsToSelector:@selector(scrollViewWillBeginDeceleratingWithOffset:)]) {
        [self.templateListDelegate scrollViewWillBeginDeceleratingWithOffset:offsetY];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    [self refreshTopAndMessageButtonViewUI];
    if ([self.templateListDelegate respondsToSelector:@selector(scrollViewDidEndDeceleratingWithOffset:)]) {
        [self.templateListDelegate scrollViewDidEndDeceleratingWithOffset:offsetY];
    }
}

#pragma mark - 公共方法
- (void)endRefreshing {
    [self.refreshHeader endRefreshing];
    [self.refreshFooter endRefreshing];
}

- (void)handleNoMoreData {
    [self.refreshFooter endRefreshingWithNoMoreData];
}
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
                 hideHeaderTime:(BOOL)isHeaderHiddenTime{
    
    // 设置下拉刷新控件
    if (self.refreshHeader && [self.refreshHeader isKindOfClass:[MJRefreshNormalHeader class]]) {
        MJRefreshNormalHeader *header = (MJRefreshNormalHeader *)self.refreshHeader;
        
        header.stateLabel.textColor = textColor ?: [UIColor grayColor];
        header.stateLabel.font = textFont ?: [UIFont systemFontOfSize:14];
        header.lastUpdatedTimeLabel.hidden = isHeaderHiddenTime;
        
        // 设置下拉刷新文字
        if (headerTextDict) {
            [headerTextDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull stateNum, NSString * _Nonnull text, BOOL * _Nonnull stop) {
                [header setTitle:text forState:(MJRefreshState)stateNum.integerValue];
            }];
        }
    }
    
    // 设置上拉加载控件
    if (self.refreshFooter && [self.refreshFooter isKindOfClass:[MJRefreshAutoNormalFooter class]]) {
        MJRefreshAutoNormalFooter *footer = (MJRefreshAutoNormalFooter *)self.refreshFooter;
        
        footer.stateLabel.textColor = textColor ?: [UIColor grayColor];
        footer.stateLabel.font = textFont ?: [UIFont systemFontOfSize:14];
        
        // 设置上拉加载文字
        if (footerTextDict) {
            [footerTextDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull stateNum, NSString * _Nonnull text, BOOL * _Nonnull stop) {
                [footer setTitle:text forState:(MJRefreshState)stateNum.integerValue];
            }];
        }
    }
}
/**
 快速设置"没有更多数据"状态
 */
- (void)setFooterNoMoreDataWithText:(NSString *)text {
    if (self.refreshFooter && [self.refreshFooter isKindOfClass:[MJRefreshAutoNormalFooter class]]) {
        MJRefreshAutoNormalFooter *footer = (MJRefreshAutoNormalFooter *)self.refreshFooter;
        footer.stateLabel.numberOfLines = 0;
        [footer setTitle:text ?: @"加载完毕-没有更多数据" forState:MJRefreshStateNoMoreData];
        [footer endRefreshingWithNoMoreData];
    }
}



- (void)resetFooter {
    [self.refreshFooter resetNoMoreData];
}

- (void)scrollToTop:(UITapGestureRecognizer *)gesture {
    [TemplateListController triggerVibration];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                               atScrollPosition:UICollectionViewScrollPositionTop
                                       animated:YES];
}

- (void)meessageButtonTap:(UITapGestureRecognizer *)gesture {
    
    UIImageView * view = (UIImageView *)gesture.view;
    //点击了消息按钮
    if ([self.templateListDelegate respondsToSelector:@selector(messageButtonDidTap:)]) {
        [self.templateListDelegate messageButtonDidTap:view];
    }
}

- (void)leftButtonTap:(UITapGestureRecognizer *)gesture {
    UIImageView * view = (UIImageView *)gesture.view;
    //点击了消息按钮
    if ([self.templateListDelegate respondsToSelector:@selector(leftButtonDidTap:)]) {
        [self.templateListDelegate leftButtonDidTap:view];
    }
}

@end
