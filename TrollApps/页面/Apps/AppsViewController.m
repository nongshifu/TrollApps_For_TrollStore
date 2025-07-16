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

//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface AppsViewController () <TemplateListDelegate, UIScrollViewDelegate, UISearchBarDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource,MiniButtonViewDelegate, UIContextMenuInteractionDelegate>
//顶部分类
@property (nonatomic, strong) NSMutableArray *titles; //分类标题数组
@property (nonatomic, strong) UIScrollView *tagsSubView;//按钮容器滚动视图
@property (nonatomic, strong) UIStackView *tagsStackView;//按钮容器
@property (nonatomic, strong) NSMutableArray<UIButton *> *tagButtons;//按钮数组

@property (nonatomic, strong) MiniButtonView * bottomButton; // 底部按钮

@property (nonatomic, strong) NSMutableArray<AppListViewController *> *viewControllers;
@property (nonatomic, strong) UIPageViewController *pageViewController; // 页面控制器
@property (nonatomic, strong) AppListViewController *currentVC;//所选择的控制器
@property (nonatomic, strong) UISearchBar *searchView;//搜索框

@property (nonatomic, strong) NSString *currentSearchKeyword;//关键词
@property (nonatomic, assign) NSInteger currentPageIndex;//分类下标

@property (nonatomic, strong) dispatch_source_t searchDebounceTimer; // 搜索防抖定时器
@property (nonatomic, assign) NSTimeInterval searchDebounceInterval; // 防抖间隔时间
@property (nonatomic, strong) UIImageView *logoImageView;

//全部APP 还是我的APP
@property (nonatomic, assign) BOOL showMyApp;
@property (nonatomic, strong) UIButton * switchAppListButton;

@end

@implementation AppsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"TrollApps";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.currentPageIndex = 0;
    self.isTapViewToHideKeyboard = YES;
    
    [self setupUI];

    
    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:SAVE_LOCAL_TAGS_KEY object:nil];
    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self updateButtonSelectionWithIndex:0];
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"显示后");
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = NO;
//    NSArray *titles = @[@"分类", @"收藏",];
//    NSArray *icons = @[@"tag.square", @"star.lefthalf.fill"];
//    [self.bottomButton updateButtonsWithStrings:titles icons:icons];
//    [self setupNavigationBar];
    
}

// 消失之前
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 在这里可以进行一些在视图消失之前的清理工作，比如停止动画、保存数据等。
    [self setupNavigationBar];
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
            
            [self cleanOldUI];
            
            [self setupSegmentedControl];
            
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
    self.searchView.alpha = 0;
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
    
    [self setupSegmentedControl];
    
    [self setupViewControllers];
    
    [self setupPageViewController];
    
    
    [self setupNavigationBar];
    
    [self setupAddButton];
    
    [self setupViewConstraints];
    
    [self updateViewConstraints];
    
    [self setupSideMenuController];
    
   
    
}

- (void)cleanOldUI {
    // 移除顶部分类标签相关视图
    [self.tagsSubView removeFromSuperview];
    self.tagsSubView = nil;
    self.tagsStackView = nil;
    [self.tagButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull btn, NSUInteger idx, BOOL * _Nonnull stop) {
        [btn removeFromSuperview];
    }];
    [self.tagButtons removeAllObjects];
    
    // 移除分页控制器
    [self.pageViewController.view removeFromSuperview];
    [self.pageViewController removeFromParentViewController];
    self.pageViewController = nil;
    [self.viewControllers removeAllObjects];
    
}

#pragma mark -导航

- (void)setupNavigationBar {
    NSLog(@"监听主题变化updateTabBarColor");
    
    
    // 设置导航栏基本属性
    self.zx_navTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.zx_navBar.zx_lineViewHeight = 0.5;
    self.zx_navBar.zx_lineView.alpha = 0.5;
    [self zx_removeNavGradientBac];
    //右侧切换我的和全部按钮
    self.switchAppListButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.switchAppListButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.switchAppListButton.titleLabel.textColor = [UIColor labelColor];
    [self.switchAppListButton setTitle:@"我的" forState:UIControlStateNormal];
    [self.switchAppListButton addTarget:self action:@selector(switchAppList:) forControlEvents:UIControlEventTouchUpInside];
    [self.zx_navBar addSubview:self.switchAppListButton];
    
    
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
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.searchView.alpha = 1;
            weakSelf.zx_navRightBtn.alpha = 0;
            weakSelf.switchAppListButton.alpha = 0;
        } completion:^(BOOL finished) {
            [weakSelf.searchView becomeFirstResponder];
        }];
    }];

    // 设置左侧头像按钮
    // 尝试从本地缓存读取头像
    UIImage *avatarImage = [self loadAvatarImage];
    
    // 设置左侧按钮
    [self zx_setLeftBtnWithImg:avatarImage clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        AppSearchViewController *vc = [AppSearchViewController new];
        
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navVC animated:YES completion:nil];
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
    
    // 设置标题和副标题
    [self zx_setMultiTitle:@"TrollApps"
                   subTitle:@"热门App应用 插件 应有尽有！"
                subTitleFont:[UIFont boldSystemFontOfSize:10]
             subTitleTextColor:[UIColor randomColorWithAlpha:1]];

    
    
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
    self.searchView = [[UISearchBar alloc] initWithFrame:CGRectMake(100, 0, 150, 40)];
    self.searchView.delegate = self;
    self.searchView.searchTextField.layer.borderWidth = 1;
    self.searchView.searchTextField.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.2].CGColor;
    self.searchView.alpha = 0;
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
    [self zx_addCustomTitleView:self.searchView];

}

//设置选项卡
- (void)setupSegmentedControl {
    NSArray *lacalTags = [[NSUserDefaults standardUserDefaults] arrayForKey:SAVE_LOCAL_TAGS_KEY];
    if(!lacalTags){
        self.titles = [NSMutableArray arrayWithArray:@[@"最新", @"最火", @"推荐", @"游戏辅助", @"巨魔iPA", @"无根插件", @"有根deb插件", @"应用多开", @"系统插件", @"老司机", @"无限金币"]];
        [[NSUserDefaults standardUserDefaults] setObject:self.titles forKey:SAVE_LOCAL_TAGS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{
        self.titles = [NSMutableArray arrayWithArray:lacalTags];
    }
   
    // 标签父视图（滚动视图）
    self.tagsSubView = [[UIScrollView alloc] init];
    self.tagsSubView.layer.cornerRadius = 20;
    
    self.tagsSubView.userInteractionEnabled = YES;
    self.tagsSubView.showsHorizontalScrollIndicator = NO; // 隐藏水平滚动条
    self.tagsSubView.showsVerticalScrollIndicator = NO;   // 隐藏垂直滚动条
    [self.view addSubview:self.tagsSubView];
    
    [self.tagsSubView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10);
        make.top.equalTo(self.zx_navBar.mas_bottom);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(kWidth - 20);
    }];
    
    // 标签堆栈视图
    self.tagsStackView = [[UIStackView alloc] init];
    self.tagsStackView.tag = 0;
    self.tagsStackView.axis = UILayoutConstraintAxisHorizontal;
    self.tagsStackView.alignment = UIStackViewAlignmentCenter;
    self.tagsStackView.spacing = 10.0;
    [self.tagsSubView addSubview:self.tagsStackView];
    
    // 堆栈视图约束（左右留出边距）
    [self.tagsStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsSubView).offset(10);
        make.left.equalTo(self.tagsSubView).offset(5);
        make.right.equalTo(self.tagsSubView).offset(-10); // 右侧留10pt边距
        
        make.height.mas_equalTo(30);
    }];
    
    // 初始化按钮数组
    self.tagButtons = [NSMutableArray array];
    
    // 添加标签按钮
    for (int i = 0; i < self.titles.count; i++) {
        NSString *title = self.titles[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.layer.cornerRadius = 7;
        button.tag = i;
        button.contentEdgeInsets = UIEdgeInsetsMake(3, 8, 3, 8);
        button.titleLabel.font = [UIFont boldSystemFontOfSize:(i == 0 ? 17 : 15)];
        button.backgroundColor = [UIColor colorWithLightColor:[UIColor randomColorWithAlpha:0.9]
                                                    darkColor:[UIColor randomColorWithAlpha:0.5]
        ];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(tagTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.tagsStackView addArrangedSubview:button];
        [self.tagButtons addObject:button];
    }
    
    // 关键：通过堆栈视图的宽度设置滚动视图的contentSize
    [self.tagsStackView layoutIfNeeded]; // 强制刷新布局，获取实际宽度
    CGFloat contentWidth = self.tagsStackView.frame.size.width + 20; // 加上左右边距（10+10）
    self.tagsSubView.contentSize = CGSizeMake(contentWidth, 50);
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
    NSArray *titles = @[@"分类", @"收藏",];
    NSArray *icons = @[@"tag.square", @"star.lefthalf.fill"];
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
        controller.tagPageIndex = i;
        controller.showMyApp = NO;
        controller.title = self.titles[i];
        controller.collectionView.backgroundColor = [UIColor clearColor];
        controller.view.backgroundColor = [UIColor clearColor];
        [controller.view removeDynamicBackground];
        [self.viewControllers addObject:controller];
        [controller refreshLoadInitialData];
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
}

#pragma mark - Action

- (void)switchAppList:(UIButton*)button{
    self.showMyApp = !self.showMyApp;
    NSString *msg = self.showMyApp ? @"已切换为我的APP" :@"切换显示全部APP";
    [SVProgressHUD showImage:[UIImage systemImageNamed:@"scribble"] status:msg];
    [SVProgressHUD dismissWithDelay:2];

    for (AppListViewController *vc in self.viewControllers) {
        vc.showMyApp = self.showMyApp;
        [vc refreshLoadInitialData];
    }
    NSString *title = self.showMyApp ? @"我的" :@"全部";
    // 创建弱引用
    [button setTitle:title forState:UIControlStateNormal];
}

#pragma mark - 约束设置

- (void)setupViewConstraints{
    
    [self.searchView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(150));
        make.right.equalTo(self.searchView.superview.mas_right).offset(0);
        make.height.mas_equalTo(40);
        make.centerY.equalTo(self.zx_navTitleLabel);
    }];
    
    
    // 分页控制器约束（充满剩余空间）
    [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsStackView.mas_bottom).offset(10);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT);
    }];
    
    [self.bottomButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT - 10);
        make.width.mas_equalTo(300);
        make.left.equalTo(self.view).offset(10);
       
    }];
    [self.switchAppListButton mas_updateConstraints:^(MASConstraintMaker *make) {

        make.width.mas_equalTo(50);
        make.height.equalTo(@40);
        make.centerY.equalTo(self.zx_navTitleView);
        make.right.equalTo(self.zx_navRightBtn.mas_left).offset(-10);

    }];
    

}

//设置约束
- (void)updateViewConstraints{
    [super updateViewConstraints];
    // 分页控制器约束（充满剩余空间）
    [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsStackView.mas_bottom).offset(10);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT);
    }];
    
    [UIView animateWithDuration:0.3 animations:^{
       
        self.switchAppListButton.alpha = !self.searchView.alpha;
        self.zx_navRightBtn.alpha = !self.searchView.alpha;
        
    }];
    
}

//读取数据
- (void)loadDataForCurrentPage {
    AppListViewController *controller = (AppListViewController *)self.viewControllers[self.currentPageIndex];
    controller.tagPageIndex = self.currentPageIndex;
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

//监听主题变化
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 检查界面模式是否发生变化
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
        
        [self setupNavigationBar];
    }
    
}


- (void)updateButtonSelectionWithIndex:(NSInteger)index {
    self.currentPageIndex = index;
    
    NSLog(@"index:%ld", (long)index);
    
    // 先获取目标按钮
    UIButton *targetButton = nil;
    for (UIButton *btn in self.tagButtons) {
        if (btn.tag == index) {
            targetButton = btn;
            break;
        }
    }
    
    // 先更新所有按钮的状态动画
    for (UIButton *button in self.tagButtons) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            if (button.tag == self.currentPageIndex) {
                // 选中状态：放大1.1倍
                button.transform = CGAffineTransformMakeScale(1.1, 1.1);
                button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
                button.alpha = 1.0;
            } else {
                // 未选中状态：恢复原始大小
                button.transform = CGAffineTransformIdentity;
                button.titleLabel.font = [UIFont systemFontOfSize:15];
                button.alpha = 0.5;
            }
        } completion:nil];
    }
    
    // 单独处理目标按钮的滚动（确保在按钮状态更新后执行）
    
    if (targetButton) {
        [self.tagsSubView layoutIfNeeded];
        
        CGRect buttonFrameInScrollView = [targetButton convertRect:targetButton.bounds toView:self.tagsSubView];
        CGRect visibleRect = self.tagsSubView.bounds;
        
        // 计算按钮中心点
        CGFloat buttonCenterX = buttonFrameInScrollView.origin.x + buttonFrameInScrollView.size.width / 2;
        // 计算滚动视图可视区域中心点
        CGFloat scrollViewCenterX = visibleRect.size.width / 2;
        
        // 计算需要滚动的偏移量
        CGFloat targetOffsetX = buttonCenterX - scrollViewCenterX;
        // 限制偏移量在有效范围内（不超出内容边界）
        targetOffsetX = MAX(0, MIN(targetOffsetX, self.tagsSubView.contentSize.width - visibleRect.size.width));
        
        // 执行滚动
        if (ABS(self.tagsSubView.contentOffset.x - targetOffsetX) > 10) { // 超过10pt才滚动
            [self.tagsSubView setContentOffset:CGPointMake(targetOffsetX, 0) animated:YES];
        }
    }
}


#pragma mark - UISearchBarDelegate

// 开始搜索
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    self.searchView.alpha =1;
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
    [self performSearchWithKeyword:self.currentSearchKeyword]; // 调用防抖搜索
    [self.view endEditing:YES];
    if(self.currentSearchKeyword.length ==0){
        [UIView animateWithDuration:0.3 animations:^{
            self.searchView.alpha = 0;
            self.switchAppListButton.alpha = 1;
            self.zx_navRightBtn.alpha = 1;
        }];
    }
}

// 点击取消
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.currentSearchKeyword = nil;
    NSLog(@"点击清除按钮 搜索:%@",self.currentSearchKeyword);
    [self performSearchWithKeyword:self.currentSearchKeyword]; // 调用防抖搜索
    [self.view endEditing:YES];
    if(self.currentSearchKeyword.length ==0){
        [UIView animateWithDuration:0.3 animations:^{
            self.searchView.alpha = 0;
            self.switchAppListButton.alpha = 1;
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
        [self updateButtonSelectionWithIndex:self.currentPageIndex];
        NSLog(@"currentPageIndex:%ld",self.currentPageIndex);
        
        
    }
}

#pragma mark -顶部导航标签按钮点击代理


- (void)tagTap:(UIButton *)button{
    NSInteger tag = button.tag;
    [self updateButtonSelectionWithIndex:tag];
    if (tag < self.viewControllers.count) {
        UIViewController *postViewController = self.viewControllers[tag];
        [self.pageViewController setViewControllers:@[postViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
}

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
        MyFavoritesListViewController *vc = [MyFavoritesListViewController new];
   
        
        [self presentPanModal:vc];

    }else{
        PublishAppViewController *vc = [PublishAppViewController new];
        [self presentPanModal:vc];
//        [self.navigationController pushViewController:vc animated:YES];
//        [self presentViewController:vc animated:YES completion:nil];
        // 2. 包装到导航控制器中（确保顶部导航栏生效）
//        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
//        [self presentViewController:navVC animated:YES completion:nil];
        
//        testNavigationViewController *navVC = [[testNavigationViewController alloc] initWithRootViewController:[testViewController new]];
//        [self presentViewController:navVC animated:YES completion:nil];
        
        
    }
}



@end
