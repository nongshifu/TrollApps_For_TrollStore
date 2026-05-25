//
//  WindowCardCell.h
//  SandboxFileManager
//
//  窗口卡片单元格
//
//

#import <UIKit/UIKit.h>

@class FileListTableViewController, WindowCardCell;

NS_ASSUME_NONNULL_BEGIN

@protocol WindowCardCellDelegate <NSObject>

@optional
/// 卡片即将被关闭
- (void)windowCardCellWillClose:(WindowCardCell *)cell;

@end

@interface WindowCardCell : UICollectionViewCell

/// 代理
@property (nonatomic, weak) id<WindowCardCellDelegate> delegate;

/// 配置窗口卡片
/// @param viewController 窗口控制器
/// @param isActive 是否为当前活动窗口
- (void)configureWithViewController:(FileListTableViewController *)viewController isActive:(BOOL)isActive;

/// 配置窗口卡片（使用标题和路径）
/// @param title 窗口标题
/// @param path 窗口路径
/// @param isActive 是否为当前活动窗口
- (void)configureWithTitle:(NSString *)title path:(NSString *)path isActive:(BOOL)isActive;

/// 配置窗口卡片（使用标题、路径和截图）
/// @param title 窗口标题
/// @param path 窗口路径
/// @param snapshot 窗口截图
/// @param isActive 是否为当前活动窗口
- (void)configureWithTitle:(NSString *)title path:(NSString *)path snapshot:(UIImage *)snapshot isActive:(BOOL)isActive;

@end

NS_ASSUME_NONNULL_END
