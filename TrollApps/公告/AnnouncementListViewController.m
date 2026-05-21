//
//  AnnouncementListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "AnnouncementListViewController.h"
#import "AnnouncementModel.h"
#import "AnnouncementCell.h"
#import "AnnouncementDetailViewController.h"

@interface AnnouncementListViewController () <TemplateSectionControllerDelegate>

@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, copy) NSString *sortBy;
@property (nonatomic, copy) NSString *sortOrder;

@end

@implementation AnnouncementListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"公告列表";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // 初始化参数
    [self initFilterParams];

    // 设置导航栏
    [self setupNavigationBar];
    
    // 加载
    [self refreshLoadInitialData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - 初始化筛选参数

- (void)initFilterParams {
    self.keyword = @"";
    self.status = -1;
    self.type = -1;
    self.priority = -1;
    self.sortBy = @"sort_weight";
    self.sortOrder = @"DESC";
}

#pragma mark - 设置导航栏

- (void)setupNavigationBar {
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;

    // 搜索控制器
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.placeholder = @"搜索公告标题/摘要/内容";
    searchBar.delegate = (id<UISearchBarDelegate>)self;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.returnKeyType = UIReturnKeySearch;

    // 筛选按钮
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"line.3.horizontal.decrease.circle"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(filterButtonTapped)];
    filterButton.tintColor = [UIColor systemBlueColor];
    self.navigationItem.rightBarButtonItem = filterButton;

    // 排序按钮
    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(sortButtonTapped)];
    sortButton.tintColor = [UIColor systemBlueColor];
    self.navigationItem.rightBarButtonItems = @[sortButton, filterButton];
    
    // 导航栏按钮
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonTapped)];
    self.navigationItem.leftBarButtonItem = closeButton;
    
}

#pragma mark - 加载数据（子类必须实现）

- (void)loadDataWithPage:(NSInteger)page {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"action"] = @"getAnnouncementList";
    params[@"page"] = @(page);
    params[@"pageSize"] = @(20);
    params[@"keyword"] = self.keyword ?: @"";

    if (self.status >= 0) {
        params[@"status"] = @(self.status);
    }
    if (self.type >= 0) {
        params[@"type"] = @(self.type);
    }
    if (self.priority >= 0) {
        params[@"priority"] = @(self.priority);
    }

    params[@"sort_by"] = self.sortBy ?: @"sort_weight";
    params[@"sort_order"] = self.sortOrder ?: @"DESC";

    NSLog(@"请求公告列表参数: %@", params);

    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                               modules:@"announcement"
                                            parameters:params
                                              progress:^(NSProgress *progress) {
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!jsonResult) {
                NSLog(@"返回数据类型错误: %@", stringResult);
                [self endRefreshing];
                return;
            }

            NSLog(@"公告列表响应: %@", jsonResult);

            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code != 200) {
                [self endRefreshing];
                return;
            }

            NSDictionary *data = jsonResult[@"data"];
            NSDictionary *pagination = data[@"pagination"];
            NSArray *list = data[@"list"];

            // 解析数据
            NSMutableArray *models = [NSMutableArray array];
            for (NSDictionary *dict in list) {
                AnnouncementModel *model = [AnnouncementModel yy_modelWithDictionary:dict];
                if (model) {
                    [models addObject:model];
                }
            }

            // 赋值父类属性
            self.page = page;
            self.hasMore = (page < [pagination[@"total_pages"] integerValue]);

            // 添加到数据源
            [self.dataSource addObjectsFromArray:models];

            // 刷新表格
            [self refreshTable];

        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"网络请求失败: %@", error);
            [self endRefreshing];
        });
    }];
}

#pragma mark - 返回 SectionController（子类必须实现）

- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if ([object isKindOfClass:[AnnouncementModel class]]) {
        return [[TemplateSectionController alloc] initWithCellClass:[AnnouncementCell class]
                                                       modelClass:[AnnouncementModel class]
                                                         delegate:self
                                                       edgeInsets:UIEdgeInsetsMake(5, 10, 5, 10)
                                                 usingCacheHeight:NO];
    }
    return nil;
}

#pragma mark - 扩展回调：传递模型和 Cell

- (void)templateSectionController:(TemplateSectionController *)sectionController
                     didSelectItem:(id)model
                           atIndex:(NSInteger)index
                              cell:(UICollectionViewCell *)cell {
    NSLog(@"你点击了公告：%ld", (long)index);

    if ([model isKindOfClass:[AnnouncementModel class]]) {
        AnnouncementModel *announcement = (AnnouncementModel *)model;

        AnnouncementDetailViewController *detailVC = [[AnnouncementDetailViewController alloc] init];
        detailVC.announcementUuid = announcement.announcement_uuid;
        detailVC.hidesBottomBarWhenPushed = YES;
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:detailVC];
        navVC.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentViewController:navVC animated:YES completion:nil];
    }
}

#pragma mark - 筛选按钮

- (void)filterButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"筛选公告"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    // 状态筛选
    [alert addAction:[UIAlertAction actionWithTitle:[self statusTitleForIndex:self.status] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showStatusPicker];
    }]];

    // 类型筛选
    [alert addAction:[UIAlertAction actionWithTitle:[self typeTitleForIndex:self.type] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showTypePicker];
    }]];

    // 优先级筛选
    [alert addAction:[UIAlertAction actionWithTitle:[self priorityTitleForIndex:self.priority] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showPriorityPicker];
    }]];

    // 重置筛选
    if (self.status >= 0 || self.type >= 0 || self.priority >= 0) {
        [alert addAction:[UIAlertAction actionWithTitle:@"重置筛选" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            self.status = -1;
            self.type = -1;
            self.priority = -1;
            [self refreshLoadInitialData];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 状态选择器

- (void)showStatusPicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择状态"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *statusTitles = @[@"全部", @"草稿", @"已发布", @"已下架", @"已删除"];

    for (NSInteger i = -1; i <= 3; i++) {
        NSString *title = (self.status == i) ? [NSString stringWithFormat:@"✓ %@", statusTitles[i + 1]] : statusTitles[i + 1];
        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.status = i;
            [self refreshLoadInitialData];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 类型选择器

- (void)showTypePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择类型"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *typeTitles = @[@"全部", @"普通公告", @"系统公告", @"活动公告", @"维护公告"];

    for (NSInteger i = -1; i <= 3; i++) {
        NSString *title = (self.type == i) ? [NSString stringWithFormat:@"✓ %@", typeTitles[i + 1]] : typeTitles[i + 1];
        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.type = i;
            [self refreshLoadInitialData];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 优先级选择器

- (void)showPriorityPicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择优先级"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *priorityTitles = @[@"全部", @"普通", @"重要", @"紧急"];

    for (NSInteger i = -1; i <= 2; i++) {
        NSString *title = (self.priority == i) ? [NSString stringWithFormat:@"✓ %@", priorityTitles[i + 1]] : priorityTitles[i + 1];
        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.priority = i;
            [self refreshLoadInitialData];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 排序按钮

- (void)sortButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"排序方式"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *sortOptions = @[
        @{@"title": @"排序权重 ↑", @"sort_by": @"sort_weight", @"sort_order": @"ASC"},
        @{@"title": @"排序权重 ↓", @"sort_by": @"sort_weight", @"sort_order": @"DESC"},
        @{@"title": @"创建时间 ↑", @"sort_by": @"create_time", @"sort_order": @"ASC"},
        @{@"title": @"创建时间 ↓", @"sort_by": @"create_time", @"sort_order": @"DESC"},
        @{@"title": @"发布时间 ↑", @"sort_by": @"publish_time", @"sort_order": @"ASC"},
        @{@"title": @"发布时间 ↓", @"sort_by": @"publish_time", @"sort_order": @"DESC"},
        @{@"title": @"浏览次数 ↑", @"sort_by": @"view_count", @"sort_order": @"ASC"},
        @{@"title": @"浏览次数 ↓", @"sort_by": @"view_count", @"sort_order": @"DESC"},
        @{@"title": @"优先级 ↑", @"sort_by": @"priority", @"sort_order": @"ASC"},
        @{@"title": @"优先级 ↓", @"sort_by": @"priority", @"sort_order": @"DESC"}
    ];

    for (NSDictionary *option in sortOptions) {
        BOOL isSelected = [self.sortBy isEqualToString:option[@"sort_by"]] && [self.sortOrder isEqualToString:option[@"sort_order"]];
        NSString *title = isSelected ? [NSString stringWithFormat:@"✓ %@", option[@"title"]] : option[@"title"];

        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.sortBy = option[@"sort_by"];
            self.sortOrder = option[@"sort_order"];
            [self refreshLoadInitialData];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    }

    [self presentViewController:alert animated:YES completion:nil];
}


- (void)closeButtonTapped {
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        // 如果是 push 进来的，使用 pop
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // 如果是模态进来的，使用 dismiss
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - 辅助方法

- (NSString *)statusTitleForIndex:(NSInteger)index {
    if (index < 0) return @"状态: 全部";
    NSArray *titles = @[@"草稿", @"已发布", @"已下架", @"已删除"];
    return [NSString stringWithFormat:@"状态: %@", titles[index]];
}

- (NSString *)typeTitleForIndex:(NSInteger)index {
    if (index < 0) return @"类型: 全部";
    NSArray *titles = @[@"普通公告", @"系统公告", @"活动公告", @"维护公告"];
    return [NSString stringWithFormat:@"类型: %@", titles[index]];
}

- (NSString *)priorityTitleForIndex:(NSInteger)index {
    if (index < 0) return @"优先级: 全部";
    NSArray *titles = @[@"普通", @"重要", @"紧急"];
    return [NSString stringWithFormat:@"优先级: %@", titles[index]];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.keyword = searchBar.text;
    [self refreshLoadInitialData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.keyword = searchText;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.keyword = @"";
    [self refreshLoadInitialData];
}

@end
