//
//  FileOperationToolbar.h
//  SandboxFileManager
//
//  文件操作悬浮工具栏
//  用于选择模式下显示各种操作按钮
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FileOperationAction) {
    FileOperationActionCopy,          // 拷贝
    FileOperationActionMove,          // 移动
    FileOperationActionDelete,        // 删除
    FileOperationActionRename,        // 重命名
    FileOperationActionCompress,      // 压缩
    FileOperationActionFavorite,      // 收藏
    FileOperationActionRemoveFavorite,      // 取消收藏
    FileOperationActionMore,          // 更多
    FileOperationActionDone           // 完成
};

@class FileOperationToolbar;

@protocol FileOperationToolbarDelegate <NSObject>
@required
- (void)toolbar:(FileOperationToolbar *)toolbar didSelectAction:(FileOperationAction)action;
@end

@interface FileOperationToolbar : UIView

@property (nonatomic, weak) id<FileOperationToolbarDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedCount; // 选中文件数量
@property (nonatomic, assign) BOOL showsDoneButton;    // 是否显示完成按钮

/// 创建工具栏
+ (instancetype)toolbar;

/// 显示工具栏（从底部滑入）
- (void)showInView:(UIView *)view animated:(BOOL)animated;

/// 隐藏工具栏
- (void)hideAnimated:(BOOL)animated;

/// 更新选中数量显示
- (void)updateSelectedCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
