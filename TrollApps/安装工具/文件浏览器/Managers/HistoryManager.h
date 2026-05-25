//
//  HistoryManager.h
//  SandboxFileManager
//
//  浏览记录管理器 - 单例类，记录文件和目录的浏览历史
//

#import <Foundation/Foundation.h>
#import "FileModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HistoryManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

/// 浏览记录列表（按时间倒序排列）
@property (nonatomic, strong, readonly) NSMutableArray<FileModel *> *historyList;

/// 最大记录数（默认50）
@property (nonatomic, assign) NSInteger maxHistoryCount;

/// 添加浏览记录
/// @param model 文件/目录模型
- (void)addHistory:(FileModel *)model;

/// 移除指定记录
/// @param model 文件/目录模型
- (void)removeHistory:(FileModel *)model;

/// 清空所有记录
- (void)clearHistory;

/// 检查是否已存在记录
/// @param model 文件/目录模型
/// @return 是否已存在
- (BOOL)hasHistory:(FileModel *)model;

/// 获取最近访问的目录列表
/// @return 目录模型列表
- (NSArray<FileModel *> *)recentDirectories;

/// 获取最近访问的文件列表
/// @return 文件模型列表
- (NSArray<FileModel *> *)recentFiles;

@end

NS_ASSUME_NONNULL_END
