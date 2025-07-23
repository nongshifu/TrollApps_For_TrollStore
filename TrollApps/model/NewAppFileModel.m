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
            return @"其他";
    }
}


+ (NSString *)getTypeDicForFileType:(FileType)fileType {
    switch (fileType) {
        case FileTypeIPA:
            return @"ipa";
        case FileTypeTIPA:
            return @"tipa";
        case FileTypeZIP:
            return @"zip";
        case FileTypeJS:
            return @"javascript";
        case FileTypeHTML:
            return @"html";
        case FileTypeJSON:
            return @"json";
        case FileTypeDEB:
            return @"deb";
        case FileTypeSH:
            return @"shell";
        case FileTypePLIST:
            return @"plist";
        case FileTypeDYLIB:
            return @"dylib";
        case FileTypeUnknown:
        default:
            return @"unknown";
    }
}

/**
 * 将文件大小（字节）格式化为人类可读的字符串，如 "1.23 MB"
 * @param fileSize 文件大小（以字节为单位）
 * @return 格式化后的字符串，包含单位（KB、MB、GB等）
 */
+ (NSString *)formattedFileSize:(NSNumber *)fileSize {
    if (!fileSize || [fileSize integerValue] <= 0) {
        return @"0 B";
    }
    
    double size = [fileSize doubleValue];
    NSArray *units = @[@"B", @"KB", @"MB", @"GB", @"TB"];
    NSInteger unitIndex = 0;
    
    // 循环直到找到合适的单位
    while (size >= 1024 && unitIndex < units.count - 1) {
        size /= 1024;
        unitIndex++;
    }
    
    // 格式化字符串，保留两位小数
    return [NSString stringWithFormat:@"%.2f %@", size, [units objectAtIndex:unitIndex]];
}

+ (BOOL)isValidURL:(NSString *)urlString {
    // 正则表达式模式，匹配常见URL格式（支持http/https/ftp等协议）
    NSString *regexPattern = @"^(https?|ftp)://[^\\s/$.?#].[^\\s]*$";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                             options:NSRegularExpressionCaseInsensitive
                                                                               error:&error];
    
    if (error) {
        NSLog(@"正则表达式错误: %@", error.localizedDescription);
        return NO;
    }
    
    // 执行匹配
    NSUInteger matches = [regex numberOfMatchesInString:urlString
                                                 options:0
                                                   range:NSMakeRange(0, urlString.length)];
    
    return matches > 0;
}

+ (NSString *)fileNameFromURL:(NSURL *)url shouldDecodeChinese:(BOOL)shouldDecode {
    if (!url) return @"";
    
    // 获取URL中的最后一个路径组件（包含可能的编码）
    NSString *lastComponent = [url lastPathComponent];
    return [self processFileName:lastComponent shouldDecode:shouldDecode];
}

+ (NSString *)fileNameFromPathString:(NSString *)path shouldDecodeChinese:(BOOL)shouldDecode {
    if (![path isKindOfClass:[NSString class]]) {
        NSLog(@"警告: fileNameFromPathString: 接收到的不是NSString类型的参数 - %@", [path class]);
        return @"";
    }
    if (!path || path.length == 0) return @"";
    
    // 从路径字符串中提取最后一个组件
    NSString *lastComponent = [path lastPathComponent];
    return [self processFileName:lastComponent shouldDecode:shouldDecode];
}

#pragma mark - 内部处理方法

/**
 处理文件名：解码+特殊字符替换
 
 @param rawName 原始文件名（可能包含编码）
 @param shouldDecode 是否解码
 @return 处理后的文件名
 */
+ (NSString *)processFileName:(NSString *)rawName shouldDecode:(BOOL)shouldDecode {
    if (!rawName || rawName.length == 0) return @"";
    
    NSString *processedName = rawName;
    
    // 1. 解码中文（如果需要）
    if (shouldDecode) {
        // 处理URL编码（如%E9%BB%84转换为“黄”）
        processedName = [processedName stringByRemovingPercentEncoding];
        // 容错：如果解码失败则使用原始字符串
        if (!processedName) processedName = rawName;
    }
    
    // 2. 替换特殊字符（空格和/替换为_）
    NSCharacterSet *invalidChars = [NSCharacterSet characterSetWithCharactersInString:@" /"];
    NSRange invalidRange = [processedName rangeOfCharacterFromSet:invalidChars];
    if (invalidRange.location != NSNotFound) {
        processedName = [processedName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        processedName = [processedName stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    
    return processedName;
}

+ (NSURL *)encodedURLFromString:(NSString *)urlString {
    if (!urlString || urlString.length == 0) {
        NSLog(@"URL字符串为空");
        return nil;
    }
    
    // 1. 拆分URL为"协议://"和"路径部分"（避免对协议部分二次编码）
    NSRange schemeRange = [urlString rangeOfString:@"://"];
    NSString *scheme = @"";
    NSString *pathPart = urlString;
    
    if (schemeRange.location != NSNotFound) {
        scheme = [urlString substringToIndex:schemeRange.location + schemeRange.length];
        pathPart = [urlString substringFromIndex:schemeRange.location + schemeRange.length];
    }
    
    // 2. 对路径部分进行编码（仅编码非URL安全字符，保留/和空格）
    NSString *encodedPathPart = [self encodeURLPathPart:pathPart];
    if (!encodedPathPart) {
        return nil;
    }
    
    // 3. 拼接编码后的完整URL字符串
    NSString *encodedURLString = [scheme stringByAppendingString:encodedPathPart];
    
    // 4. 转换为NSURL（自动处理URL格式校验）
    NSURL *encodedURL = [NSURL URLWithString:encodedURLString];
    if (!encodedURL) {
        NSLog(@"URL格式无效：%@", encodedURLString);
    }
    
    return encodedURL;
}

/**
 编码URL路径部分（保留/和空格）
 
 @param pathPart URL中的路径部分（不含协议头）
 @return 编码后的路径部分
 */
+ (NSString *)encodeURLPathPart:(NSString *)pathPart {
    if (!pathPart) return nil;
    
    // URL安全字符集：保留字母、数字、以及;/?:@&=+$,#和/、空格
    // 注意：空格在这里不替换为%20，保持原始空格（根据需求）
    NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;= "];
    
    // 对不在安全字符集中的字符进行编码（如中文、特殊符号）
    return [pathPart stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
}


@end
