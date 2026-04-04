//
//  PostListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "PostListViewController.h"
#import "PostModel.h"
#import "PostCell.h"
#import "config.h"
#import "NewProfileViewController.h"
#import "PostPublishViewController.h"
#import "SystemViewController.h"
#import "ShowOnePostViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <Masonry/Masonry.h>
#import <UIKit/UIKit.h>

#undef MY_NSLog_ENABLED
#define MY_NSLog_ENABLED YES

@interface PostListViewController () <TemplateSectionControllerDelegate, UISearchBarDelegate>
/// 搜索控制器（导航栏搜索框）
@property (nonatomic, strong) UISearchController *searchController;
/// 排序按钮（导航栏右侧）
@property (nonatomic, strong) UIButton *sortButton;
/// 筛选按钮（导航栏右侧，排序按钮左边）
@property (nonatomic, strong) UIButton *filterButton;
/// 发帖按钮
@property (nonatomic, strong) UIButton *switchButton;
/// 时间筛选弹窗（开始/结束时间选择）
@property (nonatomic, strong) UIAlertController *timeFilterAlert;

@property (nonatomic, assign) SquareVCType currentVCType; // 记录当前控制器类型
@end

@implementation PostListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 基础配置
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    self.title = @"社区广场";
    self.currentVCType = [[NSUserDefaults standardUserDefaults] integerForKey:kSquareVCTypeKey];
    // 初始化导航栏UI
    [self setupNavigationBar];
    
    // 初始化筛选参数默认值
    [self setupDefaultFilterParams];
    
    // 加载第一页数据
    [self loadDataWithPage:1];
    // 加载系统配置
    [SystemViewController sharedInstance];
}

#pragma mark - 初始化默认筛选参数
- (void)setupDefaultFilterParams {
    self.category_id = 0; // 默认全部分类
    self.topic_id = 0;    // 默认全部标签
    self.start_time = 0;  // 默认无开始时间
    self.end_time = 0;    // 默认无结束时间
    self.post_sort_type = 0; // 默认按创建时间排序
    self.keyword = @"";   // 默认无搜索关键字
}

#pragma mark - 配置导航栏UI（搜索框 + 筛选/排序按钮）
- (void)setupNavigationBar {
    // 1. 搜索框配置
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchBar.placeholder = @"搜索帖子标题/内容";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.tintColor = [UIColor labelColor];
    self.searchController.searchBar.barTintColor = [UIColor labelColor];
    self.searchController.obscuresBackgroundDuringPresentation = NO; // 搜索时不模糊背景
    self.searchController.hidesNavigationBarDuringPresentation = YES; // 搜索时不隐藏导航栏
    
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    
    // 适配iOS 11+导航栏搜索框
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    } else {
        // 低版本适配：把搜索框作为导航栏titleView
        self.navigationItem.titleView = self.searchController.searchBar;
        self.searchController.searchBar.frame = CGRectMake(0, 0, kWidth - 100, 30);
    }
    
    // 2. 筛选按钮（分类/标签/时间）
    self.filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.filterButton setTitle:@"筛选" forState:UIControlStateNormal];
    [self.filterButton addTarget:self action:@selector(filterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *filterItem = [[UIBarButtonItem alloc] initWithCustomView:self.filterButton];
    self.filterButton.tintColor = [UIColor labelColor];
    self.filterButton.titleLabel.textColor = [UIColor labelColor];
    
    // 3. 排序按钮
    self.sortButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sortButton setTitle:@"排序" forState:UIControlStateNormal];
    [self.sortButton addTarget:self action:@selector(sortButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *sortItem = [[UIBarButtonItem alloc] initWithCustomView:self.sortButton];
    self.sortButton.tintColor = [UIColor labelColor];
    self.sortButton.titleLabel.textColor = [UIColor labelColor];
    
    
    // 4. 导航栏右侧按钮
    self.navigationItem.leftBarButtonItems = @[sortItem, filterItem];
    
    // 5. 切换聊天按钮
    self.switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.switchButton setImage:[UIImage systemImageNamed:@"switch.2"] forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(switchMode) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *switchModeItem = [[UIBarButtonItem alloc] initWithCustomView:self.switchButton];
    self.switchButton.tintColor = [UIColor redColor];
    self.navigationItem.rightBarButtonItem = switchModeItem;
}

#pragma mark - 搜索框代理（UISearchBarDelegate）
// 搜索框输入完成/点击搜索按钮
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder]; // 收起键盘
    self.keyword = searchBar.text ?: @"";
    self.page = 1; // 重置页码为1
    [self loadDataWithPage:self.page]; // 重新加载数据
}

// 搜索框取消搜索
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    self.keyword = @"";
    self.page = 1;
    [self loadDataWithPage:self.page];
}

// 搜索框文本变化（可选：实时搜索，需加防抖）
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // 防抖处理：输入停止0.5秒后再搜索
    static dispatch_source_t timer;
    if (timer) {
        dispatch_source_cancel(timer);
    }
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(timer, ^{
        self.keyword = searchText ?: @"";
        self.page = 1;
        [self loadDataWithPage:self.page];
        timer = nil;
    });
    dispatch_resume(timer);
}

#pragma mark - 排序按钮点击事件（弹出排序选项）
- (void)sortButtonClicked {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择排序方式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 排序选项：对应PostSortType枚举
    NSArray *sortTitles = @[@"按创建时间", @"按热度", @"按推荐权重", @"按最后更新时间"];
    NSArray *sortTypes = @[@0, @1, @2, @3];
    
    for (NSInteger i = 0; i < sortTitles.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:sortTitles[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.post_sort_type = [sortTypes[i] integerValue];
            self.page = 1;
            [self loadDataWithPage:self.page];
        }];
        // 标记当前选中的排序方式
        if ([sortTypes[i] integerValue] == self.post_sort_type) {
            [action setValue:[UIImage imageNamed:@"selected_check"] forKey:@"image"];
           
        }
        [alert addAction:action];
    }
    
    // 取消按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // iPad适配
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.sortButton;
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 筛选按钮点击事件（分类/标签/时间筛选）
- (void)filterButtonClicked {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"帖子筛选" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 1. 分类筛选（示例：需替换为真实分类列表）
    [alert addAction:[UIAlertAction actionWithTitle:@"分类筛选" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showCategoryFilter];
    }]];
    
    // 2. 标签筛选（示例：需替换为真实标签列表）
    [alert addAction:[UIAlertAction actionWithTitle:@"标签筛选" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showTopicFilter];
    }]];
    
    // 3. 时间筛选
    [alert addAction:[UIAlertAction actionWithTitle:@"时间筛选" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showTimeFilter];
    }]];
    
    // 4. 重置筛选
    [alert addAction:[UIAlertAction actionWithTitle:@"重置筛选" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self setupDefaultFilterParams];
        self.page = 1;
        [self loadDataWithPage:self.page];
    }]];
    
    // 5. 取消
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // iPad适配
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.filterButton;
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - 发帖按钮
- (void)newPostButtonClicked {
    PostPublishViewController *vc = [PostPublishViewController new];
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nv animated:YES completion:nil];
}

#pragma mark - 切换页面模式
// 切换模式的点击事件
- (void)switchMode {
    // 1. 切换控制器类型
    self.currentVCType = !self.currentVCType;
    // 2. 发送通知给 TabBarController
    NSDictionary *userInfo = @{kSquareVCTypeKey: @(self.currentVCType)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwitchSquareVCNotification
                                                        object:nil
                                                      userInfo:userInfo];
    
    // 可选：更新按钮图标/颜色，提示切换状态
    NSString *iconName = (self.currentVCType == SquareVCTypeOther) ? @"switch.2.fill" : @"switch.2";
    
    [self.switchButton setImage:[UIImage systemImageNamed:iconName] forState:UIControlStateNormal];
    self.switchButton.tintColor = (self.currentVCType == SquareVCTypeOther) ? [UIColor blueColor] : [UIColor redColor];
}

#pragma mark - 分类筛选（示例：需替换为真实分类数据）
- (void)showCategoryFilter {
    // 1. 获取单例
    SystemViewController *sysVC = [SystemViewController sharedInstance];

    // 2. 按Key查询配置项
   
    ConfigItem *item0 = [sysVC configItemForKey:@"categories0"];
    ConfigItem *item1 = [sysVC configItemForKey:@"categories1"];
    ConfigItem *item2 = [sysVC configItemForKey:@"categories2"];
    ConfigItem *item3 = [sysVC configItemForKey:@"categories3"];
    
    // 模拟标签列表（真实场景需从后端获取）
    NSArray *categories = @[
        @{@"id": @0, @"name": item0.config_value},
        @{@"id": @1, @"name": item1.config_value},
        @{@"id": @2, @"name": item2.config_value},
        @{@"id": @3, @"name": item3.config_value}
    ];
    
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择帖子主类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary *cate in categories) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:cate[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.category_id = [cate[@"id"] integerValue];
            self.page = 1;
            [self loadDataWithPage:self.page];
        }];
        if ([cate[@"id"] integerValue] == self.category_id) {
            
            [action setValue:[UIImage imageNamed:@"selected_check"] forKey:@"image"];
        }
        [alert addAction:action];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.filterButton;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 标签筛选（示例：需替换为真实标签数据）
- (void)showTopicFilter {
    // 1. 获取单例
    SystemViewController *sysVC = [SystemViewController sharedInstance];

    // 2. 按Key查询配置项
   
    ConfigItem *item0 = [sysVC configItemForKey:@"topics0"];
    ConfigItem *item1 = [sysVC configItemForKey:@"topics1"];
    ConfigItem *item2 = [sysVC configItemForKey:@"topics2"];
    ConfigItem *item3 = [sysVC configItemForKey:@"topics3"];
    
    // 模拟标签列表（真实场景需从后端获取）
    NSArray *topics = @[
        @{@"id": @0, @"name": item0.config_value},
        @{@"id": @1, @"name": item1.config_value},
        @{@"id": @2, @"name": item2.config_value},
        @{@"id": @3, @"name": item3.config_value}
    ];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"帅选帖子的需求属性" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary *topic in topics) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:topic[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.topic_id = [topic[@"id"] integerValue];
            self.page = 1;
            [self loadDataWithPage:self.page];
        }];
        if ([topic[@"id"] integerValue] == self.topic_id) {
            
            [action setValue:[UIImage imageNamed:@"selected_check"] forKey:@"image"];
        }
        [alert addAction:action];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.filterButton;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 时间筛选（开始/结束时间选择）
- (void)showTimeFilter {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"时间筛选" message:@"选择帖子发布时间范围" preferredStyle:UIAlertControllerStyleAlert];
    
    // 1. 开始时间输入框
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"开始时间（时间戳）";
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = self.start_time > 0 ? [NSString stringWithFormat:@"%lld", self.start_time] : @"";
    }];
    
    // 2. 结束时间输入框
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"结束时间（时间戳）";
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = self.end_time > 0 ? [NSString stringWithFormat:@"%lld", self.end_time] : @"";
    }];
    
    // 3. 确认按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *startField = alert.textFields[0];
        UITextField *endField = alert.textFields[1];
        
        self.start_time = startField.text.length > 0 ? [startField.text longLongValue] : 0;
        self.end_time = endField.text.length > 0 ? [endField.text longLongValue] : 0;
        
        // 校验：结束时间不能小于开始时间
        if (self.end_time > 0 && self.start_time > 0 && self.end_time < self.start_time) {
            [SVProgressHUD showErrorWithStatus:@"结束时间不能小于开始时间"];
            [SVProgressHUD dismissWithDelay:1];
            return;
        }
        
        self.page = 1;
        [self loadDataWithPage:self.page];
    }]];
    
    // 4. 取消按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 约束配置
- (void)setupViewConstraints {
    [super setupViewConstraints];
    // 确保collectionView铺满屏幕
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.equalTo(self.view);
    }];
}

#pragma mark - 加载数据（修正参数传递）
- (void)loadDataWithPage:(NSInteger)page {
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    // 修正参数：补充topic_id，修复udid/keyword的空值处理
    NSLog(@"搜索：%@",self.keyword);
    NSDictionary *dic = @{
        @"action":@"search_posts",
        
        @"page":@(page), // 用传入的page，而非self.page（避免页码错乱）
        @"keyword":self.keyword ?: @"",
        @"category_id":@(self.category_id),
        @"topic_id":@(self.topic_id), // 新增：标签筛选参数
        @"start_time":@(self.start_time),
        @"end_time":@(self.end_time),
        @"sort_type":@(self.post_sort_type)
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/post/post_api.php",localURL]
                                             parameters:dic
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            
            if(!jsonResult){
                [SVProgressHUD showErrorWithStatus:@"返回数据错误"];
                [SVProgressHUD dismissWithDelay:1];
                NSLog(@"返回格式错误：%@",stringResult);
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"] ?: @"";
            
            if(code != 200){
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"返回错误码:%ld\n%@",(long)code,msg]];
                [SVProgressHUD dismissWithDelay:3];
                return;
            }
            
            NSDictionary *data = jsonResult[@"data"] ?: @{};
            NSLog(@"返回data：%@",data);
            
            if(page <=1){
                [self.dataSource removeAllObjects];
            }
            
            NSArray *posts = data[@"posts"] ?: @[];
            NSLog(@"返回posts：%@",posts);
            
            for (NSDictionary *dic in posts) {
                PostModel *model = [PostModel yy_modelWithDictionary:dic];
                if (model) { // 非空判断：避免nil模型加入数据源
                    if(model.post_video_url){
                        NSLog(@"视频地址：%@",model.post_video_url);
                        NSLog(@"视频缩略图地址：%@",model.post_video_thumb_url);
                        NSLog(@"视频时长：%f",model.post_video_duration);
                    }
                    
                    
                    [self.dataSource addObject:model];
                }
            }
            
            [self refreshTable];
            
            NSDictionary *pagination = data[@"pagination"] ?: @{};
            BOOL has_more = [pagination[@"has_more"] boolValue];
            if(!has_more){
                [self handleNoMoreData];
            }else{
                self.page = page + 1; // 修正：用当前page+1，而非self.page+=1
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            NSLog(@"读取错误:%@",error.localizedDescription);
            [SVProgressHUD showErrorWithStatus:@"网络请求失败"];
            [SVProgressHUD dismissWithDelay:1];
        });
    }];
}

#pragma mark - 返回SectionController
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[PostModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[PostCell class]
                                                         modelClass:[PostModel class]
                                                           delegate:self
                                                         edgeInsets:UIEdgeInsetsMake(5, 10, 5, 10) // 调整内边距，适配Cell卡片
                                                   usingCacheHeight:YES]; // 开启高度缓存，优化性能
    }
    return nil;
}

#pragma mark - 单元格点击事件
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell  {
    if([model isKindOfClass:[PostModel class]]){
        PostModel *postModel = (PostModel *)model;
        NSLog(@"点击了帖子ID：%lld，标题：%@",postModel.post_id,postModel.post_title);
        // 这里可添加跳转到帖子详情页的逻辑
        ShowOnePostViewController *vc = [ShowOnePostViewController new];
        vc.post_id = postModel.post_id;
        [self presentPanModal:vc];
    }
}


#pragma mark - 控制器显示函数

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.searchController.searchBar resignFirstResponder];
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
    self.filterButton.tintColor = [UIColor labelColor];
    self.filterButton.titleLabel.textColor = [UIColor labelColor];
    
    self.sortButton.tintColor = [UIColor labelColor];
    self.sortButton.titleLabel.textColor = [UIColor labelColor];
    
    
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
    [super topBackageView];
    
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
    self.filterButton.tintColor = [UIColor labelColor];
    self.filterButton.titleLabel.textColor = [UIColor labelColor];
    
    self.sortButton.tintColor = [UIColor labelColor];
    self.sortButton.titleLabel.textColor = [UIColor labelColor];
    NSLog(@"界面模式发生变化");
    [self setBackgroundUI];
    [self topBackageView];
    
}




@end
