//
//  ToolViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/4.
//

#import "ToolStoreListViewController.h"
#import "ToolViewCell.h"
#import "WebToolModel.h"
#import "loadData.h"
#import "NewToolViewController.h"
#import "ShowOneToolViewController.h"
#import "NewProfileViewController.h"
#import "LeftViewController.h"
#import "ArrowheadMenu.h"
// 定义排序类型枚举
typedef NS_ENUM(NSInteger, SortType) {
    SortTypeRecentUpdate = 0,    // 最近更新
    SortTypeEarliestRelease = 1, // 最早发布
    SortTypeMostComments = 2,    // 最多评论
    SortTypeMostLikes = 3,       // 最多点赞
    SortTypeMostFavorites = 4,   // 最多收藏
    SortTypeMostShares  = 5      // 最多分享
};


@interface ToolStoreListViewController ()<UISearchResultsUpdating,UISearchBarDelegate,TemplateSectionControllerDelegate, MenuViewControllerDelegate>
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, strong)  NSString *keyword;
@property (nonatomic, assign)  BOOL isMyTool;
@property (nonatomic, strong)  UIBarButtonItem * rightItem;
@property (nonatomic, assign)  SortType sortType;
@property (nonatomic, strong)  UISearchController *searchController;
@end

@implementation ToolStoreListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    NSLog(@"collectionView：%@",self.collectionView);
    [self setupViews];
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    //刷新数据
    [self refreshLoadInitialData];
    //设置左右列表
    [self setupSideMenuController];
    
}

#pragma mark - 初始化UI

- (void)setupViews{
    
    //默认
    self.title = @"热门工具";
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;

    //导航搜索
    [self setupNavigationBarWithSearch];
    //删除父类表格约束
    [self.collectionView removeFromSuperview];
    //重新添加到视图
    [self.view addSubview:self.collectionView];
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    
    
}

- (void)setupNavigationBarWithSearch {
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    // 创建搜索控制器
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"全站搜索你要的Web工具";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.returnKeyType = UIReturnKeyDone;
    
    // 配置导航项
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    
    // 地区选择按钮（移至右侧）text.alignright
   
    self.rightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"text.alignright"] style:UIBarButtonItemStylePlain target:self action:@selector(rightTapped:)];
    self.rightItem.tintColor = [UIColor labelColor];
    self.navigationItem.rightBarButtonItem = self.rightItem;
    
    // 关闭按钮
    
    UIBarButtonItem * leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"clock"] style:UIBarButtonItemStylePlain target:self action:@selector(recently)];
    
    
    leftItem.tintColor = [UIColor labelColor];
    
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *myItem = [[UIBarButtonItem alloc] initWithTitle:@"ME" style:UIBarButtonItemStylePlain target:self action:@selector(myToolTapped:)];
    myItem.tintColor = [UIColor labelColor];
    
    myItem.tintColor = [UIColor labelColor];
    
    // 关键：禁用系统默认的返回按钮
    self.navigationItem.leftItemsSupplementBackButton = NO; // 禁用补充模式
    self.navigationItem.hidesBackButton = YES; // 隐藏系统返回按钮
    
    // 设置自定义左侧按钮
    self.navigationItem.leftBarButtonItems = @[leftItem,myItem];
}


//设置左侧菜单
- (void)setupSideMenuController {
    self.sideMenuController = [self getLGSideMenuController];
   
    // 设置侧滑阈值，这里设置为从屏幕边缘开始 20 点的距离才触发侧滑
    self.sideMenuController.leftViewController = [LeftViewController new];
    
    self.sideMenuController.rightViewController = [LeftViewController new];
   
    //设置宽度
   
    self.sideMenuController.leftViewWidth = 200;
    self.sideMenuController.rightViewWidth = 200;
    // 设置左侧菜单的滑动触发范围
//    self.sideMenuController.swipeGestureArea = LGSideMenuSwipeGestureAreaBorders;//全屏可触摸
   
    //默认不允许触摸侧滑 按钮点击显示
    self.sideMenuController.leftViewSwipeGestureEnabled = YES;
    self.sideMenuController.rightViewSwipeGestureEnabled = YES;

    // 创建弱引用
    __weak typeof(self) weakSelf = self;
    //侧面出现后才可以滑动 用来隐藏
    self.sideMenuController.willShowLeftView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 禁用侧滑手势
        weakSelf.sideMenuController.leftViewSwipeGestureEnabled = YES;
        LeftViewController *vc = (LeftViewController *)weakSelf.sideMenuController.leftViewController;
        [vc refreshLoadInitialData];
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



#pragma mark - 约束相关

//设置约束
-(void)setupViewConstraints{
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT);
    }];
    
    
    
}

//更新约束
-(void)updateViewConstraints{
    [super updateViewConstraints];
    
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT);
    }];
}

#pragma mark - action 函数

//查看我的发布工具
- (void)myToolTapped:(UIBarButtonItem*)item {
    
    
    self.isMyTool = !self.isMyTool;
    [self refreshLoadInitialData];
    item.title = self.isMyTool ? @"ALL":@"ME";
    
    self.title = self.isMyTool ? @"我的发布":@"热门工具";
    if(self.isMyTool){
        self.searchController.searchBar.placeholder = @"搜索我发布的Web工具";
    }else{
        self.searchController.searchBar.placeholder = @"全站搜索你要的Web工具";
    }
    
}

//排序
- (void)rightTapped:(UIBarButtonItem*)item {
    
    // 处理左边图标点击逻辑
   
    NSArray *title = @[@"最近更新", @"最早发布", @"最多评论", @"最多点赞", @"最多收藏", @"最多分享"];
    NSArray *icon = @[@"clock", @"arrow.clockwise.icloud", @"message", @"hand.thumbsup.fill", @"star", @"arrowshape.turn.up.right"];
    CGSize menuUnitSize = CGSizeMake(130, 40);
    CGFloat distanceFromTriggerSwitch = 10;
    UIFont * font = [UIFont boldSystemFontOfSize:13];
    UIColor * menuFontColor = [UIColor labelColor];
    UIColor * menuBackColor = [[UIColor tertiarySystemBackgroundColor] colorWithAlphaComponent:0.99];
    UIColor * menuSegmentingLineColor = [UIColor labelColor];
    
    ArrowheadMenu *VC = [[ArrowheadMenu alloc] initCustomArrowheadMenuWithTitle:title
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
    [VC presentMenuView:item];
    
}

//最近使用
- (void)recently {
    [self.sideMenuController showLeftViewAnimated:YES completionHandler:nil];
}

#pragma mark - 数据操作

//刷新数据
- (void)refreshData{
    [self.dataSource removeAllObjects];
    //重置页码
    self.page = 1;
    //重新搜索
    [self loadDataWithPage:self.page];
}

#pragma mark - UISearchResultsUpdating 代理

//输入过程 防抖0.5 执行关键词搜索
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    
    [self.searchTimer invalidate];
    
    
    self.keyword = searchText;
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                       target:self
                                                     selector:@selector(refreshData)
                                                     userInfo:searchText
                                                      repeats:NO];
}


//点击取消时 执行默认搜索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.page = 1;
    [self performSearchWithText:@""];
}

// 执行搜索请求
#pragma mark - 执行搜索请求（添加分页参数）

- (void)performSearchWithText:(NSString*)text {
    //关键词判断
    
    //赋值属性
    self.keyword = text;
    //执行搜索
    [self loadDataWithPage:self.page];
}


#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page {
    NSString *udid = [loadData sharedInstance].userModel.udid ?:[[NewProfileViewController sharedInstance] getIDFV];
    
    NSDictionary *dic = @{
        @"udid":udid,
        @"action":@"getToolList",
        
        @"page":@(self.page),
        @"page_size":@(20),
        @"isMyTool":@(self.isMyTool),
        @"keyword":self.keyword?:@"",
        @"sortType":@(self.sortType)
    };
    NSString *url = [NSString stringWithFormat:@"%@/tool/tool_api.php",localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"请求读取工具stringResult：%@",stringResult);
            [self endRefreshing];
            if(self.page <=1){
                [self.dataSource removeAllObjects];
            }
            if(!jsonResult){
                [self showAlertFromViewController:self title:@"返回数据错误" message:stringResult];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if(code == 200){
                NSDictionary *data = jsonResult[@"data"];
                NSArray *tools = data[@"tools"];
                for (NSDictionary *dic in tools) {
                    NSLog(@"遍历请求读取工具dic：%@",dic);
                    WebToolModel *model = [WebToolModel yy_modelWithDictionary:dic];
                    if(model){
                        [self.dataSource addObject:model];
                    }
                }
                //刷新表格
                [self refreshTable];
                //解析页码信息
                NSDictionary *pagination = data[@"pagination"];
                NSLog(@"请求读取工具pagination：%@",pagination);
                NSInteger total_pages = [pagination[@"total_pages"] intValue];
                if(total_pages > self.page){
                    self.page +=1;
                }else{
                    [self handleNoMoreData];
                }
            }else{
                [self showAlertFromViewController:self title:@"数据错误" message:msg];
            }
            self.emptyView.hidden = self.dataSource.count>0;
        });
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertFromViewController:self title:@"error" message:[NSString stringWithFormat:@"%@",error]];
        });
    }];
    
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[WebToolModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[ToolViewCell class] modelClass:[WebToolModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10) usingCacheHeight:YES];
    }
    return nil;
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
    if([model isKindOfClass:[WebToolModel class]]){
        
        WebToolModel * webToolModel = (WebToolModel *)model;
        ShowOneToolViewController *vc = [ShowOneToolViewController new];
        vc.tool_id = webToolModel.tool_id;
        [self presentPanModal:vc];
    }
    
}

#pragma mark - 控制器显示函数
// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self setBackgroundUI];
    [self topBackageView];
    [self updateViewConstraints];

    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 在这里进行与布局完成后相关的操作，比如获取子视图的最终尺寸等
    NSLog(@"视图布局完成：%@",self.collectionView);
}



- (void)dealloc {
    // 移除通知观察者
    [[NSNotificationCenter defaultCenter] removeObserver:UIKeyboardWillShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIKeyboardWillHideNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}



- (void)topBackageView{
    //创建一个空视图渐变色
    
    UIView * navigationControllerBackageView =[[UIView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, 150)];
    navigationControllerBackageView.backgroundColor = [UIColor clearColor];
   
    UIImage *image = [UIView convertViewToPNG:navigationControllerBackageView];
    
    
    //先判断下系统
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        appearance.backgroundColor = [UIColor clearColor];
        appearance.backgroundEffect = nil; // 完全透明，无磨砂
        appearance.backgroundImage = image;
        appearance.shadowImage = [UIImage new];
        appearance.shadowColor = nil;
        
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;
        
    }else{
        //顶部背景图
        [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        //清除分割线
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    }

}


- (void)setBackgroundUI {

    // 设置背景颜色和透明度
    self.view.backgroundColor = [UIColor clearColor];
    [self.view removeDynamicBackground];
    
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    NSLog(@"界面模式发生变化");
    [self setBackgroundUI];
    [self topBackageView];
    
}


#pragma mark -使用不带选中状态的菜单需要实现的协议方法

- (void)menu:(BaseMenuViewController *)menu didClickedItemUnitWithTag:(NSInteger)tag andItemUnitTitle:(NSString *)title {
    self.sortType = tag;
    self.rightItem.title = title;
    [self refreshLoadInitialData];
    
}

@end
