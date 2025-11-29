//
//  AppsViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/6/30.
//

#import "AppsViewController.h"
#import "MiniButtonView.h"
#import "CategoryManagerViewController.h"
#import "MyFavoritesListViewController.h"
#import "ShowOneAppViewController.h"
#import "PublishAppViewController.h"
#import "AppSearchViewController.h"
#import "NewProfileViewController.h"
#import "DownloadManagerViewController.h"
#import "loadData.h"
#import "MyCollectionViewController.h"
#import "ArrowheadMenu.h"
#import "UserProfileViewController.h"
#include <dlfcn.h>
//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface AppsViewController () <TemplateListDelegate, UIScrollViewDelegate, UISearchBarDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource,MiniButtonViewDelegate, UIContextMenuInteractionDelegate, MenuViewControllerDelegate,JXCategoryViewDelegate>
//顶部分类
@property (nonatomic, strong) NSMutableArray *titles; //分类标题数组
@property (nonatomic, strong) MiniButtonView * bottomButton; // 底部按钮

@property (nonatomic, strong) NSMutableArray<AppListViewController *> *viewControllers;
@property (nonatomic, strong) UIPageViewController *pageViewController; // 页面控制器
@property (nonatomic, strong) AppListViewController *currentVC;//所选择的控制器
@property (nonatomic, strong) UISearchBar *searchBar;//搜索框

@property (nonatomic, strong) NSString *currentSearchKeyword;//关键词
@property (nonatomic, assign) NSInteger currentPageIndex;//分类下标

@property (nonatomic, strong) dispatch_source_t searchDebounceTimer; // 搜索防抖定时器
@property (nonatomic, assign) NSTimeInterval searchDebounceInterval; // 防抖间隔时间
@property (nonatomic, strong) UIImageView *logoImageView; //左侧头像

@property (nonatomic, assign) BOOL showMyApp; //全部APP 还是我的APP

@property (nonatomic, strong) UIButton * switchAppListButton;//导航上我的和全部切换按钮

@property (nonatomic, strong) UIButton * sortButton;//右上角 排序按钮

@property (nonatomic, strong) JXCategoryTitleView *categoryView; // 顶部的分类按钮

@property (nonatomic, strong) NSArray<NSString *>*sortArray;

@end

@implementation AppsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"TrollApps";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.currentPageIndex = 0;
    self.isTapViewToHideKeyboard = YES;
    self.sortArray = @[@"最近更新", @"最早发布", @"最多评论", @"最多点赞", @"最多收藏", @"最多分享"];
    [self setupUI];

    
    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:SAVE_LOCAL_TAGS_KEY object:nil];
    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self getUDID];
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"显示后");
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = NO;
    [self setupNavigationBar];

}

// 消失之前
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 在这里可以进行一些在视图消失之前的清理工作，比如停止动画、保存数据等。

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 在这里进行与布局完成后相关的操作，比如获取子视图的最终尺寸等
    NSLog(@"视图布局完成");
    self.switchAppListButton.alpha = !self.searchBar.alpha;
}

// 注销通知
- (void)dealloc {
    // 在dealloc注销通知 避免内存泄漏
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SAVE_LOCAL_TAGS_KEY object:nil];
}

- (void)handleNotification:(NSNotification *)notification {
    id object = notification.object;
    
    if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSMutableArray class]]) {
        NSArray *newTitles = (NSArray *)object;
        
        // 判断新数组与当前titles是否相同
        BOOL isSame = [self compareArraysOrdered:self.titles withArray:newTitles];
        NSLog(@"内容是否相同: %@", isSame ? @"YES" : @"NO");
        
        if (!isSame) {
            self.titles = [NSMutableArray arrayWithArray:newTitles];
            NSLog(@"更新后的标题: %@", self.titles);
            [SVProgressHUD showWithStatus:@"设置分类中"];
            self.categoryView.titles = self.titles;
            [self.categoryView reloadData];
            // 移除分页控制器
            [self.pageViewController.view removeFromSuperview];
            [self.pageViewController removeFromParentViewController];
            self.pageViewController = nil;
            [self.viewControllers removeAllObjects];
            
            
            [self setupViewControllers];
            
            [self setupPageViewController];
            
            [self updateViewConstraints];
            
            [self.view bringSubviewToFront:self.bottomButton];
            
            [SVProgressHUD dismissWithDelay:1];
            
        }
    } else {
        NSLog(@"Received invalid object type");
    }
}

// 键盘隐藏和现实
- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    self.keyboardIsShow = NO;
    self.searchBar.alpha = self.currentSearchKeyword.length > 0;
    [self updateViewConstraints];
    NSLog(@"键盘隐藏");
}


- (BOOL)compareArraysOrdered:(NSArray *)array1 withArray:(NSArray *)array2 {
    // 先比较数量
    if (array1.count != array2.count) {
        return NO;
    }

    // 逐个元素比较
    for (NSInteger i = 0; i < array1.count; i++) {
        NSString *str1 = array1[i];
        NSString *str2 = array2[i];
        
        // 使用caseInsensitive比较，忽略大小写
        if ([str1 caseInsensitiveCompare:str2] != NSOrderedSame) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark -设置UI

- (void)setupUI {
    
    [self setupSearchView];
    
    [self setupNavigationBar];
    
    [self setupSegmentedControl];
    
    [self setupViewControllers];
    
    [self setupPageViewController];
    
   
    
    [self setupAddButton];
    
    [self  setupSortButton];
    
    [self setupViewConstraints];
    
    [self updateViewConstraints];
    
    [self setupSideMenuController];
    
    
}


#pragma mark -导航

- (void)setupNavigationBar {
    NSLog(@"监听主题变化updateTabBarColor");
    
    // 设置标题和副标题
    [self zx_setMultiTitle:@"TrollApps"
                   subTitle:@"热门App应用 插件 应有尽有！"
                subTitleFont:[UIFont boldSystemFontOfSize:10]
             subTitleTextColor:[UIColor randomColorWithAlpha:1]];
    
    
    // 设置导航栏基本属性
    self.zx_navTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.zx_navBar.zx_lineViewHeight = 0.5;
    self.zx_navBar.zx_lineView.alpha = 0.5;
    [self zx_removeNavGradientBac];
    //右侧切换我的和全部按钮
    if(!self.switchAppListButton){
        self.switchAppListButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchAppListButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        self.switchAppListButton.titleLabel.textColor = [UIColor labelColor];
        [self.switchAppListButton setTitle:@"全部" forState:UIControlStateNormal];
        [self.switchAppListButton addTarget:self action:@selector(switchAppList:) forControlEvents:UIControlEventTouchUpInside];
        [self.zx_navBar addSubview:self.switchAppListButton];
    }
    
    
    
    // 添加视觉效果
    [self.zx_navBar addColorBallsWithCount:10
                                   ballradius:150
                                minDuration:30
                                maxDuration:60
                        UIBlurEffectStyle:UIBlurEffectStyleProminent
                        UIBlurEffectAlpha:0.99
                               ballalpha:0.5];
    
    
    __weak typeof(self) weakSelf = self;

    // 设置右侧搜索按钮
    [self zx_setRightBtnWithImg:[UIImage systemImageNamed:@"magnifyingglass.circle"]
                    clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {

        weakSelf.searchBar.alpha = 1;
        [weakSelf updateViewConstraints];

        [UIView animateWithDuration:0.3 animations:^{
            [weakSelf.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [weakSelf.searchBar becomeFirstResponder];
        }];
    }];

    // 设置左侧头像按钮
    // 尝试从本地缓存读取头像
    UIImage *avatarImage = [self loadAvatarImage];

    //设置左侧按钮
    [self zx_setLeftBtnWithImg:avatarImage clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        UserProfileViewController *vc = [UserProfileViewController new];
        
        vc.user_udid = [loadData sharedInstance].userModel.udid;
        
        [self presentPanModal:vc];
    }];


    // 设置按钮样式
    CGFloat width = 30;
    self.zx_navLeftBtn.zx_fixWidth = width;
    self.zx_navLeftBtn.zx_fixHeight = width;
    self.zx_navLeftBtn.zx_setCornerRadiusRounded = width/2;

    // 确保logoImageView只创建一次
    if (!self.logoImageView) {
        self.logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        [self.zx_navLeftBtn addSubview:self.logoImageView];
    }
    self.logoImageView.image = avatarImage;

    // 设置按钮尺寸
    self.zx_navRightBtn.zx_fixWidth = 28;
    self.zx_navRightBtn.zx_fixHeight = 25;



    
    
}

- (UIImage *)loadAvatarImage {
    UIImage *avatarImage = [[NewProfileViewController sharedInstance] loadAvatarFromCache];
    
    if (!avatarImage) {
        avatarImage = [NewProfileViewController sharedInstance].minImage;
        
        if (avatarImage) {
            [[NewProfileViewController sharedInstance] saveAvatarToCache:avatarImage];
        } else {
            NSLog(@"警告：未找到可用的头像");
            avatarImage = [UIImage systemImageNamed:@"applelogo"];
        }
    }
    
    NSLog(@"读取头像:%@", avatarImage);
    return avatarImage;
}

#pragma mark -其他UI
//设置左侧菜单
- (void)setupSideMenuController {
    self.sideMenuController = [self getLGSideMenuController];
    
    // 设置侧滑阈值，这里设置为从屏幕边缘开始 20 点的距离才触发侧滑
    self.sideMenuController.leftViewController = [DemoBaseViewController new];
    self.sideMenuController.rightViewController = [DemoBaseViewController new];
    //设置宽度
    self.sideMenuController.leftViewWidth = 200;
    self.sideMenuController.rightViewWidth = 200;
    // 设置左侧菜单的滑动触发范围
    self.sideMenuController.swipeGestureArea = LGSideMenuSwipeGestureAreaFull;//全屏可触摸
    //默认不允许触摸侧滑 按钮点击显示
    self.sideMenuController.leftViewSwipeGestureEnabled = YES;
    self.sideMenuController.rightViewSwipeGestureEnabled = YES;

    // 创建弱引用
    __weak typeof(self) weakSelf = self;
    //侧面出现后才可以滑动 用来隐藏
    self.sideMenuController.willShowLeftView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 禁用侧滑手势
        weakSelf.sideMenuController.leftViewSwipeGestureEnabled = YES;
    };

    self.sideMenuController.willHideLeftView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 在左侧菜单即将隐藏时，禁用左滑关闭菜单的手势
        weakSelf.sideMenuController.leftViewSwipeGestureEnabled = YES;
    };

    self.sideMenuController.willShowRightView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 禁用侧滑手势
        weakSelf.sideMenuController.rightViewSwipeGestureEnabled = YES;
    };

    self.sideMenuController.willHideRightView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 在左侧菜单即将隐藏时，禁用左滑关闭菜单的手势
        weakSelf.sideMenuController.rightViewSwipeGestureEnabled = YES;
    };
}

//设置搜索框
- (void)setupSearchView {
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(100, 0, 150, 40)];
    self.searchBar.delegate = self;
    self.searchBar.searchTextField.layer.borderWidth = 1;
    self.searchBar.searchTextField.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.2].CGColor;
    self.searchBar.alpha = 0;
    // 设置背景图片为透明
    [self.searchBar setBackgroundImage:[UIImage new]];
    
    // 设置搜索框的背景颜色
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        searchField.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3]
                                                         darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.1]
        ];
        searchField.layer.cornerRadius = 10.0;
        searchField.layer.masksToBounds = YES;
    }
    [self zx_addCustomTitleView:self.searchBar];

}

//设置选项卡
- (void)setupSegmentedControl {
    NSArray *lacalTags = [[NSUserDefaults standardUserDefaults] arrayForKey:SAVE_LOCAL_TAGS_KEY];
    if(!lacalTags){
        self.titles = [NSMutableArray arrayWithArray:[loadData sharedInstance].tags];

        [[NSUserDefaults standardUserDefaults] setObject:self.titles forKey:SAVE_LOCAL_TAGS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{
        self.titles = [NSMutableArray arrayWithArray:lacalTags];
    }
    
    self.categoryView = [[JXCategoryTitleView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.zx_navBar.frame)+5, kWidth - 115, 35)];
    self.categoryView.delegate = self;
    self.categoryView.titles = self.titles;
    self.categoryView.titleColorGradientEnabled = YES;
    self.categoryView.titleSelectedFont = [UIFont boldSystemFontOfSize:17];
    self.categoryView.titleFont = [UIFont boldSystemFontOfSize:16];
    self.categoryView.titleColor = [UIColor secondaryLabelColor];
    self.categoryView.cellSpacing = 15;
    [self.view addSubview:self.categoryView];
    
    JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
    lineView.indicatorColor = [UIColor redColor];
    lineView.indicatorWidth = JXCategoryViewAutomaticDimension;
    self.categoryView.indicators = @[lineView];
   
}

//设置底部选项卡按钮
- (void)setupAddButton {
    self.bottomButton = [[MiniButtonView alloc] initWithFrame:CGRectMake(10, CGRectGetHeight(self.view.frame)-get_BOTTOM_TAB_BAR_HEIGHT - 10, 300, 30)];
    self.bottomButton.tag = 1;
    self.bottomButton.buttonBcornerRadius = 5;
    self.bottomButton.titleColor = [UIColor whiteColor];
    self.bottomButton.tintIconColor = [UIColor whiteColor];
    self.bottomButton.buttonDelegate = self;
    self.bottomButton.buttonSpace = 10;
    self.bottomButton.fontSize = 15;
    [self.view addSubview:self.bottomButton];
    NSArray *titles = @[@"分类", @"收藏", @"下载"];
    NSArray *icons = @[@"tag", @"star.lefthalf.fill", @"icloud.and.arrow.down"];
    [self.bottomButton updateButtonsWithStrings:titles icons:icons];
    [self.bottomButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT - 10);
        make.width.mas_equalTo(300);
        make.left.equalTo(self.view).offset(10);
        make.height.equalTo(@25);
    }];
    [self.view bringSubviewToFront:self.bottomButton];
}

// 初始化子页面控制器
- (void)setupViewControllers {
    self.viewControllers = [NSMutableArray array];
    for (int i = 0; i < self.titles.count; i++) {
        AppListViewController *controller = [[AppListViewController alloc] init];
        controller.templateListDelegate = self;
        controller.hidesVerticalScrollIndicator = YES;
        
        controller.showMyApp = NO;
        controller.title = self.titles[i];
        controller.tag = self.titles[i];
        controller.collectionView.backgroundColor = [UIColor clearColor];
        controller.view.backgroundColor = [UIColor clearColor];
        [controller.view removeDynamicBackground];
        [self.viewControllers addObject:controller];
        //更新空视图状态
        [controller updateEmptyViewVisibility];
        
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
    
    
    
    // 设置初始页面
    self.currentVC = (AppListViewController*)self.viewControllers[0];
    [self.pageViewController setViewControllers:@[self.currentVC]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    // 添加到当前控制器
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    //读取第一页数据
    [self.currentVC refreshLoadInitialData];
}

// 右侧排序按钮
- (void)setupSortButton{
    
    self.sortButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sortButton.layer.cornerRadius = 7;
    self.sortButton.titleLabel.font = [UIFont systemFontOfSize:15];
    self.sortButton.backgroundColor = [UIColor randomColorWithAlpha:0.3];
    [self.sortButton setTitle:@"最近更新" forState:UIControlStateNormal];
    [self.sortButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sortButton addTarget:self action:@selector(sortTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sortButton];
}

#pragma mark - Action

- (void)switchAppList:(UIButton*)button{
    self.showMyApp = !self.showMyApp;
    

    for (AppListViewController *vc in self.viewControllers) {
        vc.showMyApp = self.showMyApp;
        [vc.dataSource removeAllObjects];
        [vc refreshTable];
        [vc refreshLoadInitialData];
    }
    NSString *title = self.showMyApp ? @"我的" :@"全部";
    
    [button setTitle:title forState:UIControlStateNormal];
    button.alpha = !self.searchBar.alpha;
    NSString *msg = self.showMyApp ? @"切换为我的APP" :@"切换显示全部APP";
    [SVProgressHUD showImage:[UIImage systemImageNamed:@"scribble"] status:msg];
    [SVProgressHUD dismissWithDelay:2];
}

// 排序按钮点击
- (void)sortTapped:(UIButton*)button {
   
    self.sortButton.backgroundColor = [UIColor randomColorWithAlpha:0.9];
    // 处理左边图标点击逻辑
    NSArray *icon = @[@"clock", @"arrow.clockwise.icloud", @"message", @"hand.thumbsup.fill", @"star", @"arrowshape.turn.up.right"];
    CGSize menuUnitSize = CGSizeMake(130, 40);
    CGFloat distanceFromTriggerSwitch = 10;
    UIFont * font = [UIFont boldSystemFontOfSize:13];
    UIColor * menuFontColor = [UIColor labelColor];
    UIColor * menuBackColor = [[UIColor tertiarySystemBackgroundColor] colorWithAlphaComponent:0.99];
    UIColor * menuSegmentingLineColor = [UIColor labelColor];
    
    ArrowheadMenu *VC = [[ArrowheadMenu alloc] initCustomArrowheadMenuWithTitle:self.sortArray
                                                                           icon:icon
                                                                   menuUnitSize:menuUnitSize
                                                                       menuFont:font
                                                                  menuFontColor:menuFontColor
                                                                  menuBackColor:menuBackColor
                                                        menuSegmentingLineColor:menuSegmentingLineColor
                                                      distanceFromTriggerSwitch:distanceFromTriggerSwitch
                                                                 menuArrowStyle:MenuArrowStyleRound
                                                                 menuPlacements:ShowAtBottom
                                                           showAnimationEffects:ShowAnimationZoom
    ];
    VC.iconSize = CGSizeMake(20, 20);
    VC.delegate = self;
    [VC presentMenuView:self.sortButton];
}

#pragma mark - 约束设置

- (void)setupViewConstraints{
    
    [self.searchBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(150));
        make.right.equalTo(self.searchBar.superview.mas_right).offset(0);
        make.height.mas_equalTo(40);
        make.centerY.equalTo(self.zx_navTitleLabel);
    }];
    
    
    // 分页控制器约束（充满剩余空间）
    [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.categoryView.mas_bottom).offset(5);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT);
    }];
    
    [self.bottomButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT - 10);
        make.width.mas_equalTo(300);
        make.left.equalTo(self.view).offset(10);
       
    }];
    //导航上切换我的 和
    [self.switchAppListButton mas_updateConstraints:^(MASConstraintMaker *make) {

        make.width.mas_equalTo(50);
        make.height.equalTo(@40);
        make.centerY.equalTo(self.zx_navTitleView);
        make.right.equalTo(self.zx_navRightBtn.mas_left).offset(-10);

    }];
    // 右上角排序
    [self.sortButton mas_updateConstraints:^(MASConstraintMaker *make) {

        make.right.equalTo(self.view).offset(-10);
        make.centerY.equalTo(self.categoryView);
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(75);
    }];
    

}

//设置约束
- (void)updateViewConstraints{
    [super updateViewConstraints];
    // 分页控制器约束（充满剩余空间）
    [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.categoryView.mas_bottom).offset(5);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT);
    }];
    
    
    // 右上角排序
    [self.sortButton mas_updateConstraints:^(MASConstraintMaker *make) {

        make.right.equalTo(self.view).offset(-10);
        make.centerY.equalTo(self.categoryView);
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(75);

    }];
    self.switchAppListButton.alpha = !self.searchBar.alpha;
    
}


//读取数据
- (void)loadDataForCurrentPage {
    AppListViewController *controller = (AppListViewController *)self.viewControllers[self.currentPageIndex];
    
    //如果存在搜索 并且不等于上次搜索 执行重新搜索
    NSLog(@"controller.currentSearchKeyword:%@ lacal:%@",controller.keyword,self.currentSearchKeyword);
    BOOL bool1 = ![controller.keyword isEqualToString:self.currentSearchKeyword];
    BOOL bool2 = controller.dataSource.count == 0;
    if (bool1 || bool2) {
        // 搜索模式
        NSLog(@"搜索模式");
        controller.keyword = self.currentSearchKeyword;
        [controller.dataSource removeAllObjects];
        [controller refreshLoadInitialData];
    }else{
        NSLog(@"普通模式");
    }
}


#pragma mark - 监听主题变化
//监听主题变化
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 检查界面模式是否发生变化
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
        
        [self setupNavigationBar];
    }
    
}


#pragma mark - UISearchBarDelegate

// 开始搜索
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    
    [self updateViewConstraints];
}

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

    return YES; // 输入合法
}

// 当文本编辑结束时调用
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.currentSearchKeyword = searchBar.searchTextField.text;
    [self performSearchWithKeyword:self.currentSearchKeyword]; // 调用防抖搜索
}

// 文本更改时调用（包括清除）
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.currentSearchKeyword = searchText;
    [self performSearchWithKeyword:searchText]; // 调用防抖搜索
}

// 点击搜索时候
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.currentSearchKeyword = searchBar.searchTextField.text;
    NSLog(@"键盘点击搜索:%@",self.currentSearchKeyword);
    self.searchBar.alpha = self.currentSearchKeyword.length > 0;
    [self performSearchWithKeyword:self.currentSearchKeyword]; // 调用防抖搜索
    [self.view endEditing:YES];
    [self updateViewConstraints];
}

// 点击取消
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.currentSearchKeyword = nil;
    NSLog(@"点击清除按钮 搜索:%@",self.currentSearchKeyword);
    [self performSearchWithKeyword:self.currentSearchKeyword]; // 调用防抖搜索
    [self.view endEditing:YES];
    [self updateViewConstraints];
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
            [self loadDataForCurrentPage];
            
        });
    });
    dispatch_resume(self.searchDebounceTimer);
}

#pragma mark - UIPageViewControllerDataSource

// 返回上一页
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    AppListViewController * vc = (AppListViewController * )viewController;
    NSInteger index = [self.viewControllers indexOfObject:vc];
    NSLog(@"index:%ld",index);
    if (index <= 0) return nil; // 第一页没有上一页
    return self.viewControllers[index - 1];
}

// 返回下一页
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    AppListViewController * vc = (AppListViewController * )viewController;
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
        self.currentVC = pageViewController.viewControllers.firstObject;
        self.currentPageIndex = [self.viewControllers indexOfObject:self.currentVC];
        
        [self.categoryView selectItemAtIndex:self.currentPageIndex];
        
        NSLog(@"currentPageIndex:%ld",self.currentPageIndex);
        
        [self switchTabsWithIndex:self.currentPageIndex];
        
        
    }
}


#pragma mark - JXCategoryViewDelegate

- (void)categoryView:(JXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    // 当选项卡切换时，同步更新分页内容
    [self.pageViewController setViewControllers:@[self.viewControllers[index]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
    
    [self switchTabsWithIndex:index];
    
    
    
}

#pragma mark 切换页面后操作
- (void)switchTabsWithIndex:(NSInteger)index{
    [DemoBaseViewController triggerVibration];
    
    self.viewControllers[index].tag = self.titles[index];
    
    self.currentPageIndex = index;
    self.sortButton.backgroundColor = [UIColor randomColorWithAlpha:0.5];
    self.sortButton.userInteractionEnabled = YES;
    if(self.currentPageIndex ==0){
        [self.sortButton setTitle:@"最近更新" forState:UIControlStateNormal];
        self.sortButton.userInteractionEnabled = NO;
    }else if(self.currentPageIndex ==1){
        [self.sortButton setTitle:@"最多评论" forState:UIControlStateNormal];
        self.sortButton.userInteractionEnabled = NO;
    }else if(self.currentPageIndex ==2){
        [self.sortButton setTitle:@"最多推荐" forState:UIControlStateNormal];
        self.sortButton.userInteractionEnabled = NO;
    }else{
        NSString *title = self.sortArray[self.currentVC.sortType];
        [self.sortButton setTitle:title forState:UIControlStateNormal];
    }
    NSArray *titles = @[@"分类", @"收藏", @"下载"];
    NSArray *icons = @[@"tag", @"star.lefthalf.fill", @"icloud.and.arrow.down"];
    [self.bottomButton updateButtonsWithStrings:titles icons:icons];
    if(self.currentVC.dataSource.count==0){
        //读取第一页数据
        [self.currentVC refreshLoadInitialData];
    }
    
}

#pragma mark -顶部导航标签按钮点击代理

- (void)keyboardHide:(UITapGestureRecognizer *)tap{
    [super keyboardHide:tap];
    [self.view endEditing:YES];
    [self updateViewConstraints];
}

- (void)buttonTappedWithTag:(NSInteger)tag title:(nonnull NSString *)title button:(nonnull UIButton *)button {
    if(tag ==0){
        CategoryManagerViewController *vc = [CategoryManagerViewController new];
        [self presentPanModal:vc];
//        [self.navigationController pushViewController:vc animated:YES];
    }else if(tag ==1){
        MyCollectionViewController *vc = [MyCollectionViewController new];
   
        
        [self presentPanModal:vc];

    }else{
        DownloadManagerViewController *vc = [DownloadManagerViewController sharedInstance];
        [self presentPanModal:vc];

    }
}

/// 获取本地存储的UDID
- (NSString *)getUDID {
    // 优先从本地存储获取（通过描述文件获取的UDID）
    NSUUID *vendorID = [UIDevice currentDevice].identifierForVendor;
    NSString *savedUDID = [[NSUserDefaults standardUserDefaults] stringForKey:[vendorID UUIDString]];
    if (savedUDID.length > 0) {
        return savedUDID;
    }
    NSLog(@"否则尝试通过系统接口获取（可能失败，仅作为备用）savedUDID:%@",savedUDID);
    // 否则尝试通过系统接口获取（可能失败，仅作为备用）
    static CFStringRef (*$MGCopyAnswer)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    if (!gestalt) {
        NSLog(@"无法加载libMobileGestalt.dylib");
        return nil;
    }
    
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
    if (!$MGCopyAnswer) {
        NSLog(@"找不到MGCopyAnswer函数");
        dlclose(gestalt);
        return nil;
    }
    
    CFStringRef udidRef = $MGCopyAnswer(CFSTR("UniqueDeviceID"));
    NSString *udid = (__bridge_transfer NSString *)udidRef;
    NSLog(@"读取的UDID:%@",udid);
    dlclose(gestalt);
    return udid;
}


 #pragma mark -使用不带选中状态的菜单需要实现的协议方法

- (void)menu:(BaseMenuViewController *)menu didClickedItemUnitWithTag:(NSInteger)tag andItemUnitTitle:(NSString *)title {
    [self.sortButton setTitle:title forState:UIControlStateNormal];
    for (AppListViewController *vc in self.viewControllers) {
        vc.sortType = (SortType)tag;
        [vc refreshLoadInitialData];
    }
}


@end
