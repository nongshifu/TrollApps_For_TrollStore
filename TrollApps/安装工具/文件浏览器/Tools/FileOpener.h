//
//  FileOpener.h
//  SandboxFileManager
//
//  文件打开管理器
//  根据文件类型决定如何打开文件
//

#import <UIKit/UIKit.h>
#import "FileModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileOpener : NSObject

/**
 单例方法
 */
+ (instancetype)sharedOpener;

/**
 根据 FileModel 打开文件
 
 @param model 文件模型
 @param viewController 从哪个控制器打开
 */
- (void)openFileWithModel:(FileModel *)model fromViewController:(UIViewController *)viewController;

/**
 根据 FileModel 打开文件（指定当前文件列表和索引，用于预览时的左右滑动）
 
 @param model 文件模型
 @param fileList 当前文件列表
 @param currentIndex 当前文件索引
 @param currentDirPath 当前目录路径
 @param viewController 从哪个控制器打开
 */
- (void)openFileWithModel:(FileModel *)model
                fileList:(NSArray<FileModel *> *)fileList
             currentIndex:(NSInteger)currentIndex
          currentDirPath:(NSString *)currentDirPath
         fromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
