//
//  AppFileModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import "NewAppFileModel.h"

@implementation NewAppFileModel


- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = [filePath copy];
        
        // 获取文件属性（添加错误打印，方便调试）
        NSError *attrError = nil;
        NSDictionary<NSFileAttributeKey, id> *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attrError];
        if (!fileAttr) {
            NSLog(@"[FileModel] ❌ 获取文件属性失败：路径=%@，错误=%@", filePath, attrError.localizedDescription);
            return nil;
        }
        NSLog(@"[FileModel] ✅ 文件属性：%@", fileAttr);
        
        // 文件名
        _file_name = [filePath lastPathComponent];
        
        // 🔥 修复 1：文件类型判断（Key 用 NSFileType，Value 比较 NSFileTypeDirectory）
        NSString *fileTypeStr = fileAttr[NSFileType]; // Key 是 NSFileType（字符串类型）
        if ([fileTypeStr isEqualToString:NSFileTypeDirectory]) {
            _file_type = FileTypeFolder;
        } else if ([fileTypeStr isEqualToString:NSFileTypeRegular]) {
            _file_type = FileTypeFile;
        } else {
            _file_type = FileTypeFile; // 其他类型（如链接、socket）默认按文件处理
        }
        NSLog(@"[FileModel] 📁 文件类型：%@（原始类型字符串：%@）",
              _file_type == FileTypeFolder ? @"文件夹" : @"文件",
              fileTypeStr);
        
        // 文件大小（文件夹大小需要递归计算）
        if (_file_type == FileTypeFile) {
            _file_size = [fileAttr[NSFileSize] unsignedLongLongValue];
        } else {
            _file_size = [self calculateFolderSizeAtPath:filePath];
        }
        NSLog(@"[FileModel] 📏 文件大小：%llu 字节（格式化后：%@）", _file_size, self.formattedFileSize);
        
        // 🔥 修复 2：修改日期 Key（用 NSFileModificationDate，对应 fileAttr 里的 NSFileModificationDate）
        _modifyDate = fileAttr[NSFileModificationDate];
        if (!_modifyDate) {
            _modifyDate = [NSDate date]; // 容错：如果没有修改日期，用当前日期
        }
        NSLog(@"[FileModel] 📅 修改日期：%@", _modifyDate);
        
        // 图标名称
        _iconName = [self getSystemIconName];
        NSLog(@"[FileModel] 🖼️ 图标名称：%@", _iconName);
    }
    return self;
}

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
            return @"iPAS巨魔包";
        case FileTypeZIP:
            return @"ZIP压缩文件";
        case FileTypeJS:
            return @"JS文件";
        case FileTypeHTML:
            return @"HTML文件";
        case FileTypeJSON:
            return @"JSON文件";
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



/// 递归计算文件夹大小
- (uint64_t)calculateFolderSizeAtPath:(NSString *)folderPath {
    uint64_t totalSize = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 🔥 修复 3：获取子路径时添加错误处理（原代码没有错误判断）
    NSError *subpathError = nil;
    NSArray *subpaths = [fm subpathsOfDirectoryAtPath:folderPath error:&subpathError];
    if (subpathError) {
        NSLog(@"[FileModel] ❌ 获取文件夹子路径失败：路径=%@，错误=%@", folderPath, subpathError.localizedDescription);
        return 0;
    }
    if (subpaths.count == 0) {
        NSLog(@"[FileModel] 📂 文件夹为空：%@", folderPath);
        return 0;
    }
    
    NSLog(@"[FileModel] 📂 计算文件夹大小：%@（包含 %ld 个子项目）", folderPath, subpaths.count);
    for (NSString *subpath in subpaths) {
        NSString *fullPath = [folderPath stringByAppendingPathComponent:subpath];
        NSError *subAttrError = nil;
        NSDictionary *subAttr = [fm attributesOfItemAtPath:fullPath error:&subAttrError];
        
        if (!subAttr) {
            NSLog(@"[FileModel] ❌ 获取子项目属性失败：路径=%@，错误=%@", fullPath, subAttrError.localizedDescription);
            continue;
        }
        
        // 🔥 修复 4：子项目类型判断（同样用 NSFileType 作为 Key）
        NSString *subTypeStr = subAttr[NSFileType];
        if (![subTypeStr isEqualToString:NSFileTypeDirectory]) { // 不是文件夹才计算大小
            uint64_t subSize = [subAttr[NSFileSize] unsignedLongLongValue];
            totalSize += subSize;
            NSLog(@"[FileModel] 📄 子文件大小：%@ = %llu 字节", subpath, subSize);
        }
    }
    NSLog(@"[FileModel] 📊 文件夹总大小：%@ = %llu 字节", folderPath, totalSize);
    return totalSize;
}

/// 格式化文件大小
- (NSString *)formattedFileSize {
    if (_file_size < 1024) {
        return [NSString stringWithFormat:@"%llu B", _file_size];
    } else if (_file_size < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", _file_size / 1024.0];
    } else if (_file_size < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", _file_size / (1024.0 * 1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.1f GB", _file_size / (1024.0 * 1024.0 * 1024.0)];
    }
}

/// 获取系统图标名称
- (NSString *)getSystemIconName {
    if (_file_type == FileTypeFolder) {
        return @"folder.fill"; // 文件夹图标
    }
    
    // 根据文件后缀获取UTI，匹配系统图标
    NSString *extension = [_file_name pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *iconName = @"doc.fill"; // 默认文件图标
    
    if (uti) {
        if (UTTypeConformsTo(uti, kUTTypeImage)) {
            iconName = @"photo.fill";
        } else if (UTTypeConformsTo(uti, kUTTypeMovie)) {
            iconName = @"film.fill";
        } else if (UTTypeConformsTo(uti, kUTTypeAudio)) {
            iconName = @"music.note.fill";
        } else if (UTTypeConformsTo(uti, kUTTypeText)) {
            iconName = @"textdoc.fill";
        } else if (UTTypeConformsTo(uti, kUTTypeSpreadsheet)) {
            iconName = @"tablecells.fill";
        } else if (UTTypeConformsTo(uti, kUTTypePresentation)) {
            iconName = @"slides.fill";
        } else if (UTTypeConformsTo(uti, kUTTypePDF)) {
            iconName = @"doc.pdf.fill";
        } else if (UTTypeConformsTo(uti, kUTTypeArchive)) {
            iconName = @"archivebox.fill";
        }
        CFRelease(uti); // 避免内存泄漏
    }
    
    return iconName;
}



/**
 * 解码URL字符串中的Unicode转义字符（如 \U542c 转换为 听）
 * @param urlString 包含Unicode转义字符的URL字符串
 * @return 解码后的URL字符串
 */
+ (NSString *)decodeUnicodeEscapesInURLString:(NSString *)urlString {
    if (!urlString || urlString.length == 0) {
        return urlString;
    }
    
    // 检测是否包含Unicode转义字符（\U开头，后跟8个十六进制字符）
    if ([urlString rangeOfString:@"\\U"].location == NSNotFound) {
        return urlString; // 没有转义字符，直接返回
    }
    
    NSMutableString *decodedString = [urlString mutableCopy];
    
    // 正则表达式匹配 \UXXXXXXXX 格式的Unicode转义字符
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\\\U([0-9a-fA-F]{8})"
                                                                           options:0
                                                                             error:nil];
    
    // 从后往前替换，避免替换后影响后续匹配位置
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:decodedString
                                                              options:NSMatchingReportCompletion
                                                                range:NSMakeRange(0, decodedString.length)];
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        if (match.numberOfRanges >= 2) {
            // 获取十六进制字符串部分
            NSString *hexString = [decodedString substringWithRange:[match rangeAtIndex:1]];
            
            // 转换为UTF-32字符
            uint32_t codePoint = strtoul([hexString UTF8String], NULL, 16);
            
            // 转换为NSString字符
            if (codePoint <= 0x10FFFF) {
                UTF32Char utf32Char = codePoint;
                NSString *unicodeChar = [[NSString alloc] initWithBytes:&utf32Char
                                                                 length:sizeof(UTF32Char)
                                                               encoding:NSUTF32LittleEndianStringEncoding];
                
                if (unicodeChar) {
                    // 替换转义序列为实际字符
                    [decodedString replaceCharactersInRange:match.range withString:unicodeChar];
                }
            }
        }
    }
    
    // 同时处理 \uXXXX 格式的转义字符（4个十六进制字符）
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\\\u([0-9a-fA-F]{4})"
                                                      options:0
                                                        error:nil];
    matches = [regex matchesInString:decodedString
                              options:NSMatchingReportCompletion
                                range:NSMakeRange(0, decodedString.length)];
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        if (match.numberOfRanges >= 2) {
            NSString *hexString = [decodedString substringWithRange:[match rangeAtIndex:1]];
            uint32_t codePoint = strtoul([hexString UTF8String], NULL, 16);
            
            if (codePoint <= 0xFFFF) {
                unichar unicodeChar = (unichar)codePoint;
                NSString *charString = [NSString stringWithCharacters:&unicodeChar length:1];
                [decodedString replaceCharactersInRange:match.range withString:charString];
            }
        }
    }
    
    return decodedString;
}

/**
 * 安全处理下载URL，自动解码Unicode转义字符
 * @param urlString 原始URL字符串
 * @return 处理后的安全URL
 */
+ (NSURL *)safeDownloadURLFromString:(NSString *)urlString {
    if (!urlString) {
        return nil;
    }
    
    // 1. 解码Unicode转义字符
    NSString *decodedUrlString = [self decodeUnicodeEscapesInURLString:urlString];
    
    // 2. 确保URL编码正确
    return [self encodedURLFromString:decodedUrlString];
}

@end
