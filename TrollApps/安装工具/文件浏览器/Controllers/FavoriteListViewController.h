//
//  FavoriteListViewController.h
//  SandboxFileManager
//
//  收藏列表控制器 - 显示所有收藏的文件
//

#import <UIKit/UIKit.h>
#import "PlistEditorViewController.h"
NS_ASSUME_NONNULL_BEGIN

@class FileListViewController;

/// 收藏列表控制器
@interface FavoriteListViewController : UIViewController

/// 传入的 FileListViewController 引用
@property (nonatomic, weak) FileListViewController *sourceFileListVC;

@end

NS_ASSUME_NONNULL_END
