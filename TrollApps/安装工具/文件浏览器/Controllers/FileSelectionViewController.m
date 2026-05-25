//
//  FileSelectionViewController.m
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/19.
//  完整修复：排序逻辑 + 搜索逻辑 + 注释完善
//

#import "FileSelectionViewController.h"
#import "FileSelectionManager.h"
#import "FileListViewController.h"
#import "FileModel.h"
#import "FileListCell.h"
#import "FileEnum.h"
#import "FileNotification.h"
#import "RecycleBinManager.h"
#import "FileOperateTool.h"
#import "FavoriteManager.h"
static NSString * const kRecycleBinCellIdentifier = @"SelectionCell";

typedef NS_ENUM(NSInteger, SelectionSortType) {
    SelectionSortTypeTimeDesc,      // 删除时间降序（最新删除在前）
    SelectionSortTypeTimeAsc,       // 删除时间升序（最早删除在前）
    SelectionSortTypeName,          // 名称排序
    SelectionSortTypeFolderFirst    // 文件夹优先
};

typedef NS_ENUM(NSInteger, SelectionDateRange) {
    SelectionDateRangeAll,          // 全部
    SelectionDateRangeToday,        // 今天
    SelectionDateRangeYesterday,    // 昨天
    SelectionDateRangeWeek,         // 最近一周
    SelectionDateRangeMonth         // 最近一个月
};

@interface FileSelectionViewController ()<UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;

/// 原始文件数据源
@property (nonatomic, strong) NSMutableArray<FileModel *> *fileList;
/// 搜索/筛选后的数据源
@property (nonatomic, strong) NSMutableArray<FileModel *> *filteredItems;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) SelectionSortType currentSortType;
@property (nonatomic, assign) SelectionDateRange currentDateRange;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation FileSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"已选择列表";
    // 默认按最新删除排序
    _currentSortType = SelectionSortTypeTimeDesc;
    _currentDateRange = SelectionDateRangeAll;
    
    _fileList = [NSMutableArray array];
    _filteredItems = [NSMutableArray array];
    
    [self setupNavigation];
    [self setupTableView];
    [self setupEmptyView];
    [self setupSearchController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 页面显示时重新加载回收站选中文件
    [self loadDeletedFiles];
}

#pragma mark - 初始化UI
/// 设置导航栏按钮（排序、日期、清空）
- (void)setupNavigation {
    self.title = @"已选择列表";
    
    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithTitle:@"排序"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(sortButtonTapped)];
    UIBarButtonItem *operationButton = [[UIBarButtonItem alloc] initWithTitle:@"操作"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(operationButtonTapped)];
    UIBarButtonItem *dateRangeButton = [[UIBarButtonItem alloc] initWithTitle:@"日期"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dateRangeButtonTapped)];
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearRecycleBin)];
    clearButton.tintColor = [UIColor systemRedColor];
    
    self.navigationItem.leftBarButtonItems = @[sortButton, dateRangeButton];
    self.navigationItem.rightBarButtonItems = @[clearButton,operationButton];
}

/// 设置搜索栏
- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索回收站文件";
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;
}

/// 创建表格视图
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 60;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:[FileListCell class] forCellReuseIdentifier:kRecycleBinCellIdentifier];
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

/// 设置空数据提示视图
- (void)setupEmptyView {
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"回收站为空";
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:16];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.emptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

#pragma mark - 数据加载
/// 加载回收站选中的文件列表
- (void)loadDeletedFiles {
    // 从选择管理器获取已选中文件
    self.fileList = [[[FileSelectionManager sharedManager] selectedFiles] mutableCopy];
    // 应用日期筛选
    [self applyDateRangeFilter];
    // 应用排序
    [self sortItems];
    
    // 控制空视图显示
    BOOL hasData = [self currentDataList].count > 0;
    self.emptyLabel.hidden = hasData;
    self.tableView.hidden = !hasData;
    
    [self.tableView reloadData];
}

/// 根据日期范围筛选文件
- (void)applyDateRangeFilter {
    if (self.currentDateRange == SelectionDateRangeAll) {
        self.filteredItems = [self.fileList mutableCopy];
        return;
    }
    
    NSDate *startDate = [self getStartDateForRange:self.currentDateRange];
    NSMutableArray *filtered = [NSMutableArray array];
    
    for (FileModel *item in self.fileList) {
        if (item.modificationDate && [item.modificationDate compare:startDate] != NSOrderedAscending) {
            [filtered addObject:item];
        }
    }
    self.filteredItems = filtered;
}

/// 获取日期范围的起始时间
- (NSDate *)getStartDateForRange:(SelectionDateRange)range {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    switch (range) {
        case SelectionDateRangeToday: {
            NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now];
            return [calendar dateFromComponents:components];
        }
        case SelectionDateRangeYesterday: {
            NSDate *today = [calendar dateFromComponents:[calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now]];
            return [calendar dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:today options:0];
        }
        case SelectionDateRangeWeek: {
            return [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:now options:0];
        }
        case SelectionDateRangeMonth: {
            return [calendar dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:now options:0];
        }
        default:
            return [NSDate dateWithTimeIntervalSince1970:0];
    }
}

#pragma mark - 排序逻辑（已完整实现）
/// 对文件列表进行排序（完整实现）
- (void)sortItems {
    NSArray *sourceArray = self.isSearching ? self.filteredItems : self.fileList;
    if (sourceArray.count == 0) return;
    
    NSMutableArray *sortedArray = [sourceArray mutableCopy];
    
    switch (self.currentSortType) {
        case SelectionSortTypeTimeDesc: {
            // 时间降序：最新修改/删除在前
            [sortedArray sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                if (!obj1.modificationDate) return NSOrderedDescending;
                if (!obj2.modificationDate) return NSOrderedAscending;
                return [obj2.modificationDate compare:obj1.modificationDate];
            }];
            break;
        }
        case SelectionSortTypeTimeAsc: {
            // 时间升序：最早修改/删除在前
            [sortedArray sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                if (!obj1.modificationDate) return NSOrderedAscending;
                if (!obj2.modificationDate) return NSOrderedDescending;
                return [obj1.modificationDate compare:obj2.modificationDate];
            }];
            break;
        }
        case SelectionSortTypeName: {
            // 文件名排序（不区分大小写）
            [sortedArray sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                return [obj1.fileName localizedCaseInsensitiveCompare:obj2.fileName];
            }];
            break;
        }
        case SelectionSortTypeFolderFirst: {
            // 文件夹优先，同类型按名称排序
            [sortedArray sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                if (obj1.itemType == FileItemTypeFolder && obj2.itemType != FileItemTypeFolder) {
                    return NSOrderedAscending;
                } else if (obj1.itemType != FileItemTypeFolder && obj2.itemType == FileItemTypeFolder) {
                    return NSOrderedDescending;
                } else {
                    return [obj1.fileName localizedCaseInsensitiveCompare:obj2.fileName];
                }
            }];
            break;
        }
        default:
            break;
    }
    
    // 赋值排序后的结果
    if (self.isSearching) {
        self.filteredItems = sortedArray;
    } else {
        self.fileList = sortedArray;
        [self applyDateRangeFilter];
    }
    
    [self.tableView reloadData];
}

/// 弹出排序选择面板
- (void)sortButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"排序方式"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"时间（最新在前）" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = SelectionSortTypeTimeDesc;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"时间（最早在前）" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = SelectionSortTypeTimeAsc;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"名称排序" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = SelectionSortTypeName;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"文件夹优先" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = SelectionSortTypeFolderFirst;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/// 弹出日期筛选面板
- (void)dateRangeButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"日期范围"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"全部" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = SelectionDateRangeAll;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"今天" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = SelectionDateRangeToday;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"昨天" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = SelectionDateRangeYesterday;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"最近一周" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = SelectionDateRangeWeek;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"最近一个月" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = SelectionDateRangeMonth;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/// 弹出操作
- (void)operationButtonTapped {
    
    NSArray *sourceArray = self.isSearching ? self.filteredItems : self.fileList;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择操作"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"移动到回收站" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [RecycleBinManager sharedManager].recycleBinEnabled = YES;
        [[RecycleBinManager sharedManager] moveFileModelsToRecycleBin:sourceArray];
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"永久删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        for (int i = 0; i<sourceArray.count; i++) {
            FileModel *model = sourceArray[i];
            [FileOperateTool deleteItemAtPath:model.filePath];
            if (i == sourceArray.count-1) {
                [self loadDeletedFiles];
            }
        }
        [self loadDeletedFiles];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"清空选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[FileSelectionManager sharedManager] clearAllSelections];
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        for (int i = 0; i<sourceArray.count; i++) {
            FileModel *model = sourceArray[i];
            [[FavoriteManager sharedManager] addFavorite:model];
        }
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        for (int i = 0; i<sourceArray.count; i++) {
            FileModel *model = sourceArray[i];
            [[FavoriteManager sharedManager] removeFavorite:model];
        }
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/// 清空回收站（确认后执行）
- (void)clearRecycleBin {
    if ([self currentDataList].count == 0) return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认清空"
                                                                   message:@"确定要清空回收站吗？此操作不可恢复。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[FileSelectionManager sharedManager] deselectAllFiles:self.fileList.copy];
        [self loadDeletedFiles];
        [self.fileListViewController refreshFileList];
        [self.fileListViewController updateSelectionCountButton];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/// 获取当前显示的数据源（搜索/筛选/原始）
- (NSArray<FileModel *> *)currentDataList {
    return self.isSearching ? self.filteredItems : self.fileList;
}

#pragma mark - UISearchResultsUpdating（搜索逻辑已修复）
/// 实时搜索回调
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    self.isSearching = (searchText.length > 0);
    
    if (self.isSearching) {
        // 搜索：文件名 / 文件路径 包含关键词（不区分大小写、重音）
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
            @"fileName CONTAINS[cd] %@ OR filePath CONTAINS[cd] %@",
            searchText, searchText];
        
        self.filteredItems = [[self.fileList filteredArrayUsingPredicate:predicate] mutableCopy];
    } else {
        // 关闭搜索：恢复日期筛选
        [self applyDateRangeFilter];
    }
    
    // 排序并刷新
    [self sortItems];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentDataList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:kRecycleBinCellIdentifier forIndexPath:indexPath];
    FileModel *model = [self currentDataList][indexPath.row];
    [cell configWithFileModel:model];
    return cell;
}

#pragma mark - UITableViewDelegate
/// 点击条目：进入对应目录
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    FileModel *model = [self currentDataList][indexPath.row];
    NSString *targetPath = (model.itemType == FileItemTypeFolder) ? model.filePath : model.parentDirPath;
    
    FileListViewController *fileListVC = [[FileListViewController alloc] initWithFullPath:targetPath];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fileListVC];
//    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) topVC = topVC.presentedViewController;
    [topVC presentViewController:nav animated:YES completion:nil];
}

/// 左滑删除（取消选中）
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction * _Nonnull action, UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        FileModel *model = [self currentDataList][indexPath.row];
        [[FileSelectionManager sharedManager] removeFile:model];
        [self loadDeletedFiles];
        
        
        [self.fileListViewController refreshFileList];
        [self.fileListViewController updateSelectionCountButton];
        
        completionHandler(YES);
    }];
    deleteAction.backgroundColor = [UIColor systemRedColor];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

@end
