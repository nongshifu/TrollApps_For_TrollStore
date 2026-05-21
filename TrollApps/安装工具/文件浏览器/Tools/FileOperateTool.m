#import "FileOperateTool.h"

@implementation FileOperateTool

+ (BOOL)createFolderWithName:(NSString *)folderName atPath:(NSString *)parentPath {
    NSString *folderPath = [parentPath stringByAppendingPathComponent:folderName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    BOOL success = [fileManager createDirectoryAtPath:folderPath
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error];
    return success;
}

+ (BOOL)createFileWithName:(NSString *)fileName atPath:(NSString *)parentPath {
    NSString *filePath = [parentPath stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:filePath]) {
        return NO;
    }

    BOOL success = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    return success;
}

+ (BOOL)deleteItemAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    BOOL success = [fileManager removeItemAtPath:path error:&error];
    return success;
}

+ (BOOL)renameItemAtPath:(NSString *)path newName:(NSString *)newName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *parentPath = [path stringByDeletingLastPathComponent];
    NSString *newPath = [parentPath stringByAppendingPathComponent:newName];
    NSError *error = nil;

    BOOL success = [fileManager moveItemAtPath:path toPath:newPath error:&error];
    return success;
}

+ (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    BOOL success = [fileManager copyItemAtPath:srcPath toPath:destPath error:&error];
    return success;
}

+ (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    BOOL success = [fileManager moveItemAtPath:srcPath toPath:destPath error:&error];
    return success;
}

#pragma mark - 批量修改后缀

+ (NSInteger)batchChangeExtensionInFolder:(NSString *)folderPath
                               oldExtension:(NSString *)oldExtension
                               newExtension:(NSString *)newExtension {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    NSInteger count = 0;

    for (NSString *file in contents) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDir];

        if (!isDir && [[filePath pathExtension] isEqualToString:oldExtension]) {
            NSString *newFilePath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:newExtension];
            if ([fileManager moveItemAtPath:filePath toPath:newFilePath error:nil]) {
                count++;
            }
        }
    }

    return count;
}

+ (NSInteger)batchChangeExtensionRecursiveInFolder:(NSString *)folderPath
                                      oldExtension:(NSString *)oldExtension
                                      newExtension:(NSString *)newExtension {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    NSInteger count = 0;

    for (NSString *file in contents) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDir];

        if (isDir) {
            // 递归遍历子目录
            count += [self batchChangeExtensionRecursiveInFolder:filePath
                                                     oldExtension:oldExtension
                                                     newExtension:newExtension];
        } else if ([[filePath pathExtension] isEqualToString:oldExtension]) {
            // 修改当前文件后缀
            NSString *newFilePath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:newExtension];
            if ([fileManager moveItemAtPath:filePath toPath:newFilePath error:nil]) {
                count++;
            }
        }
    }

    return count;
}

#pragma mark - 批量删除

+ (NSInteger)batchDeleteFilesInFolder:(NSString *)folderPath
                            extension:(NSString *)extension {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    NSInteger count = 0;

    for (NSString *file in contents) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDir];

        if (!isDir && [[filePath pathExtension] isEqualToString:extension]) {
            if ([fileManager removeItemAtPath:filePath error:nil]) {
                count++;
            }
        }
    }

    return count;
}

+ (NSInteger)batchDeleteFilesRecursiveInFolder:(NSString *)folderPath
                                      extension:(NSString *)extension {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    NSInteger count = 0;

    for (NSString *file in contents) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDir];

        if (isDir) {
            // 递归遍历子目录
            count += [self batchDeleteFilesRecursiveInFolder:filePath extension:extension];
        } else if ([[filePath pathExtension] isEqualToString:extension]) {
            // 删除当前文件
            if ([fileManager removeItemAtPath:filePath error:nil]) {
                count++;
            }
        }
    }

    return count;
}

@end