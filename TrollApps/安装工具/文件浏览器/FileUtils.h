//
//  FileUtils.h
//  TrollApps
//
//  Created by 十三哥 on 2025/11/29.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileUtils : NSObject
/// 复制文件/文件夹
/// @param sourcePath 源路径
/// @param targetPath 目标路径（父目录）
/// @param overwrite 是否覆盖已存在文件
+ (BOOL)copyItemFromPath:(NSString *)sourcePath toTargetDir:(NSString *)targetPath overwrite:(BOOL)overwrite error:(NSError **)error;

/// 移动文件/文件夹
/// @param sourcePath 源路径
/// @param targetPath 目标路径（父目录）
/// @param overwrite 是否覆盖已存在文件
+ (BOOL)moveItemFromPath:(NSString *)sourcePath toTargetDir:(NSString *)targetPath overwrite:(BOOL)overwrite error:(NSError **)error;

/// 删除文件/文件夹
/// @param filePath 文件路径
+ (BOOL)deleteItemAtPath:(NSString *)filePath error:(NSError **)error;

/// 获取沙盒根目录（Documents/Library/Caches）
+ (NSArray<NSString *> *)getSandboxRootPaths;

/// 格式化日期（yyyy-MM-dd HH:mm）
+ (NSString *)formatDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
