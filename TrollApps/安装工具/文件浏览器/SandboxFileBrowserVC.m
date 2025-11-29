//
//  SandboxFileBrowserVC.m
//  TrollApps
//
//  Created by 十三哥 on 2025/11/29.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "SandboxFileBrowserVC.h"
#import "FileModel.h"
#import "FileUtils.h"
#import "config.h"

// 操作模式（拷贝/剪切）
typedef NS_ENUM(NSInteger, OperationMode) {
    OperationModeNone,   // 无操作
    OperationModeCopy,   // 拷贝
    OperationModeCut     // 剪切
};

@interface SandboxFileBrowserVC ()
/// 当前目录路径
@property (nonatomic, copy) NSString *currentDirPath;
/// 所有文件模型
@property (nonatomic, strong) NSMutableArray<FileModel *> *allFileModels;
/// 搜索过滤后的文件模型
@property (nonatomic, strong) NSMutableArray<FileModel *> *filteredFileModels;
/// 选中的文件路径（key: IndexPath字符串, value: FileModel）
@property (nonatomic, strong) NSMutableDictionary<NSString *, FileModel *> *selectedFiles;
/// 操作模式（拷贝/剪切）
@property (nonatomic, assign) OperationMode operationMode;
/// 搜索框
@property (nonatomic, strong) UISearchBar *searchBar;
/// 预览控制器
@property (nonatomic, strong) QLPreviewController *previewVC;
/// 导航栈（记录目录访问历史，用于返回上级）
@property (nonatomic, strong) NSMutableArray<NSString *> *navStack;
/// 保存当前要预览的文件模型（解决返回后路径不更新问题）
@property (nonatomic, strong) FileModel *currentPreviewModel;

@end

@implementation SandboxFileBrowserVC

// 🔥 1. 静态单例变量（全局唯一）
static SandboxFileBrowserVC *_sharedInstance = nil;

// 🔥 2. 单例对外暴露方法（推荐使用这个方法获取实例）
+ (instancetype)sharedBrowser {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 第一次调用时，初始化单例（默认路径：沙盒根目录）
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *sandboxRootPath = [documentsPath stringByDeletingLastPathComponent];
        _sharedInstance = [[SandboxFileBrowserVC alloc] initWithStyle:UITableViewStyleGrouped];
    });
    return _sharedInstance;
}

// 🔥 3. 禁止外部通过 alloc 创建实例（重写 allocWithZone:）
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *sandboxRootPath = [documentsPath stringByDeletingLastPathComponent];
        _sharedInstance = [super allocWithZone:zone];
        // 初始化单例的核心属性（避免重复初始化）
        _sharedInstance.allFileModels = [NSMutableArray array];
        _sharedInstance.filteredFileModels = [NSMutableArray array];
        _sharedInstance.selectedFiles = [NSMutableDictionary dictionary];
        _sharedInstance.navStack = [NSMutableArray array];
        _sharedInstance.previewVC = [[QLPreviewController alloc] init];
        _sharedInstance.previewVC.dataSource = _sharedInstance;
        _sharedInstance.previewVC.delegate = _sharedInstance;
        _sharedInstance.currentDirPath = sandboxRootPath;
        // 导航栏配置
        _sharedInstance.title = @"沙盒文件浏览器";
        _sharedInstance.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回上级" style:UIBarButtonItemStylePlain target:_sharedInstance action:@selector(popToPreviousDir)];
    });
    return _sharedInstance;
}

// 🔥 4. 禁止外部通过 init 直接创建实例
- (instancetype)init {
    return [[self class] sharedBrowser];
}

// 🔥 6. 禁止外部通过 new 创建实例（new = alloc + init）
+ (instancetype)new {
    return [self sharedBrowser];
}
#pragma mark - 初始化
+ (instancetype)browserWithDefaultPath {
    SandboxFileBrowserVC *browser = [self sharedBrowser];
    return browser;
}

+ (instancetype)browserWithInitialPath:(NSString *)initialPath {
    SandboxFileBrowserVC *browser = [self sharedBrowser];
    // 第一次调用时设置初始路径，之后调用不修改（避免覆盖用户当前目录）
    if (!browser.currentDirPath || browser.currentDirPath.length == 0) {
        browser.currentDirPath = initialPath ?: [self defaultFallbackPath];
        [browser loadFilesInCurrentDir];
    }
    return browser;
}

// 兜底路径：优先 Documents → 其次 Caches → 最后 Library（确保一定有有效路径）
+ (NSString *)defaultFallbackPath {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (documents) return documents;
    
    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    if (caches) return caches;
    
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 只初始化一次 UI（单例 view 不会重复创建）
    if (!self.tableView.tableHeaderView) { // 避免重复设置头部
        [self setupTableView];
    }
    if (self.allFileModels.count == 0) { // 避免重复加载文件
        [self loadFilesInCurrentDir];
    }
    [self updateNavigationRightItems]; // 每次显示都更新导航栏按钮
}

#pragma mark - UI配置
- (void)setupTableView {
    self.tableView.rowHeight = 60;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"FileCell"];
    
    // 表格头部（显示当前路径，可点击复制）
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWidth, 80)];
    headerView.backgroundColor = [UIColor systemBackgroundColor];
    
    UILabel *pathLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 50, kWidth - 32, 30)];
    pathLabel.font = [UIFont systemFontOfSize:14];
    pathLabel.textColor = [UIColor labelColor];
    pathLabel.text = self.currentDirPath;
    pathLabel.numberOfLines = 1;
    pathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [headerView addSubview:pathLabel];
    
    // 点击头部复制路径
    UITapGestureRecognizer *tapHeader = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(copyCurrentPath)];
    [headerView addGestureRecognizer:tapHeader];
    
    self.tableView.tableHeaderView = headerView;
    
    // 长按手势（此时添加，避免在 init 里访问 self.view）
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.tableView addGestureRecognizer:longPress];
    
    
}

/// 更新导航栏右侧按钮（多选/取消/操作按钮）
- (void)updateNavigationRightItems {
    NSMutableArray *rightItems = [NSMutableArray array];
    
    if (self.selectedFiles.count > 0) {
        // 多选模式：取消 + 拷贝 + 剪切 + 删除
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelMultiSelect)];
        UIBarButtonItem *copyItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"doc.on.doc"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCopySelectedFiles)];
        UIBarButtonItem *cutItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"scissors"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCutSelectedFiles)];
        UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash.fill"] style:UIBarButtonItemStyleDone target:self action:@selector(actionDeleteSelectedFiles)];
        
        copyItem.tintColor = [UIColor systemBlueColor];
        cutItem.tintColor = [UIColor systemOrangeColor];
        
        [rightItems addObjectsFromArray:@[cancelItem, copyItem, cutItem, deleteItem]];
    } else if (self.operationMode != OperationModeNone) {
        // 剪贴板模式：粘贴 + 取消
        UIBarButtonItem *pasteItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"doc.pasteboard"] style:UIBarButtonItemStylePlain target:self action:@selector(actionPasteFiles)];
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelOperationMode)];
        pasteItem.tintColor = [UIColor systemGreenColor];
        [rightItems addObjectsFromArray:@[pasteItem, cancelItem]];
    } else {
        // 普通模式：关闭按钮
       
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeItemTap)];
        [rightItems addObjectsFromArray:@[closeItem]];
    }
    
    self.navigationItem.rightBarButtonItems = rightItems;
}

#pragma mark - 数据加载

/// 加载当前目录下的文件
- (void)loadFilesInCurrentDir {
    NSLog(@"[SandboxFileBrowserVC] ====== 开始加载目录文件 ======");
    NSLog(@"[SandboxFileBrowserVC] 当前目录路径：%@", self.currentDirPath);
    
    [self.allFileModels removeAllObjects];
    NSLog(@"[SandboxFileBrowserVC] 清空原有文件列表，准备重新加载");
    
    // 🔥 关键1：获取沙盒根目录（三大目录的父目录）
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *sandboxRootPath = [documentsPath stringByDeletingLastPathComponent];
    // 路径标准化（避免斜杠差异导致匹配失败）
    NSString *standardizedCurrentPath = [self standardizedPath:self.currentDirPath];
    NSString *standardizedSandboxRoot = [self standardizedPath:sandboxRootPath];
    
    // 🔥 关键2：判断是否是沙盒根目录 → 显示三大目录
    if ([standardizedCurrentPath isEqualToString:standardizedSandboxRoot]) {
        NSLog(@"[SandboxFileBrowserVC] 👉 当前为沙盒根目录，加载三大核心目录（Documents/Library/Caches）");
        
        // 从 getSandboxRootPaths 获取三大目录，显示在根页面
        NSArray *threeCorePaths = [FileUtils getSandboxRootPaths];
        for (NSString *corePath in threeCorePaths) {
            NSLog(@"[SandboxFileBrowserVC] 正在初始化核心目录模型：%@", corePath);
            FileModel *model = [[FileModel alloc] initWithFilePath:corePath];
            if (model) {
                [self.allFileModels addObject:model];
                NSLog(@"[SandboxFileBrowserVC] ✅ 核心目录模型初始化成功：文件名=%@，类型=%@", model.fileName, model.fileType == FileTypeFolder ? @"文件夹" : @"文件");
            } else {
                NSLog(@"[SandboxFileBrowserVC] ❌ 核心目录模型初始化失败：路径=%@", corePath);
            }
        }
    } else {
        // 普通目录：加载当前路径下的子文件（原有逻辑不变）
        NSLog(@"[SandboxFileBrowserVC] 👉 当前为普通目录，加载子文件列表");
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *dirError = nil;
        NSArray *subpaths = [fm contentsOfDirectoryAtPath:self.currentDirPath error:&dirError];
        
        if (dirError) {
            NSLog(@"[SandboxFileBrowserVC] ❌ 获取子文件路径失败：%@", dirError.localizedDescription);
            subpaths = @[];
        } else {
            NSLog(@"[SandboxFileBrowserVC] ✅ 成功获取子文件路径，共 %ld 个项目", subpaths.count);
            
            BOOL needPrintAll = subpaths.count <= 20;
            for (NSInteger i = 0; i < subpaths.count; i++) {
                NSString *subpath = subpaths[i];
                NSString *fullPath = [self.currentDirPath stringByAppendingPathComponent:subpath];
                
                if (needPrintAll || i < 5) {
                    NSLog(@"[SandboxFileBrowserVC] 正在初始化子文件模型（%ld/%ld）：%@", i+1, subpaths.count, fullPath);
                } else if (i == 5) {
                    NSLog(@"[SandboxFileBrowserVC] ... 剩余 %ld 个文件省略打印 ...", subpaths.count - 5);
                }
                
                FileModel *model = [[FileModel alloc] initWithFilePath:fullPath];
                if (model) {
                    [self.allFileModels addObject:model];
                    if (needPrintAll || i < 5) {
                        NSLog(@"[SandboxFileBrowserVC] ✅ 子文件模型初始化成功：文件名=%@，类型=%@，大小=%@，修改时间=%@",
                              model.fileName,
                              model.fileType == FileTypeFolder ? @"文件夹" : @"文件",
                              model.formattedFileSize,
                              [FileUtils formatDate:model.modifyDate]);
                    }
                } else {
                    NSLog(@"[SandboxFileBrowserVC] ❌ 子文件模型初始化失败：路径=%@", fullPath);
                }
            }
        }
    }
    
    // 排序：文件夹在前，文件在后；按名称升序
    NSLog(@"[SandboxFileBrowserVC] 👉 开始排序文件（规则：文件夹在前，文件在后；名称不区分大小写升序）");
    [self.allFileModels sortUsingComparator:^NSComparisonResult(FileModel *a, FileModel *b) {
        if (a.fileType != b.fileType) {
            return a.fileType < b.fileType ? NSOrderedAscending : NSOrderedDescending;
        }
        return [a.fileName compare:b.fileName options:NSCaseInsensitiveSearch];
    }];
    NSLog(@"[SandboxFileBrowserVC] ✅ 排序完成，最终文件列表共 %ld 个项目", self.allFileModels.count);
    
    // 打印排序后的前3个项目（预览排序结果）
    NSInteger previewCount = MIN(3, self.allFileModels.count);
    for (NSInteger i = 0; i < previewCount; i++) {
        FileModel *model = self.allFileModels[i];
        NSLog(@"[SandboxFileBrowserVC] 排序后预览（%ld/%ld）：%@（%@）",
              i+1,
              self.allFileModels.count,
              model.fileName,
              model.fileType == FileTypeFolder ? @"文件夹" : @"文件");
    }
    
    // 初始过滤（无搜索关键词时显示全部）
    NSString *currentKeyword = self.searchBar.text ?: @"[无关键词]";
    NSLog(@"[SandboxFileBrowserVC] 👉 开始过滤文件，当前搜索关键词：%@", currentKeyword);
    [self filterFilesWithKeyword:self.searchBar.text];
    
    NSLog(@"[SandboxFileBrowserVC] ====== 目录文件加载流程结束 ======\n");
}

/// 搜索过滤文件
- (void)filterFilesWithKeyword:(NSString *)keyword {
    NSLog(@"[SandboxFileBrowserVC] ====== 开始文件过滤 ======");
    NSLog(@"[SandboxFileBrowserVC] 过滤关键词：%@（原始输入：%@）",
          keyword ?: @"[空关键词]",
          keyword ?: @"nil");
    
    [self.filteredFileModels removeAllObjects];
    NSLog(@"[SandboxFileBrowserVC] 清空原有过滤列表，准备重新过滤");
    
    if (!keyword || keyword.length == 0) {
        // 无关键词：显示全部文件
        [self.filteredFileModels addObjectsFromArray:self.allFileModels];
        NSLog(@"[SandboxFileBrowserVC] 👉 无搜索关键词，直接显示全部文件");
        NSLog(@"[SandboxFileBrowserVC] ✅ 过滤完成：共 %ld 个文件（与原始列表数量一致）", self.filteredFileModels.count);
    } else {
        // 有关键词：模糊匹配（不区分大小写）
        NSString *lowerKeyword = keyword.lowercaseString;
        NSLog(@"[SandboxFileBrowserVC] 👉 按关键词模糊匹配（不区分大小写）：%@", lowerKeyword);
        
        NSMutableArray<NSString *> *matchedFileNames = [NSMutableArray array];
        for (FileModel *model in self.allFileModels) {
            if ([model.fileName.lowercaseString containsString:lowerKeyword]) {
                [self.filteredFileModels addObject:model];
                [matchedFileNames addObject:model.fileName];
                NSLog(@"[SandboxFileBrowserVC] ✅ 匹配成功：文件名=%@（路径=%@）", model.fileName, model.filePath);
            } else {
                // 可选：打印未匹配的文件（调试时开启，默认关闭）
                // NSLog(@"[SandboxFileBrowserVC] ❌ 未匹配：文件名=%@（路径=%@）", model.fileName, model.filePath);
            }
        }
        
        NSLog(@"[SandboxFileBrowserVC] ✅ 过滤完成：共匹配到 %ld 个文件", self.filteredFileModels.count);
        if (matchedFileNames.count > 0) {
            NSLog(@"[SandboxFileBrowserVC] 匹配结果列表：%@", matchedFileNames);
        } else {
            NSLog(@"[SandboxFileBrowserVC] ❌ 未匹配到任何文件");
        }
    }
    
    // 刷新表格前打印最终结果
    NSLog(@"[SandboxFileBrowserVC] 👉 准备刷新表格，显示 %ld 个文件", self.filteredFileModels.count);
    [self.tableView reloadData];
    NSLog(@"[SandboxFileBrowserVC] ====== 文件过滤流程结束 ======\n");
}
/// 路径标准化：去掉末尾斜杠，确保匹配一致性
- (NSString *)standardizedPath:(NSString *)path {
    if (!path || path.length == 0) return @"";
    return [path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
}
#pragma mark - 表格数据源 & 代理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredFileModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = [NSString stringWithFormat:@"cell-%ld",indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    
    FileModel *model = self.filteredFileModels[indexPath.row];
    
    // 图标
    
    // 🔥 1. 定义常见图片格式后缀（根据需求扩展）
    NSSet *imageSuffixSet = [NSSet setWithObjects:@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"tiff", @"heic", nil];
    // 获取文件扩展名（转小写，避免大小写差异）
    NSString *fileExtension = [model.fileName pathExtension].lowercaseString;
    // 判断是否为图片文件
    BOOL isImageFile = [imageSuffixSet containsObject:fileExtension];
    
    if (isImageFile) {
        // 🔥 2. 图片文件：用 SDWebImage 加载本地图片
        NSURL *imageFileURL = [NSURL fileURLWithPath:model.filePath];
        
        // 配置占位图（用原系统文件夹/文件图标，保持加载一致性）
        UIImage *placeholderImage = [UIImage systemImageNamed:@"photo"];
        placeholderImage = [placeholderImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        // SDWebImage 加载本地图片（支持缓存，避免重复读取）
        [cell.imageView sd_setImageWithURL:imageFileURL
                          placeholderImage:placeholderImage
                                   options:SDWebImageRetryFailed // 加载失败重试
                                 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error) {
                // 加载失败（比如文件损坏），显示默认图标
                cell.imageView.image = [UIImage systemImageNamed:@"filemenu.and.cursorarrow"];
                cell.imageView.tintColor = [UIColor systemGrayColor];
            } else {
                // 加载成功，调整图片显示模式（避免拉伸）
                cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
                
            }
        }];
        
        // 图片图标色调（可自定义）
        cell.imageView.tintColor = [UIColor systemBlueColor];
    } else {
        // 🔥 3. 非图片文件：保持原逻辑（系统图标）
        cell.imageView.image = [UIImage systemImageNamed:model.iconName];
        cell.imageView.tintColor = model.fileType == FileTypeFolder ? [UIColor systemBlueColor] : [UIColor systemGrayColor];
        cell.imageView.contentMode = UIViewContentModeScaleToFill; // 恢复默认模式
    }
    
    cell.imageView.tintColor = model.fileType == FileTypeFolder ? [UIColor systemBlueColor] : [UIColor systemGrayColor];
    
    // 标题（文件名）
    cell.textLabel.text = model.fileName;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = [UIColor labelColor];
    
    // 副标题（大小 + 修改日期）
    NSString *subTitle = [NSString stringWithFormat:@"%@ | %@", model.formattedFileSize, [FileUtils formatDate:model.modifyDate]];
    cell.detailTextLabel.text = subTitle;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    
    // 选中状态
    NSString *indexPathKey = [self indexPathToString:indexPath];
    cell.accessoryType = self.selectedFiles[indexPathKey] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.backgroundColor = self.selectedFiles[indexPathKey] ? [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.1] : [UIColor systemBackgroundColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FileModel *model = self.filteredFileModels[indexPath.row];
    
    if (self.selectedFiles.count > 0) {
        // 多选模式：切换选中状态
        [self toggleFileSelectionAtIndexPath:indexPath];
    } else {
        if (model.fileType == FileTypeFolder) {
            // 文件夹：进入下一级目录
            [self pushToSubDir:model.filePath];
        } else {
            // 文件：预览
            [self previewFile:model];
        }
    }
}

/// 左滑删除
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"删除" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        FileModel *model = self.filteredFileModels[indexPath.row];
        [self showDeleteConfirmAlertForFile:model completion:^(BOOL confirmed) {
            if (confirmed) {
                NSError *error = nil;
                BOOL success = [FileUtils deleteItemAtPath:model.filePath error:&error];
                if (success) {
                    [self loadFilesInCurrentDir];
                    [self showToast:@"删除成功"];
                } else {
                    [self showToast:[NSString stringWithFormat:@"删除失败：%@", error.localizedDescription]];
                }
            }
            completionHandler(confirmed);
        }];
    }];
    
    deleteAction.image = [UIImage systemImageNamed:@"trash.fill"];
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark - 多选相关
/// 长按进入多选模式
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    
    CGPoint point = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (!indexPath) return;
    
    // 切换选中状态
    [self toggleFileSelectionAtIndexPath:indexPath];
}

/// 切换文件选中状态
- (void)toggleFileSelectionAtIndexPath:(NSIndexPath *)indexPath {
    NSString *indexPathKey = [self indexPathToString:indexPath];
    FileModel *model = self.filteredFileModels[indexPath.row];
    
    if (self.selectedFiles[indexPathKey]) {
        [self.selectedFiles removeObjectForKey:indexPathKey];
    } else {
        self.selectedFiles[indexPathKey] = model;
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateNavigationRightItems];
}

/// 取消多选
- (void)cancelMultiSelect {
    [self.selectedFiles removeAllObjects];
    [self.tableView reloadData];
    [self updateNavigationRightItems];
}

/// IndexPath 转字符串（作为字典key）
- (NSString *)indexPathToString:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.row];
}

#pragma mark - 文件操作（拷贝/剪切/粘贴/删除）
/// 拷贝选中文件
- (void)actionCopySelectedFiles {
    self.operationMode = OperationModeCopy;
    [self showToast:@"已拷贝选中文件"];
    [self cancelMultiSelect];
    [self updateNavigationRightItems];
}

/// 剪切选中文件
- (void)actionCutSelectedFiles {
    self.operationMode = OperationModeCut;
    [self showToast:@"已剪切选中文件"];
    [self cancelMultiSelect];
    [self updateNavigationRightItems];
}

/// 删除选中文件
- (void)actionDeleteSelectedFiles {
    NSArray<FileModel *> *selectedModels = self.selectedFiles.allValues;
    if (selectedModels.count == 0) return;
    
    [self showDeleteConfirmAlertForFiles:selectedModels completion:^(BOOL confirmed) {
        if (confirmed) {
            NSError *error = nil;
            BOOL allSuccess = YES;
            
            for (FileModel *model in selectedModels) {
                BOOL success = [FileUtils deleteItemAtPath:model.filePath error:&error];
                if (!success) {
                    allSuccess = NO;
                    NSLog(@"删除失败：%@", error.localizedDescription);
                }
            }
            
            if (allSuccess) {
                [self showToast:@"全部删除成功"];
            } else {
                [self showToast:@"部分文件删除失败，请查看日志"];
            }
            
            [self.selectedFiles removeAllObjects];
            [self loadFilesInCurrentDir];
            [self updateNavigationRightItems];
        }
    }];
}

/// 粘贴文件
- (void)actionPasteFiles {
    NSArray<FileModel *> *sourceModels = self.selectedFiles.allValues;
    if (sourceModels.count == 0) {
        [self showToast:@"无待粘贴文件"];
        return;
    }
    
    BOOL allSuccess = YES;
    NSError *error = nil;
    
    for (FileModel *model in sourceModels) {
        BOOL success = NO;
        if (self.operationMode == OperationModeCopy) {
            // 拷贝
            success = [FileUtils copyItemFromPath:model.filePath toTargetDir:self.currentDirPath overwrite:YES error:&error];
        } else if (self.operationMode == OperationModeCut) {
            // 剪切（移动）
            success = [FileUtils moveItemFromPath:model.filePath toTargetDir:self.currentDirPath overwrite:YES error:&error];
        }
        
        if (!success) {
            allSuccess = NO;
            NSLog(@"操作失败：%@", error.localizedDescription);
        }
    }
    
    // 操作完成后重置模式
    self.operationMode = OperationModeNone;
    [self loadFilesInCurrentDir];
    [self updateNavigationRightItems];
    
    if (allSuccess) {
        [self showToast:self.operationMode == OperationModeCopy ? @"全部拷贝成功" : @"全部剪切成功"];
    } else {
        [self showToast:@"部分文件操作失败，请查看日志"];
    }
}

/// 取消操作模式（拷贝/剪切）
- (void)cancelOperationMode {
    self.operationMode = OperationModeNone;
    [self updateNavigationRightItems];
}

/// 关闭
- (void)closeItemTap{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - 目录导航
/// 进入子目录
- (void)pushToSubDir:(NSString *)subDirPath {
    NSLog(@"点击进入子目录:%@",subDirPath);
    [self.navStack addObject:self.currentDirPath];
    self.currentDirPath = subDirPath;
    [self loadFilesInCurrentDir];
    
    // 更新路径标签
    UILabel *pathLabel = [self.tableView.tableHeaderView viewWithTag:100];
    pathLabel.text = self.currentDirPath;
}

/// 返回上级目录
- (void)popToPreviousDir {
    if (self.navStack.count == 0) {
        // 已到根目录，弹出控制器
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    self.currentDirPath = [self.navStack lastObject];
    [self.navStack removeLastObject];
    [self loadFilesInCurrentDir];
    
    // 更新路径标签
    UILabel *pathLabel = [self.tableView.tableHeaderView viewWithTag:100];
    pathLabel.text = self.currentDirPath;
}

#pragma mark - 路径复制
- (void)copyCurrentPath {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.currentDirPath;
    [self showToast:@"路径已复制到剪贴板"];
}

#pragma mark - 文件预览
- (void)previewFile:(FileModel *)model {
    self.previewVC = [[QLPreviewController alloc] init];
    self.previewVC.dataSource = self;
    self.previewVC.delegate = self;
    self.previewVC.currentPreviewItemIndex = 0;
    self.currentPreviewModel = model;
    [self.navigationController pushViewController:self.previewVC animated:YES];
}

// QLPreviewController 数据源
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.currentPreviewModel ? 1 : 0;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    // 🔥 直接使用保存的最新预览模型，不依赖表格选中行self.allFileModels
    NSLog(@"文件预览:%@",self.currentPreviewModel.filePath);
    if (self.currentPreviewModel) {
        return [NSURL fileURLWithPath:self.currentPreviewModel.filePath];
    }
    // 兜底：无模型时返回空（避免崩溃）
    return nil;
}

#pragma mark - 搜索代理
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self filterFilesWithKeyword:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - 弹窗提示
/// 删除确认弹窗
- (void)showDeleteConfirmAlertForFile:(FileModel *)model completion:(void(^)(BOOL confirmed))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:[NSString stringWithFormat:@"是否删除 %@？", model.fileName] preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completion(NO);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        completion(YES);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/// 批量删除确认弹窗
- (void)showDeleteConfirmAlertForFiles:(NSArray<FileModel *> *)models completion:(void(^)(BOOL confirmed))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:[NSString stringWithFormat:@"是否删除选中的 %ld 个项目？", models.count] preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completion(NO);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        completion(YES);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/// 吐司提示
- (void)showToast:(NSString *)message {
    UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:toast animated:YES completion:nil];
    [self performSelector:@selector(dismissToast) withObject:nil afterDelay:1.5];
}

- (void)dismissToast {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
