#import "SandboxTool.h"
#import "FileModel.h"
#import "SSZipArchive.h"

@implementation SandboxTool

+ (NSString *)getSandboxDirectoryPath:(SandboxDirectoryType)directoryType {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];

    switch (directoryType) {
        case SandboxDirectoryTypeHome:
            return [documentsPath stringByDeletingLastPathComponent];
        case SandboxDirectoryTypeDocuments:
            return documentsPath;
        case SandboxDirectoryTypeLibrary:
            return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        case SandboxDirectoryTypeCaches:
            return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        case SandboxDirectoryTypeTmp:
            return NSTemporaryDirectory();
        default:
            return [documentsPath stringByDeletingLastPathComponent];
    }
}

+ (NSArray<NSString *> *)getFirstLevelFilesWithDirPath:(NSString *)dirPath displayType:(DisplayType)displayType {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:dirPath error:&error];

    if (error) {
        return @[];
    }

    NSMutableArray *filteredFiles = [NSMutableArray array];
    NSArray *hiddenFileNames = [self getHiddenFileNames];

    for (NSString *fileName in contents) {
        if ([hiddenFileNames containsObject:fileName]) {
            continue;
        }

        NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];

        if (displayType == DisplayTypeFolderOnly && !isDirectory) {
            continue;
        }

        [filteredFiles addObject:filePath];
    }

    return [filteredFiles copy];
}

+ (NSArray<NSString *> *)getHiddenFileNames {
    return @[@".DS_Store", @"Thumbs.db", @".localized"];
}

+ (NSArray<FileModel *> *)getFirstLevelFileModelsWithDirPath:(NSString *)dirPath displayType:(DisplayType)displayType {
    NSArray<NSString *> *filePaths = [self getFirstLevelFilesWithDirPath:dirPath displayType:displayType];
    NSMutableArray<FileModel *> *fileModels = [NSMutableArray array];

    for (NSString *filePath in filePaths) {
        FileModel *model = [FileModel modelWithFilePath:filePath];
        [fileModels addObject:model];
    }

    return [fileModels copy];
}

+ (BOOL)isDirectoryAtPath:(NSString *)path {
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return isDir;
}

+ (NSString *)formatFileSize:(long long)size {
    if (size < 1024) {
        return [NSString stringWithFormat:@"%lld B", size];
    } else if (size < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", size / 1024.0];
    } else if (size < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", size / (1024.0 * 1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.1f GB", size / (1024.0 * 1024.0 * 1024.0)];
    }
}

+ (NSDate *)getFileModificationDate:(NSString *)filePath {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return attrs[NSFileModificationDate];
}

+ (NSString *)generateFileNameWithExtension:(NSString *)extension {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd_HHmmss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%@.%@", timestamp, extension];
}

+ (NSString *)compressFilesAtPaths:(NSArray<NSString *> *)filePaths toDirectory:(NSString *)directoryPath {
    if (filePaths.count == 0 || directoryPath.length == 0) {
        return nil;
    }

    NSString *zipFileName = [self generateFileNameWithExtension:@"zip"];
    NSString *zipFilePath = [directoryPath stringByAppendingPathComponent:zipFileName];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:zipFilePath]) {
        [fileManager removeItemAtPath:zipFilePath error:nil];
    }

    BOOL success = [SSZipArchive createZipFileAtPath:zipFilePath withFilesAtPaths:filePaths];

    if (success) {
        return zipFilePath;
    } else {
        return nil;
    }
}

+ (NSString *)getFileExtension:(NSString *)fileName {
    NSArray *components = [fileName pathComponents];
    if (components.count > 1) {
        NSString *lastComponent = [components lastObject];
        NSRange dotRange = [lastComponent rangeOfString:@"." options:NSBackwardsSearch];
        if (dotRange.location != NSNotFound) {
            return [lastComponent substringFromIndex:dotRange.location + 1];
        }
    }
    return @"";
}

+ (BOOL)batchModifyExtensionInDirectory:(NSString *)directoryPath oldExtension:(NSString *)oldExtension newExtension:(NSString *)newExtension recursive:(BOOL)recursive {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    NSArray *contents;
    if (recursive) {
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
        NSMutableArray *allPaths = [NSMutableArray array];
        NSString *fileName;
        while ((fileName = [enumerator nextObject])) {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:fileName];
            BOOL isDir = NO;
            [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
            if (!isDir) {
                [allPaths addObject:fullPath];
            }
        }
        contents = allPaths;
    } else {
        contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    }

    NSMutableArray *filesToModify = [NSMutableArray array];
    for (NSString *filePath in contents) {
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:filePath];
        NSString *ext = [self getFileExtension:fullPath];

        if ([ext caseInsensitiveCompare:oldExtension] == NSOrderedSame) {
            [filesToModify addObject:fullPath];
        }
    }

    BOOL allSuccess = YES;
    for (NSString *filePath in filesToModify) {
        NSString *directory = [filePath stringByDeletingLastPathComponent];
        NSString *fileNameWithoutExt = [[filePath lastPathComponent] stringByDeletingPathExtension];
        NSString *newFileName = [fileNameWithoutExt stringByAppendingPathExtension:newExtension];
        NSString *newPath = [directory stringByAppendingPathComponent:newFileName];

        NSError *renameError = nil;
        [fileManager moveItemAtPath:filePath toPath:newPath error:&renameError];
        if (renameError) {
            allSuccess = NO;
        }
    }

    return allSuccess;
}

+ (BOOL)batchDeleteByExtensionInDirectory:(NSString *)directoryPath extension:(NSString *)extension recursive:(BOOL)recursive {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    NSArray *contents;
    if (recursive) {
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
        NSMutableArray *allPaths = [NSMutableArray array];
        NSString *fileName;
        while ((fileName = [enumerator nextObject])) {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:fileName];
            BOOL isDir = NO;
            [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
            if (!isDir) {
                [allPaths addObject:fullPath];
            }
        }
        contents = allPaths;
    } else {
        contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    }

    NSMutableArray *filesToDelete = [NSMutableArray array];
    for (NSString *filePath in contents) {
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:filePath];
        NSString *ext = [self getFileExtension:fullPath];

        if ([ext caseInsensitiveCompare:extension] == NSOrderedSame) {
            [filesToDelete addObject:fullPath];
        }
    }

    BOOL allSuccess = YES;
    for (NSString *filePath in filesToDelete) {
        NSError *deleteError = nil;
        [fileManager removeItemAtPath:filePath error:&deleteError];
        if (deleteError) {
            allSuccess = NO;
        }
    }

    return allSuccess;
}

@end
