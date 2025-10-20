//
//  AppSearchViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "AppSearchViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>
#import "AppSearchCell.h"

@interface AppSearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate,UISearchResultsUpdating>


@property (nonatomic, strong) UITableView *resultTableView;
@property (nonatomic, strong) NSMutableArray<ITunesAppModel *> *dataSource;
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, assign) BOOL isLoading;       // 加载状态标记

@property (nonatomic, strong) UIBarButtonItem *countryItem; // 地区选择按钮
@property (nonatomic, strong) NSArray *countryList; // 支持的地区列表

@property (nonatomic, assign) NSInteger currentPage; // 当前页码（从0开始）
@property (nonatomic, assign) NSInteger totalCount;  // 总结果数（用于判断是否有更多数据）
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation AppSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    
    self.title = @"AppStore搜索";
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    self.isTapViewToHideKeyboard = YES;
    [self setupCountryData];
    [self setupNavigationBarWithSearch];
    [self setupNavigationBar];
    [self setupTableView];
    
    [self setupRefresh]; // 初始化刷新控件
    
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    [self setupNavigationBarWithSearch];
    // 确保在视图即将显示时设置导航栏，覆盖系统默认设置
    
    if(!self.keyword){
        [self performSearchWithText:@"游戏"];
    }else{
        self.searchController.searchBar.text =self.keyword;
        [self performSearchWithText:self.keyword];
    }
    
}

#pragma mark - 初始化导航栏（含搜索框和地区选择）

- (void)setupNavigationBarWithSearch {
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = YES;
    // 创建搜索控制器
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"输入应用名称搜索";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.returnKeyType = UIReturnKeyDone;
    
    // 配置导航项
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    
    // 地区选择按钮（移至右侧）
    self.countryItem = [[UIBarButtonItem alloc] initWithTitle:@"中国"
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(countryButtonTapped)];
    self.countryItem.tintColor = [UIColor labelColor];
    self.navigationItem.rightBarButtonItem = self.countryItem;
    
    // 关闭按钮
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dismiss)];
    closeButton.tintColor = [UIColor labelColor];
    
    // 关键：禁用系统默认的返回按钮
    self.navigationItem.leftItemsSupplementBackButton = NO; // 禁用补充模式
    self.navigationItem.hidesBackButton = YES; // 隐藏系统返回按钮
    
    // 设置自定义左侧按钮
    self.navigationItem.leftBarButtonItem = closeButton;
}

#pragma mark - 初始化表格
- (void)setupTableView {
   
    self.dataSource = [NSMutableArray array];
    // 结果表格
    self.resultTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.resultTableView.dataSource = self;
    self.resultTableView.backgroundColor = [UIColor clearColor];
    self.resultTableView.delegate = self;
    self.resultTableView.rowHeight = UITableViewAutomaticDimension;
    self.resultTableView.estimatedRowHeight = 100;
    self.resultTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    [self.resultTableView registerClass:[AppSearchCell class] forCellReuseIdentifier:@"AppCell"];
    [self.view addSubview:self.resultTableView];
    
    
    // 约束布局（直接从顶部开始）
    [self.resultTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
}

#pragma mark - 初始化刷新控件
- (void)setupRefresh {
    // 下拉刷新
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.textColor = [UIColor systemGrayColor];
    header.arrowView.image = [UIImage systemImageNamed:@"chevron.down"];
    self.resultTableView.mj_header = header;
    
    // 上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    footer.stateLabel.textColor = [UIColor systemGrayColor];
    self.resultTableView.mj_footer = footer;
    self.resultTableView.mj_footer.hidden = YES;
}

#pragma mark - 分页数据处理
// 重置分页数据（用于下拉刷新）
- (void)resetPageData {
    self.currentPage = 0;
    self.totalCount = 0;
    [self.dataSource removeAllObjects];
}

// 下拉刷新：重新加载第一页
- (void)refreshData {
    [self resetPageData];
    [self performSearchWithText:self.keyword?self.keyword:@"游戏"]; // 调用搜索方法，会加载第0页数据
}

// 上拉加载更多：加载下一页
- (void)loadMoreData {
    // 判断是否还有更多数据
    self.currentPage++;
    [self performSearchWithText:self.keyword];; // 加载下一页
}


#pragma mark - 初始化地区数据
- (void)setupCountryData {
    // 地区列表：包含常用国家/地区的名称和代码（可扩展）
    self.countryList = @[
        @{@"name": @"中国", @"code": @"cn"},
        @{@"name": @"美国", @"code": @"us"},
        @{@"name": @"日本", @"code": @"jp"},
        @{@"name": @"英国", @"code": @"gb"},
        @{@"name": @"韩国", @"code": @"kr"},
        @{@"name": @"德国", @"code": @"de"},
        @{@"name": @"法国", @"code": @"fr"},
        @{@"name": @"澳大利亚", @"code": @"au"}
    ];
    // 默认选中中国区
    self.selectedCountryCode = @"cn";
}

#pragma mark - 初始化导航栏（含地区选择）
- (void)setupNavigationBar {
    self.navigationItem.title = @"App搜索";
    
    // 地区选择按钮
    self.countryItem = [[UIBarButtonItem alloc] initWithTitle:@"中国"
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(countryButtonTapped)];
    self.countryItem.tintColor = [UIColor labelColor];
    
    // 左侧取消按钮（可选）
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(cancelSearch)];
    self.navigationItem.leftBarButtonItem = cancelItem;
    self.navigationItem.rightBarButtonItem = self.countryItem;
}

// 取消搜索（返回上一页）
- (void)cancelSearch {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 地区选择按钮点击
- (void)countryButtonTapped {
    // 创建地区选择弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择商店地区"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 遍历地区列表添加选项
    for (NSDictionary *country in self.countryList) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:country[@"name"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            // 更新选中的地区
            self.selectedCountryCode = country[@"code"];
            self.countryItem.title = country[@"name"];
            
            // 如果已有搜索关键词，切换地区后重新搜索
            if (self.keyword.length > 0) {
                [self.searchTimer invalidate];
                [self performSearchWithText:self.keyword];
            }
        }];
        [alert addAction:action];
    }
    
    // 取消按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    // 适配iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.countryItem;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UISearchResultsUpdating 代理


- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    
    [self.searchTimer invalidate];
    
    if (searchText.length == 0) {
        [self resetPageData];
        [self.resultTableView reloadData];
        [self.resultTableView.mj_footer setHidden:YES];
        [self performSearchWithText:@"游戏"];
        return;
    }
    
    self.keyword = searchText;
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                       target:self
                                                     selector:@selector(refreshData)
                                                     userInfo:searchText
                                                      repeats:NO];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
//    self.keyword = @"";
//    [self performSearchWithText:@"游戏"];
}

// 执行搜索请求
#pragma mark - 执行搜索请求（添加分页参数）

- (void)performSearchWithText:(NSString*)text {
    if (self.isLoading) return;
    self.isLoading = YES;
    
    
    
    // 关键词编码
    NSString *encodedKeyword = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    // 构建带分页参数的URL（添加offset参数）
    NSString *urlString = [NSString stringWithFormat:@"https://itunes.apple.com/search?entity=software&limit=20&offset=%ld&term=%@&country=%@",
                           self.currentPage,
                          encodedKeyword,
                          self.selectedCountryCode];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"请求URL：%@", urlString);
    
    // 发送请求（与原有逻辑一致，仅URL不同）
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 结束刷新状态
            [self.resultTableView.mj_header endRefreshing];
            [self.resultTableView.mj_footer endRefreshing];
            self.isLoading = NO;
            
            if (error) {
                NSLog(@"网络请求错误：%@", error);
                return;
            }
            
            // 解析JSON
            NSError *jsonError;
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                NSLog(@"JSON解析错误：%@", jsonError);
                return;
            }
            
            // 获取总结果数（从API返回的resultCount字段）
            self.totalCount = [jsonObject[@"resultCount"] integerValue];
            NSArray *results = jsonObject[@"results"];
            
            // 下拉刷新时直接替换数据，上拉加载时追加数据
            if (self.currentPage == 0) {
                [self.dataSource removeAllObjects];
            }
            for (NSDictionary *dict in results) {
                ITunesAppModel *model = [ITunesAppModel modelWithDictionary:dict];
                if (model) [self.dataSource addObject:model];
            }
            
            // 刷新表格
            [self.resultTableView reloadData];
            
            // 控制footer显示/隐藏
            self.resultTableView.mj_footer.hidden = (self.dataSource.count == 0);
            
            // 判断是否还有更多数据
            if (self.totalCount < 20) {
                [self.resultTableView.mj_footer endRefreshingWithNoMoreData];
            }
        });
    }];
    [task resume];
}

#pragma mark - 表格数据源与代理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

// 修改 cellForRowAtIndexPath 方法
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppCell" forIndexPath:indexPath];
    ITunesAppModel *model = self.dataSource[indexPath.row];
    [cell configureWithModel:model];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    ITunesAppModel *selectedModel = self.dataSource[indexPath.row];
    
    // 回调选中的模型（包含所有参数）
    if ([self.delegate respondsToSelector:@selector(didSelectAppModel:controller:tableView:cell:)]) {
        [self.delegate didSelectAppModel:selectedModel controller:self tableView:tableView cell:cell];
    }
    
    // 示例：打印选中的信息
    NSLog(@"选中应用：%@\n图标地址：%@\nStoreID：bundleID:%@  storeID:%@",
          selectedModel.trackName,
          selectedModel.artworkUrl512,
          selectedModel.bundleId,
          selectedModel.trackId);
}

#pragma mark - 内存管理

- (void)dealloc {
    [self.searchTimer invalidate];
}

@end
