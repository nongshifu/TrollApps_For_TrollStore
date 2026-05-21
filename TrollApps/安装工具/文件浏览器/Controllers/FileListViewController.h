//
//  FileListViewController.h
//  SandboxFileManager
//
//  沙盒文件管理器 - 文件列表视图控制器
//  负责显示文件列表、搜索、排序、批量选择等核心功能
//

#import <UIKit/UIKit.h>
#import "FileManagerDelegate.h"
#import "FileEnum.h"
#import "FileListCell.h"
#import "PlistEditorViewController.h"

@class FileModel;

#pragma mark - FileListViewController

/// 文件列表视图控制器
/// 功能：显示文件列表、搜索、排序、收藏、批量选择、文件操作等
@interface FileListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, FileListCellDelegate, FileManagerDelegate, UISearchControllerDelegate>

#pragma mark - UI组件

/// 文件列表表格视图
@property (nonatomic, strong) UITableView *tableView;

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

/// 底部工具栏视图
@property (nonatomic, strong) UIView *bottomToolbar;

/// 路径显示按钮（底部）
@property (nonatomic, strong) UIButton *pathButton;

/// 统计信息视图（文件夹数量、文件数量、总大小）
@property (nonatomic, strong) UILabel *statisticsLabel;

/// 筛选按钮（文件夹/全部）
@property (nonatomic, strong) UIButton *filterButton;

/// 收藏按钮
@property (nonatomic, strong) UIButton *favoriteButton;

/// 底部按钮滚动视图（包含排序按钮）
@property (nonatomic, strong) UIScrollView *bottomButtonScrollView;

/// 底部功能按钮数组（统一管理）
@property (nonatomic, strong) NSMutableArray<UIButton *> *bottomButtons;

/// 按名称排序按钮
@property (nonatomic, strong) UIButton *sortNameButton;

/// 按类型排序按钮
@property (nonatomic, strong) UIButton *sortTypeButton;

/// 按日期排序按钮
@property (nonatomic, strong) UIButton *sortDateButton;

/// 按大小排序按钮
@property (nonatomic, strong) UIButton *sortSizeButton;

/// 空视图（无文件时显示）
@property (nonatomic, strong) UIView *emptyView;

#pragma mark - 文件目录属性

/// 当前沙盒目录类型
@property (nonatomic, assign) SandboxDirectoryType currentSandboxDir;

/// 当前目录路径
@property (nonatomic, copy) NSString *currentDirPath;

/// 当前显示类型（全部/仅文件夹）
@property (nonatomic, assign) DisplayType currentDisplayType;

#pragma mark - 状态标记

/// 是否处于批量编辑模式
@property (nonatomic, assign) BOOL isBatchEditing;

/// 是否显示收藏列表
@property (nonatomic, assign) BOOL isShowFavoriteList;

/// 是否仅搜索当前目录
@property (nonatomic, assign) BOOL searchCurrentDirectoryOnly;

/// 当前排序类型（0:名称 1:类型 2:日期 3:大小）
@property (nonatomic, assign) FileSortType currentSortType;

/// 是否升序排列
@property (nonatomic, assign) BOOL isSortAscending;

#pragma mark - 数据源

/// 文件列表数据源
@property (nonatomic, strong) NSMutableArray<FileModel *> *fileList;

/// 已选择的文件列表（批量操作时使用）
@property (nonatomic, strong) NSMutableArray<FileModel *> *selectedFileList;

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

/// 导航到指定目录
/// @param directoryPath 目标目录路径
- (void)navigateToDirectory:(NSString *)directoryPath;

/// 设置空视图
- (void)setupEmptyView;

/// 设置初始路径（在viewDidLoad之前调用）
/// @param path 目录路径
- (void)setInitialPath:(NSString *)path;

/// 设置初始沙盒目录类型和子路径
/// @param directoryType 沙盒目录类型
/// @param subPath 子路径
- (void)setInitialSandboxDirectory:(SandboxDirectoryType)directoryType subPath:(NSString *)subPath;

@end
