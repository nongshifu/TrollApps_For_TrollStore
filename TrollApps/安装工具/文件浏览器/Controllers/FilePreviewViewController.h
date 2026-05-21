//
//  FilePreviewViewController.h
//  SandboxFileManager
//
//  文件预览控制器 - 支持图片、视频、文档等多种文件类型的预览
//

#import <UIKit/UIKit.h>
#import "PlistEditorViewController.h"
NS_ASSUME_NONNULL_BEGIN

@class FileModel;

/// 文件预览控制器
@interface FilePreviewViewController : UIViewController

/// 当前文件模型
@property (nonatomic, strong) FileModel *currentModel;

/// 文件列表数组（用于横向滚动切换）
@property (nonatomic, strong) NSArray<FileModel *> *fileList;

/// 当前索引
@property (nonatomic, assign) NSInteger currentIndex;

/// 是否从操作按钮进入（NO表示从点击进入）
@property (nonatomic, assign) BOOL fromActionButton;

/// 当前目录路径
@property (nonatomic, copy) NSString *currentDirPath;

@end

NS_ASSUME_NONNULL_END
