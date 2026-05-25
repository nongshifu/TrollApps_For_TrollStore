//
//  FileSelectionManager.h
//  SandboxFileManager
//
//  文件勾选管理器 - 单例类，统一管理文件勾选状态
//

#import <Foundation/Foundation.h>
#import "FileModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileSelectionManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

/// 已选中的文件列表
@property (nonatomic, strong, readonly) NSArray<FileModel *> *selectedFiles;

/// 选中文件数量
@property (nonatomic, assign, readonly) NSInteger selectedCount;

/// 添加文件到选中列表
/// @param file 文件模型
- (void)addFile:(FileModel *)file;

/// 从选中列表移除文件
/// @param file 文件模型
- (void)removeFile:(FileModel *)file;

/// 切换文件选中状态
/// @param file 文件模型
/// @return 是否选中
- (BOOL)toggleFileSelection:(FileModel *)file;

/// 检查文件是否已选中
/// @param file 文件模型
/// @return 是否已选中
- (BOOL)isFileSelected:(FileModel *)file;

/// 清空所有选中文件
- (void)clearAllSelections;

/// 选中所有文件
/// @param files 文件列表
- (void)selectAllFiles:(NSArray<FileModel *> *)files;

/// 取消选中所有文件
/// @param files 文件列表
- (void)deselectAllFiles:(NSArray<FileModel *> *)files;

@end

NS_ASSUME_NONNULL_END