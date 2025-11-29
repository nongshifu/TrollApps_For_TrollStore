//
//  FileModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/11/29.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FileType) {
    FileTypeFile,    // 文件
    FileTypeFolder   // 文件夹
};

@interface FileModel : NSObject
/// 文件路径（完整路径）
@property (nonatomic, copy, readonly) NSString *filePath;
/// 文件名（带后缀）
@property (nonatomic, copy, readonly) NSString *fileName;
/// 文件类型
@property (nonatomic, assign, readonly) FileType fileType;
/// 文件大小（字节）
@property (nonatomic, assign, readonly) uint64_t fileSize;
/// 修改日期
@property (nonatomic, strong, readonly) NSDate *modifyDate;
/// 文件图标名称（系统图标）
@property (nonatomic, copy, readonly) NSString *iconName;

/// 初始化文件模型
/// @param filePath 文件完整路径
- (instancetype)initWithFilePath:(NSString *)filePath;

/// 格式化文件大小（B/KB/MB/GB）
- (NSString *)formattedFileSize;
@end

NS_ASSUME_NONNULL_END
