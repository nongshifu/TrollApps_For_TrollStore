//
//  FileOperateTool.h
//  SandboxFileManager
//
//  文件操作工具类
//

#import <Foundation/Foundation.h>

#pragma mark - FileOperateTool

/// 文件操作工具类
/// 提供基础的文件系统操作：创建、删除、重命名、复制、移动
@interface FileOperateTool : NSObject

#pragma mark - 创建

/// 创建文件夹
/// @param folderName 文件夹名称
/// @param parentPath 父目录路径
/// @return YES表示创建成功
+ (BOOL)createFolderWithName:(NSString *)folderName atPath:(NSString *)parentPath;

/// 创建文件
/// @param fileName 文件名称
/// @param parentPath 父目录路径
/// @return YES表示创建成功
+ (BOOL)createFileWithName:(NSString *)fileName atPath:(NSString *)parentPath;

#pragma mark - 删除

/// 删除文件或文件夹
/// @param path 文件/文件夹路径
/// @return YES表示删除成功
+ (BOOL)deleteItemAtPath:(NSString *)path;

#pragma mark - 重命名

/// 重命名文件或文件夹
/// @param path 原路径
/// @param newName 新名称
/// @return YES表示重命名成功
+ (BOOL)renameItemAtPath:(NSString *)path newName:(NSString *)newName;

#pragma mark - 复制

/// 复制文件或文件夹
/// @param srcPath 源路径
/// @param destPath 目标路径
/// @return YES表示复制成功
+ (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath;

#pragma mark - 移动

/// 移动文件或文件夹
/// @param srcPath 源路径
/// @param destPath 目标路径
/// @return YES表示移动成功
+ (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath;

#pragma mark - 批量修改后缀

/// 批量修改后缀（仅当前目录）
/// @param folderPath 文件夹路径
/// @param oldExtension 原后缀名（无需带点）
/// @param newExtension 新后缀名（无需带点）
/// @return 成功修改的文件数量
+ (NSInteger)batchChangeExtensionInFolder:(NSString *)folderPath
                               oldExtension:(NSString *)oldExtension
                               newExtension:(NSString *)newExtension;

/// 批量修改后缀（递归遍历所有子目录）
/// @param folderPath 文件夹路径
/// @param oldExtension 原后缀名（无需带点）
/// @param newExtension 新后缀名（无需带点）
/// @return 成功修改的文件数量
+ (NSInteger)batchChangeExtensionRecursiveInFolder:(NSString *)folderPath
                                      oldExtension:(NSString *)oldExtension
                                      newExtension:(NSString *)newExtension;

#pragma mark - 批量删除

/// 批量删除指定后缀文件（仅当前目录）
/// @param folderPath 文件夹路径
/// @param extension 后缀名（无需带点）
/// @return 成功删除的文件数量
+ (NSInteger)batchDeleteFilesInFolder:(NSString *)folderPath
                            extension:(NSString *)extension;

/// 批量删除指定后缀文件（递归遍历所有子目录）
/// @param folderPath 文件夹路径
/// @param extension 后缀名（无需带点）
/// @return 成功删除的文件数量
+ (NSInteger)batchDeleteFilesRecursiveInFolder:(NSString *)folderPath
                                      extension:(NSString *)extension;

@end
