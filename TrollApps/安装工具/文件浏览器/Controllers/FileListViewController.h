//
//  FileListViewController.h
//  SandboxFileManager
//
//  文件列表视图控制器 - 父容器
//  使用 UIPageViewController 管理多个 FileListTableViewController 页面
//

#import <UIKit/UIKit.h>
#import "FileManagerDelegate.h"
#import "FileEnum.h"
#import "FileOperationToolbar.h"


@class FileModel;
@class FileListTableViewController;
@class RootViewController;

#pragma mark - FileListViewController

/// 文件列表视图控制器 - 父容器
/// 功能：管理多个表格页面、导航栏UI、底部按钮布局、页面切换
@interface FileListViewController : UIViewController

#pragma mark - UI组件

/// 固定的表格容器视图
@property (nonatomic, strong) UIView *tableContainerView;

/// 跟视图
@property (nonatomic, strong) RootViewController *rootViewController;

/// 所有表格控制器字典（key为页面标识，value为FileListTableViewController）
@property (nonatomic, strong) NSMutableDictionary<NSString *, FileListTableViewController *> *tableViewControllers;

/// 当前页面标识
@property (nonatomic, copy) NSString *currentPageIdentifier;

/// 所有窗口控制器数组（按顺序排列）
@property (nonatomic, strong) NSMutableArray<FileListTableViewController *> *windowControllers;

/// 当前窗口索引
@property (nonatomic, assign) NSInteger currentWindowIndex;

/// 窗口切换器最后滚动位置
@property (nonatomic, assign) CGFloat windowSwitcherLastOffsetX;

/// 创建文件夹按钮（导航栏左侧）
@property (nonatomic, strong) UIBarButtonItem *createButton;

/// 粘贴按钮（导航栏）
@property (nonatomic, strong) UIBarButtonItem *pasteButton;

/// 关闭按钮（导航栏右侧）
@property (nonatomic, strong) UIBarButtonItem *closeButton;

/// 完成按钮（导航栏右侧）
@property (nonatomic, strong) UIBarButtonItem *completeButton;

/// 收藏按钮（导航栏右侧）
@property (nonatomic, strong) UIBarButtonItem *collectionButton;

/// 搜索控制器
@property (nonatomic, strong) UISearchController *searchController;

/// 搜索结果数组
@property (nonatomic, strong) NSMutableArray<FileModel *> *searchResults;

/// 路径显示按钮（底部）
@property (nonatomic, strong) UIButton *pathButton;

/// 统计信息视图（文件夹数量、文件数量、总大小）
@property (nonatomic, strong) UILabel *statisticsLabel;

/// 底部按钮滚动视图（包含排序按钮）
@property (nonatomic, strong) UIScrollView *bottomButtonScrollView;

/// 底部功能按钮数组（统一管理）
@property (nonatomic, strong) NSMutableArray<UIButton *> *bottomButtons;

/// 左侧操作按钮（圆形）
@property (nonatomic, strong) UIButton *leftActionButton;

/// 是否显示左侧操作按钮
@property (nonatomic, assign) BOOL showingLeftActionButton;

/// 上一级目录截图显示视图（用于右滑返回动画）
@property (nonatomic, strong) UIImageView *parentSnapshotView;

/// 是否正在进行滑动返回操作
@property (nonatomic, assign) BOOL isSlidingBack;

/// 临时文件列表（用于生成上层目录截图）
@property (nonatomic, strong) NSMutableArray *tempSnapshotFiles;

#pragma mark - 文件目录属性

/// 当前沙盒目录类型
@property (nonatomic, assign) SandboxDirectoryType currentSandboxDir;

/// 当前目录路径
@property (nonatomic, copy) NSString *currentDirPath;

/// 当前显示类型（全部/仅文件夹）
@property (nonatomic, assign) DisplayType currentDisplayType;

@property (nonatomic, strong) FileListTableViewController *currentVC;

#pragma mark - 状态标记

/// 是否处于批量编辑模式
@property (nonatomic, assign) BOOL isBatchEditing;

/// 是否为文件选择器模式
@property (nonatomic, assign) BOOL isFilePickerMode;

/// 是否允许多选
@property (nonatomic, assign) BOOL allowsMultipleSelection;

/// 是否显示悬浮工具栏
@property (nonatomic, assign) BOOL showsFloatingToolbar;

/// 是否显示收藏列表
@property (nonatomic, assign) BOOL isShowFavoriteList;

/// 是否仅搜索当前目录
@property (nonatomic, assign) BOOL searchCurrentDirectoryOnly;

/// 当前排序类型（0:名称 1:类型 2:日期 3:大小）
@property (nonatomic, assign) NSInteger currentSortType;

/// 是否升序排列
@property (nonatomic, assign) BOOL isSortAscending;

#pragma mark - 窗口管理属性

/// 窗口索引（多窗口模式下使用）
@property (nonatomic, assign) NSInteger windowIndex;

/// 窗口截图（用于窗口管理卡片显示）
@property (nonatomic, strong) UIImage *windowSnapshot;

/// 是否显示历史记录模式
@property (nonatomic, assign) BOOL showHistoryMode;

/// 是否显示收藏模式
@property (nonatomic, assign) BOOL showFavoritesMode;

#pragma mark - 数据源

/// 文件列表数据源
@property (nonatomic, strong) NSMutableArray<FileModel *> *fileList;

/// 收藏列表数据源
@property (nonatomic, strong) NSMutableArray<FileModel *> *favoriteFileList;

/// 剪贴板文件列表（复制/剪切操作）
@property (nonatomic, strong) NSMutableArray<FileModel *> *clipboardFileList;

/// 是否为复制操作（YES:复制 NO:移动）
@property (nonatomic, assign) BOOL isCopyOperation;

#pragma mark - 代理

/// 文件管理器代理
@property (nonatomic, assign) id<FileManagerDelegate> delegate;

#pragma mark - 初始化方法

/// 使用默认初始化（Documents目录）
/// @return 实例对象
- (instancetype)init;

/// 使用完整路径初始化
/// @param fullPath 完整目录路径
/// @return 实例对象
- (instancetype)initWithFullPath:(NSString *)fullPath;

/// 使用沙盒目录类型初始化
/// @param directoryType 沙盒目录类型
/// @return 实例对象
- (instancetype)initWithSandboxDirectory:(SandboxDirectoryType)directoryType;

/// 使用沙盒目录类型 + 子路径初始化
/// @param directoryType 沙盒目录类型
/// @param subPath 子路径（相对于沙盒目录，可为nil）
/// @return 实例对象
- (instancetype)initWithSandboxDirectory:(SandboxDirectoryType)directoryType subPath:(NSString *)subPath;

#pragma mark - 公共方法

/// 导航到指定路径
/// @param path 目标目录路径
- (void)navigateToPath:(NSString *)path;

/// 刷新文件列表
- (void)refreshFileList;

/// 进入批量编辑模式
- (void)enterBatchEditMode;

/// 退出批量编辑模式
- (void)exitBatchEditMode;

/// 更新选择统计按钮
- (void)updateSelectionCountButton;

/// 窗口切换
- (void)showWindowSwitcher;

/// 生成当前窗口的截图
- (void)takeWindowSnapshot;

/// 导航到指定目录
/// @param directoryPath 目标目录路径
- (void)navigateToDirectory:(NSString *)directoryPath;

/// 设置初始路径（在viewDidLoad之前调用）
/// @param path 目录路径
- (void)setInitialPath:(NSString *)path;

/// 设置初始沙盒目录类型和子路径
/// @param directoryType 沙盒目录类型
/// @param subPath 子路径
- (void)setInitialSandboxDirectory:(SandboxDirectoryType)directoryType subPath:(NSString *)subPath;

#pragma mark - 页面管理方法

/// 注册一个表格页面控制器
/// @param viewController 表格页面控制器
/// @param identifier 页面标识
- (void)registerTableViewController:(FileListTableViewController *)viewController withIdentifier:(NSString *)identifier;

/// 切换到指定页面
/// @param identifier 页面标识
- (void)switchToPageWithIdentifier:(NSString *)identifier;

/// 移除指定页面
/// @param identifier 页面标识
- (void)removePageWithIdentifier:(NSString *)identifier;

/// 获取当前活跃的表格控制器
/// @return 当前活跃的表格控制器
- (FileListTableViewController *)currentTableViewController;

/// 获取指定标识的表格控制器
/// @param identifier 页面标识
/// @return 表格控制器
- (FileListTableViewController *)tableViewControllerWithIdentifier:(NSString *)identifier;


// 底部功能条的点击
- (void)didSelectAction:(FileOperationAction)action;

@end
