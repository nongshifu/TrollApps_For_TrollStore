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

@interface ToolStoreListViewController ()<UISearchResultsUpdating,UISearchBarDelegate,TemplateSectionControllerDelegate>
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, strong)  NSString *keyword;
@end

@implementation ToolStoreListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"collectionView：%@",self.collectionView);
    [self setupViews];
    [self setupViewConstraints];
    [self updateViewConstraints];
    //刷新数据
    [self refreshLoadInitialData];
    
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
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.searchBar.placeholder = @"输入应用名称搜索";
    searchController.searchBar.delegate = self;
    searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchController.searchBar.returnKeyType = UIReturnKeyDone;
    
    // 配置导航项
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *countryItem = [[UIBarButtonItem alloc] initWithTitle:@"我的发布"
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(myToolTapped)];
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


#pragma mark - 约束相关

//设置约束
-(void)setupViewConstraints{
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
//        make.top.equalTo(self.view).offset(40);
//        make.centerX.equalTo(self.view);
//        make.bottom.equalTo(self.view.mas_bottom).offset(-20);
//        make.width.equalTo(self.view);
    }];
    
    
    
}

//更新约束
-(void)updateViewConstraints{
    [super updateViewConstraints];
    
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
//        make.top.equalTo(self.view).offset(40);
//        make.centerX.equalTo(self.view);
//        make.bottom.equalTo(self.view.mas_bottom).offset(-20);
//        make.width.equalTo(self.view);
//        
    }];
}

#pragma mark - action 函数

//查看我的发布工具
- (void)myToolTapped {
    
}
//最近使用
- (void)recently {
    
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
    NSString *udid = [loadData sharedInstance].userModel.udid ?:@"";
    NSDictionary *dic = @{
        @"udid":udid,
        @"action":@"getToolList",
        @"category":@"popular",
        @"page":@(self.page),
        @"page_size":@(20),
        @"keyword":self.keyword?:@"",
        @"sort_field":@"sort_field"//排序
    };
    NSString *url = [NSString stringWithFormat:@"%@/tool_api.php",localURL];
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
        return [[TemplateSectionController alloc] initWithCellClass:[ToolViewCell class] modelClass:[WebToolModel class] delegate:self edgeInsets:UIEdgeInsetsMake(10, 10, 0, 10) usingCacheHeight:NO];
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

// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
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


@end
