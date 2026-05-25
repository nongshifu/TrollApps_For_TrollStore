//
//  HistoryListViewController.m
//  SandboxFileManager
//
//  历史记录控制器实现
//

#import "HistoryListViewController.h"
#import "HistoryManager.h"
#import "FileModel.h"
#import "FileListViewController.h"
#import "FileEnum.h"
#import "FileListCell.h"

static NSString * const kHistoryCellIdentifier = @"HistoryCell";

typedef NS_ENUM(NSInteger, HistorySortType) {
    HistorySortTypeTimeDesc,      // 时间降序（最新在前）
    HistorySortTypeTimeAsc,       // 时间升序（最旧在前）
    HistorySortTypeName,          // 名称排序
    HistorySortTypeFolderFirst    // 文件夹优先
};

typedef NS_ENUM(NSInteger, HistoryDateRange) {
    HistoryDateRangeAll,          // 全部
    HistoryDateRangeToday,        // 今天
    HistoryDateRangeYesterday,    // 昨天
    HistoryDateRangeWeek,         // 最近一周
    HistoryDateRangeMonth         // 最近一个月
};

@interface HistoryListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, FileListCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<FileModel *> *historyList;
@property (nonatomic, strong) NSMutableArray<FileModel *> *filteredList;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) HistorySortType currentSortType;
@property (nonatomic, assign) HistoryDateRange currentDateRange;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation HistoryListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _currentSortType = HistorySortTypeTimeDesc;
    _currentDateRange = HistoryDateRangeAll;
    [self setupUI];
    [self setupSearchController];
    [self loadHistory];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadHistory];
}

- (void)setupUI {
    self.title = @"浏览历史";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 60;
    [self.tableView registerClass:[FileListCell class] forCellReuseIdentifier:kHistoryCellIdentifier];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithTitle:@"排序"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(sortButtonTapped)];
    UIBarButtonItem *dateRangeButton = [[UIBarButtonItem alloc] initWithTitle:@"日期"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dateRangeButtonTapped)];
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"清空"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(clearButtonTapped)];
    
    self.navigationItem.leftBarButtonItems = @[sortButton, dateRangeButton];
    self.navigationItem.rightBarButtonItem = clearButton;
}

- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索历史记录";
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;
}

- (void)loadHistory {
    NSArray *historyData = [[HistoryManager sharedManager] historyList];
    self.historyList = [historyData mutableCopy];
    [self applyDateRangeFilter];
    [self sortHistoryList];
    [self.tableView reloadData];
}

- (void)applyDateRangeFilter {
    if (self.currentDateRange == HistoryDateRangeAll) {
        self.filteredList = [self.historyList mutableCopy];
        return;
    }
    
    NSDate *startDate = [self getStartDateForRange:self.currentDateRange];
    NSMutableArray<FileModel *> *filtered = [NSMutableArray array];
    
    for (FileModel *model in self.historyList) {
        if (model.lastAccessTime && [model.lastAccessTime compare:startDate] != NSOrderedAscending) {
            [filtered addObject:model];
        }
    }
    
    self.filteredList = filtered;
}

- (NSDate *)getStartDateForRange:(HistoryDateRange)range {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    switch (range) {
        case HistoryDateRangeToday: {
            NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now];
            return [calendar dateFromComponents:components];
        }
        case HistoryDateRangeYesterday: {
            NSDate *today = [calendar dateFromComponents:[calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now]];
            return [calendar dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:today options:0];
        }
        case HistoryDateRangeWeek: {
            return [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:now options:0];
        }
        case HistoryDateRangeMonth: {
            return [calendar dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:now options:0];
        }
        default:
            return [NSDate dateWithTimeIntervalSince1970:0];
    }
}

- (void)sortHistoryList {
    switch (self.currentSortType) {
        case HistorySortTypeTimeDesc:
            [self.filteredList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                return [obj2.lastAccessTime compare:obj1.lastAccessTime];
            }];
            break;
        case HistorySortTypeTimeAsc:
            [self.filteredList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                return [obj1.lastAccessTime compare:obj2.lastAccessTime];
            }];
            break;
        case HistorySortTypeName:
            [self.filteredList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                return [obj1.fileName compare:obj2.fileName options:NSCaseInsensitiveSearch];
            }];
            break;
        case HistorySortTypeFolderFirst:
            [self.filteredList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                if (obj1.itemType == obj2.itemType) {
                    return [obj2.lastAccessTime compare:obj1.lastAccessTime];
                }
                return obj1.itemType == FileItemTypeFolder ? NSOrderedAscending : NSOrderedDescending;
            }];
            break;
    }
}

- (void)sortButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"排序方式"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"时间（最新在前）" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = HistorySortTypeTimeDesc;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"时间（最旧在前）" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = HistorySortTypeTimeAsc;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"名称排序" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = HistorySortTypeName;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"文件夹优先" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSortType = HistorySortTypeFolderFirst;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dateRangeButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"日期范围"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"全部" style:self.currentDateRange == HistoryDateRangeAll ? UIAlertActionStyleDefault : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = HistoryDateRangeAll;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"今天" style:self.currentDateRange == HistoryDateRangeToday ? UIAlertActionStyleDefault : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = HistoryDateRangeToday;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"昨天" style:self.currentDateRange == HistoryDateRangeYesterday ? UIAlertActionStyleDefault : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = HistoryDateRangeYesterday;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"最近一周" style:self.currentDateRange == HistoryDateRangeWeek ? UIAlertActionStyleDefault : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = HistoryDateRangeWeek;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"最近一个月" style:self.currentDateRange == HistoryDateRangeMonth ? UIAlertActionStyleDefault : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentDateRange = HistoryDateRangeMonth;
        [self loadHistory];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认清空"
                                                                   message:@"确定要清空所有浏览历史吗？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[HistoryManager sharedManager] clearHistory];
        [self loadHistory];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSArray<FileModel *> *)currentDataList {
    return self.isSearching ? self.filteredList : self.historyList;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    self.isSearching = (searchText.length > 0);

    if (self.isSearching) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileName CONTAINS[cd] %@ OR filePath CONTAINS[cd] %@", searchText, searchText];
        NSMutableArray *searchResult = [[self.historyList filteredArrayUsingPredicate:predicate] mutableCopy];
        self.filteredList = searchResult;
    } else {
        [self applyDateRangeFilter];
    }
    [self sortHistoryList];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentDataList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:kHistoryCellIdentifier forIndexPath:indexPath];
    FileModel *model = [self currentDataList][indexPath.row];
    [cell configWithFileModel:model];
    cell.isBatchEditing = NO;
    cell.cellDelegate = self;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    FileModel *model = [self currentDataList][indexPath.row];
    
    NSString *targetPath = (model.itemType == FileItemTypeFolder) ? model.filePath : model.parentDirPath;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationNavigateToPath"
                                                        object:nil
                                                      userInfo:@{@"path": targetPath}];
    
    UIViewController *parentVC = self.navigationController.parentViewController;
    if ([parentVC respondsToSelector:@selector(setSelectedIndex:)]) {
        [parentVC performSelector:@selector(setSelectedIndex:) withObject:@(0)];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        FileModel *model = [self currentDataList][indexPath.row];
        [[HistoryManager sharedManager] removeHistory:model];
        [self.historyList removeObject:model];
        [self.filteredList removeObject:model];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        completionHandler(YES);
    }];
    
    deleteAction.backgroundColor = [UIColor systemRedColor];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark - FileListCellDelegate

- (void)fileListCell:(FileListCell *)cell didSelectCheckBox:(BOOL)selected forFileModel:(FileModel *)model {
}

- (void)fileListCell:(FileListCell *)cell didTapActionButtonForFileModel:(FileModel *)model {
    NSString *targetPath = (model.itemType == FileItemTypeFolder) ? model.filePath : model.parentDirPath;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationNavigateToPath"
                                                        object:nil
                                                      userInfo:@{@"path": targetPath}];
    
    UIViewController *parentVC = self.navigationController.parentViewController;
    if ([parentVC respondsToSelector:@selector(setSelectedIndex:)]) {
        [parentVC performSelector:@selector(setSelectedIndex:) withObject:@(0)];
    }
}

@end