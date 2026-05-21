#import "FileListViewController.h"
#import "FileListCell.h"
#import "FileModel.h"
#import "SandboxTool.h"
#import "FileOperateTool.h"
#import "FavoriteManager.h"
#import "FileNotification.h"
#import "FileEnum.h"
#import "FileActionHandler.h"
#import "RemarkManager.h"
#import "FavoriteListViewController.h"
#import "FilePreviewViewController.h"
#import "PlistEditorVC.h"

static NSString * const kCellIdentifier = @"FileListCell";

@interface FileListViewController ()
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
@property (nonatomic, strong) UIBarButtonItem *searchScopeItem;
@property (nonatomic, strong) UIBarButtonItem *selectionCountButton;
@property (nonatomic, copy) NSString *initialPath;
@property (nonatomic, assign) SandboxDirectoryType initialSandboxDir;
@property (nonatomic, copy) NSString *initialSubPath;
@property (nonatomic, assign) BOOL hasCustomInitialPath;
@end

@implementation FileListViewController

#pragma mark - 初始化方法

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasCustomInitialPath = NO;
        _initialSandboxDir = SandboxDirectoryTypeHome;
        _initialSubPath = nil;
    }
    return self;
}

- (instancetype)initWithFullPath:(NSString *)fullPath {
    self = [super init];
    if (self) {
        _initialPath = [fullPath copy];
        _hasCustomInitialPath = YES;
    }
    return self;
}

- (instancetype)initWithSandboxDirectory:(SandboxDirectoryType)directoryType {
    return [self initWithSandboxDirectory:directoryType subPath:nil];
}

- (instancetype)initWithSandboxDirectory:(SandboxDirectoryType)directoryType subPath:(NSString *)subPath {
    self = [super init];
    if (self) {
        _initialSandboxDir = directoryType;
        _initialSubPath = [subPath copy];
        _hasCustomInitialPath = NO;
    }
    return self;
}

- (void)setInitialPath:(NSString *)path {
    _initialPath = [path copy];
    _hasCustomInitialPath = YES;
}

- (void)setInitialSandboxDirectory:(SandboxDirectoryType)directoryType subPath:(NSString *)subPath {
    _initialSandboxDir = directoryType;
    _initialSubPath = [subPath copy];
    _hasCustomInitialPath = NO;
}

#pragma mark - 视图加载

// 视图加载完成时调用
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setupUI];
    [self setupEmptyView];
    [self setupNotifications];
    [self refreshFileList];
}

// 初始化数据
- (void)setupData {
    _currentDisplayType = DisplayTypeAll;
    _isBatchEditing = NO;
    _isShowFavoriteList = NO;
    _searchCurrentDirectoryOnly = YES;
    _currentSortType = 0;
    _isSortAscending = YES;
    _fileList = [NSMutableArray array];
    _selectedFileList = [NSMutableArray array];
    _favoriteFileList = [NSMutableArray array];
    _clipboardFileList = nil;
    _isCopyOperation = YES;
    _searchResults = [NSMutableArray array];
    
    if (_hasCustomInitialPath && _initialPath) {
        _currentDirPath = [_initialPath copy];
        _currentSandboxDir = [self detectSandboxDirectoryTypeFromPath:_currentDirPath];
    } else {
        NSString *basePath = [SandboxTool getSandboxDirectoryPath:_initialSandboxDir];
        if (_initialSubPath && _initialSubPath.length > 0) {
            _currentDirPath = [basePath stringByAppendingPathComponent:_initialSubPath];
        } else {
            _currentDirPath = basePath;
        }
        _currentSandboxDir = _initialSandboxDir;
    }
}

- (SandboxDirectoryType)detectSandboxDirectoryTypeFromPath:(NSString *)path {
    NSArray *dirTypes = @[@(SandboxDirectoryTypeDocuments),
                          @(SandboxDirectoryTypeLibrary),
                          @(SandboxDirectoryTypeCaches),
                          @(SandboxDirectoryTypeTmp)];
    
    for (NSNumber *dirTypeNum in dirTypes) {
        SandboxDirectoryType dirType = (SandboxDirectoryType)[dirTypeNum integerValue];
        NSString *dirPath = [SandboxTool getSandboxDirectoryPath:dirType];
        if ([path hasPrefix:dirPath]) {
            return dirType;
        }
    }
    return SandboxDirectoryTypeDocuments;
}

// 设置界面UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"文件管理器";
    
    if (self.navigationController) {
        self.navigationController.navigationBar.barTintColor = [UIColor systemBackgroundColor];
        self.navigationController.navigationBar.tintColor = [UIColor labelColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor labelColor]}];
        if (@available(iOS 15.0, *)) {
            UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
            [appearance configureWithDefaultBackground];
            self.navigationController.navigationBar.standardAppearance = appearance;
            self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        }
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    
    [self setupNavigationBar];
    [self setupPathLabel];
    [self setupTableView];
    [self setupBottomToolbar];
    [self setupLongPressGesture];
    [self setupSwipeGesture];
}

// 设置导航栏
- (void)setupNavigationBar {
    UIImage *backIcon = [UIImage systemImageNamed:@"chevron.backward"];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:backIcon
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(backButtonTapped:)];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索文件";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;
    
    // 创建搜索范围选项卡
    UISegmentedControl *searchScopeControl = [[UISegmentedControl alloc] initWithItems:@[@"当前", @"全部"]];
    searchScopeControl.selectedSegmentIndex = 0;
    [searchScopeControl addTarget:self action:@selector(searchScopeChanged:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *searchScopeItem = [[UIBarButtonItem alloc] initWithCustomView:searchScopeControl];
    self.searchScopeItem = searchScopeItem;
    
    self.createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                      target:self
                                                                      action:@selector(createButtonTapped:)];
    
    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                     target:self
                                                                     action:@selector(closeButtonTapped:)];
    
    self.completeButton = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(exitBatchEditMode)];
    
    self.collectionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"star"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(openCollectionListViewController)];
    
    self.pasteButton = [[UIBarButtonItem alloc] initWithTitle:@"粘贴"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(pasteButtonTappedFromNav:)];
    self.pasteButton.enabled = NO;
    
    self.selectionCountButton = [[UIBarButtonItem alloc] initWithTitle:@"0 项"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    self.selectionCountButton.enabled = NO;
    
    self.navigationItem.leftBarButtonItems = @[backButton, self.createButton];
    self.navigationItem.rightBarButtonItems = @[self.closeButton,self.collectionButton];
    self.definesPresentationContext = YES;
}

// 设置路径标签按钮和底部排序按钮
- (void)setupPathLabel {
    self.pathButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pathButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.pathButton.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.pathButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.pathButton.titleLabel.numberOfLines = 1;
    self.pathButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
    [self.pathButton addTarget:self action:@selector(pathLabelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pathButton];

    // 创建统计信息标签
    self.statisticsLabel = [[UILabel alloc] init];
    self.statisticsLabel.font = [UIFont systemFontOfSize:11];
    self.statisticsLabel.textColor = [UIColor secondaryLabelColor];
    self.statisticsLabel.textAlignment = NSTextAlignmentCenter;
    self.statisticsLabel.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    [self.view addSubview:self.statisticsLabel];

    // 创建底部按钮滚动视图
    self.bottomButtonScrollView = [[UIScrollView alloc] init];
    self.bottomButtonScrollView.showsHorizontalScrollIndicator = NO;
    self.bottomButtonScrollView.showsVerticalScrollIndicator = NO;
    self.bottomButtonScrollView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.bottomButtonScrollView];
    
    // 创建按钮配置数组
    NSArray<NSDictionary<NSString *, id> *> *buttonConfigs = @[
        @{@"title": @"名称↑", @"tag": @0},
        @{@"title": @"类型↑", @"tag": @1},
        @{@"title": @"日期↑", @"tag": @2},
        @{@"title": @"大小↑", @"tag": @3},
        @{@"title": @"收藏", @"tag": @100},
        @{@"title": @"全部", @"tag": @101},
        @{@"title": @"改后缀", @"tag": @102},
        @{@"title": @"删后缀", @"tag": @103},
        @{@"title": @"跳转", @"tag": @104},
    ];

    self.bottomButtons = [NSMutableArray array];

    for (NSDictionary<NSString *, id> *config in buttonConfigs) {
        NSString *title = config[@"title"];
        NSInteger tag = [config[@"tag"] integerValue];

        UIButton *button = [self createSortButtonWithTitle:title tag:tag];
        [self.bottomButtonScrollView addSubview:button];
        [self.bottomButtons addObject:button];
    }

    [self updateSortButtonStates];
    [self updateFunctionButtonStates];
}
// 创建排序按钮
- (UIButton *)createSortButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13];
    button.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    button.layer.cornerRadius = 6;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor systemBlueColor].CGColor;
    button.tag = tag;
    [button addTarget:self action:@selector(bottomButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

// 底部按钮统一点击处理
- (void)bottomButtonTapped:(UIButton *)sender {
    NSInteger tag = sender.tag;

    if (tag >= 0 && tag <= 3) {
        [self handleSortButtonTap:sender];
    } else if (tag == 100) {
        [self favoriteButtonTapped:sender];
    } else if (tag == 101) {
        [self filterButtonTapped:sender];
    } else if (tag == 102) {
        [self batchChangeExtensionTapped:sender];
    } else if (tag == 103) {
        [self batchDeleteExtensionTapped:sender];
    } else if (tag == 104) {
        [self jumpToPathTapped:sender];
    }
}

// 排序按钮点击处理
- (void)handleSortButtonTap:(UIButton *)sender {
    NSInteger newSortType = sender.tag;

    if (self.currentSortType == newSortType) {
        self.isSortAscending = !self.isSortAscending;
    } else {
        self.currentSortType = newSortType;
        self.isSortAscending = YES;
    }

    [self updateSortButtonStates];
    [self sortFileList];
}

// 更新排序按钮状态
- (void)updateSortButtonStates {
    NSArray *titles = @[@"名称", @"类型", @"日期", @"大小"];

    for (NSInteger i = 0; i < 4; i++) {
        UIButton *button = self.bottomButtons[i];
        NSString *arrow = self.isSortAscending ? @"↑" : @"↓";
        [button setTitle:[NSString stringWithFormat:@"%@%@", titles[i], arrow] forState:UIControlStateNormal];

        if (i == self.currentSortType) {
            button.backgroundColor = [UIColor systemBlueColor];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            button.backgroundColor = [UIColor tertiarySystemBackgroundColor];
            [button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        }
    }
}

// 更新功能按钮状态
- (void)updateFunctionButtonStates {
    UIButton *favoriteBtn = self.bottomButtons[4];
    UIButton *filterBtn = self.bottomButtons[5];

    if (self.isShowFavoriteList) {
        favoriteBtn.backgroundColor = [UIColor systemBlueColor];
        [favoriteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        favoriteBtn.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        [favoriteBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    }

    if (self.currentDisplayType == DisplayTypeFolderOnly) {
        filterBtn.backgroundColor = [UIColor systemBlueColor];
        [filterBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [filterBtn setTitle:@"文件夹" forState:UIControlStateNormal];
    } else {
        filterBtn.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        [filterBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [filterBtn setTitle:@"全部" forState:UIControlStateNormal];
    }

    [self relayoutScrollViewButtons];
}

// 重新布局滚动视图内的按钮
- (void)relayoutScrollViewButtons {
    CGFloat buttonX = 16;
    CGFloat buttonY = 3;
    CGFloat sortButtonHeight = 26;
    CGFloat buttonPadding = 10;

    for (UIButton *button in self.bottomButtons) {
        [button sizeToFit];
        CGFloat buttonWidth = button.frame.size.width + buttonPadding;
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, sortButtonHeight - 6);
        buttonX += buttonWidth + 10;
    }
    self.bottomButtonScrollView.contentSize = CGSizeMake(buttonX + 15, sortButtonHeight);
}

// 设置表格视图
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerClass:[FileListCell class] forCellReuseIdentifier:kCellIdentifier];
    [self.view addSubview:self.tableView];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
}

// 设置空视图
- (void)setupEmptyView {
    self.emptyView = [[UIView alloc] init];
    self.emptyView.backgroundColor = [UIColor systemBackgroundColor];
    self.emptyView.hidden = YES;
    [self.view addSubview:self.emptyView];
    
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.image = [UIImage systemImageNamed:@"folder.badge.questionmark"];
    iconView.tintColor = [UIColor systemGrayColor];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emptyView addSubview:iconView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"暂无文件";
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emptyView addSubview:titleLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"点击下方按钮重新加载";
    subtitleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.textColor = [UIColor secondaryLabelColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emptyView addSubview:subtitleLabel];
    
    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [reloadButton setTitle:@"重新加载" forState:UIControlStateNormal];
    [reloadButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    reloadButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    reloadButton.layer.borderWidth = 1;
    reloadButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
    reloadButton.layer.cornerRadius = 8;
    [reloadButton addTarget:self action:@selector(reloadButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    reloadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emptyView addSubview:reloadButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [iconView.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:self.emptyView.centerYAnchor constant:-80],
        [iconView.widthAnchor constraintEqualToConstant:80],
        [iconView.heightAnchor constraintEqualToConstant:80],
        
        [titleLabel.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:20],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
        
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [subtitleLabel.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
        
        [reloadButton.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:24],
        [reloadButton.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
        [reloadButton.widthAnchor constraintEqualToConstant:120],
        [reloadButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

// 重新加载按钮点击
- (void)reloadButtonTapped {
    [self refreshFileList];
}

// 更新空视图显示状态
- (void)updateEmptyView {
    BOOL isEmpty = NO;
    if (self.searchController.isActive) {
        isEmpty = (self.searchResults.count == 0);
    } else if (self.isShowFavoriteList) {
        isEmpty = (self.favoriteFileList.count == 0);
    } else {
        isEmpty = (self.fileList.count == 0);
    }
    
    self.emptyView.hidden = !isEmpty;
}

// 设置底部工具栏
- (void)setupBottomToolbar {
    self.bottomToolbar = [[UIView alloc] init];
    self.bottomToolbar.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.bottomToolbar.hidden = YES;
    [self.view addSubview:self.bottomToolbar];
    
    UIButton *selectAllBtn = [self createToolbarButtonWithTitle:@"全选" action:@selector(selectAllButtonTapped:)];
    [selectAllBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    
    UIButton *deselectAllBtn = [self createToolbarButtonWithTitle:@"全取消" action:@selector(deselectAllButtonTapped:)];
    [deselectAllBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    
    UIButton *copyBtn = [self createToolbarButtonWithTitle:@"拷贝" action:@selector(copyButtonTapped:)];
    [copyBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    
    UIButton *moveBtn = [self createToolbarButtonWithTitle:@"移动" action:@selector(moveButtonTapped:)];
    [moveBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    
    UIButton *deleteBtn = [self createToolbarButtonWithTitle:@"删除" action:@selector(deleteButtonTapped:)];
    [deleteBtn setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    
    UIButton *compressBtn = [self createToolbarButtonWithTitle:@"压缩" action:@selector(compressButtonTapped:)];
    [compressBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    
    UIButton *doneBtn = [self createToolbarButtonWithTitle:@"完成" action:@selector(doneButtonTapped:)];
    [doneBtn setTitleColor:[UIColor systemGreenColor] forState:UIControlStateNormal];
    
    selectAllBtn.tag = 0;
    deselectAllBtn.tag = 1;
    copyBtn.tag = 2;
    moveBtn.tag = 3;
    deleteBtn.tag = 4;
    compressBtn.tag = 5;
    doneBtn.tag = 6;
    
    [self.bottomToolbar addSubview:selectAllBtn];
    [self.bottomToolbar addSubview:deselectAllBtn];
    [self.bottomToolbar addSubview:copyBtn];
    [self.bottomToolbar addSubview:moveBtn];
    [self.bottomToolbar addSubview:deleteBtn];
    [self.bottomToolbar addSubview:compressBtn];
    [self.bottomToolbar addSubview:doneBtn];
}

// 创建工具栏按钮
- (UIButton *)createToolbarButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

// 设置长按手势
- (void)setupLongPressGesture {
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.minimumPressDuration = 0.5;
    [self.tableView addGestureRecognizer:self.longPressGesture];
}

// 设置右滑返回手势
- (void)setupSwipeGesture {
    UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipeGesture:)];
    rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipeGesture];
}

// 处理视图右滑手势
- (void)handleRightSwipeGesture:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        // 检查是否可以返回上一层目录
        NSString *documentsPath = [SandboxTool getSandboxDirectoryPath:SandboxDirectoryTypeDocuments];
        NSString *rootPath = [documentsPath stringByDeletingLastPathComponent];
        
        if ([self.currentDirPath isEqualToString:rootPath] || self.isShowFavoriteList || self.searchController.isActive) {
            return;
        }
        
        NSString *parentPath = [self.currentDirPath stringByDeletingLastPathComponent];
        [self navigateToDirectory:parentPath];
    }
}

// 设置通知观察
- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleFavoriteChanged:)
                                                 name:kNotificationFavoriteChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleFileListChanged:)
                                                 name:kNotificationFileListChanged
                                               object:nil];
}

// 视图布局完成时调用
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    
    CGFloat safeTop = self.view.safeAreaInsets.top;
    
    CGFloat sortButtonHeight = 26;
    CGFloat statisticsHeight = 20;
    CGFloat pathHeight = 26;
    CGFloat toolbarHeight = 50;
    CGFloat bottomSafeHeight = self.view.safeAreaInsets.bottom;
    CGFloat horizontalPadding = 0;
    
    // 顶部排序按钮滚动视图布局
    self.bottomButtonScrollView.frame = CGRectMake(0,
                                                   safeTop,
                                                   self.view.bounds.size.width, sortButtonHeight);
    
    // 排列顶部滚动视图内的排序按钮
    [self relayoutScrollViewButtons];
    
    // 统计信息标签布局（路径标签上方）
    self.statisticsLabel.frame = CGRectMake(0,
                                            self.view.bounds.size.height - statisticsHeight - pathHeight - bottomSafeHeight,
                                            self.view.bounds.size.width, statisticsHeight);
    
    // 路径标签布局（底部）
    self.pathButton.frame = CGRectMake(horizontalPadding,
                                       self.view.bounds.size.height - pathHeight - bottomSafeHeight,
                                       self.view.bounds.size.width - horizontalPadding * 2, pathHeight);
    
    if (self.isBatchEditing) {
        self.tableView.frame = CGRectMake(0, safeTop  + sortButtonHeight,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height - safeTop - sortButtonHeight - statisticsHeight - pathHeight - toolbarHeight - bottomSafeHeight);
        self.bottomToolbar.frame = CGRectMake(0, self.view.bounds.size.height - toolbarHeight - bottomSafeHeight,
                                              self.view.bounds.size.width, toolbarHeight);
        [self layoutToolbarButtons];
    } else {
        self.tableView.frame = CGRectMake(0, safeTop  + sortButtonHeight,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height - safeTop  - sortButtonHeight - statisticsHeight - pathHeight - bottomSafeHeight);
        self.bottomToolbar.frame = CGRectMake(0, -100, 0, 0);
    }
    
    // 空视图布局（与tableView相同位置）
    self.emptyView.frame = self.tableView.frame;
}

// 布局工具栏按钮
- (void)layoutToolbarButtons {
    CGFloat width = self.view.bounds.size.width;
    CGFloat buttonWidth = width / 7;
    for (NSInteger i = 0; i < self.bottomToolbar.subviews.count; i++) {
        UIView *subview = self.bottomToolbar.subviews[i];
        if ([subview isKindOfClass:[UIButton class]]) {
            subview.frame = CGRectMake(i * buttonWidth, 5, buttonWidth, 40);
        }
    }
}

#pragma mark - Actions

// 打开收藏列表
- (void)openCollectionListViewController {
    FavoriteListViewController *favoriteListVC = [[FavoriteListViewController alloc] init];
    favoriteListVC.sourceFileListVC = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:favoriteListVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

// 导航到指定路径
- (void)navigateToPath:(NSString *)path {
    self.currentDirPath = path;
    [self refreshFileList];
}

// 返回按钮点击事件
- (void)backButtonTapped:(UIBarButtonItem *)sender {
    NSString *parentPath = [self.currentDirPath stringByDeletingLastPathComponent];
    NSString *documentsPath = [SandboxTool getSandboxDirectoryPath:SandboxDirectoryTypeDocuments];
    NSString *rootPath = [documentsPath stringByDeletingLastPathComponent];
    
    if ([self.currentDirPath isEqualToString:rootPath]) {
        return;
    }
    
    self.currentDirPath = parentPath;
    [self refreshFileList];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDirectoryChanged
                                                        object:nil
                                                      userInfo:@{@"path": self.currentDirPath}];
}

// 关闭按钮点击事件
- (void)closeButtonTapped:(UIBarButtonItem *)sender {
    // 发送通知，带上当前目录、选中的文件和self
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDirectoryChanged
                                                        object:self
                                                      userInfo:@{
        @"path": self.currentDirPath,
        @"selectedFiles": [self.selectedFileList copy],
        @"controller": self
    }];
    
    // 调用代理方法
    if ([self.delegate respondsToSelector:@selector(fileManagerDidCloseWithSelectedFiles:currentDirPath:controller:)]) {
        [self.delegate fileManagerDidCloseWithSelectedFiles:[self.selectedFileList copy]
                                             currentDirPath:self.currentDirPath
                                                 controller:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 路径标签按钮点击事件，复制路径到剪贴板
- (void)pathLabelTapped {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.currentDirPath;
    [self showAlertWithTitle:@"提示" message:@"路径已复制到剪贴板"];
}

// 导航栏粘贴按钮点击事件
- (void)pasteButtonTappedFromNav:(UIBarButtonItem *)sender {
    if (self.clipboardFileList.count == 0) {
        return;
    }
    
    NSString *operation = self.isCopyOperation ? @"拷贝" : @"移动";
    NSMutableString *resultMessage = [NSMutableString string];
    
    for (FileModel *model in self.clipboardFileList) {
        NSString *destinationPath = [self.currentDirPath stringByAppendingPathComponent:model.fileName];
        NSError *error = nil;
        BOOL success = NO;
        
        if (self.isCopyOperation) {
            success = [[NSFileManager defaultManager] copyItemAtPath:model.filePath toPath:destinationPath error:&error];
        } else {
            success = [[NSFileManager defaultManager] moveItemAtPath:model.filePath toPath:destinationPath error:&error];
        }
        
        if (success) {
            [resultMessage appendFormat:@"%@ 成功\n", model.fileName];
        } else {
            [resultMessage appendFormat:@"%@ 失败: %@\n", model.fileName, error.localizedDescription];
        }
    }
    
    [self showAlertWithTitle:[NSString stringWithFormat:@"%@结果", operation] message:resultMessage];
    
    self.clipboardFileList = nil;
    self.pasteButton.enabled = NO;
    self.pasteButton.title = @"粘贴";
    NSMutableArray *items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items removeObject:self.pasteButton];
    self.navigationItem.rightBarButtonItems = items;
    [self refreshFileList];
}

// 取消粘贴按钮点击事件
- (void)cancelPasteButtonTapped:(UIBarButtonItem *)sender {
    self.clipboardFileList = nil;
    self.pasteButton.enabled = NO;
    self.pasteButton.title = @"粘贴";
    
    if (self.searchController.isActive) {
        // 搜索模式下，显示搜索范围选项卡
        self.navigationItem.rightBarButtonItems = @[self.closeButton, self.closeButton];
    } else {
        // 非搜索模式下
        self.navigationItem.rightBarButtonItems = @[self.closeButton, self.collectionButton];
    }
}

// 筛选按钮点击事件
- (void)filterButtonTapped:(UIButton *)sender {
    if (self.currentDisplayType == DisplayTypeAll) {
        self.currentDisplayType = DisplayTypeFolderOnly;
        [sender setTitle:@"文件夹" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemBlueColor];
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        self.currentDisplayType = DisplayTypeAll;
        [sender setTitle:@"全部" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        [sender setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    }
    [self updateFunctionButtonStates];
    [self refreshFileList];
}

// 批量修改后缀按钮点击事件
- (void)batchChangeExtensionTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"批量修改后缀"
                                                                   message:@"请输入原后缀和新后缀"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"原后缀 (如: txt)";
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"新后缀 (如: md)";
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];

    UIAlertAction *currentDirAction = [UIAlertAction actionWithTitle:@"仅当前目录"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
        NSString *oldExt = alert.textFields[0].text;
        NSString *newExt = alert.textFields[1].text;
        if (oldExt.length > 0 && newExt.length > 0) {
            NSInteger count = [FileOperateTool batchChangeExtensionInFolder:self.currentDirPath
                                                              oldExtension:oldExt
                                                              newExtension:newExt];
            [self showResultAlert:[NSString stringWithFormat:@"成功修改 %ld 个文件后缀", (long)count]];
            [self refreshFileList];
        }
    }];

    UIAlertAction *recursiveAction = [UIAlertAction actionWithTitle:@"包含子目录"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *oldExt = alert.textFields[0].text;
        NSString *newExt = alert.textFields[1].text;
        if (oldExt.length > 0 && newExt.length > 0) {
            NSInteger count = [FileOperateTool batchChangeExtensionRecursiveInFolder:self.currentDirPath
                                                                     oldExtension:oldExt
                                                                     newExtension:newExt];
            [self showResultAlert:[NSString stringWithFormat:@"成功修改 %ld 个文件后缀", (long)count]];
            [self refreshFileList];
        }
    }];

    [alert addAction:cancelAction];
    [alert addAction:currentDirAction];
    [alert addAction:recursiveAction];

    [self presentViewController:alert animated:YES completion:nil];
}

// 批量删除后缀按钮点击事件
- (void)batchDeleteExtensionTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"批量删除指定后缀文件"
                                                                   message:@"请输入要删除的后缀"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"后缀名 (如: txt)";
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];

    UIAlertAction *currentDirAction = [UIAlertAction actionWithTitle:@"仅当前目录"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
        NSString *ext = alert.textFields[0].text;
        if (ext.length > 0) {
            NSInteger count = [FileOperateTool batchDeleteFilesInFolder:self.currentDirPath
                                                              extension:ext];
            [self showResultAlert:[NSString stringWithFormat:@"成功删除 %ld 个文件", (long)count]];
            [self refreshFileList];
        }
    }];

    UIAlertAction *recursiveAction = [UIAlertAction actionWithTitle:@"包含子目录"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *ext = alert.textFields[0].text;
        if (ext.length > 0) {
            NSInteger count = [FileOperateTool batchDeleteFilesRecursiveInFolder:self.currentDirPath
                                                                       extension:ext];
            [self showResultAlert:[NSString stringWithFormat:@"成功删除 %ld 个文件", (long)count]];
            [self refreshFileList];
        }
    }];

    [alert addAction:cancelAction];
    [alert addAction:currentDirAction];
    [alert addAction:recursiveAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showResultAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"操作结果"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                               style:UIAlertActionStyleDefault
                                             handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// 跳转目录按钮点击事件
- (void)jumpToPathTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"跳转目录"
                                                                   message:@"请输入完整路径"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"完整路径";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];

    UIAlertAction *jumpAction = [UIAlertAction actionWithTitle:@"跳转"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        NSString *path = alert.textFields[0].text;
        if (path.length > 0) {
            BOOL isDir = NO;
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
            if (exists && isDir) {
                self.currentDirPath = path;
                [self refreshFileList];
            } else {
                [self showResultAlert:@"路径无效或不是目录"];
            }
        }
    }];

    [alert addAction:cancelAction];
    [alert addAction:jumpAction];

    [self presentViewController:alert animated:YES completion:nil];
}

// 新建按钮点击事件
- (void)createButtonTapped:(UIBarButtonItem *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"新建文件夹"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self showCreateNameInputWithType:CreateItemTypeFolder];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"新建文件"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self showCreateNameInputWithType:CreateItemTypeFile];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 显示创建名称输入框
- (void)showCreateNameInputWithType:(CreateItemType)type {
    NSString *title = (type == CreateItemTypeFolder) ? @"新建文件夹" : @"新建文件";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入名称";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"创建"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length > 0) {
            [self createItemWithName:name type:type];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 创建文件或文件夹
- (void)createItemWithName:(NSString *)name type:(CreateItemType)type {
    BOOL success = NO;
    if (type == CreateItemTypeFolder) {
        success = [FileOperateTool createFolderWithName:name atPath:self.currentDirPath];
    } else {
        success = [FileOperateTool createFileWithName:name atPath:self.currentDirPath];
    }
    
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
        [self refreshFileList];
    } else {
        [self showAlertWithTitle:@"创建失败" message:@"无法创建文件或文件夹"];
    }
}

// 收藏按钮点击事件
- (void)favoriteButtonTapped:(UIButton *)sender {
    self.isShowFavoriteList = !self.isShowFavoriteList;
    
    if (self.isShowFavoriteList) {
        sender.backgroundColor = [UIColor systemBlueColor];
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.favoriteFileList = [[[FavoriteManager sharedManager] getAllFavorites] mutableCopy];
        // 设置收藏列表中所有文件的 isFavorite 属性为 YES
        for (FileModel *model in self.favoriteFileList) {
            model.isFavorite = YES;
        }
        self.fileList = self.favoriteFileList;
    } else {
        sender.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        [sender setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [self refreshFileList];
    }
    [self.tableView reloadData];
}

// 搜索范围变更事件
- (void)searchScopeChanged:(UISegmentedControl *)sender {
    self.searchCurrentDirectoryOnly = (sender.selectedSegmentIndex == 0);
    // 重新执行搜索
    if (self.searchController.searchBar.text.length > 0) {
        [self updateSearchResultsForSearchController:self.searchController];
    }
}

#pragma mark - UISearchControllerDelegate

// 将要显示搜索控制器时调用
- (void)willPresentSearchController:(UISearchController *)searchController {
    // 显示搜索范围选项卡
    self.navigationItem.rightBarButtonItems = @[self.searchScopeItem];
}

// 搜索控制器消失后调用
- (void)didDismissSearchController:(UISearchController *)searchController {
    // 隐藏搜索范围选项卡
    self.navigationItem.rightBarButtonItems = @[self.closeButton, self.collectionButton];
}

// 长按手势处理，进入批量编辑模式
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gesture locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        if (indexPath) {
            [self enterBatchEditMode];
            
            FileModel *model = nil;
            if (self.searchController.isActive) {
                model = self.searchResults[indexPath.row];
            } else {
                model = self.fileList[indexPath.row];
            }
            model.isSelected = YES;
            if (![self isFileSelected:model]) {
                [self.selectedFileList addObject:model];
            }
            
        }
        [self updateSelectionCountButton];
        [self.tableView reloadData];
    }
}

// 检查文件是否已选中（通过路径判断）
- (BOOL)isFileSelected:(FileModel *)model {
    for (FileModel *selectedModel in self.selectedFileList) {
        if ([selectedModel.filePath isEqualToString:model.filePath]) {
            return YES;
        }
    }
    return NO;
}

// 从选中列表中移除文件（通过路径判断）
- (void)removeFileFromSelection:(FileModel *)model {
    FileModel *toRemove = nil;
    for (FileModel *selectedModel in self.selectedFileList) {
        if ([selectedModel.filePath isEqualToString:model.filePath]) {
            toRemove = selectedModel;
            break;
        }
    }
    if (toRemove) {
        [self.selectedFileList removeObject:toRemove];
    }
}

// 进入批处理模式
- (void)enterBatchEditMode {
    self.isBatchEditing = YES;
    self.navigationItem.rightBarButtonItems = @[self.completeButton, self.selectionCountButton];
    self.bottomToolbar.hidden = NO;
    [self updateSelectionCountButton];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

// 更新选择数量按钮的显示
- (void)updateSelectionCountButton {
    NSString *title = [NSString stringWithFormat:@"%lu 项", (unsigned long)self.selectedFileList.count];
    self.selectionCountButton.title = title;
}

// 退出批量编辑模式
- (void)exitBatchEditMode {
    self.isBatchEditing = NO;
    if (self.searchController.isActive) {
        // 搜索模式下，显示搜索范围选项卡
        self.navigationItem.rightBarButtonItems = @[self.closeButton, self.searchScopeItem];
    } else {
        // 非搜索模式下
        self.navigationItem.rightBarButtonItems = @[self.closeButton, self.collectionButton];
    }
    
    self.bottomToolbar.hidden = YES;
    
    NSArray *currentList = self.searchController.isActive ? self.searchResults : self.fileList;
    for (FileModel *model in currentList) {
        model.isSelected = NO;
    }
    [self.selectedFileList removeAllObjects];
    [self.tableView reloadData];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

// 全选按钮点击事件
- (void)selectAllButtonTapped:(UIButton *)sender {
    NSArray *currentList = self.searchController.isActive ? self.searchResults : self.fileList;
    for (FileModel *model in currentList) {
        model.isSelected = YES;
    }
    self.selectedFileList = [currentList mutableCopy];
    [self updateSelectionCountButton];
    [self.tableView reloadData];
}

// 完成按钮点击事件
- (void)doneButtonTapped:(UIButton *)sender {
    [self exitBatchEditMode];
}

// 全不选按钮点击事件
- (void)deselectAllButtonTapped:(UIButton *)sender {
    NSArray *currentList = self.searchController.isActive ? self.searchResults : self.fileList;
    for (FileModel *model in currentList) {
        model.isSelected = NO;
    }
    [self.selectedFileList removeAllObjects];
    [self updateSelectionCountButton];
    [self.tableView reloadData];
}

// 拷贝按钮点击事件
- (void)copyButtonTapped:(UIButton *)sender {
    if (self.selectedFileList.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要拷贝的文件"];
        [self exitBatchEditMode];
        return;
    }
    
    self.clipboardFileList = [self.selectedFileList mutableCopy];
    self.isCopyOperation = YES;
    
    self.pasteButton.title = @"粘贴";
    self.pasteButton.enabled = YES;
    
    [self exitBatchEditMode];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancelPasteButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[self.pasteButton, cancelButton];
}

// 移动按钮点击事件
- (void)moveButtonTapped:(UIButton *)sender {
    if (self.selectedFileList.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要移动的文件"];
        [self exitBatchEditMode];
        return;
    }
    
    self.clipboardFileList = [self.selectedFileList mutableCopy];
    self.isCopyOperation = NO;
    
    self.pasteButton.title = @"移动";
    self.pasteButton.enabled = YES;
    
    [self exitBatchEditMode];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancelPasteButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[self.pasteButton, cancelButton];
}

- (void)deleteButtonTapped:(UIButton *)sender {
    if (self.selectedFileList.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要删除的文件"];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除"
                                                                   message:[NSString stringWithFormat:@"确定要删除选中的 %lu 个项目吗？", (unsigned long)self.selectedFileList.count]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteSelectedItems];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 删除选中的项目
- (void)deleteSelectedItems {
    NSMutableArray *pathsToDelete = [NSMutableArray array];
    for (FileModel *model in self.selectedFileList) {
        [pathsToDelete addObject:model.filePath];
    }
    
    BOOL allSuccess = YES;
    for (NSString *path in pathsToDelete) {
        if (![FileOperateTool deleteItemAtPath:path]) {
            allSuccess = NO;
        }
    }
    
    if (allSuccess) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
        [self refreshFileList];
    } else {
        [self showAlertWithTitle:@"删除失败" message:@"部分文件删除失败"];
    }
    [self exitBatchEditMode];
}

// 压缩按钮点击事件
- (void)compressButtonTapped:(UIButton *)sender {
    if (self.selectedFileList.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要压缩的文件或文件夹"];
        [self exitBatchEditMode];
        return;
    }
    
    // 确定目标目录
    NSString *destinationDir = nil;
    
    if (self.searchController.isActive && !self.searchCurrentDirectoryOnly) {
        // 多目录搜索模式，使用缓存目录
        destinationDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    } else {
        // 当前目录搜索或非搜索模式，使用当前目录
        destinationDir = self.currentDirPath;
    }
    
    [[FileActionHandler sharedHandler] compressFilesWithInput:self.selectedFileList
                                               destinationDir:destinationDir
                                           fromViewController:self];
    [self exitBatchEditMode];
}

// 显示警告提示框
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Data

// 更新统计信息
- (void)updateStatistics {
    NSInteger folderCount = 0;
    NSInteger fileCount = 0;
    unsigned long long totalSize = 0;

    for (FileModel *model in self.fileList) {
        if (model.itemType == FileItemTypeFolder) {
            folderCount++;
        } else {
            fileCount++;
            totalSize += model.fileSize;
        }
    }

    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
    NSString *sizeStr = [formatter stringFromByteCount:totalSize];

    NSString *statsText = [NSString stringWithFormat:@"📁 %ld 个  📄 %ld 个  💾 %@", (long)folderCount, (long)fileCount, sizeStr];

    BOOL isCurrentDirFavorite = [[FavoriteManager sharedManager] isFavorite:self.currentDirPath];
    NSString *remark = [[RemarkManager sharedManager] getRemarkForFilePath:self.currentDirPath];

    if (isCurrentDirFavorite || remark.length > 0) {
        self.statisticsLabel.textColor = [UIColor systemOrangeColor];
        NSMutableArray *tags = [NSMutableArray array];
        if (isCurrentDirFavorite) {
            [tags addObject:@"⭐ 已收藏"];
        }
        if (remark.length > 0) {
            [tags addObject:[NSString stringWithFormat:@"📝 %@", remark]];
        }
        statsText = [statsText stringByAppendingFormat:@"  %@", [tags componentsJoinedByString:@"  "]];
    } else {
        self.statisticsLabel.textColor = [UIColor secondaryLabelColor];
    }

    self.statisticsLabel.text = statsText;
}

// 下拉刷新处理
- (void)handleRefresh:(UIRefreshControl *)refreshControl {
    [self refreshFileList];
    [refreshControl endRefreshing];
}

// 刷新文件列表
- (void)refreshFileList {
    if (self.isShowFavoriteList) {
        self.favoriteFileList = [[[FavoriteManager sharedManager] getAllFavorites] mutableCopy];
        self.fileList = self.favoriteFileList;
    } else {
        NSArray *models = [SandboxTool getFirstLevelFileModelsWithDirPath:self.currentDirPath displayType:self.currentDisplayType];
        self.fileList = [models mutableCopy];
        
        for (FileModel *model in self.fileList) {
            model.isFavorite = [[FavoriteManager sharedManager] isFavorite:model.filePath];
        }
    }
    
    [self sortFileList];
    [self.pathButton setTitle:self.currentDirPath forState:UIControlStateNormal];
    [self updateStatistics];
    [self.tableView reloadData];
    [self updateEmptyView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        return self.searchResults.count;
    }
    return self.fileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    FileModel *model = nil;
    if (self.searchController.isActive) {
        model = self.searchResults[indexPath.row];
    } else {
        model = self.fileList[indexPath.row];
    }
    // 通过路径判断是否已选中，避免对象指针不同导致的判断失败
    BOOL isSelected = NO;
    for (FileModel *selectedModel in self.selectedFileList) {
        if ([selectedModel.filePath isEqualToString:model.filePath]) {
            isSelected = YES;
            break;
        }
    }
    model.isSelected = isSelected;
    [cell configWithFileModel:model];
    cell.isBatchEditing = self.isBatchEditing;
    cell.cellDelegate = self;
    return cell;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    if (searchText.length == 0) {
        [self.searchResults removeAllObjects];
        [self.tableView reloadData];
        [self updateEmptyView];
        return;
    }
    
    [self.searchResults removeAllObjects];
    
    if (self.searchCurrentDirectoryOnly) {
        // 只搜索当前目录（不包含子文件夹）
        [self searchFilesInDirectory:self.currentDirPath withKeyword:searchText recursive:NO];
    } else {
        // 从当前目录开始搜索（包括子文件夹）
        [self searchFilesInDirectory:self.currentDirPath withKeyword:searchText recursive:YES];
    }
    [self.tableView reloadData];
    [self updateEmptyView];
}

// 在指定目录中搜索文件
- (void)searchFilesInDirectory:(NSString *)directoryPath withKeyword:(NSString *)keyword recursive:(BOOL)recursive {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    
    if (error) {
        return;
    }
    
    for (NSString *fileName in contents) {
        if ([fileName.lowercaseString containsString:keyword.lowercaseString]) {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            FileModel *model = [FileModel modelWithFilePath:filePath];
            model.isFavorite = [[FavoriteManager sharedManager] isFavorite:model.filePath];
            [self.searchResults addObject:model];
        }
        
        if (recursive) {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            BOOL isDirectory = NO;
            [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
            
            if (isDirectory) {
                [self searchFilesInDirectory:filePath withKeyword:keyword recursive:recursive];
            }
        }
    }
}

#pragma mark - UITableViewDelegate

// 设置单元格高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

// 单元格被点击时调用
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"点击了：%ld",indexPath.row);
    FileModel *model = nil;
    if (self.searchController.isActive) {
        model = self.searchResults[indexPath.row];
    } else {
        model = self.fileList[indexPath.row];
    }
    
    if (self.isBatchEditing) {
        model.isSelected = !model.isSelected;
        
        if (model.isSelected) {
            if (![self isFileSelected:model]) {
                [self.selectedFileList addObject:model];
            }
        } else {
            [self removeFileFromSelection:model];
        }
        
        [self updateSelectionCountButton];
        [self.tableView reloadData];
        return;
    }
    
    if (model.itemType == FileItemTypeFolder) {
        self.searchController.active = NO;
        
        if (self.isShowFavoriteList) {
            self.isShowFavoriteList = NO;
            self.favoriteButton.tintColor = [UIColor labelColor];
        }
        
        self.currentDirPath = model.filePath;
        [self refreshFileList];
        
        if ([self.delegate respondsToSelector:@selector(fileManagerDidEnterDirectory:)]) {
            [self.delegate fileManagerDidEnterDirectory:model.filePath];
        }
    } else {
        self.searchController.active = NO;
        if ([self.delegate respondsToSelector:@selector(fileManagerDidClickItem:itemName:currentDirPath:)]) {
            [self.delegate fileManagerDidClickItem:model itemName:model.fileName currentDirPath:self.currentDirPath];
        }

        NSString *extension = [model.filePath pathExtension].lowercaseString;
        if ([extension isEqualToString:@"plist"] || [extension isEqualToString:@"xml"]) {
            PlistEditorViewController *editorVC = [[PlistEditorViewController alloc] init];
//            PlistEditorVC *editorVC = [[PlistEditorVC alloc] init];
            editorVC.fileModel = model;
            editorVC.filePath = model.filePath;
            [self.navigationController pushViewController:editorVC animated:YES];
            return;
        }

        NSMutableArray *previewList = [NSMutableArray array];
        NSInteger selectedIndex = 0;
        for (NSInteger i = 0; i < self.fileList.count; i++) {
            FileModel *m = self.fileList[i];
            if (m.itemType != FileItemTypeFolder) {
                [previewList addObject:m];
                if (i == (self.searchController.isActive ? [self.searchResults indexOfObject:model] : indexPath.row)) {
                    selectedIndex = previewList.count - 1;
                }
            }
        }

        if (previewList.count > 0) {
            FilePreviewViewController *previewVC = [[FilePreviewViewController alloc] init];
            previewVC.fileList = previewList;
            previewVC.currentIndex = selectedIndex;
            previewVC.fromActionButton = NO;
            previewVC.currentDirPath = self.currentDirPath;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:previewVC];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileModel *model = nil;
    if (self.searchController.isActive) {
        model = self.searchResults[indexPath.row];
    } else {
        model = self.fileList[indexPath.row];
    }
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self confirmDeleteItem:model];
        completionHandler(YES);
    }];
    
    UIContextualAction *renameAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                               title:@"重命名"
                                                                             handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self showRenameAlertForItem:model];
        completionHandler(YES);
    }];
    
    renameAction.backgroundColor = [UIColor systemBlueColor];
    
    NSString *favoriteTitle = model.isFavorite ? @"取消收藏" : @"收藏";
    UIContextualAction *favoriteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                                 title:favoriteTitle
                                                                               handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self toggleFavoriteForItem:model];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        completionHandler(YES);
    }];
    
    favoriteAction.backgroundColor = [UIColor systemOrangeColor];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, renameAction, favoriteAction]];
}

// 确认删除项目
- (void)confirmDeleteItem:(FileModel *)model {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除"
                                                                   message:[NSString stringWithFormat:@"确定要删除 \"%@\" 吗？", model.fileName]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if ([FileOperateTool deleteItemAtPath:model.filePath]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
            [self refreshFileList];
        } else {
            [self showAlertWithTitle:@"删除失败" message:@"无法删除文件"];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 显示重命名提示框
- (void)showRenameAlertForItem:(FileModel *)model {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = model.fileName;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newName = alert.textFields.firstObject.text;
        if (newName.length > 0 && ![newName isEqualToString:model.fileName]) {
            if ([FileOperateTool renameItemAtPath:model.filePath newName:newName]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
                [self refreshFileList];
            } else {
                [self showAlertWithTitle:@"重命名失败" message:@"无法重命名文件"];
            }
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 切换收藏状态
- (void)toggleFavoriteForItem:(FileModel *)model {
    if (model.isFavorite) {
        // ======================
        // 取消收藏：弹出确认框
        // ======================
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"取消收藏" message:@"确定要取消收藏该文件吗？" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            // 执行取消收藏
            [[FavoriteManager sharedManager] removeFavorite:model];
            
            // 刷新逻辑（你原来的代码）
            if (self.isShowFavoriteList) {
                self.favoriteFileList = [[[FavoriteManager sharedManager] getAllFavorites] mutableCopy];
                for (FileModel *m in self.favoriteFileList) {
                    m.isFavorite = YES;
                }
                self.fileList = self.favoriteFileList;
                [self.tableView reloadData];
                return;
            }
            [self.tableView reloadData];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // ======================
        // 收藏：弹出带备注的输入框
        // ======================
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加收藏" message:@"请输入备注" preferredStyle:UIAlertControllerStyleAlert];
        
        // 添加输入框，默认显示当前 remark
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请输入备注";
            textField.text = model.remark; // 默认值
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 获取输入的备注
            UITextField *textField = alert.textFields.firstObject;
            NSString *remark = textField.text ?: @"";
            
            // 赋值给 model
            model.remark = remark;
            
            // 保存备注到本地
            [[RemarkManager sharedManager] saveRemark:remark forFilePath:model.filePath];
            
            // 执行收藏
            [[FavoriteManager sharedManager] addFavorite:model];
            
            // 刷新逻辑（你原来的代码）
            if (self.isShowFavoriteList) {
                self.favoriteFileList = [[[FavoriteManager sharedManager] getAllFavorites] mutableCopy];
                for (FileModel *m in self.favoriteFileList) {
                    m.isFavorite = YES;
                }
                self.fileList = self.favoriteFileList;
                [self.tableView reloadData];
                return;
            }
            [self.tableView reloadData];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - FileListCellDelegate

- (void)fileListCell:(FileListCell *)cell didSelectCheckBox:(BOOL)selected forFileModel:(FileModel *)model {
    if (selected) {
        if (![self isFileSelected:model]) {
            [self.selectedFileList addObject:model];
        }
    } else {
        [self removeFileFromSelection:model];
    }
    [self updateSelectionCountButton];
    [self.tableView reloadData];
}

// 文件列表单元格点击了操作按钮
- (void)fileListCell:(FileListCell *)cell didTapActionButtonForFileModel:(FileModel *)model {
    if (model.itemType == FileItemTypeFolder) {
        [[FileActionHandler sharedHandler] showActionSheetForModel:model
                                                fromViewController:self
                                                          delegate:nil];
    } else {
        NSMutableArray *previewList = [NSMutableArray array];
        NSInteger selectedIndex = 0;
        for (NSInteger i = 0; i < self.fileList.count; i++) {
            FileModel *m = self.fileList[i];
            if (m.itemType != FileItemTypeFolder) {
                [previewList addObject:m];
                if ([m.filePath isEqualToString:model.filePath]) {
                    selectedIndex = previewList.count - 1;
                }
            }
        }

        if (previewList.count > 0) {
            FilePreviewViewController *previewVC = [[FilePreviewViewController alloc] init];
            previewVC.fileList = previewList;
            previewVC.currentIndex = selectedIndex;
            previewVC.fromActionButton = YES;
            previewVC.currentDirPath = self.currentDirPath;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:previewVC];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
}

#pragma mark - FileManagerDelegate

// 点击文件项时调用
- (void)fileManagerDidClickItem:(FileModel *)itemModel itemName:(NSString *)itemName currentDirPath:(NSString *)currentDirPath {
    NSLog(@"Clicked item: %@ at path: %@", itemName, currentDirPath);
}

// 文件列表变更时调用
- (void)fileManagerDidChangeFileList {
    [self refreshFileList];
}

// 进入目录时调用
- (void)fileManagerDidEnterDirectory:(NSString *)directoryPath {
    NSLog(@"Entered directory: %@", directoryPath);
}

// 导航到指定目录
- (void)navigateToDirectory:(NSString *)directoryPath {
    // 如果当前在批量编辑模式，退出
    if (self.isBatchEditing) {
        [self exitBatchEditMode];
    }
    
    // 取消收藏列表显示
    self.isShowFavoriteList = NO;
    
    // 更新当前目录路径
    self.currentDirPath = directoryPath;
    
    // 刷新文件列表
    [self refreshFileList];
    
    // 延迟关闭搜索控制器，避免在搜索栏可见时移除
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.searchController.isActive) {
            self.searchController.active = NO;
        }
    });
}

#pragma mark - Notifications

// 收藏状态变更通知处理
- (void)handleFavoriteChanged:(NSNotification *)notification {
    for (FileModel *model in self.fileList) {
        model.isFavorite = [[FavoriteManager sharedManager] isFavorite:model.filePath];
    }
    [self.tableView reloadData];
}

// 文件列表变更通知处理
- (void)handleFileListChanged:(NSNotification *)notification {
    [self refreshFileList];
}

// 排序文件列表
- (void)sortFileList {
    if (self.fileList.count == 0) return;
    
    switch (self.currentSortType) {
        case 0: { // 按文件名排序
            [self.fileList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                // 文件夹优先
                if (obj1.itemType == FileItemTypeFolder && obj2.itemType == FileItemTypeFile) return NSOrderedAscending;
                if (obj1.itemType == FileItemTypeFile && obj2.itemType == FileItemTypeFolder) return NSOrderedDescending;
                NSComparisonResult result = [obj1.fileName compare:obj2.fileName options:NSCaseInsensitiveSearch];
                if (self.isSortAscending) {
                    return result;
                } else {
                    if (result == NSOrderedAscending) return NSOrderedDescending;
                    if (result == NSOrderedDescending) return NSOrderedAscending;
                    return result;
                }
            }];
            break;
        }
            
        case 1: { // 按类型排序
            [self.fileList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                // 文件夹优先
                if (obj1.itemType == FileItemTypeFolder && obj2.itemType == FileItemTypeFile) return NSOrderedAscending;
                if (obj1.itemType == FileItemTypeFile && obj2.itemType == FileItemTypeFolder) return NSOrderedDescending;
                
                NSString *ext1 = [obj1.filePath pathExtension].lowercaseString;
                NSString *ext2 = [obj2.filePath pathExtension].lowercaseString;
                NSComparisonResult result = [ext1 compare:ext2 options:NSCaseInsensitiveSearch];
                if (self.isSortAscending) {
                    return result;
                } else {
                    if (result == NSOrderedAscending) return NSOrderedDescending;
                    if (result == NSOrderedDescending) return NSOrderedAscending;
                    return result;
                }
            }];
            break;
        }
            
        case 2: { // 按日期排序（修改日期）
            [self.fileList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                // 文件夹优先
                if (obj1.itemType == FileItemTypeFolder && obj2.itemType == FileItemTypeFile) return NSOrderedAscending;
                if (obj1.itemType == FileItemTypeFile && obj2.itemType == FileItemTypeFolder) return NSOrderedDescending;
                
                NSComparisonResult result = [obj1.modificationDate compare:obj2.modificationDate];
                if (self.isSortAscending) {
                    return result;
                } else {
                    if (result == NSOrderedAscending) return NSOrderedDescending;
                    if (result == NSOrderedDescending) return NSOrderedAscending;
                    return result;
                }
            }];
            break;
        }
            
        case 3: { // 按大小排序
            [self.fileList sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
                // 文件夹优先
                if (obj1.itemType == FileItemTypeFolder && obj2.itemType == FileItemTypeFile) return NSOrderedAscending;
                if (obj1.itemType == FileItemTypeFile && obj2.itemType == FileItemTypeFolder) return NSOrderedDescending;
                
                NSComparisonResult result;
                if (obj1.fileSize < obj2.fileSize) {
                    result = NSOrderedAscending;
                } else if (obj1.fileSize > obj2.fileSize) {
                    result = NSOrderedDescending;
                } else {
                    result = NSOrderedSame;
                }
                if (self.isSortAscending) {
                    return result;
                } else {
                    if (result == NSOrderedAscending) return NSOrderedDescending;
                    if (result == NSOrderedDescending) return NSOrderedAscending;
                    return result;
                }
            }];
            break;
        }
            
        default:
            break;
    }
    
    [self.tableView reloadData];
}

// 销毁时移除通知观察
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
