//
//  MyCollectionViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/20.

//

#import "MyCollectionViewController.h"
#import "MyFavoritesListViewController.h"
#import "config.h"
#import "ShowOneAppViewController.h"

#import "AppInfoModel.h"
#import "WebToolModel.h"
#import <Masonry/Masonry.h>
//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface MyCollectionViewController ()<TemplateSectionControllerDelegate, UITextViewDelegate, TemplateListDelegate, UIPageViewControllerDelegate,UIPageViewControllerDataSource, UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchView;//搜索框
@property (nonatomic, strong) dispatch_source_t searchDebounceTimer; // 搜索防抖定时器
@property (nonatomic, strong) UIButton *sortButton;

@property (nonatomic, assign) NSTimeInterval searchDebounceInterval; // 防抖间隔时间
@property (nonatomic, assign) BOOL sort;
@property (nonatomic, strong) NSString *keyword;


@property (nonatomic, strong) NSMutableArray <MyFavoritesListViewController*>*viewControllers;
@property (nonatomic, strong) UIPageViewController *pageViewController; // 页面控制器
@property (nonatomic, strong) MyFavoritesListViewController *currentVC;//所选择的控制器
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation MyCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    self.isTapViewToHideKeyboard = YES;

    UIButton *button = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"chevron.compact.down"] target:self action:@selector(close:)];
    button.frame = CGRectMake(kWidth - 45, 10, 30, 30);
    button.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    button.layer.cornerRadius = 15;
    [self.view addSubview:button];
    
    self.sortButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sortButton setTitle:@"New" forState:UIControlStateNormal];
    self.sortButton.frame = CGRectMake(kWidth - 125, 10, 60, 30);
    self.sortButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    [self.sortButton addTarget:self action:@selector(sortButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    self.sortButton.layer.cornerRadius = 15;
    [self.view addSubview:self.sortButton];
    
    
    [self setupSearchView];
    
    //初始化页面切换
    [self setupViewControllers];
    //设置页面
    [self setupPageViewController];
    
    [self setupPageControl];
    
    [self updateViewConstraints];
    
}

//设置搜索框
- (void)setupSearchView {
    self.searchView = [[UISearchBar alloc] initWithFrame:CGRectMake(8, 10, 240, 40)];
    self.searchView.delegate = self;
    self.searchView.searchTextField.layer.borderWidth = 1;
    self.searchView.searchTextField.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.2].CGColor;
    self.searchView.alpha = 1;
    
    // 设置带属性的占位符
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [UIColor grayColor], // 颜色
        NSFontAttributeName: [UIFont systemFontOfSize:13]  // 字体大小
    };
    self.searchView.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"搜索我收藏的APP" attributes:attributes];
    
    // 设置背景图片为透明
    [self.searchView setBackgroundImage:[UIImage new]];
    
    // 设置搜索框的背景颜色
    UITextField *searchField = [self.searchView valueForKey:@"searchField"];
    if (searchField) {
        searchField.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3]
                                                         darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.1]
        ];
        searchField.layer.cornerRadius = 10.0;
        searchField.layer.masksToBounds = YES;
    }
    
    [self.view addSubview:self.searchView];
}

// 初始化子页面控制器
- (void)setupViewControllers {
    self.viewControllers = [NSMutableArray array];
    for (int i = 0; i < 2; i++) {
        MyFavoritesListViewController *controller = [[MyFavoritesListViewController alloc] init];
        controller.templateListDelegate = self;
        controller.hidesVerticalScrollIndicator = YES;
        controller.keyword = @"";
        controller.sort = YES;
        controller.selectedIndex = i;
        controller.collectionView.backgroundColor = [UIColor clearColor];
        controller.view.backgroundColor = [UIColor clearColor];
        [controller.view removeDynamicBackground];
        [self.viewControllers addObject:controller];
        
    }
}

// 初始化分页控制器
- (void)setupPageViewController {
    // 配置分页控制器（水平滚动，带滚动效果）
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:@{UIPageViewControllerOptionInterPageSpacingKey: @10}];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    self.pageViewController.view.layer.cornerRadius = 10;
    self.pageViewController.view.layer.masksToBounds = YES;
    
    // 设置初始页面
    self.currentVC = self.viewControllers[0];
    [self.pageViewController setViewControllers:@[self.currentVC]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    // 添加到当前控制器
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    [self.view sendSubviewToBack:self.pageViewController.view];
}

//指示器
- (void)setupPageControl {
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 2;
    self.pageControl.currentPage = 0;
    self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 添加点击事件处理
    [self.pageControl addTarget:self
                         action:@selector(pageControlValueChanged:)
               forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.pageControl];
}

#pragma mark -设置约束

- (void)updateViewConstraints{
    [super updateViewConstraints];
    // 表格视图约束（合并冲突的旧约束）
    [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchView.mas_bottom).offset(15);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight-20);
    }];
    [self.pageControl mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@20);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
}

#pragma mark - Action

- (void)sortButtonTap:(UIButton*)button {
    
    //重置页码
    self.currentVC.page = 1;
    //取反操作
    self.currentVC.sort = !self.currentVC.sort;
    //重新加载数据
    [self.currentVC refreshLoadInitialData];
    //更新按钮
    NSString *buttonTitle = self.currentVC.sort ? @"HOT":@"NEW";
    
    [self.sortButton setTitle:buttonTitle forState:UIControlStateNormal];
    
    
    
}

- (void)close:(UIButton*)button{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 * 处理 UIPageControl 值变化事件
 */
- (void)pageControlValueChanged:(UIPageControl *)sender {
    NSInteger targetIndex = sender.currentPage;
    [self switchUIWithIndex:targetIndex];
    
}
//根据标签切换UI
- (void)switchUIWithIndex:(NSInteger)index{
    // 获取目标视图控制器
    MyFavoritesListViewController *targetVC = self.viewControllers[index];
    
    // 判断滚动方向（向前或向后）
    UIPageViewControllerNavigationDirection direction =
    index > self.selectedIndex
        ? UIPageViewControllerNavigationDirectionForward
        : UIPageViewControllerNavigationDirectionReverse;
    
    // 更新当前选中的索引
    self.selectedIndex = index;
    
    // 更新当前选中的视图控制器
    self.currentVC = targetVC;
    
    // 切换到目标页面
    [self.pageViewController setViewControllers:@[targetVC]
                                      direction:direction
                                       animated:YES
                                     completion:^(BOOL finished) {
        if (finished) {
//            NSLog(@"已通过指示器切换到页面 %ld", (long)targetIndex);
        }
    }];
    //设置底部原点
    self.pageControl.currentPage = index;
    //设置页面的数据类型
    targetVC.selectedIndex = index;
    self.selectedIndex = index;
    
    self.currentVC = targetVC;
    
    NSString *buttonTitle = index == 0 ? @"软件" :@"工具";
    [self.sortButton setTitle:buttonTitle forState:UIControlStateNormal];
    if(index == 0){
        self.searchView.placeholder = @"搜索我收藏的APP";
    }else{
        self.searchView.placeholder = @"搜索我收藏的工具";
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *buttonTitle = targetVC.sort ? @"HOT":@"NEW";
        [self.sortButton setTitle:buttonTitle forState:UIControlStateNormal];
    });
}
#pragma mark - 控制器辅助函数
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    
    
}

#pragma mark - SectionController 代理协议

/// 刷新指定Cell
- (void)refreshCell:(UICollectionViewCell *)cell {
    NSLog(@"刷新指定Cell:%@",cell);
}


// 原始索引回调（保留 IGListKit 原生行为）
- (void)templateSectionController:(TemplateSectionController *)sectionController
             didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"点击了index:%ld",index);
}

// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    if([model isKindOfClass:[AppInfoModel class]]){
        AppInfoModel *appInfo = (AppInfoModel *)model;
        ShowOneAppViewController *vc = [ShowOneAppViewController new];
        vc.app_id = appInfo.app_id;
        [self presentPanModal:vc];
    }
    
}


//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return NO;
}


#pragma mark - UISearchBarDelegate

// 当文本即将改变时调用，用于输入验证
- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // 获取当前搜索框中的文本
    NSString *currentText = searchBar.text;
    if (!currentText) {
        currentText = @"";
    }
    
    // 计算输入后的新文本
    NSString *newText = [currentText stringByReplacingCharactersInRange:range withString:text];
    
    // 1. 限制输入长度不超过10个汉字
    if (newText.length > 10) {
        return NO; // 超过长度限制，不允许输入
    }
    
//    /// 2. 限制只允许中文、英文和数字（不允许符号）
//    NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\u4e00-\u9fa5"];
//    NSCharacterSet *inputChars = [NSCharacterSet characterSetWithCharactersInString:text];
//
//    // 检查输入是否包含非法字符（使用 isSubsetOfSet 方法）
//    if (![inputChars isSupersetOfSet:allowedChars]) {
//        return NO;
//    }
    
    return YES; // 输入合法
}

// 当文本编辑结束时调用
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.keyword = searchBar.searchTextField.text;
    [self performSearchWithKeyword:self.keyword]; // 调用防抖搜索
}

// 文本更改时调用（包括清除）
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.keyword = searchText;
    [self performSearchWithKeyword:searchText]; // 调用防抖搜索
}

// 点击搜索时候
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.keyword = searchBar.searchTextField.text;
    NSLog(@"键盘点击搜索:%@",self.keyword);
    [self performSearchWithKeyword:self.keyword]; // 调用防抖搜索
    [self.view endEditing:YES];
    if(self.keyword.length ==0){
        [UIView animateWithDuration:0.3 animations:^{
            self.searchView.alpha = 0;
            self.zx_navRightBtn.alpha = 1;
        }];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.keyword = @"";
    NSLog(@"点击清除按钮 搜索:%@",self.keyword);
    [self performSearchWithKeyword:self.keyword]; // 调用防抖搜索
    [self.view endEditing:YES];
    if(self.keyword.length ==0){
        [UIView animateWithDuration:0.3 animations:^{
            self.searchView.alpha = 0;
            self.zx_navRightBtn.alpha = 1;
        }];
    }
}


// 防抖搜索实现（0.5秒延时）
- (void)performSearchWithKeyword:(NSString *)keyword {
   
    if (keyword.length >=10) {
        NSLog(@"太长过滤过短的搜索词:%@",keyword);
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"face.smiling"] status:@"输入那么长干嘛??"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    
    // 清除之前的定时器
    if (self.searchDebounceTimer) {
        NSLog(@"清除之前的定时器:%@",self.searchDebounceTimer);
        dispatch_source_cancel(self.searchDebounceTimer);
        self.searchDebounceTimer = nil;
    }
    
    // 设置新定时器（0.5秒后执行搜索）
    self.searchDebounceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.searchDebounceTimer,
                             dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                             DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(self.searchDebounceTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"设置新定时器（0.5秒后执行搜索）");
            self.currentVC.keyword = keyword;
            [self.currentVC.dataSource removeAllObjects];
            [self.currentVC loadDataWithPage:1];
            
        });
    });
    dispatch_resume(self.searchDebounceTimer);
}

#pragma mark - UIPageViewControllerDataSource

// 返回上一页
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    MyFavoritesListViewController * vc = (MyFavoritesListViewController * )viewController;
    NSInteger index = [self.viewControllers indexOfObject:vc];
    NSLog(@"index:%ld",index);
    if (index <= 0) return nil; // 第一页没有上一页
    return self.viewControllers[index - 1];
}

// 返回下一页
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    MyFavoritesListViewController * vc = (MyFavoritesListViewController * )viewController;
    NSInteger index = [self.viewControllers indexOfObject:vc];
    NSLog(@"index:%ld",index);
    if (index >= self.viewControllers.count - 1) return nil; // 最后一页没有下一页
    return self.viewControllers[index + 1];
}

#pragma mark - UIPageViewControllerDelegate

// 页面切换完成后调用
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        // 获取当前显示的页面索引
        MyFavoritesListViewController *VC = (MyFavoritesListViewController*)pageViewController.viewControllers.firstObject;
        
        NSInteger index = [self.viewControllers indexOfObject:VC];
        
        [self switchUIWithIndex:index];
        
    }
}


//侧滑手势
- (BOOL)allowScreenEdgeInteractive{
    return NO;
}


- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取手势的位置
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    
    if (CGRectContainsPoint(self.pageViewController.view.frame, loc)) {
        return NO;
    }
    
    // 默认返回 YES，允许拖拽
    return YES;
}



@end
