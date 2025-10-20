#import "DownloadManagerViewController.h"
#import "FileInstallManager.h"
#import "NewAppFileModel.h"
#import "config.h"
#import "Masonry.h"
#import "EmptyView.h"
#import "AppInfoModel.h"
#import "DownloadTaskModel.h"




@interface DownloadManagerViewController ()<UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *fileList;          // 原始文件列表
@property (nonatomic, strong) NSMutableArray *filteredFileList;  // 过滤后的文件列表
@property (nonatomic, strong) NSString *downloadDir;             // 统一下载目录
@property (nonatomic, strong) UILabel *titleLabel;               // 主标题
@property (nonatomic, strong) UILabel *subtitleLabel;            // 副标题
@property (nonatomic, strong) UIScrollView *filterScrollView;    // 筛选器滚动视图
@property (nonatomic, strong) NSMutableArray <UIButton *>*filterButtons;     // 筛选按钮数组
@property (nonatomic, strong) UIView *headerView;                // 顶部视图


@property (nonatomic, strong) UIView *bottomToolBar;           // 底部操作栏
@property (nonatomic, strong) UIButton *selectAllBtn;          // 全选按钮
@property (nonatomic, strong) UIButton *deselectAllBtn;        // 全取消按钮
@property (nonatomic, strong) UIButton *deleteBtn;             // 删除按钮
@property (nonatomic, strong) UIButton *cancelBtn;             // 取消按钮
@property (nonatomic, strong) UIButton *clearButton;           // 清除按钮

@property (nonatomic, strong) NSMutableArray *selectedFilePaths; // 选中文件路径
/**
 空视图
 */
@property (nonatomic, strong) EmptyView *emptyView;
@property (nonatomic, strong) UIDocumentInteractionController *documentController; // 文件分享控制器
@end


@implementation DownloadManagerViewController

+ (instancetype)sharedInstance {
    
    static DownloadManagerViewController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        // 在这里进行初始化设置（如果需要的话）
        
    });
    return sharedInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化筛选类型
    self.currentFilterType = FilterTypeAll; // 默认显示全部
    
    // 获取统一下载目录
    self.downloadDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Downloads"];
    
    // 初始化UI
    [self setupHeaderView];
    
    [self setupTableView];
    
    // 加载文件列表
    [self loadFileList];
    
    // 初始化选中数组
    self.selectedFilePaths = [NSMutableArray array]; // 初始化集合
    
    // 初始化长按手势（进入多选模式）
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewLongPressed:)];
    [self.tableView addGestureRecognizer:longPress];
    
    // 初始化底部操作栏（默认隐藏）
    [self setupBottomToolBar];
    
    [self setupViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadFileList]; // 每次显示时刷新列表
    [self buttonTappedIndex:self.currentFilterType];
}

#pragma mark - 初始化顶部视图
- (void)setupHeaderView {
    // 创建顶部视图
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    [self.view addSubview:self.headerView];
    
    // 主标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"下载管理";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [self.headerView addSubview:self.titleLabel];
    
    // 副标题
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"管理所有已下载的文件";
    self.subtitleLabel.font = [UIFont systemFontOfSize:14];
    self.subtitleLabel.textColor = [UIColor grayColor];
    [self.headerView addSubview:self.subtitleLabel];
    
    //清除按钮
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton setImage:[UIImage systemImageNamed:@"trash"] forState:UIControlStateNormal];
    [self.clearButton addTarget:self action:@selector(clear:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.clearButton];
    
    // 初始化筛选按钮数组
    self.filterButtons = [NSMutableArray array];
    
    // 创建筛选器滚动视图
    self.filterScrollView = [[UIScrollView alloc] init];
    self.filterScrollView.showsHorizontalScrollIndicator = NO;
    [self.headerView addSubview:self.filterScrollView];
    
    // 动态添加筛选按钮（根据FilterType枚举）
    [self setupFilterButtons];
}

#pragma mark - 初始化底部操作栏

- (void)setupBottomToolBar {
    // 底部工具栏
    self.bottomToolBar = [[UIView alloc] init];
    self.bottomToolBar.backgroundColor = [UIColor whiteColor];
    self.bottomToolBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomToolBar.layer.shadowOpacity = 0.1;
    self.bottomToolBar.layer.shadowOffset = CGSizeMake(0, -2);
    self.bottomToolBar.hidden = YES;
    [self.view addSubview:self.bottomToolBar];
    
    // 按钮宽度
    CGFloat btnWidth = (self.view.bounds.size.width - 40) / 4;
    
    // 1. 全选按钮
    self.selectAllBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.selectAllBtn setTitle:@"全选" forState:UIControlStateNormal];
    self.selectAllBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.selectAllBtn addTarget:self action:@selector(selectAllFiles) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBar addSubview:self.selectAllBtn];
    
    // 2. 全取消按钮
    self.deselectAllBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deselectAllBtn setTitle:@"全取消" forState:UIControlStateNormal];
    self.deselectAllBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.deselectAllBtn addTarget:self action:@selector(deselectAllFiles) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBar addSubview:self.deselectAllBtn];
    
    // 3. 删除按钮
    self.deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [self.deleteBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.deleteBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.deleteBtn addTarget:self action:@selector(deleteSelectedFiles) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBar addSubview:self.deleteBtn];
    
    // 4. 取消按钮
    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.cancelBtn addTarget:self action:@selector(cancelEditMode) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBar addSubview:self.cancelBtn];
}

#pragma mark - 初始化筛选按钮

- (void)setupFilterButtons {
    // 计算筛选按钮的总宽度
    CGFloat totalWidth = 0;
    CGFloat buttonPadding = 12;
    CGFloat buttonHeight = 32;
    CGFloat buttonSpacing = 10; // 按钮之间的间隔
    
    // 存储所有按钮，用于统一设置选中状态等
    self.filterButtons = [NSMutableArray array];
    
    // 创建"下载中"按钮
    UIButton *downloadingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadingButton.tag = FilterTypeDownloading;
    [downloadingButton setTitle:@"下载中" forState:UIControlStateNormal];
    downloadingButton.titleLabel.font = [UIFont systemFontOfSize:14];
    downloadingButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:1.0];
    downloadingButton.layer.cornerRadius = buttonHeight / 2;
    [downloadingButton addTarget:self action:@selector(filterButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.filterScrollView addSubview:downloadingButton];
    
    // 计算按钮宽度（根据标题自适应）
    CGSize titleSize = [@"下载中" sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    CGFloat buttonWidth = titleSize.width + buttonPadding * 2;
    
    // 修正：第一个按钮的x坐标从0开始，通过totalWidth累积间隔，确保后续按钮间隔一致
    downloadingButton.frame = CGRectMake(totalWidth, 0, buttonWidth, buttonHeight);
    // 累积宽度：按钮宽度 + 间隔（为下一个按钮预留间隔）
    totalWidth += buttonWidth + buttonSpacing;
    [self.filterButtons addObject:downloadingButton];
    
    // 创建"全部"按钮
    UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
    allButton.tag = FilterTypeAll;
    [allButton setTitle:@"全部" forState:UIControlStateNormal];
    allButton.titleLabel.font = [UIFont systemFontOfSize:14];
    allButton.backgroundColor = [UIColor lightGrayColor];
    allButton.layer.cornerRadius = buttonHeight / 2;
    [allButton addTarget:self action:@selector(filterButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.filterScrollView addSubview:allButton];
    
    // 计算按钮宽度
    titleSize = [@"全部" sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    buttonWidth = titleSize.width + buttonPadding * 2;
    
    // 此时totalWidth已包含"下载中"按钮的宽度 + 间隔，直接作为"全部"按钮的x坐标
    allButton.frame = CGRectMake(totalWidth, 0, buttonWidth, buttonHeight);
    totalWidth += buttonWidth + buttonSpacing; // 继续累积宽度 + 间隔
    [self.filterButtons addObject:allButton];
    
    // 遍历所有文件类型并创建对应按钮（原有逻辑正确，保持不变）
    for (int i = 0; i < FileTypeOther; i++) {
        FileType fileType = (FileType)i;
        NSString *typeName = [NewAppFileModel chineseDescriptionForFileType:fileType];
        NSString *shortName = [self shortNameForFileTypeName:typeName];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = FilterTypeFileTypes + i;
        [button setTitle:shortName forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        button.backgroundColor = [UIColor lightGrayColor];
        button.layer.cornerRadius = buttonHeight / 2;
        [button addTarget:self action:@selector(filterButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.filterScrollView addSubview:button];
        
        CGSize size = [shortName sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
        buttonWidth = size.width + buttonPadding * 2;
        button.frame = CGRectMake(totalWidth, 0, buttonWidth, buttonHeight);
        
        [self.filterButtons addObject:button];
        totalWidth += buttonWidth + buttonSpacing;
        
    }
    // 修正滚动视图内容大小（确保右侧预留间隔）
    self.filterScrollView.contentSize = CGSizeMake(totalWidth - buttonSpacing, buttonHeight);
}


#pragma mark - 筛选按钮点击事件

- (void)filterButtonTapped:(UIButton *)sender {
    [self buttonTappedIndex:sender.tag];
}

- (void)buttonTappedIndex:(NSInteger )index {
    // 更新按钮状态
    for (UIButton *button in self.filterButtons) {
        button.backgroundColor = (button.tag == index) ?
            [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:1.0] :
            [UIColor lightGrayColor];
    }
    
    // 更新当前筛选类型
    self.currentFilterType = (FilterType)index;
    
    // 应用筛选
    [self filterFiles];
    
    // 滚动到选中的按钮位置
    [self.filterScrollView scrollRectToVisible:self.filterButtons[index].frame animated:YES];
}

#pragma mark - 初始化表格
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    
    // 允许编辑模式下选中单元格
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"FileCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DownloadTaskCell"];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadFileList)];
    
    // 初始化空视图
    self.emptyView = [[EmptyView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    [self.view addSubview:self.emptyView];
    [self.view bringSubviewToFront:self.emptyView];
    
    [self updateEmptyViewVisibility];
    
    // 注册下载任务状态变化回调
    [[FileInstallManager sharedManager] registerTaskStatusChangedCallback:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleTaskStatusChanged];
        });
    }];

}

// 处理任务状态变化（新增方法）
- (void)handleTaskStatusChanged {
    // 获取所有下载任务
    NSArray<DownloadTaskModel *> *allTasks = [[FileInstallManager sharedManager] allDownloadTasks];
    
    // 检查是否有已完成的任务
    BOOL hasCompletedTask = NO;
    for (DownloadTaskModel *task in allTasks) {
        if (task.status == DownloadStatusCompleted) {
            hasCompletedTask = YES;
            break;
        }
    }
    
    
    // 如果有已完成的任务，刷新列表（清除已完成任务并重新加载）
    if (hasCompletedTask) {
        [self cleanCompletedTasksAndRefresh];
    } else {
        // 无已完成任务，仅刷新UI（如进度更新）
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

// 清除已完成任务并刷新列表（新增方法）
- (void)cleanCompletedTasksAndRefresh {
    // 1. 移除已完成的任务（从FileInstallManager的任务列表中）
    NSArray<DownloadTaskModel *> *allTasks = [[FileInstallManager sharedManager] allDownloadTasks];
    NSMutableArray<DownloadTaskModel *> *completedTasks = [NSMutableArray array];
    
    for (DownloadTaskModel *task in allTasks) {
        if (task.status == DownloadStatusCompleted) {
            [completedTasks addObject:task];
        }
    }
    
    // 从下载管理器中移除已完成任务（需要FileInstallManager提供删除方法，见步骤2）
    for (DownloadTaskModel *task in completedTasks) {
        [[FileInstallManager sharedManager] removeTask:task];
    }
    
    // 2. 重新加载文件列表（刷新本地文件和剩余任务）
    [self loadFileList];
}

#pragma mark - 刷新控件配置
// 更新空视图状态
- (void)updateEmptyViewVisibility {
    // 自定义空视图内容
    [_emptyView configureWithImage:[UIImage systemImageNamed:@"list.bullet.rectangle"]
                           title:@"暂无数据"
                     buttonTitle:@"刷新"];
    
    // 添加按钮点击事件
    [_emptyView.actionButton addTarget:self
                                action:@selector(loadFileList)
                      forControlEvents:UIControlEventTouchUpInside];
    [_emptyView updateConstraints];
}

#pragma mark - 设置约束
- (void)setupViewConstraints {
    CGFloat statusBarHeight = 0;
    CGFloat navigationBarHeight = 0;
    CGFloat headerHeight = 135; // 顶部视图高度
    
    // 设置顶部视图约束
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(statusBarHeight + navigationBarHeight);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(headerHeight));
    }];
    
    // 设置标题和副标题约束
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(16);
        make.left.equalTo(self.headerView).offset(16);
    }];
    
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.headerView).offset(16);
    }];
    
    // 设置顶部右侧删除按钮
    [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(16);
        make.right.equalTo(self.headerView).offset(-16);
        make.width.height.equalTo(@20);
    }];
    
    // 设置筛选滚动视图约束
    [self.filterScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(12);
        make.left.equalTo(self.headerView).offset(8);
        make.right.equalTo(self.headerView).offset(-8);
        make.height.equalTo(@32);
    }];
    
    // 底部工具栏约束
    [self.bottomToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        make.height.equalTo(@50);
    }];
    
    // 按钮约束
    CGFloat btnWidth = (self.view.bounds.size.width - 40) / 4;
    [self.selectAllBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomToolBar).offset(10);
        make.top.bottom.equalTo(self.bottomToolBar);
        make.width.equalTo(@(btnWidth));
    }];
    
    [self.deselectAllBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectAllBtn.mas_right).offset(10);
        make.top.bottom.equalTo(self.bottomToolBar);
        make.width.equalTo(@(btnWidth));
    }];
    
    [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.deselectAllBtn.mas_right).offset(10);
        make.top.bottom.equalTo(self.bottomToolBar);
        make.width.equalTo(@(btnWidth));
    }];
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.deleteBtn.mas_right).offset(10);
        make.top.bottom.equalTo(self.bottomToolBar);
        make.width.equalTo(@(btnWidth));
    }];
    
    // 设置表格约束
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
    // 空视图
    [self.emptyView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(30);
        make.width.height.equalTo(@300);
        make.centerX.equalTo(self.view);
    }];
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    
    // 底部工具栏约束
    [self.bottomToolBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
    // 设置表格约束
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        if(self.tableView.isEditing){
            make.bottom.equalTo(self.bottomToolBar.mas_top);
        }else{
            make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        }
    }];
    
    // 空视图
    [self.emptyView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(30);
        make.width.height.equalTo(@300);
        make.centerX.equalTo(self.view);
    }];
    
    self.emptyView.alpha = self.fileList.count == 0;
}

#pragma mark - 加载文件列表
- (void)loadFileList {
    NSLog(@"加载文件列表");
    NSError *error;
    // 获取目录下所有文件
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.downloadDir error:&error];
    if (error) {
        NSLog(@"获取文件列表失败: %@", error.localizedDescription);
        return;
    }
    
    // 过滤隐藏文件并拼接完整路径
    self.fileList = [NSMutableArray array];
    for (NSString *fileName in files) {
        if ([fileName hasPrefix:@"."]) continue; // 跳过隐藏文件
        NSString *filePath = [self.downloadDir stringByAppendingPathComponent:fileName];
        [self.fileList addObject:filePath];
    }
    
    // 按修改时间排序（最新的在前面）
    [self.fileList sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSDictionary *attr1 = [[NSFileManager defaultManager] attributesOfItemAtPath:obj1 error:nil];
        NSDictionary *attr2 = [[NSFileManager defaultManager] attributesOfItemAtPath:obj2 error:nil];
        return [attr2[NSFileModificationDate] compare:attr1[NSFileModificationDate]];
    }];
    
    // 应用当前筛选条件（关键：重新筛选，确保已完成任务被移除）
    [self filterFiles];
    
    // 刷新表格
    [self.tableView reloadData];
    
    [self.tableView.mj_header endRefreshing];
    
    // 更新空视图状态
    self.emptyView.alpha = self.filteredFileList.count == 0;
}

#pragma mark - 筛选文件
- (void)filterFiles {
    NSArray<DownloadTaskModel *> *allTasks = [[FileInstallManager sharedManager] allDownloadTasks];
    
    // 过滤出未完成的任务（仅保留下载中、暂停、等待的任务）
    NSArray<DownloadTaskModel *> *activeTasks = [allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DownloadTaskModel *task, NSDictionary *bindings) {
        return task.status != DownloadStatusCompleted;
    }]];
    
    if (self.currentFilterType == FilterTypeDownloading) {
        // 下载中：仅显示未完成的任务
        self.filteredFileList = [activeTasks mutableCopy];
        self.subtitleLabel.text = [NSString stringWithFormat:@"下载中 (%lu个任务)", (unsigned long)activeTasks.count];
    }
    else if (self.currentFilterType == FilterTypeAll) {
        // 全部：未完成任务 + 本地文件
        self.filteredFileList = [NSMutableArray array];
        [self.filteredFileList addObjectsFromArray:activeTasks]; // 仅添加未完成任务
        [self.filteredFileList addObjectsFromArray:self.fileList]; // 添加本地文件
        self.subtitleLabel.text = [NSString stringWithFormat:@"全部 (%lu个项目)", (unsigned long)self.filteredFileList.count];
    }
    else {
        // 按文件类型筛选（原有逻辑不变）
        FileType fileType = (FileType)(self.currentFilterType - FilterTypeFileTypes);
        self.filteredFileList = [NSMutableArray array];
        
        for (NSString *filePath in self.fileList) {
            FileType type = [NewAppFileModel fileTypeForFileName:[filePath lastPathComponent]];
            if (type == fileType) {
                [self.filteredFileList addObject:filePath];
            }
        }
        
        NSString *filterTitle = [NewAppFileModel chineseDescriptionForFileType:fileType];
        filterTitle = [self shortNameForFileTypeName:filterTitle];
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ (%lu个文件)", filterTitle, (unsigned long)self.filteredFileList.count];
    }
    
    [self.tableView reloadData];
}

#pragma mark - 长按表格进入多选模式
- (void)tableViewLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    if (self.tableView.isEditing) return;
    
    CGPoint point = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (!indexPath) return;
    
    // 检查长按的是否是可删除的文件（不是下载任务）
    if (self.currentFilterType == FilterTypeDownloading ||
        (self.currentFilterType == FilterTypeAll && indexPath.row < [[FileInstallManager sharedManager] allDownloadTasks].count)) {
        [self showAlertWithTitle:@"提示" message:@"下载任务不支持多选操作"];
        return;
    }
    
    // 进入编辑模式
    [self.tableView setEditing:YES animated:YES];
    self.bottomToolBar.hidden = NO;
    
    // 选中长按的单元格
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    // 将选中路径添加到集合
    NSString *filePath = self.filteredFileList[indexPath.row];
    [self.selectedFilePaths addObject:filePath];
    
    // 调整底部约束
    [self.tableView updateConstraints];
}

#pragma mark - UITableView数据源
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredFileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id item = self.filteredFileList[indexPath.row]; // 获取当前元素（可能是DownloadTaskModel或NSString）
    
    // 若元素是下载任务（DownloadTaskModel），则使用任务单元格
    if ([item isKindOfClass:[DownloadTaskModel class]]) {
        DownloadTaskModel *task = (DownloadTaskModel *)item;
        return [self cellForDownloadTask:tableView atIndexPath:indexPath task:task];
    }
    // 若元素是文件路径（NSString），则使用文件单元格
    else if ([item isKindOfClass:[NSString class]]) {
        NSInteger fileIndex = indexPath.row; // 直接使用当前索引（无需偏移计算）
        return [self cellForDownloadedFile:tableView atIndexPath:indexPath fileIndex:fileIndex];
    }
    // 异常情况处理
    else {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"InvalidCell"];
    }
}

// 配置下载任务单元格
- (UITableViewCell *)cellForDownloadTask:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath task:(DownloadTaskModel *)task {
    static NSString *taskCellId = @"DownloadTaskCell";
    // 强制使用支持副标题的样式
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:taskCellId];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3];
    
    // 添加进度覆盖层（半透明绿色）
    UIView *progressView = [[UIView alloc] init];
    progressView.tag = 100;
    progressView.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.2]; // 半透明绿色
    progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight; // 高度自适应
    [cell.contentView insertSubview:progressView atIndex:0]; // 放在最底层，不遮挡文字
    // 主标题显示文件名
    cell.textLabel.text = [NewAppFileModel fileNameFromPathString:task.fileName shouldDecodeChinese:YES];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    
    // 副标题显示下载信息（百分比、状态、速度等）
    NSString *statusText = @"";
    switch (task.status) {
        case DownloadStatusDownloading: {
            // 计算下载速度
            static NSTimeInterval lastUpdateTime = 0;
            static int64_t lastBytes = 0;
            NSTimeInterval now = CACurrentMediaTime();
            double speed = 0;
            
            if (lastUpdateTime > 0 && now - lastUpdateTime > 0.5) {
                int64_t bytesDiff = task.downloadedSize - lastBytes;
                speed = bytesDiff / (now - lastUpdateTime);
                lastUpdateTime = now;
                lastBytes = task.downloadedSize;
            } else if (lastUpdateTime == 0) {
                lastUpdateTime = now;
                lastBytes = task.downloadedSize;
            }
            
            // 格式化速度文本
            NSString *speedStr = @"0 B/s";
            if (speed > 0) {
                if (speed < 1024) speedStr = [NSString stringWithFormat:@"%.1f B/s", speed];
                else if (speed < 1024*1024) speedStr = [NSString stringWithFormat:@"%.1f KB/s", speed/1024];
                else speedStr = [NSString stringWithFormat:@"%.1f MB/s", speed/(1024*1024)];
            }
            
            // 组合副标题文本（百分比 + 速度）
            statusText = [NSString stringWithFormat:@"%.0f%% • %@", task.progress * 100, speedStr];
            break;
        }
        case DownloadStatusPaused:
            statusText = [NSString stringWithFormat:@"%.0f%% • 已暂停", task.progress * 100];
            break;
        case DownloadStatusFailed:
            statusText = [NSString stringWithFormat:@"%.0f%% • 下载失败", task.progress * 100];
            break;
        case DownloadStatusWaiting:
            statusText = @"等待中";
            break;
        case DownloadStatusCompleted:
            statusText = @"100% • 已完成";
            break;
    }
    cell.detailTextLabel.text = statusText;
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor]; // 确保文本可见
    
    // 更新进度覆盖层宽度（从左到右覆盖）
    
    CGFloat progressWidth = [UIScreen mainScreen].bounds.size.width * task.progress;
    progressView.frame = CGRectMake(0, 0, progressWidth, cell.contentView.bounds.size.height);
    
    return cell;
}

// 配置已完成文件单元格
- (UITableViewCell *)cellForDownloadedFile:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath fileIndex:(NSInteger)fileIndex {
    static NSString *fileCellId = @"FileCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:fileCellId];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3];
    
    // 获取文件路径
    NSString *filePath = self.filteredFileList[fileIndex];
    NSString *fileName = [NewAppFileModel fileNameFromPathString:filePath shouldDecodeChinese:YES];
    
    // 处理特殊格式文件名（例如："前缀_mainFile_实际文件名.后缀"）
    NSArray *array = [fileName componentsSeparatedByString:MAIN_File_KEY];
    if (array.count > 1) {
        cell.textLabel.text = array[1];
    } else {
        cell.textLabel.text = fileName;
    }
    
    // 设置文件信息
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSDate *modificationDate = attributes[NSFileModificationDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    
    // 获取文件大小
    NSNumber *fileSizeNumber = attributes[NSFileSize];
    NSString *fileSizeStr = @"未知大小";
    if (fileSizeNumber) {
        long long fileSize = [fileSizeNumber longLongValue];
        if (fileSize < 1024) {
            fileSizeStr = [NSString stringWithFormat:@"%lld B", fileSize];
        } else if (fileSize < 1024 * 1024) {
            fileSizeStr = [NSString stringWithFormat:@"%.2f KB", (double)fileSize / 1024];
        } else if (fileSize < 1024 * 1024 * 1024) {
            fileSizeStr = [NSString stringWithFormat:@"%.2f MB", (double)fileSize / (1024 * 1024)];
        } else {
            fileSizeStr = [NSString stringWithFormat:@"%.2f GB", (double)fileSize / (1024 * 1024 * 1024)];
        }
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ • %@",
                                [self fileTypeDescription:filePath],
                                [formatter stringFromDate:modificationDate]];
    
    // 编辑模式下显示勾选状态
    if (self.tableView.isEditing) {
        cell.accessoryType = [self.selectedFilePaths containsObject:filePath] ?
                             UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 判断是下载任务还是已完成文件
    if (self.currentFilterType == FilterTypeDownloading ||
        (self.currentFilterType == FilterTypeAll && indexPath.row < [[FileInstallManager sharedManager] allDownloadTasks].count)) {
        
        // 下载任务操作
        DownloadTaskModel *task = self.currentFilterType == FilterTypeDownloading ?
            self.filteredFileList[indexPath.row] :
            [[FileInstallManager sharedManager] allDownloadTasks][indexPath.row];
        
        [self showTaskActionSheet:task];
    } else {
        // 已完成文件操作
        NSInteger fileIndex = self.currentFilterType == FilterTypeAll ?
            indexPath.row - [[FileInstallManager sharedManager] allDownloadTasks].count :
            indexPath.row;
        
        NSString *filePath = self.filteredFileList[fileIndex];
        
        if (self.tableView.isEditing) {
            // 多选模式下处理选择
            BOOL isSelected = [self.selectedFilePaths containsObject:filePath];
            if (isSelected) {
                [self.selectedFilePaths removeObject:filePath];
            } else {
                [self.selectedFilePaths addObject:filePath];
            }
            
            // 更新单元格勾选状态
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = isSelected ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
        } else {
            // 普通模式下显示文件操作菜单
            [self showFileActionSheetForPath:filePath];
        }
    }
}

// 任务操作菜单
- (void)showTaskActionSheet:(DownloadTaskModel *)task {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:task.fileName message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (task.status == DownloadStatusDownloading) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"暂停" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[FileInstallManager sharedManager] pauseTask:task];
        }]];
    } else if (task.status == DownloadStatusPaused || task.status == DownloadStatusFailed) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[FileInstallManager sharedManager] resumeTask:task];
        }]];
    }
    
    if (task.status != DownloadStatusCompleted) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"取消下载" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[FileInstallManager sharedManager] cancelTask:task];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[FileInstallManager sharedManager] removeTask:task];
                [self loadFileList];
            });
            
            
        }]];
    }
    
    if (task.status == DownloadStatusCompleted && task.localPath) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self installFileAtPath:task.localPath];
        }]];
        
        [sheet addAction:[UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openFileInAppAtPath:task.localPath];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

// 左滑删除功能
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 只有已完成的文件支持删除
    if (self.currentFilterType == FilterTypeDownloading ||
        (self.currentFilterType == FilterTypeAll && indexPath.row < [[FileInstallManager sharedManager] allDownloadTasks].count)) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger fileIndex = self.currentFilterType == FilterTypeAll ?
            indexPath.row - [[FileInstallManager sharedManager] allDownloadTasks].count :
            indexPath.row;
        
        NSString *filePath = self.filteredFileList[fileIndex];
        
        // 删除文件
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (success) {
            // 从数据源中移除
            [self.fileList removeObject:filePath];
            [self.filteredFileList removeObjectAtIndex:fileIndex];
            
            // 更新UI
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            // 更新副标题计数
            [self filterFiles];
        } else {
            [self showAlertWithTitle:@"删除失败" message:error.localizedDescription];
        }
    }
}

#pragma mark - 文件操作菜单
- (void)showFileActionSheetForPath:(NSString *)filePath {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"文件操作"
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 1. 安装选项（保留原有功能）
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self installFileAtPath:filePath];
    }]];
    
    // 2. 在App中打开选项
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"在App中打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openFileInAppAtPath:filePath];
    }]];
    
    // 3. 分享选项
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self shareFileAtPath:filePath];
    }]];
    
    // 4. 取消选项
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // 显示菜单
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - 文件操作实现
- (void)installFileAtPath:(NSString *)filePath {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSLog(@"下载完成执行安装fileURL:%@",fileURL);
        if(fileURL){
            [[FileInstallManager sharedManager] installFileWithURL:fileURL completion:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    [self showAlertWithTitle:@"安装失败" message:error.localizedDescription];
                }
            }];
        }
    });
    
}

- (void)openFileInAppAtPath:(NSString *)filePath {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    // 检查文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self showAlertWithTitle:@"文件不存在" message:@"该文件可能已被删除"];
        return;
    }
    
    // 创建文件交互控制器
    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.documentController.delegate = self;
    
    // 尝试在其他应用中打开
    BOOL canOpen = [self.documentController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    if (!canOpen) {
        [self showAlertWithTitle:@"无法打开" message:@"没有找到支持打开此文件的应用"];
    }
}

- (void)shareFileAtPath:(NSString *)filePath {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    // 检查文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self showAlertWithTitle:@"文件不存在" message:@"该文件可能已被删除"];
        return;
    }
    
    // 创建分享活动控制器
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
    
    // 排除不想要的活动类型
    activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact];
    
    // 显示分享菜单
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

#pragma mark - UITableViewDelegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 允许编辑模式下选中单元格
    return indexPath;
}

#pragma mark - 全选
- (void)selectAllFiles {
    [self.selectedFilePaths removeAllObjects];
    
    // 只选择文件，不选择下载任务
    if (self.currentFilterType == FilterTypeAll) {
        NSArray<DownloadTaskModel *> *downloadTasks = [[FileInstallManager sharedManager] allDownloadTasks];
        NSRange fileRange = NSMakeRange(downloadTasks.count, self.filteredFileList.count - downloadTasks.count);
        NSArray *files = [self.filteredFileList subarrayWithRange:fileRange];
        [self.selectedFilePaths addObjectsFromArray:files];
    } else if (self.currentFilterType != FilterTypeDownloading) {
        [self.selectedFilePaths addObjectsFromArray:self.filteredFileList];
    }
    
    [self.tableView reloadData]; // 刷新所有单元格的勾选状态
}

#pragma mark - 全取消
- (void)deselectAllFiles {
    [self.selectedFilePaths removeAllObjects];
    [self.tableView reloadData]; // 刷新所有单元格的勾选状态
}

#pragma mark - 删除选中文件
- (void)deleteSelectedFiles {
    if (self.selectedFilePaths.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要删除的文件"];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除"
                                                                   message:[NSString stringWithFormat:@"是否删除选中的%lu个文件？", (unsigned long)self.selectedFilePaths.count]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 执行删除
        for (NSString *filePath in self.selectedFilePaths) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            [self.fileList removeObject:filePath];
        }
        
        // 更新列表
        [self.filteredFileList removeObjectsInArray:self.selectedFilePaths];
        [self.selectedFilePaths removeAllObjects];
        [self.tableView reloadData];
        [self filterFiles]; // 更新副标题计数
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 取消编辑模式
- (void)cancelEditMode {
    [self.tableView setEditing:NO animated:YES];
    self.bottomToolBar.hidden = YES;
    [self.selectedFilePaths removeAllObjects];
    
    // 恢复表格底部约束
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
    // 刷新所有单元格（隐藏勾选图标）
    [self.tableView reloadData];
}

- (void)clear:(UIButton*)button {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除下载" message:@"清空所有下载的文件" preferredStyle:UIAlertControllerStyleActionSheet];
    // 添加取消按钮
    UIAlertAction*cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        
    }];
    [alert addAction:cancelAction];
    UIAlertAction*confirmAction = [UIAlertAction actionWithTitle:@"删除全部" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 清理沙盒缓存
        NSString *downloadPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
                                      stringByAppendingPathComponent:@"Downloads"];
        
        NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:downloadPath];
        for (int i = 0; i<files.count; i++) {
            NSString *file = files[i];
        
            NSString *filePath = [downloadPath stringByAppendingPathComponent:file];
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                NSLog(@"清理文件 %@ 失败: %@", filePath, error);
            }
            [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"共(%ld)正在删除第%d个文件\n%@",files.count,i,file]];
            if(i==files.count-1){
                [SVProgressHUD showSuccessWithStatus:@"删除完毕"];
                [SVProgressHUD dismissWithDelay:2];
            }
            
        }
    }];
    [alert addAction:confirmAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 显示提示弹窗
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertWithConfirmationFromViewController:(UIViewController *)viewController
                                              title:(NSString *)title
                                            message:(NSString *)message
                                         confirmTitle:(NSString *)confirmTitle
                                          cancelTitle:(NSString *)cancelTitle
                                         onConfirmed:(void(^)(void))confirmed
                                        onCancelled:(void(^)(void))cancelled {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *action) {
        if (confirmed) {
            confirmed();
        }
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {
        if (cancelled) {
            cancelled();
        }
    }]];
    
    [viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 辅助方法
// 获取文件类型描述
- (NSString *)fileTypeDescription:(NSString *)filePath {
    FileType type = [NewAppFileModel fileTypeForFileName:[filePath lastPathComponent]];
    return [NewAppFileModel chineseDescriptionForFileType:type];
}

// 从完整文件类型名称提取简短名称
- (NSString *)shortNameForFileTypeName:(NSString *)fullName {
    if ([fullName containsString:@"应用"]) return @"应用";
    if ([fullName containsString:@"插件"]) return @"插件";
    if ([fullName containsString:@"脚本"]) return @"脚本";
    if ([fullName containsString:@"网页"]) return @"网页";
    if ([fullName containsString:@"JSON"]) return @"JSON";
    if ([fullName containsString:@"配置"]) return @"配置";
    if ([fullName containsString:@"动态链接"]) return @"库";
    if ([fullName containsString:@"压缩"]) return @"压缩包";
    return fullName;
}

//侧滑手势
- (BOOL)allowScreenEdgeInteractive{
    return NO;
}

@end
