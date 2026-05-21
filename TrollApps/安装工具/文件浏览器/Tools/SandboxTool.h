//
//  SandboxTool.h
//  SandboxFileManager
//
//  沙盒目录工具类
//

#import <Foundation/Foundation.h>
#import "FileEnum.h"
#import "FileModel.h"

#pragma mark - SandboxTool

/// 沙盒目录工具类
/// 提供沙盒文件系统的路径获取和文件列表查询功能
@interface SandboxTool : NSObject

#pragma mark - 路径获取

/// 获取沙盒目录路径
/// @param directoryType 目录类型
/// @return 目录完整路径
+ (NSString *)getSandboxDirectoryPath:(SandboxDirectoryType)directoryType;

#pragma mark - 文件列表

/// 获取目录下第一层文件路径数组
/// @param dirPath 目录路径
/// @param displayType 显示类型（全部/仅文件夹）
/// @return 文件路径数组
+ (NSArray<NSString *> *)getFirstLevelFilesWithDirPath:(NSString *)dirPath displayType:(DisplayType)displayType;

/// 获取目录下第一层文件模型数组
/// @param dirPath 目录路径
/// @param displayType 显示类型（全部/仅文件夹）
/// @return 文件模型数组
+ (NSArray<FileModel *> *)getFirstLevelFileModelsWithDirPath:(NSString *)dirPath displayType:(DisplayType)displayType;

#pragma mark - 隐藏文件

/// 获取隐藏文件名列表
/// @return 隐藏文件名数组
+ (NSArray<NSString *> *)getHiddenFileNames;

@end
