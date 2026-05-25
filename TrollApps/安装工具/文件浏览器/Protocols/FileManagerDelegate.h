//
//  FileManagerDelegate.h
//  SandboxFileManager
//
//  文件管理器代理协议
//  用于FileListViewController与外部控制器通信
//

#import <Foundation/Foundation.h>

@class FileModel;

#ifndef FileManagerDelegate_h
#define FileManagerDelegate_h

#pragma mark - FileManagerDelegate

/// 文件管理器代理协议
/// 实现此协议以接收文件管理器的各种事件回调
@protocol FileManagerDelegate <NSObject>

@required

/// 点击文件/文件夹时调用
/// @param itemModel 文件模型
/// @param itemName 文件名
/// @param currentDirPath 当前所在目录路径
- (void)fileManagerDidClickItem:(FileModel *)itemModel itemName:(NSString *)itemName currentDirPath:(NSString *)currentDirPath;

/// 文件列表发生变化时调用（如创建、删除、重命名、移动文件等）
- (void)fileManagerDidChangeFileList;

@optional

/// 文件管理器关闭时调用
/// @param selectedFiles 关闭前选中的文件数组
/// @param currentDirPath 关闭时所在的目录路径
/// @param controller 文件管理器控制器实例
- (void)fileManagerDidCloseWithSelectedFiles:(NSArray<FileModel *> *)selectedFiles currentDirPath:(NSString *)currentDirPath controller:(UIViewController *)controller;

/// 进入目录时调用
/// @param directoryPath 进入的目录路径
- (void)fileManagerDidEnterDirectory:(NSString *)directoryPath;

/// 退出目录时调用
- (void)fileManagerDidExitDirectory;

@end

#endif
