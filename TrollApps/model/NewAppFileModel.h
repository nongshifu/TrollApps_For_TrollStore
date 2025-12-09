//
//  AppFileModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
NS_ASSUME_NONNULL_BEGIN

// 文件类型枚举
typedef NS_ENUM(NSInteger, FileType) {
    FileTypeUnknown = 0,    // 未知类型
    // 安装包类型
    FileTypeIPA = 1,            // iOS应用安装包
    FileTypeTIPA = 2,           // 多应用安装包集合
    FileTypeDEB = 3,            // Debian软件包(越狱插件)
    
    // 脚本/配置类型
    FileTypeJS = 4,             // JavaScript脚本
    FileTypeHTML = 5,           // HTML网页文件
    FileTypeJSON = 6,           // JSON数据文件
    FileTypeSH = 7,             // Shell脚本
    FileTypePLIST = 8,          // Property List配置文件
    
    // 二进制类型
    FileTypeDYLIB = 9,          // 动态链接库
    
    // 压缩包类型
    FileTypeZIP = 10,            // ZIP压缩文件
    
    FileTypeOther = 11,    // 其他
    FileTypeFile = 12,    // 文件
    FileTypeFolder = 13   // 文件夹
    
};

@interface NewAppFileModel : NSObject
/// 文件路径（完整路径）
@property (nonatomic, copy, readonly) NSString *filePath;

@property (nonatomic, copy) NSString *file_name;
/// 文件大小（字节）
@property (nonatomic, assign, readonly) uint64_t  file_size;
@property (nonatomic, copy) NSString *suffix;
@property (nonatomic, copy) NSURL *file_url;
@property (nonatomic, strong) NSData *file_Data;
@property (nonatomic, strong) UIImage *fileIcon;
@property (nonatomic, assign) FileType file_type;
/// 修改日期
@property (nonatomic, strong, readonly) NSDate *modifyDate;
/// 文件图标名称（系统图标）
@property (nonatomic, copy, readonly) NSString *iconName;
/// 格式化文件大小（B/KB/MB/GB）
- (NSString *)formattedFileSize;


/// 通过文件名检测文件类型
+ (FileType)fileTypeForFileName:(NSString *)fileName;

/// 通过文件URL检测文件类型
+ (FileType)fileTypeForFileURL:(NSURL *)fileURL;

/// 获取文件类型的中文描述
+ (NSString *)chineseDescriptionForFileType:(FileType)fileType;

/// 获取文件类型对应的文件夹目录
+ (NSString *)getTypeDicForFileType:(FileType)fileType;


/// 判断URL对应的文件是否为图片
+ (BOOL)isImageFileWithURL:(NSURL *)url;

/// 判断URL对应的文件是否为视频
+ (BOOL)isVideoFileWithURL:(NSURL *)url;

/// 判断URL对应的文件是否为图片或视频（媒体文件）
+ (BOOL)isMediaFileWithURL:(NSURL *)url;

/// 判断是否是合法URL
+ (BOOL)isValidURL:(NSString *)urlString;

/**
 * 将文件大小（字节）格式化为人类可读的字符串，如 "1.23 MB"
 * @param fileSize 文件大小（以字节为单位）
 * @return 格式化后的字符串，包含单位（KB、MB、GB等）
 */
+ (NSString *)formattedFileSize:(NSNumber *)fileSize;

/**
 通过NSURL获取文件名
 
 @param url 文件URL
 @param shouldDecode 是否解码中文
 @return 处理后的文件名（特殊字符已替换）
 */
+ (NSString *)fileNameFromURL:(NSURL *)url shouldDecodeChinese:(BOOL)shouldDecode;

/**
 通过文件路径字符串获取文件名
 
 @param path 文件路径字符串
 @param shouldDecode 是否解码中文
 @return 处理后的文件名（特殊字符已替换）
 */
+ (NSString *)fileNameFromPathString:(NSString *)path shouldDecodeChinese:(BOOL)shouldDecode;

/**
 将字符串URL转换为编码后的NSURL（保留原始空格和/）
 
 @param urlString 原始URL字符串（可能包含未编码的中文或特殊字符）
 @return 编码后的NSURL（nil表示转换失败）
 */
+ (NSURL *)encodedURLFromString:(NSString *)urlString;

/**
 * 解码URL字符串中的Unicode转义字符（如 \U542c 转换为 听）
 * @param urlString 包含Unicode转义字符的URL字符串
 * @return 解码后的URL字符串
 */
+ (NSString *)decodeUnicodeEscapesInURLString:(NSString *)urlString;


/// 初始化文件模型
/// @param filePath 文件完整路径
- (instancetype)initWithFilePath:(NSString *)filePath;



@end

NS_ASSUME_NONNULL_END
