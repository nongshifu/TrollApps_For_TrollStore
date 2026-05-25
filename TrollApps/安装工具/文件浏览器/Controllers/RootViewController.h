//
//  RootViewController.h
//  SandboxFileManager
//
//  根控制器 - 管理底部标签栏和多窗口切换
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RootViewController : UITabBarController

/// 创建并返回根控制器实例
+ (instancetype)rootController;

/// 是否处于编辑模式
@property (nonatomic, assign) BOOL isEditMode;

/// 文件浏览导航控制器
@property (nonatomic, strong, readonly) UINavigationController *browserNavController;

/// 切换到文件浏览标签
- (void)switchToFileBrowser;

/// 切换到历史记录标签
- (void)switchToHistory;

/// 切换到收藏标签
- (void)switchToFavorites;

/// 切换到回收站标签
- (void)switchToRecycleBin;

/// 切换到窗口管理标签
- (void)switchToWindowManager;

/// 打开新的文件浏览窗口
/// @param path 初始目录路径
- (void)openNewWindowWithPath:(NSString *)path;

/// 进入编辑模式（显示操作工具栏）
- (void)enterEditMode;

/// 退出编辑模式（显示正常标签栏）
- (void)exitEditMode;

/// 更新底部按钮统计
- (void)updateSelectionCount;



@end

NS_ASSUME_NONNULL_END
