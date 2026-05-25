//
//  WindowManager.h
//  SandboxFileManager
//
//  窗口管理器 - 单例类，管理多个文件浏览窗口
//

#import <Foundation/Foundation.h>
#import "FileListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WindowManagerDelegate <NSObject>
- (void)windowManagerDidAddWindow:(FileListViewController *)windowVC;
- (void)windowManagerDidRemoveWindow:(FileListViewController *)windowVC;
- (void)windowManagerDidSwitchToWindow:(FileListViewController *)windowVC;
@end

@interface WindowManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

/// 当前活动窗口
@property (nonatomic, weak, readonly) FileListViewController *currentWindow;

/// 所有窗口列表
@property (nonatomic, strong, readonly) NSArray<FileListViewController *> *allWindows;

/// 窗口数量
@property (nonatomic, assign, readonly) NSInteger windowCount;

/// 代理
@property (nonatomic, weak) id<WindowManagerDelegate> delegate;

/// 创建新窗口
/// @param path 初始目录路径
/// @return 新创建的窗口控制器
- (FileListViewController *)createWindowWithPath:(NSString *)path;

/// 切换到指定窗口
/// @param windowVC 目标窗口控制器
- (void)switchToWindow:(FileListViewController *)windowVC;

/// 切换到指定索引的窗口
/// @param index 窗口索引
- (void)switchToWindowAtIndex:(NSInteger)index;

/// 关闭指定窗口
/// @param windowVC 要关闭的窗口控制器
- (void)closeWindow:(FileListViewController *)windowVC;

/// 关闭指定索引的窗口
/// @param index 窗口索引
- (void)closeWindowAtIndex:(NSInteger)index;

/// 关闭所有窗口
- (void)closeAllWindows;

/// 获取窗口索引
/// @param windowVC 窗口控制器
/// @return 索引位置
- (NSInteger)indexOfWindow:(FileListViewController *)windowVC;

#pragma mark - 持久化存储

/// 保存窗口状态到本地
- (void)saveWindowState;

/// 从本地加载窗口状态
/// @return 是否成功加载
- (BOOL)loadWindowState;

@end

NS_ASSUME_NONNULL_END