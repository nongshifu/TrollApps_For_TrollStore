//
//  DownloadRecordViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/9.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DownloadRecordViewController.h"
#import "NewProfileViewController.h"
#import "DownloadRecordModel.h"
#import "DownloadRecordCell.h"
#import "TemplateSectionController.h"
#import "ShowOneAppViewController.h"


#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@interface DownloadRecordViewController ()<TemplateSectionControllerDelegate, UISearchBarDelegate>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *sortTypeButton;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, assign) NSInteger currentSortType; // 0: 最新在前, 1: 最早在前

@end

@implementation DownloadRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [self setupViewConstraints];
    [self loadDataWithPage:1]; // 初始加载第一页数据
}

#pragma mark - 初始化UI
- (void)setupUI {
    [super setupUI];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"下载历史";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = [UIColor labelColor];
    
    // 搜索框
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"搜索应用名称";
    self.searchBar.backgroundColor = [UIColor clearColor];
    [self.searchBar setBackgroundImage:[UIImage new]]; // 去除搜索框背景
    
    // 排序按钮
    self.sortTypeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sortTypeButton setTitle:@"最新下载" forState:UIControlStateNormal];
    [self.sortTypeButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    self.sortTypeButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.sortTypeButton addTarget:self action:@selector(sortTypeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    self.currentSortType = 0;
    
    // 头部视图
    self.headerView = [[UIView alloc] init];
    [self.headerView addSubview:self.titleLabel];
    [self.headerView addSubview:self.searchBar];
    [self.headerView addSubview:self.sortTypeButton];
    
    [self.view addSubview:self.headerView];
    
    // 移除父类视图约束，重新添加
    [self.collectionView removeFromSuperview];
    
    [self.view addSubview:self.collectionView];
    
   
}

#pragma mark - 设置约束
- (void)setupViewConstraints {
    
    // 头部视图约束
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(120);
    }];
    
    // 标题约束
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(15);
        make.left.equalTo(self.headerView).offset(20);
        make.right.lessThanOrEqualTo(self.headerView).offset(-16);
    }];
    
    // 搜索框约束
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(15);
        make.left.equalTo(self.headerView).offset(10);
        make.right.equalTo(self.headerView).offset(-10);
        make.height.mas_equalTo(36);
    }];
    
    // 排序按钮约束
    [self.sortTypeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchBar.mas_bottom).offset(10);
        make.right.equalTo(self.headerView).offset(-16);
    }];
    
    // 集合视图约束
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.width.mas_equalTo(kWidth);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    // 集合视图约束
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.width.mas_equalTo(kWidth);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 在这里进行与布局完成后相关的操作，比如获取子视图的最终尺寸等
    NSLog(@"视图布局完成：%@",self.collectionView);
}

#pragma mark - 排序按钮点击事件
- (void)sortTypeButtonClicked {
    // 切换排序类型
    self.currentSortType = 1 - self.currentSortType;
    // 更新按钮标题
    [self.sortTypeButton setTitle:self.currentSortType == 0 ? @"最新下载" : @"最早下载" forState:UIControlStateNormal];
    // 重置页码，重新加载数据
    self.page = 1;
    [self.dataSource removeAllObjects];
    [self loadDataWithPage:1];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    // 搜索关键词
    self.keyword = searchBar.text;
    // 重置页码，重新加载数据
    self.page = 1;
    [self.dataSource removeAllObjects];
    [self loadDataWithPage:1];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        // 搜索框为空，清除关键词
        self.keyword = @"";
        // 重置页码，重新加载数据
        self.page = 1;
        [self.dataSource removeAllObjects];
        [self loadDataWithPage:1];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    // 清除关键词
    self.keyword = @"";
    // 重置页码，重新加载数据
    self.page = 1;
    [self.dataSource removeAllObjects];
    [self loadDataWithPage:1];
}

#pragma mark - 加载数据
- (void)loadDataWithPage:(NSInteger)page {
    // 显示加载指示器
    [SVProgressHUD showWithStatus:nil];
    
    // 1. 构建请求参数（注意：参数结构需与接口匹配！）
    NSDictionary *parameters = @{
        @"action": @"getDownloadHistory",
        @"page": @(page),
        @"pageSize": @(10), // 每页10条数据
        @"keyword": self.keyword ?: @"",
        @"sortType": @(self.currentSortType)
    };
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@/app/app_api.php", localURL];
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                             urlString:urlString
                                            parameters:parameters
                                                 udid:[NewProfileViewController sharedInstance].userInfo.udid
                                              progress:^(NSProgress *progress) {
        // 可选：进度回调
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 隐藏加载指示器
            [SVProgressHUD dismiss];
            
            [self endRefreshing];
            
            NSLog(@"jsonResult:%@", jsonResult);
            NSLog(@"stringResult:%@", stringResult);
            
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code == 200) {
                // 更新数据源
                if (page == 1) {
                    // 第一页，替换数据源
                    [self.dataSource removeAllObjects];
                }
                // 解析数据
                NSDictionary *data = jsonResult[@"data"];
                NSArray *list = data[@"list"];
                NSDictionary *pagination = data[@"pagination"];
                
                // 转换为模型对象
                
                for (NSDictionary *dict in list) {
                    DownloadRecordModel *model = [DownloadRecordModel yy_modelWithDictionary:dict];
                    [self.dataSource addObject:model];
                }
                
                
                // 更新分页信息
                NSInteger total = [pagination[@"total"] integerValue];
                BOOL hasMore = [pagination[@"hasMore"] boolValue];
                
                
                
                if(hasMore){
                    [self handleNoMoreData];
                }else{
                    self.page+=1;
                }
                NSLog(@"total:%ld self.dataSource:%@",total,self.dataSource);
                
                // 刷新列表
                [self refreshTable];

            } else {
                // 显示错误信息
                [SVProgressHUD showErrorWithStatus:jsonResult[@"msg"]];
                [SVProgressHUD dismissWithDelay:1];
                
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 隐藏加载指示器
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",error]];
            [SVProgressHUD dismissWithDelay:1];
            
        });
    }];
}

#pragma mark - 返回对应的 SectionController


/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if(object && [object isKindOfClass:[DownloadRecordModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[DownloadRecordCell class] modelClass:[DownloadRecordModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 0, 0) usingCacheHeight:YES];
    }
    return nil;
}



#pragma mark - SectionController 代理协议


// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    if([model isKindOfClass:[DownloadRecordModel class]]){
        DownloadRecordModel *appInfoModel = (DownloadRecordModel *)model;
        NSLog(@"appInfoModel：%ld",(long)appInfoModel.appId);
        ShowOneAppViewController *vc = [ShowOneAppViewController new];
        vc.app_id = appInfoModel.appId;
        [self presentPanModal:vc];
        
        
    }
    
}


@end
