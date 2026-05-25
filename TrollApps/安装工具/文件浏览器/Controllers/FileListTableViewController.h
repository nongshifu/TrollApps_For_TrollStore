//
//  FileListTableViewController.h
//  SandboxFileManager
//
//  文件列表表格控制器 - 管理单个表格视图
//  处理表格显示、数据源、搜索结果显示等
//

#import <UIKit/UIKit.h>
#import "FileListCell.h"
#import "FileEnum.h"
#import "FileListViewController.h"

@class FileModel;
@class FileListTableViewController;


#pragma mark - FileListTableViewController

/// 文件列表表格控制器
/// 功能：管理单个表格视图，显示文件列表，处理表格交互
@interface FileListTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, FileListCellDelegate>

/// 表格视图
@property (nonatomic, strong) UITableView *tableView;

/// 表格标识符
@property (nonatomic, copy) NSString *identifier;

/// 文件列表数据源
@property (nonatomic, strong) NSMutableArray<FileModel *> *fileList;

/// 父控制器
@property (nonatomic, strong) FileListViewController *fileListViewController;

/// 搜索结果数组
@property (nonatomic, strong) NSMutableArray<FileModel *> *searchResults;

/// 是否显示搜索结果
@property (nonatomic, assign) BOOL isShowingSearchResults;

/// 是否显示收藏列表
@property (nonatomic, assign) BOOL isShowFavoriteList;

/// 搜索控制器
@property (nonatomic, strong) UISearchController *searchController;

/// 是否处于批量编辑模式
@property (nonatomic, assign) BOOL isBatchEditing;

/// 空视图（无文件时显示）
@property (nonatomic, strong) UIView *emptyView;

/// 长按手势
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;

/// 当前目录路径
@property (nonatomic, copy) NSString *currentDirPath;

/// 刷新控件
@property (nonatomic, strong) UIRefreshControl *refreshControl;

/// 刚操作的文件路径（用于高亮显示）
@property (nonatomic, copy) NSString *highlightedFilePath;

#pragma mark - 初始化方法

/// 使用标识符初始化
/// @param identifier 表格标识符
/// @return 实例对象
- (instancetype)initWithIdentifier:(NSString *)identifier;

#pragma mark - 公共方法

/// 刷新文件列表
- (void)refreshFileList;

/// 更新空视图显示状态
- (void)updateEmptyView;

/// 重新加载数据
- (void)reloadData;

/// 排序列表
- (void)sortFileList;

@end
