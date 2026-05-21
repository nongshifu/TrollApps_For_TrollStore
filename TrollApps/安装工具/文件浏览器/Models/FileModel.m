#import "FileModel.h"
#import "RemarkManager.h"

@implementation FileModel

+ (instancetype)modelWithFilePath:(NSString *)filePath {
    FileModel *model = [[FileModel alloc] init];
    model.filePath = filePath;
    model.fileName = [filePath lastPathComponent];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];

    if (attributes) {
        NSString *itemType = attributes[NSFileType];
        if ([itemType isEqualToString:NSFileTypeDirectory]) {
            model.itemType = FileItemTypeFolder;
            model.fileSize = 0;
        } else {
            model.itemType = FileItemTypeFile;
            model.fileSize = [attributes[NSFileSize] unsignedLongLongValue];
        }
        model.modificationDate = attributes[NSFileModificationDate];
    }

    model.parentDirPath = [filePath stringByDeletingLastPathComponent];
    model.isFavorite = NO;
    model.isSelected = NO;
    
    // 从本地加载备注
    model.remark = [[RemarkManager sharedManager] getRemarkForFilePath:filePath];

    return model;
}

- (NSString *)formattedFileSize {
    if (self.itemType == FileItemTypeFolder) {
        return @"文件夹";
    }

    unsigned long long bytes = self.fileSize;
    if (bytes < 1024) {
        return [NSString stringWithFormat:@"%llu B", bytes];
    } else if (bytes < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", bytes / 1024.0];
    } else if (bytes < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", bytes / (1024.0 * 1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.1f GB", bytes / (1024.0 * 1024.0 * 1024.0)];
    }
}

- (NSString *)formattedModificationDate {
    if (!self.modificationDate) {
        return @"--";
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    return [formatter stringFromDate:self.modificationDate];
}

- (BOOL)isHiddenFile {
    if (self.fileName.length > 0 && [self.fileName hasPrefix:@"."]) {
        return YES;
    }
    return NO;
}

@end
