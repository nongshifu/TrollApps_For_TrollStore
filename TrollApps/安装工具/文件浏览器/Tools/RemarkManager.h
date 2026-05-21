//
//  RemarkManager.h
//  SandboxFileManager
//
//  备注管理器 - 负责文件备注的持久化存储
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RemarkManager : NSObject

/// 获取单例
+ (instancetype)sharedManager;

/// 保存备注
/// @param remark 备注内容
/// @param filePath 文件路径（作为唯一标识）
- (void)saveRemark:(NSString *)remark forFilePath:(NSString *)filePath;

/// 获取备注
/// @param filePath 文件路径
- (NSString *)getRemarkForFilePath:(NSString *)filePath;

/// 删除备注
/// @param filePath 文件路径
- (void)deleteRemarkForFilePath:(NSString *)filePath;

/// 清空所有备注
- (void)clearAllRemarks;

@end

NS_ASSUME_NONNULL_END
