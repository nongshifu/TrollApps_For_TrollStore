//
//  RecycleBinViewController.m
//  SandboxFileManager
//
//  回收站控制器实现
//

#import "RecycleBinViewController.h"
#import "RecycleBinManager.h"
#import "FileModel.h"
#import "FileListCell.h"
#import "FileEnum.h"

static NSString * const kRecycleBinCellIdentifier = @"RecycleBinCell";

typedef NS_ENUM(NSInteger, RecycleBinSortType) {
    RecycleBinSortTypeTimeDesc,      // 删除时间降序（最新删除在前）
    RecycleBinSortTypeTimeAsc,       // 删除时间升序（最早删除在前）
    RecycleBinSortTypeName,          // 名称排序
    RecycleBinSortTypeFolderFirst    // 文件夹优先
};

typedef NS_ENUM(NSInteger, RecycleBinDateRange) {
    RecycleBinDateRangeAll,          // 全部
    RecycleBinDateRangeToday,        // 今天
    RecycleBinDateRangeYesterday,    // 昨天
    RecycleBinDateRangeWeek,         // 最近一周
    RecycleBinDateRangeMonth         // 最近一个月
};

@interface RecycleBinViewController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSArray *recycleBinItems;
@property (nonatomic, strong) NSMutableArray *filteredItems;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) RecycleBinSortType currentSortType;
@property (nonatomic, assign) RecycleBinDateRange currentDateRange;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation RecycleBinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    _currentSortType = RecycleBinSortTypeTimeDesc;
    _currentDateRange = RecycleBinDateRangeAll;
    
    [self setupNavigation];
    [self setupTableView];
    [self setupEmptyView];
    [self setupSearchController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadDeletedFiles];
}

- (void)setupNavigation {
    self.title = @"回收站";
    
    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithTitle:@"排序"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(sortButtonTapped)];
    UIBarButtonItem *dateRangeButton = [[UIBarButtonItem alloc] initWithTitle:@"日期"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dateRangeButtonTapped)];
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearRecycleBin)];
    clearButton.tintColor = [UIColor systemRedColor];
    
    self.navigationItem.leftBarButtonItems = @[sortButton, dateRangeButton];
    self.navigationItem.rightBarButtonItem = clearButton;
}

- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索回收站";
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;
}

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

- (void)loadDeletedFiles {
    self.recycleBinItems = [[RecycleBinManager sharedManager] recycleBinItems];
    [self applyDateRangeFilter];
    [self sortItems];
    
    self.emptyLabel.hidden = [self currentDataList].count > 0;
    self.tableView.hidden = [self currentDataList].count == 0;
    
    [self.tableView reloadData];
}

- (void)applyDateRangeFilter {
    if (self.currentDateRange == RecycleBinDateRangeAll) {
        self.filteredItems = [self.recycleBinItems mutableCopy];
        return;
    }
    
    NSDate *startDate = [self getStartDateForRange:self.currentDateRange];
    NSMutableArray *filtered = [NSMutableArray array];
    
    for (RecycleBinItem *item in self.recycleBinItems) {
        if (item.deletedDate && [item.deletedDate compare:startDate] != NSOrderedAscending) {
            [filtered addObject:item];
        }
    }
    
    self.filteredItems = filtered;
}

- (NSDate *)getStartDateForRange:(RecycleBinDateRange)range {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    switch (range) {
        case RecycleBinDateRangeToday: {
            NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now];
            return [calendar dateFromComponents:components];
        }
        case RecycleBinDateRangeYesterday: {
            NSDate *today = [calendar dateFromComponents:[calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now]];
            return [calendar dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:today options:0];
        }
        case RecycleBinDateRangeWeek: {
            return [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:now options:0];
        }
        case RecycleBinDateRangeMonth: {
            return [calendar dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:now options:0];
        }
        default:
            return [NSDate dateWithTimeIntervalSince1970:0];
    }
}

- (void)sortItems {
    switch (self.currentSortType) {
        case RecycleBinSortTypeTimeDesc:
            [self.filteredItems sortUsingComparator:^NSComparisonResult(RecycleBinItem *obj1, RecycleBinItem *obj2) {
                return [obj2.deletedDate compare:obj1.deletedDate];
            }];
            break;
        case RecycleBinSortTypeTimeAsc:
            [self.filteredItems sortUsingComparator:^NSComparisonResult(RecycleBinItem *obj1, RecycleBinItem *obj2) {
                return [obj1.deletedDate compare:obj2.deletedDate];
            }];
            break;
        case RecycleBinSortTypeName:
            [self.filteredItems sortUsingComparator:^NSComparisonResult(RecycleBinItem *obj1, RecycleBinItem *obj2) {
                return [obj1.fileModel.fileName compare:obj2.fileModel.fileName options:NSCaseInsensitiveSearch];
            }];
            break;
        case RecycleBinSortTypeFolderFirst:
            [self.filteredItems sortUsingComparator:^NSComparisonResult(RecycleBinItem *obj1, RecycleBinItem *obj2) {
                if (obj1.fileModel.itemType == obj2.fileModel.itemType) {
                    return [obj2.deletedDate compare:obj1.deletedDate];
                }
                return obj1.fileModel.itemType == FileItemTypeFolder ? NSOrderedAscending : NSOrderedDescending;
            }];
            break;
    }
}

- (void)sortButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"排序方式"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"删除时间（最新在前）" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = RecycleBinSortTypeTimeDesc;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"删除时间（最早在前）" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = RecycleBinSortTypeTimeAsc;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"名称排序" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = RecycleBinSortTypeName;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"文件夹优先" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = RecycleBinSortTypeFolderFirst;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dateRangeButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"日期范围"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"全部" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = RecycleBinDateRangeAll;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"今天" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = RecycleBinDateRangeToday;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"昨天" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = RecycleBinDateRangeYesterday;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"最近一周" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = RecycleBinDateRangeWeek;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"最近一个月" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = RecycleBinDateRangeMonth;
        [self loadDeletedFiles];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearRecycleBin {
    if ([self currentDataList].count == 0) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认清空"
                                                                   message:@"确定要清空回收站吗？此操作不可恢复。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[RecycleBinManager sharedManager] emptyRecycleBin];
        [self loadDeletedFiles];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSArray *)currentDataList {
    return self.isSearching ? self.filteredItems : self.recycleBinItems;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    self.isSearching = (searchText.length > 0);
    
    if (self.isSearching) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileModel.fileName CONTAINS[cd] %@ OR fileModel.filePath CONTAINS[cd] %@", searchText, searchText];
        NSMutableArray *searchResult = [[self.recycleBinItems filteredArrayUsingPredicate:predicate] mutableCopy];
        self.filteredItems = searchResult;
    } else {
        [self applyDateRangeFilter];
    }
    [self sortItems];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentDataList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:kRecycleBinCellIdentifier forIndexPath:indexPath];
    
    RecycleBinItem *item = [self currentDataList][indexPath.row];
    FileModel *model = item.fileModel;
    
    [cell configWithFileModel:model];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    RecycleBinItem *item = [self currentDataList][indexPath.row];
    FileModel *model = item.fileModel;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"恢复文件"
                                                                   message:[NSString stringWithFormat:@"确定要恢复 \"%@\" 吗？", model.fileName]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"恢复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[RecycleBinManager sharedManager] restoreItem:item withConflictHandler:^(RecycleBinItem *item, NSString *conflictingPath, void (^completionHandler)(RecycleBinRestoreConflictOption)) {
            NSString *fileName = [conflictingPath lastPathComponent];
            UIAlertController *conflictAlert = [UIAlertController alertControllerWithTitle:@"文件已存在"
                                                                                  message:[NSString stringWithFormat:@"目标路径 \"%@\" 已存在", fileName]
                                                                           preferredStyle:UIAlertControllerStyleAlert];
            
            [conflictAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                completionHandler(RecycleBinRestoreConflictOptionRename);
            }]];
            
            [conflictAlert addAction:[UIAlertAction actionWithTitle:@"覆盖" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                completionHandler(RecycleBinRestoreConflictOptionOverwrite);
            }]];
            
            [conflictAlert addAction:[UIAlertAction actionWithTitle:@"重命名" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                completionHandler(RecycleBinRestoreConflictOptionRename);
            }]];
            
            [self presentViewController:conflictAlert animated:YES completion:nil];
        }];
        [self loadDeletedFiles];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        RecycleBinItem *item = [self currentDataList][indexPath.row];
        [[RecycleBinManager sharedManager] deleteItem:item];
        self.recycleBinItems = [[RecycleBinManager sharedManager] recycleBinItems];
        [self loadDeletedFiles];
        completionHandler(YES);
    }];
    
    deleteAction.backgroundColor = [UIColor systemRedColor];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

@end
