//
//  FileListTableViewController.m
//  SandboxFileManager
//
//  文件列表表格控制器 - 管理单个表格视图
//

#import "FileListTableViewController.h"
#import "FileListCell.h"
#import "FileModel.h"
#import "SandboxTool.h"
#import "FileOperateTool.h"
#import "FavoriteManager.h"
#import "FileNotification.h"
#import "FileEnum.h"
#import "FileActionHandler.h"
#import "RemarkManager.h"
#import "FileSelectionManager.h"
#import "FilePreviewViewController.h"
#import "FileOpener.h"
#import "WindowManager.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

static NSString * const kCellIdentifier = @"FileListCell";

@interface FileListTableViewController ()

@end

@implementation FileListTableViewController

#pragma mark - 初始化方法

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _fileList = [NSMutableArray array];
        _searchResults = [NSMutableArray array];
        _isShowingSearchResults = NO;
        _isBatchEditing = NO;
        _currentDirPath = nil;
    }
    return self;
}

#pragma mark - 视图加载

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
    [self setupEmptyView];
    [self setupNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

#pragma mark - 设置方法

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerClass:[FileListCell class] forCellReuseIdentifier:kCellIdentifier];
    [self.view addSubview:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;
    
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.minimumPressDuration = 0.5;
    [self.tableView addGestureRecognizer:self.longPressGesture];
}

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

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleFileListChanged:)
                                                 name:kNotificationFileListChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleFavoriteChanged:)
                                                 name:kNotificationFavoriteChanged
                                               object:nil];
}

#pragma mark - 布局

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    self.emptyView.frame = self.view.bounds;
}

#pragma mark - 公共方法

- (void)refreshFileList {
    if (!self.currentDirPath) {
        return;
    }
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentDirPath error:nil];
    [self.fileList removeAllObjects];
    
    for (NSString *name in contents) {
        if ([name hasPrefix:@"."]) {
            continue;
        }
        
        NSString *fullPath = [self.currentDirPath stringByAppendingPathComponent:name];
        FileModel *model = [FileModel modelWithFilePath:fullPath];
        if (model) {
            if(self.isShowFavoriteList){
                if(!model.isFavorite) continue;
                [self.fileList addObject:model];
            }else{
                [self.fileList addObject:model];
            }
            
        }
    }
    
    [self sortFileList];
    [self updateStatistics];
    [self reloadData];
    [self.refreshControl endRefreshing];
}

- (void)reloadData {
    [self.tableView reloadData];
    [self updateEmptyView];
    // 刷新完成后执行
    dispatch_async(dispatch_get_main_queue(), ^{
        // 👉 这里就是 reloadData 完全结束的时机
        NSLog(@"表格刷新完成！");
        [self.fileListViewController takeWindowSnapshot];
        // 可以安全获取 cell、滚动、更新UI等
    });
    
}

- (void)updateEmptyView {
    BOOL isEmpty = self.isShowingSearchResults ? (self.searchResults.count == 0) : (self.fileList.count == 0);
    self.emptyView.hidden = !isEmpty;
}

- (void)sortFileList {
    if (self.isShowingSearchResults) {
        [self sortArray:self.searchResults];
    } else {
        [self sortArray:self.fileList];
    }
}

- (void)sortArray:(NSMutableArray<FileModel *> *)array {
    if (array.count == 0) return;
    
    NSInteger sortType = self.fileListViewController.currentSortType;
    BOOL isAscending = self.fileListViewController.isSortAscending;
    
    [array sortUsingComparator:^NSComparisonResult(FileModel *obj1, FileModel *obj2) {
        // 文件夹总是优先
        if (obj1.itemType == FileItemTypeFolder && obj2.itemType != FileItemTypeFolder) {
            return NSOrderedAscending;
        } else if (obj1.itemType != FileItemTypeFolder && obj2.itemType == FileItemTypeFolder) {
            return NSOrderedDescending;
        }
        
        NSComparisonResult result;
        
        switch (sortType) {
            case 0: // 名称
                result = [obj1.fileName localizedCaseInsensitiveCompare:obj2.fileName];
                break;
            case 1: // 类型
                result = [obj1.filePath.pathExtension localizedCaseInsensitiveCompare:obj2.filePath.pathExtension];
                if (result == NSOrderedSame) {
                    result = [obj1.fileName localizedCaseInsensitiveCompare:obj2.fileName];
                }
                break;
            case 2: // 日期
                if (!obj1.modificationDate) {
                    result = NSOrderedDescending;
                } else if (!obj2.modificationDate) {
                    result = NSOrderedAscending;
                } else {
                    result = [obj1.modificationDate compare:obj2.modificationDate];
                }
                break;
            case 3: // 大小
                if (obj1.fileSize < obj2.fileSize) {
                    result = NSOrderedAscending;
                } else if (obj1.fileSize > obj2.fileSize) {
                    result = NSOrderedDescending;
                } else {
                    result = [obj1.fileName localizedCaseInsensitiveCompare:obj2.fileName];
                }
                break;
            default:
                result = [obj1.fileName localizedCaseInsensitiveCompare:obj2.fileName];
                break;
        }
        
        // 处理降序
        if (!isAscending && result != NSOrderedSame) {
            result = (result == NSOrderedAscending) ? NSOrderedDescending : NSOrderedAscending;
        }
        
        return result;
    }];
}

- (void)updateStatistics {
}

#pragma mark - Actions

- (void)handleRefresh:(UIRefreshControl *)sender {
    [self refreshFileList];
}

- (void)reloadButtonTapped {
    [self refreshFileList];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gesture locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        if (indexPath) {
            FileModel *model = nil;
            if (self.isShowingSearchResults) {
                model = self.searchResults[indexPath.row];
            } else {
                model = self.fileList[indexPath.row];
            }
            
            [self.fileListViewController enterBatchEditMode];
        }
    }
}

- (void)handleFileListChanged:(NSNotification *)notification {
    [self refreshFileList];
}

- (void)handleFavoriteChanged:(NSNotification *)notification {
    [self refreshFileList];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isShowingSearchResults) {
        return self.searchResults.count;
    }
    return self.fileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"kCellIdentifier-%ld",indexPath.row] forIndexPath:indexPath];
    // 每次都新建自定义cell，不重用
    FileListCell *cell = [[FileListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"kCellIdentifier-%ld",indexPath.row]];
        
    FileModel *model = nil;
    if (self.isShowingSearchResults) {
        model = self.searchResults[indexPath.row];
    } else {
        model = self.fileList[indexPath.row];
    }
    
    [cell configWithFileModel:model];
    cell.isBatchEditing = self.isBatchEditing;
    cell.cellDelegate = self;
    
    // 判断是否需要高亮
    if (self.highlightedFilePath && [model.filePath isEqualToString:self.highlightedFilePath]) {
        cell.isHighlightedFile = YES;
    } else {
        cell.isHighlightedFile = NO;
    }
    
    return cell;
}

/// 清除高亮效果
- (void)clearHighlight {
    if (self.highlightedFilePath) {
        self.highlightedFilePath = nil;
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    FileModel *model = nil;
    if (self.isShowingSearchResults) {
        model = self.searchResults[indexPath.row];
    } else {
        model = self.fileList[indexPath.row];
    }
    
    if (self.isBatchEditing) {
        // 更新选择状态
        BOOL is_selected = [[FileSelectionManager sharedManager] isFileSelected:model];
        if (is_selected) {
            [[FileSelectionManager sharedManager] removeFile:model];
        } else {
            [[FileSelectionManager sharedManager] addFile:model];
        }
        
        // 更新 model 的选中状态
        model.isSelected = !is_selected;
        
        // 更新按钮状态
        [self.fileListViewController updateSelectionCountButton];
        
        // 直接更新当前 cell 的 checkButton，不刷新
        FileListCell *cell = (FileListCell*)[tableView cellForRowAtIndexPath:indexPath];
        cell.checkButton.selected = model.isSelected;
        
        [tableView reloadData];
        
    } else {
        if (model.itemType == FileItemTypeFolder) {
            
            // ===================== 正确动画：左移出 → 刷新 → 右滑入 =====================
            CGRect originalFrame = tableView.frame;
            
            // 1. 表格 向左 滑出屏幕（你要的移出左侧）
            [UIView animateWithDuration:0.15 animations:^{
                tableView.frame = CGRectMake(-originalFrame.size.width, originalFrame.origin.y,
                                             originalFrame.size.width, originalFrame.size.height);
            } completion:^(BOOL finished) {
                
                // 2. ✅ 移出完成后，立刻刷新目录数据（核心！必须放这里）
                self.currentDirPath = model.filePath;
                NSLog(@"点击进入了:%@",self.currentDirPath);
                [self refreshFileList];
                self.fileListViewController.currentDirPath = self.currentDirPath;
                [self.fileListViewController refreshFileList];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDirectoryChanged
                                                                    object:nil
                                                                  userInfo:@{@"path": self.currentDirPath}];
                
                
                // 先把表格挪到屏幕右侧（看不见）
                tableView.frame = CGRectMake(originalFrame.size.width, originalFrame.origin.y,
                                             originalFrame.size.width, originalFrame.size.height);
                
                // 3. ✅ 从屏幕右侧 平滑滑回 原始位置（你要的效果）
                [UIView animateWithDuration:0.15 animations:^{
                    tableView.frame = originalFrame;
                } completion:^(BOOL finished) {
                    // 动画完成后，延迟一点时间再截图
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.fileListViewController takeWindowSnapshot];
                        [[WindowManager sharedManager] saveWindowState];
                    });
                }];
            }];
            // ======================================================================
        } else {
            [[FileOpener sharedOpener] openFileWithModel:model
                                               fileList:self.isShowingSearchResults ? self.searchResults : self.fileList
                                            currentIndex:indexPath.row
                                         currentDirPath:self.currentDirPath
                                      fromViewController:self.fileListViewController];
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
            model.isFavorite = NO;
            // 执行取消收藏
            [[FavoriteManager sharedManager] removeFavorite:model];
            
            [self refreshFileList];
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
            // 收藏
            model.isFavorite = YES;
            
            // 赋值给 model
            model.remark = remark;
            
            // 保存备注到本地
            [[RemarkManager sharedManager] saveRemark:remark forFilePath:model.filePath];
            
            // 执行收藏
            [[FavoriteManager sharedManager] addFavorite:model];
            
            // 刷新逻辑（你原来的代码）
            [self refreshFileList];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - FileListCellDelegate

// 文件列表单元格点击了选择框
- (void)fileListCell:(FileListCell *)cell didSelectCheckBox:(BOOL)selected forFileModel:(FileModel *)model {
    // 更新按钮状态
    [self.fileListViewController updateSelectionCountButton];
}

// 文件列表单元格点击了操作按钮 - 触发左滑效果
- (void)fileListCell:(FileListCell *)cell didTapActionButtonForFileModel:(FileModel *)model {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath) {
        // 触发左滑效果
        [[FileActionHandler sharedHandler] showActionSheetForModel:model fromViewController:self delegate:self];
    }
}

// 显示左滑操作
- (void)showSwipeActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 直接显示左滑操作菜单，使用UIAlertController模拟
    FileModel *model = nil;
    if (self.isShowingSearchResults) {
        model = self.searchResults[indexPath.row];
    } else {
        model = self.fileList[indexPath.row];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 收藏/取消收藏
    NSString *favoriteTitle = model.isFavorite ? @"取消收藏" : @"收藏";
    [alert addAction:[UIAlertAction actionWithTitle:favoriteTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self toggleFavoriteForItem:model];
    }]];
    
    // 重命名
    [alert addAction:[UIAlertAction actionWithTitle:@"重命名"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self showRenameAlertForItem:model];
    }]];
    
    // 删除
    [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self confirmDeleteItem:model];
    }]];
    
    // 取消
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    // 适配 iPad
    UIPopoverPresentationController *popController = alert.popoverPresentationController;
    if (popController) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        popController.sourceView = cell;
        popController.sourceRect = cell.bounds;
        popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - 辅助函数
// 显示警告提示框
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
