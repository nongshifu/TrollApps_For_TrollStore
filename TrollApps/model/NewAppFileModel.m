//
//  AppFileModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import "NewAppFileModel.h"

@implementation NewAppFileModel
+ (BOOL)isImageFileWithURL:(NSURL *)url {
    if (!url) return NO;
    // 常见图片扩展名
    NSArray *imageExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"heic", @"webp", @"bmp"];
    return [self _isFileWithURL:url inExtensions:imageExtensions];
}

+ (BOOL)isVideoFileWithURL:(NSURL *)url {
    if (!url) return NO;
    // 常见视频扩展名
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi", @"mkv", @"flv", @"wmv", @"mpeg", @"mpg"];
    return [self _isFileWithURL:url inExtensions:videoExtensions];
}

+ (BOOL)isMediaFileWithURL:(NSURL *)url {
    return [self isImageFileWithURL:url] || [self isVideoFileWithURL:url];
}

/// 私有方法：判断URL的扩展名是否在目标列表中
+ (BOOL)_isFileWithURL:(NSURL *)url inExtensions:(NSArray<NSString *> *)extensions {
    NSString *ext = url.pathExtension.lowercaseString;
    return [extensions containsObject:ext];
}

// 支持的文件扩展名映射表(小写)
static NSDictionary<NSString *, NSNumber *> *fileExtensionMap;

+ (void)initialize {
    if (self == [NewAppFileModel class]) {
        fileExtensionMap = @{
            @"ipa": @(FileTypeIPA),
            @"tipa": @(FileTypeTIPA),
            @"zip": @(FileTypeZIP),
            @"js": @(FileTypeJS),
            @"html": @(FileTypeHTML),
            @"json": @(FileTypeJSON),
            @"deb": @(FileTypeDEB),
            @"sh": @(FileTypeSH),
            @"plist": @(FileTypePLIST),
            @"dylib": @(FileTypeDYLIB),
        };
    }
}

+ (FileType)fileTypeForFileName:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return FileTypeUnknown;
    }
    
    // 获取扩展名并转为小写
    NSString *extension = [[fileName pathExtension] lowercaseString];
    NSNumber *typeNumber = fileExtensionMap[extension];
    
    return typeNumber ? (FileType)typeNumber.integerValue : FileTypeUnknown;
}

+ (FileType)fileTypeForFileURL:(NSURL *)fileURL {
    if (!fileURL) {
        return FileTypeUnknown;
    }
    
    // 获取文件URL的路径扩展名
    NSString *fileName = [fileURL lastPathComponent];
    return [self fileTypeForFileName:fileName];
}

+ (NSString *)chineseDescriptionForFileType:(FileType)fileType {
    switch (fileType) {
        case FileTypeIPA:
            return @"iPA安装包";
        case FileTypeTIPA:
            return @"iPAS巨魔安装包";
        case FileTypeZIP:
            return @"ZIP压缩文件";
        case FileTypeJS:
            return @"JavaScript脚本";
        case FileTypeHTML:
            return @"HTML文件";
        case FileTypeJSON:
            return @"JSON数据文件";
        case FileTypeDEB:
            return @"Deb越狱插件";
        case FileTypeSH:
            return @"Shell脚本";
        case FileTypePLIST:
            return @"Plist";
        case FileTypeDYLIB:
            return @"Dylib";
        case FileTypeUnknown:
        default:
            return @"未知文件类型";
    }
}

@end
