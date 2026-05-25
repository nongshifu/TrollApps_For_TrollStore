//
//  WindowSwitcherViewController.h
//  SandboxFileManager
//
//  窗口切换器视图控制器
//  使用横向滚动的 UICollectionView 显示窗口卡片
//
//

#import <UIKit/UIKit.h>

@class FileListTableViewController;
@class WindowSwitcherViewController;
@class DockFlowLayout;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - WindowSwitcherViewControllerDelegate

@protocol WindowSwitcherViewControllerDelegate <NSObject>

@optional

/// 选择了某个窗口
/// @param switcher 窗口切换器
/// @param viewController 选中的视图控制器
/// @param index 选中的索引
- (void)windowSwitcher:(WindowSwitcherViewController *)switcher didSelectViewController:(FileListTableViewController *)viewController atIndex:(NSInteger)index;

/// 关闭了窗口切换器
/// @param switcher 窗口切换器
- (void)windowSwitcherDidClose:(WindowSwitcherViewController *)switcher;

/// 关闭了某个窗口
/// @param switcher 窗口切换器
/// @param viewController 被关闭的视图控制器
/// @param index 被关闭的索引
- (void)windowSwitcher:(WindowSwitcherViewController *)switcher didCloseViewController:(FileListTableViewController *)viewController atIndex:(NSInteger)index;

/// 添加新窗口
/// @param switcher 窗口切换器
- (void)windowSwitcherDidRequestAddNewWindow:(WindowSwitcherViewController *)switcher;

@end

#pragma mark - WindowSwitcherViewController

@interface WindowSwitcherViewController : UIViewController

#pragma mark - 初始化

/// 使用窗口信息数组初始化
/// @param infos 窗口信息数组，每个字典包含 title、path、windowIndex
/// @param currentIndex 当前选中索引
- (instancetype)initWithWindowInfos:(NSArray<NSDictionary *> *)infos currentIndex:(NSInteger)currentIndex;

/// 使用窗口控制器数组初始化（已废弃）
/// @param controllers 窗口控制器数组
/// @param currentIndex 当前选中索引
- (instancetype)initWithWindowControllers:(NSArray<FileListTableViewController *> *)controllers currentIndex:(NSInteger)currentIndex NS_DEPRECATED_IOS(1_0, 1_0);

#pragma mark - 数据源

/// 更新窗口数据
/// @param infos 新的窗口信息数组
/// @param currentIndex 新的当前索引
- (void)updateWithWindowInfos:(NSArray<NSDictionary *> *)infos currentIndex:(NSInteger)currentIndex;

/// 更新窗口数据（已废弃）
/// @param controllers 新的窗口控制器数组
/// @param currentIndex 新的当前索引
- (void)updateWithWindowControllers:(NSArray<FileListTableViewController *> *)controllers currentIndex:(NSInteger)currentIndex NS_DEPRECATED_IOS(1_0, 1_0);

#pragma mark - 代理

/// 代理
@property (nonatomic, weak) id<WindowSwitcherViewControllerDelegate> delegate;

#pragma mark - 滚动位置

/// 上次滚动位置（用于记忆）
@property (nonatomic, assign) CGFloat lastContentOffsetX;

/// 窗口信息数组（只读）
@property (nonatomic, readonly) NSArray<NSDictionary *> *windowInfos;

@end

NS_ASSUME_NONNULL_END
