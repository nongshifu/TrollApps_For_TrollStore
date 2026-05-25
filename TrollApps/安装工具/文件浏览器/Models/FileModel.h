//
//  FileModel.h
//  SandboxFileManager
//
//  文件模型 - 表示一个文件或文件夹
//

#import <Foundation/Foundation.h>
#import "FileEnum.h"

#pragma mark - FileModel

/// 文件模型
/// 用于表示文件系统中的文件或文件夹
@interface FileModel : NSObject

#pragma mark - 基本属性

/// 文件名（含扩展名）
@property (nonatomic, copy) NSString *fileName;

/// 文件完整路径
@property (nonatomic, copy) NSString *filePath;

/// 父目录路径
@property (nonatomic, copy) NSString *parentDirPath;

/// 文件类型（文件夹/文件）
@property (nonatomic, assign) FileItemType itemType;

/// 文件大小（字节）
@property (nonatomic, assign) unsigned long long fileSize;

/// 文件修改日期
@property (nonatomic, copy) NSDate *modificationDate;

/// 最后访问时间（用于历史记录）
@property (nonatomic, copy) NSDate *lastAccessTime;

/// 备注
@property (nonatomic, copy) NSString *remark;

/// 拓展
@property (nonatomic, strong) NSObject * expand;

#pragma mark - 状态标记

/// 是否已收藏
@property (nonatomic, assign) BOOL isFavorite;

/// 是否已选中（批量操作时使用）
@property (nonatomic, assign) BOOL isSelected;

#pragma mark - 类方法

/// 通过文件路径创建模型
/// @param filePath 文件完整路径
/// @return FileModel实例
+ (instancetype)modelWithFilePath:(NSString *)filePath;

- (NSDictionary *)toDictionary;

/// 从字典初始化（用于从持久化恢复）
- (instancetype)initWithDictionary:(NSDictionary *)dict;

#pragma mark - 实例方法

/// 获取格式化的文件大小字符串
/// @return 如 "1.5 MB"、"500 KB" 等
- (NSString *)formattedFileSize;

/// 获取格式化的修改日期字符串
/// @return 如 "2026-05-04 14:30"
- (NSString *)formattedModificationDate;

/// 判断是否为隐藏文件
/// @return YES表示隐藏文件
- (BOOL)isHiddenFile;

@end
