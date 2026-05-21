//
//  AppFileModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import "NewAppFileModel.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NewAppFileModel

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = [filePath copy];
        
        NSError *attrError = nil;
        NSDictionary<NSFileAttributeKey, id> *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attrError];
        if (!fileAttr) {
            NSLog(@"[FileModel] ❌ 获取文件属性失败：路径=%@，错误=%@", filePath, attrError.localizedDescription);
            return nil;
        }
        
        _file_name = [filePath lastPathComponent];
        
        NSString *fileTypeStr = fileAttr[NSFileType];
        if ([fileTypeStr isEqualToString:NSFileTypeDirectory]) {
            _file_type = FileTypeFolder;
        } else if ([fileTypeStr isEqualToString:NSFileTypeRegular]) {
            // 普通文件 → 根据后缀判断精确类型
            _file_type = [NewAppFileModel fileTypeForFileName:_file_name];
        } else {
            _file_type = FileTypeUnknown;
        }
        
        if (_file_type == FileTypeFile || _file_type == FileTypeUnknown) {
            _file_type = [NewAppFileModel fileTypeForFileName:_file_name];
        }

        if (_file_type == FileTypeFile) {
            _file_size = [fileAttr[NSFileSize] unsignedLongLongValue];
        } else {
            _file_size = [self calculateFolderSizeAtPath:filePath];
        }
        
        _modifyDate = fileAttr[NSFileModificationDate];
        if (!_modifyDate) {
            _modifyDate = [NSDate date];
        }
        
        _iconName = [self getSystemIconName];
    }
    return self;
}

+ (BOOL)isImageFileWithURL:(NSURL *)url {
    if (!url) return NO;
    NSArray *imageExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"heic", @"webp", @"bmp", @"tiff"];
    return [self _isFileWithURL:url inExtensions:imageExtensions];
}

+ (BOOL)isVideoFileWithURL:(NSURL *)url {
    if (!url) return NO;
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi", @"mkv", @"flv", @"wmv", @"mpeg", @"mpg", @"rmvb", @"m4v"];
    return [self _isFileWithURL:url inExtensions:videoExtensions];
}

+ (BOOL)isMediaFileWithURL:(NSURL *)url {
    return [self isImageFileWithURL:url] || [self isVideoFileWithURL:url];
}

+ (BOOL)_isFileWithURL:(NSURL *)url inExtensions:(NSArray<NSString *> *)extensions {
    NSString *ext = url.pathExtension.lowercaseString;
    return [extensions containsObject:ext];
}

static NSDictionary<NSString *, NSNumber *> *fileExtensionMap;

+ (void)initialize {
    if (self == [NewAppFileModel class]) {
        fileExtensionMap = @{
            @"ipa": @(FileTypeIPA),
            @"tipa": @(FileTypeTIPA),
            @"deb": @(FileTypeDEB),
            @"js": @(FileTypeJS),
            @"html": @(FileTypeHTML),
            @"htm": @(FileTypeHTML),
            @"json": @(FileTypeJSON),
            @"sh": @(FileTypeSH),
            @"plist": @(FileTypePLIST),
            @"dylib": @(FileTypeDYLIB),
            @"zip": @(FileTypeZIP),
            @"rar": @(FileTypeZIP),
            @"7z": @(FileTypeZIP),
            
            @"jpg": @(FileTypeIMAGE),
            @"jpeg": @(FileTypeIMAGE),
            @"png": @(FileTypeIMAGE),
            @"gif": @(FileTypeIMAGE),
            @"heic": @(FileTypeIMAGE),
            @"webp": @(FileTypeIMAGE),
            @"bmp": @(FileTypeIMAGE),
            
            @"mp4": @(FileTypeVIDEO),
            @"mov": @(FileTypeVIDEO),
            @"avi": @(FileTypeVIDEO),
            @"mkv": @(FileTypeVIDEO),
            @"flv": @(FileTypeVIDEO),
            @"m4v": @(FileTypeVIDEO),
        };
    }
}

+ (FileType)fileTypeForFileName:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return FileTypeUnknown;
    }
    
    NSString *extension = [[fileName pathExtension] lowercaseString];
    NSNumber *typeNumber = fileExtensionMap[extension];
    
    if (typeNumber) {
        return (FileType)typeNumber.integerValue;
    }
    
    if ([self isImageFileWithURL:[NSURL fileURLWithPath:fileName]]) {
        return FileTypeIMAGE;
    }
    if ([self isVideoFileWithURL:[NSURL fileURLWithPath:fileName]]) {
        return FileTypeVIDEO;
    }
    
    return FileTypeUnknown;
}

+ (FileType)fileTypeForFileURL:(NSURL *)fileURL {
    if (!fileURL) return FileTypeUnknown;
    return [self fileTypeForFileName:[fileURL lastPathComponent]];
}

// MARK: - 中文描述（已补齐全部类型）
+ (NSString *)chineseDescriptionForFileType:(FileType)fileType {
    switch (fileType) {
        case FileTypeUnknown: return @"未知文件";
        case FileTypeIPA: return @"iPA安装包";
        case FileTypeTIPA: return @"iPAS巨魔包";
        case FileTypeDEB: return @"Deb越狱插件";
        case FileTypeJS: return @"JS脚本";
        case FileTypeHTML: return @"HTML文件";
        case FileTypeJSON: return @"JSON文件";
        case FileTypeSH: return @"Shell脚本";
        case FileTypePLIST: return @"Plist配置";
        case FileTypeDYLIB: return @"Dylib动态库";
        case FileTypeZIP: return @"压缩文件";
        case FileTypeIMAGE: return @"图片文件";
        case FileTypeVIDEO: return @"视频文件";
        case FileTypeOther: return @"其他文件";
        case FileTypeFile: return @"普通文件";
        case FileTypeFolder: return @"文件夹";
        default: return @"未知类型";
    }
}

// MARK: - 类型标识（对接后端用）
+ (NSString *)getTypeDicForFileType:(FileType)fileType {
    switch (fileType) {
        case FileTypeUnknown: return @"unknown";
        case FileTypeIPA: return @"ipa";
        case FileTypeTIPA: return @"tipa";
        case FileTypeDEB: return @"deb";
        case FileTypeJS: return @"javascript";
        case FileTypeHTML: return @"html";
        case FileTypeJSON: return @"json";
        case FileTypeSH: return @"shell";
        case FileTypePLIST: return @"plist";
        case FileTypeDYLIB: return @"dylib";
        case FileTypeZIP: return @"zip";
        case FileTypeIMAGE: return @"image";
        case FileTypeVIDEO: return @"video";
        case FileTypeOther: return @"other";
        case FileTypeFile: return @"file";
        case FileTypeFolder: return @"folder";
        default: return @"unknown";
    }
}

+ (NSString *)formattedFileSize:(NSNumber *)fileSize {
    if (!fileSize || [fileSize integerValue] <= 0) {
        return @"0 B";
    }
    
    double size = [fileSize doubleValue];
    NSArray *units = @[@"B", @"KB", @"MB", @"GB", @"TB"];
    NSInteger unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.count - 1) {
        size /= 1024;
        unitIndex++;
    }
    
    return [NSString stringWithFormat:@"%.2f %@", size, units[unitIndex]];
}

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

- (NSString *)getSystemIconName {
    if (_file_type == FileTypeFolder) {
        return @"folder.fill";
    }
    
    switch (_file_type) {
        case FileTypeIMAGE: return @"photo.fill";
        case FileTypeVIDEO: return @"film.fill";
        case FileTypeZIP: return @"archivebox.fill";
        case FileTypeIPA: return @"doc.richtext.fill";
        case FileTypeDEB: return @"puzzlepiece.fill";
        case FileTypeJS: return @"curlybraces.fill";
        case FileTypeJSON: return @"list.bullet";
        case FileTypeHTML: return @"safari.fill";
        case FileTypePLIST: return @"gearshape.fill";
        case FileTypeDYLIB: return @"wrench.fill";
        case FileTypeSH: return @"terminal.fill";
        case FileTypeFolder: return @"folder.fill";
        default: return @"doc.fill";
    }
}

- (uint64_t)calculateFolderSizeAtPath:(NSString *)folderPath {
    uint64_t totalSize = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSError *subpathError = nil;
    NSArray *subpaths = [fm subpathsOfDirectoryAtPath:folderPath error:&subpathError];
    if (subpathError) return 0;
    
    for (NSString *subpath in subpaths) {
        NSString *fullPath = [folderPath stringByAppendingPathComponent:subpath];
        NSError *err = nil;
        NSDictionary *attr = [fm attributesOfItemAtPath:fullPath error:&err];
        if (!attr) continue;
        
        NSString *type = attr[NSFileType];
        if (![type isEqualToString:NSFileTypeDirectory]) {
            totalSize += [attr[NSFileSize] unsignedLongLongValue];
        }
    }
    return totalSize;
}

+ (BOOL)isValidURL:(NSString *)urlString {
    NSString *pattern = @"^(https?|ftp)://[^\\s/$.?#].[^\\s]*$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    return regex && [regex numberOfMatchesInString:urlString options:0 range:NSMakeRange(0, urlString.length)] > 0;
}

+ (NSString *)fileNameFromURL:(NSURL *)url shouldDecodeChinese:(BOOL)shouldDecode {
    if (!url) return @"";
    return [self processFileName:[url lastPathComponent] shouldDecode:shouldDecode];
}

+ (NSString *)fileNameFromPathString:(NSString *)path shouldDecodeChinese:(BOOL)shouldDecode {
    if (![path isKindOfClass:[NSString class]] || path.length == 0) return @"";
    return [self processFileName:[path lastPathComponent] shouldDecode:shouldDecode];
}

+ (NSString *)processFileName:(NSString *)rawName shouldDecode:(BOOL)shouldDecode {
    if (!rawName) return @"";
    NSString *name = shouldDecode ? [rawName stringByRemovingPercentEncoding] ?: rawName : rawName;
    name = [name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    name = [name stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return name;
}

+ (NSURL *)encodedURLFromString:(NSString *)urlString {
    if (!urlString.length) return nil;
    NSRange schemeRange = [urlString rangeOfString:@"://"];
    NSString *scheme = @"";
    NSString *path = urlString;
    
    if (schemeRange.location != NSNotFound) {
        scheme = [urlString substringToIndex:schemeRange.location + schemeRange.length];
        path = [urlString substringFromIndex:schemeRange.location + schemeRange.length];
    }
    
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;= "];
    NSString *encoded = [path stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    return [NSURL URLWithString:[scheme stringByAppendingString:encoded]];
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

+ (NSURL *)safeDownloadURLFromString:(NSString *)urlString {
    if (!urlString) return nil;
    return [self encodedURLFromString:[self decodeUnicodeEscapesInURLString:urlString]];
}

@end
