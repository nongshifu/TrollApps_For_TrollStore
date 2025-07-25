//
//  CommunityViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/6/30.
//

#import "CommunityViewController.h"
#import "NewProfileViewController.h"
#import "WebToolModel.h"
#import "ToolViewCell.h"

@interface CommunityViewController ()<UISearchResultsUpdating,UISearchBarDelegate,TemplateSectionControllerDelegate>
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, strong)  NSString *keyword;
@end

@implementation CommunityViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    [self setupViews];
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    
}


#pragma mark - 初始化UI

- (void)setupViews{
    
    //默认
    self.title = @"交流社区";
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;

    //导航搜索
    [self setupNavigationBarWithSearch];
    
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    
    
}

- (void)setupNavigationBarWithSearch {
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    // 创建搜索控制器
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.searchBar.placeholder = @"输入搜索内容";
    searchController.searchBar.delegate = self;
    searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchController.searchBar.returnKeyType = UIReturnKeyDone;
    
    // 配置导航项
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *countryItem = [[UIBarButtonItem alloc] initWithTitle:@"关于" style:UIBarButtonItemStylePlain target:self action:@selector(myToolTapped:)];
    countryItem.tintColor = [UIColor labelColor];
    self.navigationItem.rightBarButtonItem = countryItem;
    
    // 关闭按钮
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"最近"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(recently)];
    closeButton.tintColor = [UIColor labelColor];
    
    // 关键：禁用系统默认的返回按钮
    self.navigationItem.leftItemsSupplementBackButton = NO; // 禁用补充模式
    self.navigationItem.hidesBackButton = YES; // 隐藏系统返回按钮
    
    // 设置自定义左侧按钮
    self.navigationItem.leftBarButtonItem = closeButton;
}

#pragma mark - 数据操作

//刷新数据
- (void)refreshData{
    
    //重置页码
    self.page = 1;
    //重新搜索
    [self loadDataWithPage:self.page];
}

#pragma mark - 约束相关

//设置约束
-(void)setupViewConstraints{
    
    
    
}

//更新约束
-(void)updateViewConstraints{
    [super updateViewConstraints];
    
}

#pragma mark - action 函数

//查看我的发布工具
- (void)myToolTapped:(UIBarButtonItem*)item {
    
}
//最近使用
- (void)recently {
    
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
    [self refreshTable];
    
    [self endRefreshing];
    [self handleNoMoreData];
    
    [self updateEmptyViewVisibility];
    
    // 自定义空视图内容
    [self.emptyView configureWithImage:[UIImage systemImageNamed:@"list.bullet.rectangle"]
                           title:@"欢迎热门社区对接\n合作联系微信:shisange2026"
                     buttonTitle:@"刷新"];
    
    // 添加按钮点击事件
    [self.emptyView.actionButton addTarget:self
                                action:@selector(refreshLoadInitialData)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.emptyView updateConstraints];
    
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
        
    }
    
}

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
    
    [self loadDataWithPage:self.page];
    
    
    
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
    [super topBackageView];
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
    [super setBackgroundUI];

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

@end
