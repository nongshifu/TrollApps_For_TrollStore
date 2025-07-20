//
//  AppFileModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 文件类型枚举
typedef NS_ENUM(NSInteger, FileType) {
    
    // 安装包类型
    FileTypeIPA = 0,            // iOS应用安装包
    FileTypeTIPA,           // 多应用安装包集合
    FileTypeDEB,            // Debian软件包(越狱插件)
    
    // 脚本/配置类型
    FileTypeJS,             // JavaScript脚本
    FileTypeHTML,           // HTML网页文件
    FileTypeJSON,           // JSON数据文件
    FileTypeSH,             // Shell脚本
    FileTypePLIST,          // Property List配置文件
    
    // 二进制类型
    FileTypeDYLIB,          // 动态链接库
    
    // 压缩包类型
    FileTypeZIP,            // ZIP压缩文件
    FileTypeUnknown,    // 未知类型
};

@interface NewAppFileModel : NSObject

@property (nonatomic, copy) NSString *file_name;
@property (nonatomic, copy) NSNumber  *file_size;
@property (nonatomic, copy) NSString *suffix;
@property (nonatomic, copy) NSURL *file_url;
@property (nonatomic, strong) NSData *file_Data;
@property (nonatomic, strong) UIImage *fileIcon;
@property (nonatomic, assign) FileType file_type;


/// 通过文件名检测文件类型
+ (FileType)fileTypeForFileName:(NSString *)fileName;

/// 通过文件URL检测文件类型
+ (FileType)fileTypeForFileURL:(NSURL *)fileURL;

/// 获取文件类型的中文描述
+ (NSString *)chineseDescriptionForFileType:(FileType)fileType;


/// 判断URL对应的文件是否为图片
+ (BOOL)isImageFileWithURL:(NSURL *)url;

/// 判断URL对应的文件是否为视频
+ (BOOL)isVideoFileWithURL:(NSURL *)url;

/// 判断URL对应的文件是否为图片或视频（媒体文件）
+ (BOOL)isMediaFileWithURL:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
