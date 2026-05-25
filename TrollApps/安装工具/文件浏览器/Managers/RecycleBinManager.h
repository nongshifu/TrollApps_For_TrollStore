//
//  RecycleBinManager.h
//  SandboxFileManager
//
//  回收站管理器 - 单例类，管理删除的文件和目录
//

#import <Foundation/Foundation.h>
#import "FileModel.h"
#import "RecycleBinManager.h"
@class RecycleBinItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RecycleBinRestoreConflictOption) {
    RecycleBinRestoreConflictOptionRename,    // 重命名恢复
    RecycleBinRestoreConflictOptionOverwrite  // 覆盖原文件
};

typedef void(^RecycleBinRestoreConflictHandler)(RecycleBinItem *item, NSString *conflictingPath, void(^completionHandler)(RecycleBinRestoreConflictOption option));

@interface RecycleBinItem : NSObject

/// 文件模型
@property (nonatomic, strong) FileModel *fileModel;

/// 删除时间
@property (nonatomic, strong) NSDate *deletedDate;

/// 原始路径
@property (nonatomic, strong) NSString *originalPath;

/// 转换为字典
- (NSDictionary *)toDictionary;

/// 从字典初始化
+ (instancetype)itemWithDictionary:(NSDictionary *)dict;

@end

@interface RecycleBinManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

/// 是否启用回收站
@property (nonatomic, assign, getter=isRecycleBinEnabled) BOOL recycleBinEnabled;

/// 回收站中的项目列表（按删除时间倒序排列）
@property (nonatomic, strong) NSMutableArray<RecycleBinItem *> *recycleBinItems;



/// 回收站项目数量
@property (nonatomic, assign, readonly) NSInteger itemCount;

/// 回收站大小（字节）
@property (nonatomic, assign, readonly) unsigned long long totalSize;

/// 返回所有项目
- (NSArray<RecycleBinItem *> *)allRecycleBinItems;

/// 将文件移动到回收站
/// @param model 文件/目录模型
/// @return 是否成功
- (BOOL)moveToRecycleBin:(FileModel *)model;

/// 将文件模型数组移动到回收站
/// @param models 文件/目录模型数组
- (void)moveFileModelsToRecycleBin:(NSArray <FileModel *>*)models;

/// 从回收站恢复文件
/// @param item 回收站项目
/// @return 是否成功
- (BOOL)restoreItem:(RecycleBinItem *)item;

/// 从回收站恢复文件（带冲突处理）
/// @param item 回收站项目
/// @param conflictHandler 冲突处理回调，如果为 nil 则行为与 restoreItem: 相同
/// @return 是否成功（如果是异步操作会立即返回 YES）
- (BOOL)restoreItem:(RecycleBinItem *)item withConflictHandler:(nullable RecycleBinRestoreConflictHandler)conflictHandler;

/// 检查恢复目标是否已存在
/// @param item 回收站项目
/// @return 冲突路径，如果返回 nil 表示没有冲突
- (nullable NSString *)checkRestoreConflictForItem:(RecycleBinItem *)item;

/// 从回收站恢复所有文件
/// @return 恢复的数量
- (NSInteger)restoreAllItems;

/// 从回收站删除文件（彻底删除）
/// @param item 回收站项目
/// @return 是否成功
- (BOOL)deleteItem:(RecycleBinItem *)item;

/// 清空回收站
/// @return 删除的数量
- (NSInteger)emptyRecycleBin;

/// 获取回收站路径
- (NSString *)recycleBinPath;

@end

NS_ASSUME_NONNULL_END
