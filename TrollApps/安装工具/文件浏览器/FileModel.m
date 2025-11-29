#import "FileModel.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation FileModel

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
        _fileName = [filePath lastPathComponent];
        
        // 🔥 修复 1：文件类型判断（Key 用 NSFileType，Value 比较 NSFileTypeDirectory）
        NSString *fileTypeStr = fileAttr[NSFileType]; // Key 是 NSFileType（字符串类型）
        if ([fileTypeStr isEqualToString:NSFileTypeDirectory]) {
            _fileType = FileTypeFolder;
        } else if ([fileTypeStr isEqualToString:NSFileTypeRegular]) {
            _fileType = FileTypeFile;
        } else {
            _fileType = FileTypeFile; // 其他类型（如链接、socket）默认按文件处理
        }
        NSLog(@"[FileModel] 📁 文件类型：%@（原始类型字符串：%@）",
              _fileType == FileTypeFolder ? @"文件夹" : @"文件",
              fileTypeStr);
        
        // 文件大小（文件夹大小需要递归计算）
        if (_fileType == FileTypeFile) {
            _fileSize = [fileAttr[NSFileSize] unsignedLongLongValue];
        } else {
            _fileSize = [self calculateFolderSizeAtPath:filePath];
        }
        NSLog(@"[FileModel] 📏 文件大小：%llu 字节（格式化后：%@）", _fileSize, self.formattedFileSize);
        
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
    if (_fileSize < 1024) {
        return [NSString stringWithFormat:@"%llu B", _fileSize];
    } else if (_fileSize < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", _fileSize / 1024.0];
    } else if (_fileSize < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", _fileSize / (1024.0 * 1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.1f GB", _fileSize / (1024.0 * 1024.0 * 1024.0)];
    }
}

/// 获取系统图标名称
- (NSString *)getSystemIconName {
    if (_fileType == FileTypeFolder) {
        return @"folder.fill"; // 文件夹图标
    }
    
    // 根据文件后缀获取UTI，匹配系统图标
    NSString *extension = [_fileName pathExtension];
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

@end
