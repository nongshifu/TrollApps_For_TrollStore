//
//  FileUtils.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "FileUtils.h"

@implementation FileUtils
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
@end
