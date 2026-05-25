//
//  FileListViewController.m
//  SandboxFileManager
//
//  文件列表视图控制器 - 父容器
//  使用 UIPageViewController 管理多个 FileListTableViewController 页面
//

#import "FileListViewController.h"
#import "FileListTableViewController.h"
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
#import "FileSelectionManager.h"
#import "RootViewController.h"
#import "HistoryManager.h"
#import "RecycleBinManager.h"
#import "FileSelectionViewController.h"
#import "WindowSwitcherViewController.h"
#import "WindowManager.h"
#import "FileOperationToolbar.h"

@interface FileListViewController () <UISearchResultsUpdating, UISearchBarDelegate, WindowSwitcherViewControllerDelegate, FileOperationToolbarDelegate>
/// 返回按钮
@property (nonatomic, strong) UIBarButtonItem *backButton;
/// 进入选择模式
@property (nonatomic, strong) UIBarButtonItem *selectionModeItem;
/// 选择统计按钮
@property (nonatomic, strong) UIBarButtonItem *selectionCountButton;
/// 全选按钮
@property (nonatomic, strong) UIBarButtonItem *selectAllButton;
/// 全取消
@property (nonatomic, strong) UIBarButtonItem *deselectAllButton;


@property (nonatomic, copy) NSString *initialPath;
@property (nonatomic, assign) SandboxDirectoryType initialSandboxDir;
@property (nonatomic, copy) NSString *initialSubPath;
@property (nonatomic, assign) BOOL hasCustomInitialPath;
@property (nonatomic, strong) FileOperationToolbar *editToolbar;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setupUI];
    [self setupNotifications];
    [self refreshFileList];
    
    // 延迟一点时间，等视图完全加载后再截图
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self takeWindowSnapshot];
    });
}

#pragma mark - 初始化数据

- (void)setupData {
    _currentDisplayType = DisplayTypeAll;
    _isBatchEditing = NO;
    _isShowFavoriteList = NO;
    _searchCurrentDirectoryOnly = YES;
    _currentSortType = SortTypeName;
    _isSortAscending = YES;
    _fileList = [NSMutableArray array];
    _favoriteFileList = [NSMutableArray array];
    _clipboardFileList = nil;
    _isCopyOperation = YES;
    _searchResults = [NSMutableArray array];
    _windowIndex = 0;
    _currentWindowIndex = 0;
    _windowSwitcherLastOffsetX = 0;
    _tableViewControllers = [NSMutableDictionary dictionary];
    _windowControllers = [NSMutableArray array];
    _currentPageIdentifier = nil;
    
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

#pragma mark - 设置界面UI

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
    [self setupTableContainerView];
    [self setupSwipeGesture];
    [self setupLeftActionPanel];
}

- (void)setupNavigationBar {
    UIImage *backIcon = [UIImage systemImageNamed:@"chevron.backward"];
    self.backButton = [[UIBarButtonItem alloc] initWithImage:backIcon
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(backButtonTapped:)];
    
    self.createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                    target:self
                                                                    action:@selector(createButtonTapped:)];
    
    
    self.selectionModeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(enterBatchEditMode)];
    
    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                   target:self
                                                                   action:@selector(closeButtonTapped:)];
    
    self.completeButton = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(exitBatchEditMode)];
    
    self.selectAllButton = [[UIBarButtonItem alloc] initWithTitle:@"全选"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(selectAllButtonTapped:)];
    
    self.deselectAllButton = [[UIBarButtonItem alloc] initWithTitle:@"全取消"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(deselectAllButtonTapped:)];
    
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
                                                              target:self
                                                              action:@selector(openFileSelectionViewController)];
    
    [self setupSearchController];
    
    self.navigationItem.leftBarButtonItems = @[self.backButton, self.createButton];
    self.navigationItem.rightBarButtonItems = @[self.selectionModeItem, self.collectionButton];
}

- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索文件...";
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.definesPresentationContext = YES;
    
    // 设置搜索范围选项卡
    self.searchController.searchBar.scopeButtonTitles = @[@"当前", @"全部"];
    self.searchController.searchBar.delegate = self;
    
    // 默认显示搜索框
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)setupPathLabel {
    self.pathButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pathButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.pathButton.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.pathButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.pathButton.titleLabel.numberOfLines = 1;
    self.pathButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
    [self.pathButton addTarget:self action:@selector(pathLabelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pathButton];
    
    self.statisticsLabel = [[UILabel alloc] init];
    self.statisticsLabel.font = [UIFont systemFontOfSize:11];
    self.statisticsLabel.textColor = [UIColor secondaryLabelColor];
    self.statisticsLabel.textAlignment = NSTextAlignmentCenter;
    self.statisticsLabel.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    [self.view addSubview:self.statisticsLabel];
    
    self.bottomButtonScrollView = [[UIScrollView alloc] init];
    self.bottomButtonScrollView.showsHorizontalScrollIndicator = NO;
    self.bottomButtonScrollView.showsVerticalScrollIndicator = NO;
    self.bottomButtonScrollView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.bottomButtonScrollView];
    
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

- (void)setupTableContainerView {
    // 创建固定的表格容器视图
    self.tableContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableContainerView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.tableContainerView];
    
    // 创建初始窗口
    self.currentVC = [[FileListTableViewController alloc] initWithIdentifier:@"default"];
    self.currentVC.currentDirPath = self.currentDirPath;
    self.currentVC.fileListViewController = self;
    [self registerTableViewController:self.currentVC withIdentifier:@"default"];
    
    [self.pathButton setTitle:self.currentDirPath forState:UIControlStateNormal];
}

- (void)setupSwipeGesture {
    // 使用 UIPanGestureRecognizer 替代 UISwipeGestureRecognizer，实现跟随手指滑动
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
    
    // 创建上一级目录截图显示视图 - 尺寸与 tableContainerView 相同
    self.parentSnapshotView = [[UIImageView alloc] init];
    self.parentSnapshotView.contentMode = UIViewContentModeScaleToFill;
    self.parentSnapshotView.clipsToBounds = YES;
    self.parentSnapshotView.hidden = YES;
    [self.view insertSubview:self.parentSnapshotView belowSubview:self.tableContainerView];
}

- (void)setupLeftActionPanel {
    self.leftActionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CGFloat width = 40.0f;
    self.leftActionButton.frame = CGRectMake(0, 0, width, width);
    self.leftActionButton.layer.cornerRadius = width/2;
    self.leftActionButton.backgroundColor = [UIColor systemBlueColor];
    self.leftActionButton.tintColor = [UIColor whiteColor];
    
    UIImage *icon = [UIImage systemImageNamed:@"ellipsis" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightBold]];
    [self.leftActionButton setImage:icon forState:UIControlStateNormal];
    
    self.leftActionButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.leftActionButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.leftActionButton.layer.shadowOpacity = 0.3;
    self.leftActionButton.layer.shadowRadius = 6;
    
    [self.leftActionButton addTarget:self action:@selector(leftActionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.leftActionButton.hidden = YES;
    self.leftActionButton.alpha = 0;
    [self.view addSubview:self.leftActionButton];
    
    _showingLeftActionButton = NO;
}

- (void)leftActionButtonTapped:(UIButton *)sender {
    NSInteger selectedCount = [[FileSelectionManager sharedManager] selectedCount];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请选择"
                                                                   message:[NSString stringWithFormat:@"共选择（%ld）个文件",selectedCount]
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    // 移动拷贝
    if(self.isCopyOperation){
        [alert addAction:[UIAlertAction actionWithTitle:@"粘贴到此处" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectAction:FileOperationActionCopy];
        }]];
    }else{
        [alert addAction:[UIAlertAction actionWithTitle:@"移动到此处" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectAction:FileOperationActionMove];
        }]];
    }
    
    
    // 压缩
    [alert addAction:[UIAlertAction actionWithTitle:@"压缩" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self didSelectAction:FileOperationActionCompress];
    }]];
    
    // 收藏
    [alert addAction:[UIAlertAction actionWithTitle:@"收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self didSelectAction:FileOperationActionFavorite];
    }]];
    
    // 取消收藏
    [alert addAction:[UIAlertAction actionWithTitle:@"取消收藏" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self didSelectAction:FileOperationActionRemoveFavorite];
    }]];
    
    
    // 删除
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        [self didSelectAction:FileOperationActionDelete];
    }]];
    
    
    // 取消
    [alert addAction:[UIAlertAction actionWithTitle:@"清空选择数据" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[FileSelectionManager sharedManager] clearAllSelections];
        [self cancelPasteOperation];
        [self showLeftActionPanel];
    }]];
    
    // 取消
    [alert addAction:[UIAlertAction actionWithTitle:@"取消操作" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self cancelPasteOperation];
    }]];
    
    // iPad 需要设置 popover
    alert.popoverPresentationController.sourceView = sender;
    alert.popoverPresentationController.sourceRect = sender.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)cancelPasteOperation {
    self.clipboardFileList = nil;
    self.pasteButton.enabled = NO;
    self.pasteButton.title = @"粘贴";
    NSMutableArray *items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items removeObject:self.pasteButton];
    self.navigationItem.rightBarButtonItems = @[self.selectionModeItem, self.collectionButton];
    
}


- (void)showLeftActionPanel {
    
    NSInteger selectedCount = [[FileSelectionManager sharedManager] selectedCount];
    _showingLeftActionButton = selectedCount > 0;
    self.leftActionButton.hidden = selectedCount == 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.leftActionButton.alpha = selectedCount > 0;
    }];
}


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

#pragma mark - 布局

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat safeTop = self.view.safeAreaInsets.top;
    CGFloat sortButtonHeight = 26;
    CGFloat statisticsHeight = 20;
    CGFloat pathHeight = 26;
    CGFloat toolbarHeight = 60; // 自定义工具栏
    CGFloat bottomSafeHeight = self.view.safeAreaInsets.bottom;
    CGFloat horizontalPadding = 0;
    
    // 检查是否在 RootViewController 中
    BOOL isInRootVC = NO;
    UIViewController *rootVC = self.navigationController.parentViewController;
    if ([rootVC isKindOfClass:[RootViewController class]]) {
        isInRootVC = YES;
    }
    
    self.bottomButtonScrollView.frame = CGRectMake(0, safeTop, self.view.bounds.size.width, sortButtonHeight);
    [self relayoutScrollViewButtons];
    
    self.statisticsLabel.frame = CGRectMake(0,
                                            self.view.bounds.size.height - statisticsHeight - pathHeight - bottomSafeHeight,
                                            self.view.bounds.size.width, statisticsHeight);
    
    self.pathButton.frame = CGRectMake(horizontalPadding,
                                       self.view.bounds.size.height - pathHeight - bottomSafeHeight,
                                       self.view.bounds.size.width - horizontalPadding * 2, pathHeight);
    
    CGFloat bottomOffset = bottomSafeHeight;
    if (self.isBatchEditing) {
        if (isInRootVC) {
            bottomOffset += 30; // RootViewController 中只需要一点空间
        } else {
            bottomOffset += toolbarHeight; // 自定义工具栏
        }
    }
    self.tableContainerView.frame = CGRectMake(0, safeTop + sortButtonHeight,
                                               self.view.bounds.size.width,
                                               self.view.bounds.size.height - safeTop - sortButtonHeight - statisticsHeight - pathHeight - bottomOffset);
    
    // 布局左侧操作面板
    [self layoutLeftActionPanel];
}

- (void)layoutLeftActionPanel {
    CGFloat buttonSize = 40;
    CGFloat buttonX = 10;
//    CGFloat safeTop = self.view.safeAreaInsets.top;
//    CGFloat sortButtonHeight = 26;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat pathHeight = 26;
    CGFloat statisticsHeight = 20;
    CGFloat buttonY = self.view.bounds.size.height - safeBottom - pathHeight - statisticsHeight - buttonSize - 20;
    
    self.leftActionButton.frame = CGRectMake(buttonX, buttonY, buttonSize, buttonSize);
}

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

#pragma mark - 页面管理方法实现

- (void)registerTableViewController:(FileListTableViewController *)viewController withIdentifier:(NSString *)identifier {
    if (!viewController || !identifier) {
        return;
    }
    
    FileListTableViewController *existingVC = _tableViewControllers[identifier];
    if (existingVC) {
        [self removePageWithIdentifier:identifier];
    }
    
    viewController.view.hidden = YES;
    _tableViewControllers[identifier] = viewController;
    [_windowControllers addObject:viewController];
    
    if (!_currentPageIdentifier) {
        [self switchToPageWithIdentifier:identifier];
    }
    
    [self.view setNeedsLayout];
}

- (void)switchToPageWithIdentifier:(NSString *)identifier {
    if (!identifier || !_tableViewControllers[identifier]) {
        return;
    }
    
    if (_currentPageIdentifier) {
        UIViewController *oldVC = _tableViewControllers[_currentPageIdentifier];
        oldVC.view.hidden = YES;
        [oldVC.view removeFromSuperview];
    }
    
    _currentPageIdentifier = identifier;
    FileListTableViewController *newVC = _tableViewControllers[identifier];
    newVC.view.hidden = NO;
    newVC.view.frame = self.tableContainerView.bounds;
    newVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableContainerView addSubview:newVC.view];
    
    // 更新当前窗口索引
    for (NSInteger i = 0; i < _windowControllers.count; i++) {
        if ([_windowControllers[i].identifier isEqualToString:identifier]) {
            _currentWindowIndex = i;
            break;
        }
    }
    
    self.currentVC = newVC;
    
    // 更新路径显示
    [self.pathButton setTitle:newVC.currentDirPath forState:UIControlStateNormal];
    
    [self.view setNeedsLayout];
}

- (void)removePageWithIdentifier:(NSString *)identifier {
    if (!identifier || !_tableViewControllers[identifier]) {
        return;
    }
    
    FileListTableViewController *vc = _tableViewControllers[identifier];
    [vc.view removeFromSuperview];
    
    // 从窗口数组中移除
    [_windowControllers removeObject:vc];
    
    if ([_currentPageIdentifier isEqualToString:identifier]) {
        _currentPageIdentifier = nil;
        _currentWindowIndex = 0;
    }
    
    [_tableViewControllers removeObjectForKey:identifier];
}

- (FileListTableViewController *)currentTableViewController {
    if (_currentPageIdentifier) {
        return _tableViewControllers[_currentPageIdentifier];
    }
    // 如果没有当前页面标识符，返回当前的VC（这是在setupTableContainerView中设置的）
    return self.currentVC;
}

- (FileListTableViewController *)tableViewControllerWithIdentifier:(NSString *)identifier {
    return _tableViewControllers[identifier];
}

- (void)windowSwitcherDidClose:(WindowSwitcherViewController *)switcher {
    // 可以在这里做一些清理工作
}

#pragma mark - Actions

- (void)openCollectionListViewController {
    FavoriteListViewController *favoriteListVC = [[FavoriteListViewController alloc] init];
    favoriteListVC.sourceFileListVC = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:favoriteListVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)openFileSelectionViewController {
    FileSelectionViewController *favoriteListVC = [[FileSelectionViewController alloc] init];
    favoriteListVC.fileListViewController = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:favoriteListVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)navigateToPath:(NSString *)path {
    self.currentDirPath = path;
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (currentVC) {
        currentVC.currentDirPath = path;
        [currentVC refreshFileList];
    }
    [self refreshFileList];
}

- (void)navigateToDirectory:(NSString *)directoryPath {
    self.currentDirPath = directoryPath;
    NSLog(@"navigateToDirectory：%@",directoryPath);
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (currentVC) {
        currentVC.currentDirPath = directoryPath;
        [currentVC refreshFileList];
    }
    [self refreshFileList];
    
    // 延迟一点时间，等视图更新后再截图
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self takeWindowSnapshot];
    });
}

- (void)refreshFileList {
    NSLog(@"refreshFileList");
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (currentVC) {
        [currentVC refreshFileList];
    }
    [self updateStatistics];
}

- (void)takeWindowSnapshot {
    // 确保 view 已经加载并且在窗口层级中
    if (self.view.window == nil) {
        return;
    }
    
    // 获取当前表格控制器
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (!currentVC || !currentVC.tableView) {
        return;
    }
    
    // 只截取表格视图（UITableView）
    UITableView *tableView = currentVC.tableView;
    
    // 截图
    UIGraphicsBeginImageContextWithOptions(tableView.bounds.size, NO, 0.0);
    [tableView drawViewHierarchyInRect:tableView.bounds afterScreenUpdates:YES];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 保存截图
    if (snapshot) {
        self.windowSnapshot = snapshot;
        // 同步更新 WindowManager 中当前窗口的截图
        [[WindowManager sharedManager] saveWindowState];
    }
}

- (void)backButtonTapped:(UIBarButtonItem *)sender {
    FileListTableViewController *currentVC = [self currentTableViewController];
    NSString *parentPath = [currentVC.currentDirPath stringByDeletingLastPathComponent];
    NSLog(@"parentPath:%@",parentPath);
    // 获取 Home 目录作为沙盒根目录
    NSString *homePath = [SandboxTool getSandboxDirectoryPath:SandboxDirectoryTypeHome];
    NSLog(@"homePath:%@",homePath);
    // 如果当前目录就是 Home 目录，不允许继续返回
    if ([currentVC.currentDirPath isEqualToString:homePath]) {
        return;
    }
    
    [self navigateToDirectory:parentPath];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDirectoryChanged
                                                        object:nil
                                                      userInfo:@{@"path": self.currentDirPath}];
}

- (void)closeButtonTapped:(UIBarButtonItem *)sender {
    NSArray *selectedFiles = [[FileSelectionManager sharedManager] selectedFiles];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDirectoryChanged
                                                        object:self
                                                      userInfo:@{
                                                          @"path": self.currentDirPath,
                                                          @"selectedFiles": selectedFiles,
                                                          @"controller": self
                                                      }];
    
    if ([self.delegate respondsToSelector:@selector(fileManagerDidCloseWithSelectedFiles:currentDirPath:controller:)]) {
        [self.delegate fileManagerDidCloseWithSelectedFiles:selectedFiles
                                             currentDirPath:self.currentDirPath
                                                 controller:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pathLabelTapped {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.currentDirPath;
    [self showAlertWithTitle:@"提示" message:@"路径已复制到剪贴板"];
}

- (void)pasteButtonTappedFromNav:(UIBarButtonItem *)sender {
    if (self.clipboardFileList.count == 0) {
        return;
    }

    __weak typeof(self) weakSelf = self;

    if (self.isCopyOperation) {
        [[FileActionHandler sharedHandler] copyFiles:self.clipboardFileList
                                        toDirectory:self.currentDirPath
                                   fromViewController:self
                                       conflictHandler:^(FileModel *model, NSString *conflictingPath, NSString *suggestedName, void (^completion)(FileConflictOption, NSString * _Nullable)) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf showConflictAlertWithModel:model conflictingPath:conflictingPath suggestedName:suggestedName completion:completion];
            }
        } completion:^(NSInteger successCount, NSArray<NSString *> *successFilePaths) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf finishPasteOperationWithSuccessCount:successCount successFilePaths:successFilePaths];
            }
        }];
    } else {
        [[FileActionHandler sharedHandler] moveFiles:self.clipboardFileList
                                        toDirectory:self.currentDirPath
                                   fromViewController:self
                                       conflictHandler:^(FileModel *model, NSString *conflictingPath, NSString *suggestedName, void (^completion)(FileConflictOption, NSString * _Nullable)) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf showConflictAlertWithModel:model conflictingPath:conflictingPath suggestedName:suggestedName completion:completion];
            }
        } completion:^(NSInteger successCount, NSArray<NSString *> *successFilePaths) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf finishPasteOperationWithSuccessCount:successCount successFilePaths:successFilePaths];
            }
        }];
    }
}

- (void)showConflictAlertWithModel:(FileModel *)model
                   conflictingPath:(NSString *)conflictingPath
                      suggestedName:(NSString *)suggestedName
                        completion:(void(^)(FileConflictOption option, NSString * _Nullable newFileName))completion {

    NSString *fileName = [conflictingPath lastPathComponent];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"文件已存在"
                                                                   message:[NSString stringWithFormat:@"\"%@\" 已存在", fileName]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completion(FileConflictOptionCancel, nil);
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"覆盖" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        completion(FileConflictOptionOverwrite, nil);
    }]];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = suggestedName;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"重命名" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        NSString *newFileName = textField.text;
        if (newFileName.length > 0) {
            completion(FileConflictOptionRename, newFileName);
        } else {
            completion(FileConflictOptionCancel, nil);
        }
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)finishPasteOperationWithSuccessCount:(NSInteger)successCount successFilePaths:(NSArray<NSString *> *)successFilePaths {
    NSString *operation = self.isCopyOperation ? @"拷贝" : @"移动";
    [self showAlertWithTitle:[NSString stringWithFormat:@"%@结果", operation]
                     message:[NSString stringWithFormat:@"成功 %@ %ld 个文件", operation, (long)successCount]];

    self.clipboardFileList = nil;
    self.pasteButton.enabled = NO;
    self.pasteButton.title = @"粘贴";
    NSMutableArray *items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items removeObject:self.pasteButton];
    self.navigationItem.rightBarButtonItems = @[self.selectionModeItem,self.collectionButton];
    
    // 设置高亮文件路径（如果有成功的文件，取最后一个）
    if (successFilePaths.count > 0) {
        FileListTableViewController *currentVC = [self currentTableViewController];
        currentVC.highlightedFilePath = successFilePaths.lastObject;
    }
    
    [self refreshFileList];
    
    // 3秒后自动取消高亮
    if (successFilePaths.count > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            FileListTableViewController *currentVC = [self currentTableViewController];
//            if (currentVC.highlightedFilePath) {
//                currentVC.highlightedFilePath = nil;
//                [currentVC.tableView reloadData];
//            }
        });
    }
}

- (void)cancelPasteButtonTapped:(UIBarButtonItem *)sender {
    self.clipboardFileList = nil;
    self.pasteButton.enabled = NO;
    self.pasteButton.title = @"粘贴";
    self.navigationItem.rightBarButtonItems = @[self.selectionModeItem, self.collectionButton];
}

- (void)actionButtonTapped:(UIBarButtonItem *)sender {
   
    
    NSString *title = self.isCopyOperation ? @"粘贴操作" : @"移动操作";
    // 1. 创建弹窗控制器（样式：UIAlertControllerStyleAlert 居中弹窗）
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:[NSString stringWithFormat:@"共%ld个文件\n是否进行次操作",self.clipboardFileList.count]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
   
    // 3. 添加【取消】按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    // 4. 添加【确定】按钮（点击后获取输入框内容）
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:self.isCopyOperation ? @"粘贴到这里" : @"移动到这里"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        if(self.isCopyOperation){
            [self pasteButtonTappedFromNav:self.pasteButton];
        }
        
        
    }];
    [alert addAction:confirmAction];
    
    // 4. 添加【确定】按钮（点击后获取输入框内容）
    UIAlertAction *clearOperation = [UIAlertAction actionWithTitle:@"取消/清空操作"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
        
        [self.clipboardFileList removeAllObjects];
        self.navigationItem.rightBarButtonItems = @[self.selectionModeItem,self.collectionButton];
        
    }];
    [alert addAction:clearOperation];
    
    // 5. 弹出显示
    [self presentViewController:alert animated:YES completion:nil];
}


/// 小工具栏按钮点击
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

- (void)handleSortButtonTap:(UIButton *)sender {
    FileSortType newSortType = sender.tag;
    
    if (self.currentSortType == newSortType) {
        self.isSortAscending = !self.isSortAscending;
    } else {
        self.currentSortType = newSortType;
        self.isSortAscending = YES;
    }
    
    [self updateSortButtonStates];
    [self sortCurrentFileList];
}

- (void)sortCurrentFileList {
    FileListTableViewController *currentVC = [self currentTableViewController];
    
    if (currentVC) {
        [currentVC sortFileList];
        [currentVC reloadData];
    }
}

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
    
    [self relayoutScrollViewButtons];
}

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

/// 切换显示收藏
- (void)favoriteButtonTapped:(UIButton *)sender {
    self.isShowFavoriteList = !self.isShowFavoriteList;
    self.currentVC.isShowFavoriteList = self.isShowFavoriteList;
    
    if (self.isShowFavoriteList) {
        sender.backgroundColor = [UIColor systemBlueColor];
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        
    } else {
        sender.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        [sender setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        
    }
    
    self.currentVC = [self currentTableViewController];
    if (self.currentVC) {
        [self refreshFileList];
        
    }
}

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

#pragma mark - Search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self performSearchWithText:searchController.searchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    // scope 0 = 当前，scope 1 = 全部
    self.searchCurrentDirectoryOnly = (selectedScope == 0);
    [self performSearchWithText:searchBar.text];
}

- (void)performSearchWithText:(NSString *)searchText {
    FileListTableViewController *currentVC = [self currentTableViewController];
    
    if (searchText.length == 0) {
        // 清空搜索
        currentVC.isShowingSearchResults = NO;
        [currentVC.searchResults removeAllObjects];
        [currentVC reloadData];
        return;
    }
    
    // 执行搜索
    currentVC.isShowingSearchResults = YES;
    [currentVC.searchResults removeAllObjects];
    
    NSArray *searchArray = self.searchCurrentDirectoryOnly ? currentVC.fileList : self.fileList;
    
    for (FileModel *model in searchArray) {
        if ([model.fileName localizedCaseInsensitiveContainsString:searchText]) {
            [currentVC.searchResults addObject:model];
        }
    }
    
    [currentVC reloadData];
}

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
                [self navigateToDirectory:path];
            } else {
                [self showResultAlert:@"路径无效或不是目录"];
            }
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:jumpAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

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

// 长按 右滑
- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    // 获取手势状态
    UIGestureRecognizerState state = gesture.state;
    CGPoint translation = [gesture translationInView:self.view];
    
    // 只处理向右滑动
    if (translation.x < 0) {
        return;
    }
    
    // 检查是否可以返回
    NSString *documentsPath = [SandboxTool getSandboxDirectoryPath:SandboxDirectoryTypeDocuments];
    NSString *rootPath = [documentsPath stringByDeletingLastPathComponent];
    if ([self.currentDirPath isEqualToString:rootPath] || self.isShowFavoriteList || self.searchController.isActive) {
        return;
    }
    
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat maxOffset = screenWidth * 0.6; // 最大滑动距离为屏幕宽度的60%
    CGFloat currentOffset = MIN(translation.x, maxOffset);
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            // 手势开始，显示上一级目录截图
            self.isSlidingBack = YES;
            [self loadParentSnapshot];
            self.parentSnapshotView.hidden = NO;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            // 更新滑动位置
            [self updateSlideOffset:currentOffset];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // 手势结束，判断是否触发返回
            [self finishSlideWithOffset:currentOffset];
            break;
        }
        default:
            break;
    }
}

- (void)loadParentSnapshot {
    // 获取上一级目录路径
    NSString *parentPath = [self.currentDirPath stringByDeletingLastPathComponent];
    
    // 设置截图视图尺寸与 tableContainerView 相同
    CGRect frame = self.tableContainerView.frame;
    self.parentSnapshotView.frame = frame;
    
    // 首先尝试从 WindowManager 获取上一级目录的截图
    FileListViewController *parentWindow = nil;
    for (FileListViewController *windowVC in [[WindowManager sharedManager] allWindows]) {
        if ([windowVC.currentDirPath isEqualToString:parentPath]) {
            parentWindow = windowVC;
            break;
        }
    }
    
    if (parentWindow && parentWindow.windowSnapshot) {
        self.parentSnapshotView.image = parentWindow.windowSnapshot;
    } else {
        // 如果没有截图，动态生成上层目录的截图
        UIImage *parentSnapshot = [self generateSnapshotForPath:parentPath];
        if (parentSnapshot) {
            self.parentSnapshotView.image = parentSnapshot;
        } else {
            // 如果无法生成截图，使用默认背景色
            self.parentSnapshotView.image = nil;
            self.parentSnapshotView.backgroundColor = [UIColor systemBackgroundColor];
        }
    }
}

- (UIImage *)generateSnapshotForPath:(NSString *)path {
    // 创建临时表格视图来显示上层目录内容
    UITableView *tempTableView = [[UITableView alloc] initWithFrame:self.tableContainerView.bounds style:UITableViewStylePlain];
    tempTableView.backgroundColor = [UIColor systemBackgroundColor];
    
    // 加载上层目录的文件列表
    NSArray *files = [SandboxTool getFileListAtPath:path displayType:DisplayTypeAll];
    
    // 如果文件列表为空，返回空截图
    if (!files || files.count == 0) {
        UIGraphicsBeginImageContextWithOptions(tempTableView.bounds.size, NO, 0.0);
        [[UIColor systemBackgroundColor] setFill];
        UIRectFill(tempTableView.bounds);
        UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return snapshot;
    }
    
    // 设置表格数据源
    tempTableView.dataSource = self;
    tempTableView.delegate = self;
    [tempTableView registerClass:[FileListCell class] forCellReuseIdentifier:@"TempCell"];
    
    // 临时存储文件列表用于截图
    self.tempSnapshotFiles = [files mutableCopy];
    
    // 强制刷新表格
    [tempTableView reloadData];
    
    // 截图
    UIGraphicsBeginImageContextWithOptions(tempTableView.bounds.size, NO, 0.0);
    [tempTableView drawViewHierarchyInRect:tempTableView.bounds afterScreenUpdates:YES];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 清理临时数据
    self.tempSnapshotFiles = nil;
    
    return snapshot;
}

#pragma mark - UITableViewDataSource (for snapshot)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.tempSnapshotFiles) {
        return self.tempSnapshotFiles.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TempCell" forIndexPath:indexPath];
    
    if (self.tempSnapshotFiles && indexPath.row < self.tempSnapshotFiles.count) {
        FileModel *model = self.tempSnapshotFiles[indexPath.row];
        cell.model = model;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate (for snapshot)

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60; // 与 FileListCell 一致
}

- (void)updateSlideOffset:(CGFloat)offset {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat progress = offset / (screenWidth * 0.6);
    
    // 更新表格容器视图位置（向右滑动）
    self.tableContainerView.transform = CGAffineTransformMakeTranslation(offset, 0);
    
    // 更新上一级截图视图位置（从左侧滑入）
    self.parentSnapshotView.transform = CGAffineTransformMakeTranslation(offset - screenWidth, 0);
    
    // 添加缩放效果
    CGFloat scale = 1.0 - progress * 0.05;
    self.tableContainerView.transform = CGAffineTransformScale(self.tableContainerView.transform, scale, scale);
    
    // 添加透明度变化
    self.tableContainerView.alpha = 1.0 - progress * 0.9;
    
    // 添加阴影效果
    self.tableContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tableContainerView.layer.shadowOffset = CGSizeMake(-5, 0);
    self.tableContainerView.layer.shadowOpacity = progress * 0.5;
    self.tableContainerView.layer.shadowRadius = 10;
}

- (void)finishSlideWithOffset:(CGFloat)offset {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat threshold = screenWidth * 0.3; // 超过30%屏幕宽度触发返回
    
    if (offset >= threshold) {
        // 触发返回上一级目录
        [self animateToParentDirectory];
    } else {
        // 滚回原位
        [self animateBackToOriginalPosition];
    }
}

- (void)animateToParentDirectory {
    CGFloat screenWidth = self.view.bounds.size.width;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableContainerView.transform = CGAffineTransformMakeTranslation(screenWidth, 0);
        self.tableContainerView.alpha = 0;
        self.parentSnapshotView.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:^(BOOL finished) {
        // 执行实际的目录切换
        NSString *parentPath = [self.currentDirPath stringByDeletingLastPathComponent];
        [self navigateToDirectory:parentPath];
        
        // 重置视图状态
        [self resetSlideViews];
    }];
}

- (void)animateBackToOriginalPosition {
    [UIView animateWithDuration:0.3 animations:^{
        [self resetSlideViews];
    }];
}

- (void)resetSlideViews {
    self.tableContainerView.transform = CGAffineTransformIdentity;
    self.tableContainerView.alpha = 1.0;
    self.tableContainerView.layer.shadowOpacity = 0;
    
    self.parentSnapshotView.transform = CGAffineTransformIdentity;
    self.parentSnapshotView.hidden = YES;
    
    self.isSlidingBack = NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // 如果是滑动返回操作，允许手势开始
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint velocity = [pan velocityInView:self.view];
        
        // 只允许向右滑动
        if (velocity.x > 0) {
            // 检查是否在根目录
            NSString *documentsPath = [SandboxTool getSandboxDirectoryPath:SandboxDirectoryTypeDocuments];
            NSString *rootPath = [documentsPath stringByDeletingLastPathComponent];
            if (![self.currentDirPath isEqualToString:rootPath] && !self.isShowFavoriteList && !self.searchController.isActive) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)enterBatchEditMode {
    self.isBatchEditing = YES;
    self.navigationItem.rightBarButtonItems = @[self.completeButton, self.selectionCountButton];
    self.navigationItem.leftBarButtonItems = @[self.selectAllButton, self.deselectAllButton];
    [self updateSelectionCountButton];
    
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (currentVC) {
        currentVC.isBatchEditing = YES;
        [currentVC reloadData];
    }
    
    [self.view setNeedsLayout];
    
    // 检查是否在 RootViewController 中
    UIViewController *rootVC = self.navigationController.parentViewController;
    if ([rootVC isKindOfClass:[RootViewController class]]) {
        [(RootViewController *)rootVC enterEditMode];
    } else {
        // 如果不在 RootViewController 中，显示自定义工具栏
        [self showEditToolbar];
    }
}

- (void)exitBatchEditMode {
    self.isBatchEditing = NO;

    self.navigationItem.rightBarButtonItems = @[self.selectionModeItem, self.collectionButton];
    self.navigationItem.leftBarButtonItems = @[self.backButton, self.createButton];
    
    NSArray *currentList = self.searchController.isActive ? self.searchResults : self.fileList;
    for (FileModel *model in currentList) {
        model.isSelected = [[FileSelectionManager sharedManager] isFileSelected:model];
    }
    
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (currentVC) {
        currentVC.isBatchEditing = NO;
        currentVC.fileListViewController = self;
        [currentVC reloadData];
    }
    
    [self.view setNeedsLayout];
    
    // 检查是否在 RootViewController 中
    UIViewController *rootVC = self.navigationController.parentViewController;
    if ([rootVC isKindOfClass:[RootViewController class]]) {
        RootViewController *vc = (RootViewController *)rootVC;
        if(vc.isEditMode){
            vc.isEditMode = NO;
            [vc exitEditMode];
        }
    } else {
        // 如果不在 RootViewController 中，隐藏自定义工具栏
        [self hideEditToolbar];
    }
    [self showLeftActionPanel];
}

- (void)updateSelectionCountButton {
    NSString *title = [NSString stringWithFormat:@"%lu 项", (unsigned long)[[FileSelectionManager sharedManager] selectedCount]];
    if (!self.selectionCountButton) return;
    self.selectionCountButton.title = title;
    [self.rootViewController updateSelectionCount];
    
    // 更新自定义工具栏的数量显示
    [self.editToolbar updateSelectedCount:[[FileSelectionManager sharedManager] selectedCount]];
}

#pragma mark - 自定义工具栏

- (void)showEditToolbar {
    if (!_editToolbar) {
        _editToolbar = [FileOperationToolbar toolbar];
        _editToolbar.delegate = self;
        _editToolbar.showsDoneButton = YES;
    }
    [_editToolbar updateSelectedCount:[[FileSelectionManager sharedManager] selectedCount]];
    [_editToolbar showInView:self.view animated:YES];
}

- (void)hideEditToolbar {
    [_editToolbar hideAnimated:YES];
}

#pragma mark - FileOperationToolbarDelegate

- (void)toolbar:(FileOperationToolbar *)toolbar didSelectAction:(FileOperationAction)action {
    [self didSelectAction:action];
}

- (void)didSelectAction:(FileOperationAction)action{
    NSArray *selectedFiles = [[FileSelectionManager sharedManager] selectedFiles];
    
    switch (action) {
        case FileOperationActionCopy:
            [self handleCopyAction:selectedFiles];
            // 显示左侧操作面板
            [self showLeftActionPanel];
            break;
        case FileOperationActionMove:
            [self handleMoveAction:selectedFiles];
            // 显示左侧操作面板
            [self showLeftActionPanel];
            break;
        case FileOperationActionDelete:
            [self handleDeleteAction:selectedFiles];
            break;
        case FileOperationActionRename:
            [self handleRenameAction:selectedFiles];
            break;
        case FileOperationActionCompress:
            [self handleCompressAction:selectedFiles];
            break;
        case FileOperationActionFavorite:
            [self handleFavoriteAction:selectedFiles];
            break;
        case FileOperationActionRemoveFavorite:
            [self handleRemoveFavoriteAction:selectedFiles];
            break;
        case FileOperationActionMore:
            [self handleMoreAction:selectedFiles];
            break;
        case FileOperationActionDone:
            [self exitBatchEditMode];
            break;
    }
}

- (void)handleCopyAction:(NSArray<FileModel *> *)files {
    if (files.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要拷贝的文件"];
        return;
    }
    self.clipboardFileList = [files mutableCopy];
    self.isCopyOperation = YES;
    [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"已复制 %lu 个项目", (unsigned long)files.count]];
    [self exitBatchEditMode];
    [self updateSelectionCountButton];
    self.title = @"已拷贝";
    self.navigationItem.rightBarButtonItems = @[self.selectionModeItem,self.selectionCountButton];
    [self cancelPasteOperation];
    
}

- (void)handleMoveAction:(NSArray<FileModel *> *)files {
    if (files.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要移动的文件"];
        return;
    }
    self.clipboardFileList = [files mutableCopy];
    self.isCopyOperation = NO;
    [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"已剪切 %lu 个项目", (unsigned long)files.count]];
    [self exitBatchEditMode];
    [self updateSelectionCountButton];
    self.title = @"待移动";
    self.navigationItem.rightBarButtonItems = @[self.selectionModeItem,self.selectionCountButton];
    [self cancelPasteOperation];
    
}

- (void)handleDeleteAction:(NSArray<FileModel *> *)files {
    if (files.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要删除的文件"];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除"
                                                                   message:[NSString stringWithFormat:@"确定要删除选中的 %lu 个项目吗？", (unsigned long)files.count]
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"彻底删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self executeDelete:files];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除到回收站" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self moveToRecycleBin:files];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)executeDelete:(NSArray<FileModel *> *)files {
   
    
    for (FileModel *model in files) {
        [FileOperateTool deleteItemAtPath:model.filePath];
    }
    
    [[FileSelectionManager sharedManager] clearAllSelections];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
    
    [self showAlertWithTitle:@"成功" message:@"删除成功"];
    [self exitBatchEditMode];
    [self cancelPasteOperation];
    
}

- (void)moveToRecycleBin:(NSArray<FileModel *> *)files {
   
    for (FileModel *model in files) {
        [[RecycleBinManager sharedManager] moveToRecycleBin:model];
    }
    
    [[FileSelectionManager sharedManager] clearAllSelections];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
    
    [self showAlertWithTitle:@"成功" message:@"已移至回收站"];
    [self exitBatchEditMode];
    [self cancelPasteOperation];
    
}

- (void)handleCompressAction:(NSArray<FileModel *> *)files {
    if (files.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要压缩的文件"];
        return;
    }
    [[FileActionHandler sharedHandler] compressFilesWithInput:files destinationDir:self.currentDirPath fromViewController:self];
    [self exitBatchEditMode];
    [self cancelPasteOperation];
    
}

- (void)handleFavoriteAction:(NSArray<FileModel *> *)files {
    if (files.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要收藏的文件"];
        return;
    }
    
    for (FileModel *model in files) {
        [[FavoriteManager sharedManager] addFavorite:model];
    }
    
    [self showAlertWithTitle:@"成功" message:[NSString stringWithFormat:@"已收藏 %lu 个项目", (unsigned long)files.count]];
    [self exitBatchEditMode];
    [self cancelPasteOperation];
    
}

- (void)handleRemoveFavoriteAction:(NSArray<FileModel *> *)files {
    if (files.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要收藏的文件"];
        return;
    }
    
    for (FileModel *model in files) {
        [[FavoriteManager sharedManager] removeFavorite:model];
    }
    
    [self showAlertWithTitle:@"成功" message:[NSString stringWithFormat:@"已取消收藏 %lu 个项目", (unsigned long)files.count]];
    [self exitBatchEditMode];
    [self cancelPasteOperation];
    
}

- (void)handleMoreAction:(NSArray<FileModel *> *)files {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"更多操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"重命名" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self handleRenameAction:files];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleRenameAction:(NSArray<FileModel *> *)files {
    [self showLeftActionPanel];
    
    if (files.count == 0) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要重命名的文件"];
        return;
    }
    
    if (files.count > 1) {
        [self showAlertWithTitle:@"提示" message:@"一次只能重命名一个文件"];
        return;
    }
    
    FileModel *model = files.firstObject;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = model.fileName;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newName = alert.textFields.firstObject.text;
        if (newName && newName.length > 0 && ![newName isEqualToString:model.fileName]) {
            NSString *newPath = [[model.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newName];
            NSError *error = nil;
            if ([[NSFileManager defaultManager] moveItemAtPath:model.filePath toPath:newPath error:&error]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
                [self showAlertWithTitle:@"成功" message:@"重命名成功"];
                [self cancelPasteOperation];
                
            } else {
                [self showAlertWithTitle:@"失败" message:error.localizedDescription];
            }
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)selectAllButtonTapped:(UIBarButtonItem *)sender {
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (currentVC) {
        NSArray *list = currentVC.isShowingSearchResults ? currentVC.searchResults : currentVC.fileList;
        [[FileSelectionManager sharedManager] selectAllFiles:list];
        [self updateSelectionCountButton];
        [currentVC reloadData];
    }
}

- (void)deselectAllButtonTapped:(UIBarButtonItem *)sender {
    FileListTableViewController *currentVC = [self currentTableViewController];
    if (currentVC) {
        NSArray *list = currentVC.isShowingSearchResults ? currentVC.searchResults : currentVC.fileList;
        [[FileSelectionManager sharedManager] deselectAllFiles:list];
        [self updateSelectionCountButton];
        [currentVC reloadData];
    }
}



- (void)updateStatistics {
    NSInteger folderCount = 0;
    NSInteger fileCount = 0;
    unsigned long long totalSize = 0;
    
    FileListTableViewController *currentVC = [self currentTableViewController];
    NSArray<FileModel *> *listToCount = currentVC ? (currentVC.isShowingSearchResults ? currentVC.searchResults : currentVC.fileList) : self.fileList;
    
    for (FileModel *model in listToCount) {
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
    NSString *remark = [[RemarkManager sharedManager] getRemarkForFilePath:self.currentDirPath];
    
    NSString *statsText = [NSString stringWithFormat:@"📁 %ld 个  📄 %ld 个  💾 %@", (long)folderCount, (long)fileCount, sizeStr];

    BOOL isCurrentDirFavorite = [[FavoriteManager sharedManager] isFavorite:self.currentDirPath];
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

- (void)handleFavoriteChanged:(NSNotification *)notification {
    [self refreshFileList];
}

- (void)handleFileListChanged:(NSNotification *)notification {
    [self refreshFileList];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 窗口切换器

- (void)showWindowSwitcher {
    // 检查 self.view 是否在窗口层级中
    if (self.view.window == nil) {
        NSLog(@"FileListViewController view is not in window hierarchy, skipping showWindowSwitcher");
        return;
    }
    
    // 检查是否已经有presented的viewController
    if (self.presentedViewController) {
        return;
    }
    
    NSArray *allWindows = [[WindowManager sharedManager] allWindows];
    
    if (allWindows.count == 0) {
        [[WindowManager sharedManager] createWindowWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
        allWindows = [[WindowManager sharedManager] allWindows];
    }
    
    NSMutableArray *windowInfos = [NSMutableArray array];
    NSInteger currentIndex = 0;
    
    for (NSInteger i = 0; i < allWindows.count; i++) {
        FileListViewController *windowVC = allWindows[i];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        info[@"path"] = windowVC.currentDirPath ?: @"";
        info[@"windowIndex"] = @(i);
        // 添加截图信息
        if (windowVC.windowSnapshot) {
            info[@"snapshot"] = windowVC.windowSnapshot;
        }
        
        FileListTableViewController *currentVC = [windowVC currentTableViewController];
        if (currentVC) {
            info[@"title"] = currentVC.currentDirPath.lastPathComponent ?: @"窗口";
        } else {
            info[@"title"] = windowVC.currentDirPath.lastPathComponent ?: @"窗口";
        }
        
        [windowInfos addObject:info];
        
        if (windowVC == [[WindowManager sharedManager] currentWindow]) {
            currentIndex = i;
        }
    }
    
    WindowSwitcherViewController *switcher = [[WindowSwitcherViewController alloc] initWithWindowInfos:[windowInfos copy] currentIndex:currentIndex];
    switcher.delegate = self;
    switcher.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:switcher animated:YES completion:nil];
}

- (void)setupDefaultWindow {
    // 创建默认的表格视图
    if (self.windowControllers.count == 0) {
        FileListTableViewController *defaultVC = [[FileListTableViewController alloc] initWithIdentifier:@"default"];
        defaultVC.currentDirPath = self.currentDirPath ?: [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        defaultVC.fileListViewController = self;
        [self registerTableViewController:defaultVC withIdentifier:@"default"];
    }
}

#pragma mark - WindowSwitcherViewControllerDelegate

- (void)windowSwitcher:(WindowSwitcherViewController *)switcher didSelectViewController:(FileListTableViewController *)viewController atIndex:(NSInteger)index {
    // 获取对应的 FileListViewController
    NSLog(@"获取对应的 FileListViewController:%@",viewController);
    NSArray *allWindows = [[WindowManager sharedManager] allWindows];
    if (index >= 0 && index < allWindows.count) {
        FileListViewController *selectedWindow = allWindows[index];
        
        // 确保 rootViewController 被正确设置
        selectedWindow.rootViewController = self.rootViewController;
        
        // 切换到该窗口（会触发 RootViewController 的 windowManagerDidSwitchToWindow）
        [[WindowManager sharedManager] switchToWindow:selectedWindow];
    }
}


- (void)windowSwitcher:(WindowSwitcherViewController *)switcher didCloseViewController:(FileListTableViewController *)viewController atIndex:(NSInteger)index {
    // 关闭对应的窗口（会在 WindowManager 中自动保存状态）
    [[WindowManager sharedManager] closeWindowAtIndex:index];
}

- (void)windowSwitcherDidRequestAddNewWindow:(WindowSwitcherViewController *)switcher {
    // 创建新窗口（会自动切换到新窗口）
    [[WindowManager sharedManager] createWindowWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    
    // 切换已经在 createWindowWithPath 中处理，这里只需要关闭窗口切换器
    [switcher dismissViewControllerAnimated:YES completion:nil];
}

@end
