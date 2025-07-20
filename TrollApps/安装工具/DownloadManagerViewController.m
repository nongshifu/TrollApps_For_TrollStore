#import "DownloadManagerViewController.h"
#import "FileInstallManager.h"
#import "NewAppFileModel.h"
#import "config.h"
#import "Masonry.h"
#import "EmptyView.h"

@interface DownloadManagerViewController ()<UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *fileList;          // 原始文件列表
@property (nonatomic, strong) NSMutableArray *filteredFileList;  // 过滤后的文件列表
@property (nonatomic, strong) NSString *downloadDir;             // 统一下载目录
@property (nonatomic, strong) UILabel *titleLabel;               // 主标题
@property (nonatomic, strong) UILabel *subtitleLabel;            // 副标题
@property (nonatomic, strong) UIScrollView *filterScrollView;    // 筛选器滚动视图
@property (nonatomic, strong) NSMutableArray *filterButtons;     // 筛选按钮数组
@property (nonatomic, strong) UIView *headerView;                // 顶部视图
@property (nonatomic, assign) FileType currentFilterType;        // 当前筛选类型

@property (nonatomic, strong) UIView *bottomToolBar;           // 底部操作栏
@property (nonatomic, strong) UIButton *selectAllBtn;          // 全选按钮
@property (nonatomic, strong) UIButton *deselectAllBtn;        // 全取消按钮
@property (nonatomic, strong) UIButton *deleteBtn;             // 删除按钮
@property (nonatomic, strong) UIButton *cancelBtn;             // 取消按钮
@property (nonatomic, strong) NSMutableArray *selectedFilePaths; // 选中文件路径
/**
 空视图
 */
@property (nonatomic, strong) EmptyView *emptyView;
@property (nonatomic, strong) UIDocumentInteractionController *documentController; // 文件分享控制器
@end

@implementation DownloadManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化筛选类型
    self.currentFilterType = FileTypeUnknown; // 默认显示全部
    
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
    
    // 初始化筛选按钮数组
    self.filterButtons = [NSMutableArray array];
    
    // 创建筛选器滚动视图
    self.filterScrollView = [[UIScrollView alloc] init];
    self.filterScrollView.showsHorizontalScrollIndicator = NO;
    [self.headerView addSubview:self.filterScrollView];
    
    // 动态添加筛选按钮（根据FileType枚举）
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
    CGFloat buttonSpacing = 10;
    
    // 创建"全部"按钮
    UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
    allButton.tag = FileTypeUnknown; // 用FileTypeUnknown表示全部
    [allButton setTitle:@"全部" forState:UIControlStateNormal];
    allButton.titleLabel.font = [UIFont systemFontOfSize:14];
    allButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:1.0];
    allButton.layer.cornerRadius = buttonHeight / 2;
    [allButton addTarget:self action:@selector(filterButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.filterScrollView addSubview:allButton];
    
    // 计算按钮宽度（根据标题自适应）
    CGSize titleSize = [@"全部" sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    CGFloat buttonWidth = titleSize.width + buttonPadding * 2;
    
    // 修复：使用buttonSpacing作为左侧间距，而不是buttonPadding
    allButton.frame = CGRectMake(buttonSpacing, 0, buttonWidth, buttonHeight);
    
    // 添加到按钮数组和总宽度
    [self.filterButtons addObject:allButton];
    totalWidth += buttonWidth + buttonSpacing*2; // 只加一个buttonSpacing，因为已经在frame中使用了buttonSpacing作为左侧间距
    
    // 遍历所有文件类型并创建对应按钮（从0到FileTypeUnknown-1）
    for (int i = 0; i < FileTypeUnknown; i++) {
        FileType fileType = (FileType)i;
        NSString *typeName = [NewAppFileModel chineseDescriptionForFileType:fileType];
        
        // 提取简短名称（例如"iOS应用安装包" -> "应用"）
        NSString *shortName = [self shortNameForFileTypeName:typeName];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = fileType;
        [button setTitle:shortName forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        button.backgroundColor = [UIColor lightGrayColor];
        button.layer.cornerRadius = buttonHeight / 2;
        [button addTarget:self action:@selector(filterButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.filterScrollView addSubview:button];
        
        // 计算按钮宽度
        CGSize size = [shortName sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
        buttonWidth = size.width + buttonPadding * 2;
        button.frame = CGRectMake(totalWidth, 0, buttonWidth, buttonHeight);
        
        // 添加到按钮数组和总宽度
        [self.filterButtons addObject:button];
        totalWidth += buttonWidth + buttonSpacing;
    }
    
    // 设置滚动视图内容大小
    self.filterScrollView.contentSize = CGSizeMake(totalWidth, buttonHeight);
}

#pragma mark - 筛选按钮点击事件
- (void)filterButtonTapped:(UIButton *)sender {
    // 更新按钮状态
    for (UIButton *button in self.filterButtons) {
        button.backgroundColor = (button == sender) ?
            [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:1.0] :
            [UIColor lightGrayColor];
    }
    
    // 更新当前筛选类型
    self.currentFilterType = (FileType)sender.tag;
    
    // 应用筛选
    [self filterFiles];
    
    // 滚动到选中的按钮位置
    [self.filterScrollView scrollRectToVisible:sender.frame animated:YES];
}

#pragma mark - 初始化表格
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    
    // 关键修复1：允许编辑模式下选中单元格
    self.tableView.allowsSelectionDuringEditing = YES; // 核心属性，必须设置为YES
    self.tableView.allowsMultipleSelectionDuringEditing = YES; // 支持多选
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"FileCell"];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadFileList)];
    
    // 初始化空视图
    self.emptyView = [[EmptyView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    [self.view addSubview:self.emptyView];
    [self.view bringSubviewToFront:self.emptyView];
    
    [self updateEmptyViewVisibility];
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
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);;
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
            make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);;
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
    
    // 应用当前筛选条件
    [self filterFiles];
    
    [self.tableView reloadData];
    
    [self.tableView.mj_header endRefreshing];
    
    [self.emptyView updateConstraints];
    
    self.emptyView.alpha = self.fileList.count == 0;
}

#pragma mark - 筛选文件
- (void)filterFiles {
    // 根据当前筛选类型过滤文件
    if (self.currentFilterType == FileTypeUnknown) {
        // 全部
        self.filteredFileList = [self.fileList mutableCopy];
    } else {
        // 按文件类型筛选
        self.filteredFileList = [NSMutableArray array];
        for (NSString *filePath in self.fileList) {
            FileType type = [NewAppFileModel fileTypeForFileName:[filePath lastPathComponent]];
            if (type == self.currentFilterType) {
                [self.filteredFileList addObject:filePath];
            }
        }
    }
    
    // 更新副标题显示当前筛选状态
    NSString *filterTitle = (self.currentFilterType == FileTypeUnknown) ?
        @"全部" : [NewAppFileModel chineseDescriptionForFileType:self.currentFilterType];
    
    // 提取简短名称
    filterTitle = [self shortNameForFileTypeName:filterTitle];
    
    self.subtitleLabel.text = [NSString stringWithFormat:@"已筛选: %@ (%lu个文件)",
                              filterTitle, (unsigned long)self.filteredFileList.count];
    [self.tableView reloadData];
}

#pragma mark - 长按表格进入多选模式
- (void)tableViewLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    if (self.tableView.isEditing) return;
    
    CGPoint point = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (!indexPath) return;
    
    // 进入编辑模式
    [self.tableView setEditing:YES animated:YES];
    self.bottomToolBar.hidden = NO;
    
    // 选中长按的单元格（使用系统方法）
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
    static NSString *cellIdentifier = @"FileCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
//    }
//
    // 数据设置（不变）
    NSString *filePath = self.filteredFileList[indexPath.row];
    NSString *fileName = [filePath lastPathComponent];
    NSArray *array = [fileName componentsSeparatedByString:@"_mainFile_"];
    cell.textLabel.text = array[1];
    
    // 设置副标题（不变）
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSDate *modificationDate = attributes[NSFileModificationDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ • %@",
                                [self fileTypeDescription:filePath],
                                [formatter stringFromDate:modificationDate]];
    
    // 背景设置（不变）
    cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    // 关键：使用系统原生的多选模式
    if (self.tableView.isEditing) {
        // 根据选中状态设置系统自带的勾选标记
        cell.accessoryType = [self.selectedFilePaths containsObject:filePath] ?
                             UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.accessoryView = nil; // 确保不使用自定义视图
        BOOL isSelected = [self.selectedFilePaths containsObject:filePath];
        if(isSelected){
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - UITableView代理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *filePath = self.filteredFileList[indexPath.row];
    
    if (self.tableView.isEditing) {
        // 1. 更新选中状态
        BOOL isSelected = [self.selectedFilePaths containsObject:filePath];
        if (isSelected) {
            [self.selectedFilePaths removeObject:filePath];
        } else {
            [self.selectedFilePaths addObject:filePath];
        }

        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } else {
        // 普通模式：显示操作菜单
        [self showFileActionSheetForPath:filePath];
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
    [self showAlertWithConfirmationFromViewController:self title:@"是否安装" message:@"" confirmTitle:@"安装" cancelTitle:@"取消" onConfirmed:^{
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[FileInstallManager sharedManager] installFileWithURL:fileURL completion:^(BOOL success, NSError * _Nullable error) {
            if (!success) {
                [self showAlertWithTitle:@"安装失败" message:error.localizedDescription];
            }
        }];
    } onCancelled:^{
        // 取消操作
    }];
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

// 左滑删除
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *filePath = self.filteredFileList[indexPath.row];
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (success) {
            // 从原始列表和过滤列表中都删除
            [self.fileList removeObject:filePath];
            [self.filteredFileList removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            // 更新副标题计数
            self.subtitleLabel.text = [NSString stringWithFormat:@"已筛选: %@ (%lu个文件)",
                                      [self shortNameForFileTypeName:[NewAppFileModel chineseDescriptionForFileType:self.currentFilterType]],
                                      (unsigned long)self.filteredFileList.count];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除失败" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

#pragma mark - 全选
- (void)selectAllFiles {
    [self.selectedFilePaths removeAllObjects];
    [self.selectedFilePaths addObjectsFromArray:self.filteredFileList];
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
