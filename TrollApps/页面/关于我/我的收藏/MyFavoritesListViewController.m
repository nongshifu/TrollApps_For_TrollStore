//
//  MyFavoritesListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/2.
//

#import "MyFavoritesListViewController.h"
#import "AppInfoModel.h"
#import "AppInfoCell.h"
#import "NewProfileViewController.h"
#import "ShowOneAppViewController.h"
//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}
@interface MyFavoritesListViewController () <TemplateSectionControllerDelegate, UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchView;//搜索框
@property (nonatomic, strong) dispatch_source_t searchDebounceTimer; // 搜索防抖定时器
@property (nonatomic, assign) NSTimeInterval searchDebounceInterval; // 防抖间隔时间
@property (nonatomic, assign) BOOL sort;
@end

@implementation MyFavoritesListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isTapViewToHideKeyboard = YES;

    UIButton *button = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"chevron.compact.down"] target:self action:@selector(close:)];
    button.frame = CGRectMake(kWidth - 45, 10, 30, 30);
    button.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    button.layer.cornerRadius = 15;
    [self.view addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button2 addTarget:self action:@selector(switchSort:) forControlEvents:UIControlEventTouchUpInside];
    [button2 setTitle:@"New" forState:UIControlStateNormal];
    button2.frame = CGRectMake(kWidth - 115, 10, 50, 30);
    button2.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    button2.layer.cornerRadius = 15;
    [self.view addSubview:button2];
    
    [self setupSearchView];
    
    
}

//设置搜索框
- (void)setupSearchView {
    self.searchView = [[UISearchBar alloc] initWithFrame:CGRectMake(8, 10, 200, 40)];
    self.searchView.delegate = self;
    self.searchView.searchTextField.layer.borderWidth = 1;
    self.searchView.searchTextField.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.2].CGColor;
    self.searchView.alpha = 1;
    self.searchView.placeholder = @"搜索";
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

- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self.collectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(60);
        make.width.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
}

#pragma mark - Action
- (void)close:(UIButton*)button{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchSort:(UIButton*)button{
    self.sort = !self.sort;
    NSString *title = self.sort ? @"New" : @"Hot";
    [button setTitle:title forState:UIControlStateNormal];
    self.page = 1;
    [self.dataSource removeAllObjects];
    [self loadDataWithPage:self.page];
}

#pragma mark - 控制器辅助函数
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    
    
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page{
    
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid?:@"";
    
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getUserFavoriteList",
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"udid":udid,
        @"page":@(self.page),
        @"pageSize":@(20),
        @"sort":@(self.sort),// 排序方式（NO=最新收藏，YES=最早收藏）
    };
    NSString *url = [NSString stringWithFormat:@"%@/app_api.php",localURL];
    NSLog(@"url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url parameters:dic
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self endRefreshing];
            
            if(!jsonResult){
                [SVProgressHUD showErrorWithStatus:@"返回数据非法"];
                [SVProgressHUD dismissWithDelay:2 completion:^{
                    return;
                }];
            }
            NSLog(@"读取数据jsonResult: %@", jsonResult);
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *message = jsonResult[@"msg"];
            if(code == 200){
                NSArray * appInfo_data = jsonResult[@"data"];
                NSLog(@"返回数量:%ld",appInfo_data.count);
                for (NSDictionary *dic in appInfo_data) {
                    AppInfoModel *model = [AppInfoModel yy_modelWithDictionary:dic];
                    [self.dataSource addObject:model];
                }
                [self refreshTable];
                
                NSDictionary * pagination = jsonResult[@"pagination"];
                BOOL has_more = [pagination[@"has_more"] boolValue];
                if(has_more){
                    NSLog(@"有更多数据");
                    self.page+=1;
                }else{
                    NSLog(@"没有有更多数据");
                    [self handleNoMoreData];
                }
                
                
            }else{
                NSLog(@"数据搜索失败出错: %@", message);
                [SVProgressHUD showErrorWithStatus:message];
                [SVProgressHUD dismissWithDelay:2 completion:^{
                    return;
                }];
            }
            
        });
    } failure:^(NSError *error) {
        NSLog(@"异步请求Error: %@", error);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"请求错误\n%@",error]];
        [SVProgressHUD dismissWithDelay:2 completion:^{
            return;
        }];
    }];
    
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if ([object isKindOfClass:[AppInfoModel class]]) {
        
        return [[TemplateSectionController alloc] initWithCellClass:[AppInfoCell class] modelClass:[AppInfoModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10) cellHeight:100];
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
            [self.dataSource removeAllObjects];
            [self loadDataWithPage:1];
            
        });
    });
    dispatch_resume(self.searchDebounceTimer);
}

@end
