//
//  CommandExecutor.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CommandResult) {
    CommandResultSuccess = 0,
    CommandResultFailure,
    CommandResultFileNotFound,
    CommandResultPermissionDenied
};

@interface CommandExecutor : NSObject


/// 单例
+ (instancetype)shared;

/// 查找内置二进制工具的路径（如 ldid、install_name_tool）
- (NSString *)pathForExecutable:(NSString *)name;

/// 执行命令（普通用户权限）
- (CommandResult)executeCommand:(NSString *)command
                      arguments:(NSArray<NSString *> *)arguments
                          output:(NSString **)output
                           error:(NSString **)errorMsg;

/// 执行命令（root 权限，需越狱环境）
- (CommandResult)executeRootCommand:(NSString *)command
                          arguments:(NSArray<NSString *> *)arguments
                              output:(NSString **)output
                               error:(NSString **)errorMsg;

#pragma mark - 常用命令封装

/// 复制文件（cp）
- (BOOL)copyFrom:(NSString *)srcPath to:(NSString *)destPath overwrite:(BOOL)overwrite error:(NSError **)error;

/// 移动文件（mv）
- (BOOL)moveFrom:(NSString *)srcPath to:(NSString *)destPath overwrite:(BOOL)overwrite error:(NSError **)error;

/// 删除文件（rm）
- (BOOL)removePath:(NSString *)path recursively:(BOOL)recursive error:(NSError **)error;

/// 伪签名（ldid）
- (BOOL)pseudoSignFile:(NSString *)filePath force:(BOOL)force error:(NSError **)error;

/// 注入动态库（insert_dylib）
- (BOOL)insertDylib:(NSString *)dylibPath intoMachO:(NSString *)machOPath weak:(BOOL)weak error:(NSError **)error;


@end

NS_ASSUME_NONNULL_END
