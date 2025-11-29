//
//  FileUtils.m
//  TrollApps
//
//  Created by 十三哥 on 2025/11/29.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "FileUtils.h"

@implementation FileUtils

+ (BOOL)copyItemFromPath:(NSString *)sourcePath toTargetDir:(NSString *)targetPath overwrite:(BOOL)overwrite error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *targetFullPath = [targetPath stringByAppendingPathComponent:[sourcePath lastPathComponent]];
    
    // 检查目标文件是否存在
    if ([fm fileExistsAtPath:targetFullPath]) {
        if (overwrite) {
            // 覆盖：先删除目标文件
            if (![fm removeItemAtPath:targetFullPath error:error]) {
                return NO;
            }
        } else {
            *error = [NSError errorWithDomain:@"FileUtils" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"目标文件已存在，未开启覆盖"}];
            return NO;
        }
    }
    
    // 复制
    return [fm copyItemAtPath:sourcePath toPath:targetFullPath error:error];
}

+ (BOOL)moveItemFromPath:(NSString *)sourcePath toTargetDir:(NSString *)targetPath overwrite:(BOOL)overwrite error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *targetFullPath = [targetPath stringByAppendingPathComponent:[sourcePath lastPathComponent]];
    
    // 检查目标文件是否存在
    if ([fm fileExistsAtPath:targetFullPath]) {
        if (overwrite) {
            if (![fm removeItemAtPath:targetFullPath error:error]) {
                return NO;
            }
        } else {
            *error = [NSError errorWithDomain:@"FileUtils" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"目标文件已存在，未开启覆盖"}];
            return NO;
        }
    }
    
    // 移动
    return [fm moveItemAtPath:sourcePath toPath:targetFullPath error:error];
}

+ (BOOL)deleteItemAtPath:(NSString *)filePath error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm removeItemAtPath:filePath error:error];
}

+ (NSArray<NSString *> *)getSandboxRootPaths {
    // Documents：用户数据（iTunes备份）
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    // Library：配置文件/缓存（Library/Caches 不备份）
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    // Caches：缓存文件
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    return @[documentsPath, libraryPath, cachesPath];
}

+ (NSString *)formatDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    formatter.timeZone = [NSTimeZone localTimeZone];
    return [formatter stringFromDate:date];
}

@end
