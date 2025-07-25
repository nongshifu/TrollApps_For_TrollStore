//
//  CommandExecutor.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.

//

#import "CommandExecutor.h"
#import "NSTask.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@implementation CommandExecutor

+ (instancetype)shared {
    static CommandExecutor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CommandExecutor alloc] init];
    });
    return instance;
}

#pragma mark - 工具路径查找

- (NSString *)pathForExecutable:(NSString *)name {
    // 1. 优先从应用 Bundle 的 Resources 目录查找
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *path = [resourcePath stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
        return path;
    }
    
    // 2. 查找系统目录（/usr/bin、/bin 等，适用于越狱环境）
    NSArray *systemPaths = @[@"/usr/bin", @"/bin", @"/usr/local/bin", @"/sbin"];
    for (NSString *sysPath in systemPaths) {
        path = [sysPath stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
            return path;
        }
    }
    
    // 3. 查找同目录（如果应用被放置在特殊位置）
    NSString *appPath = [[NSBundle mainBundle] executablePath];
    path = [[appPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
        return path;
    }
    
    return nil; // 未找到工具
}

#pragma mark - 命令执行核心

- (CommandResult)executeCommand:(NSString *)command
                      arguments:(NSArray<NSString *> *)arguments
                          output:(NSString **)output
                           error:(NSString **)errorMsg {
    if (!command || ![[NSFileManager defaultManager] isExecutableFileAtPath:command]) {
        if (errorMsg) *errorMsg = @"命令不存在或不可执行";
        return CommandResultFileNotFound;
    }
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = command;
    task.arguments = arguments;
    
    NSPipe *outputPipe = [NSPipe pipe];
    task.standardOutput = outputPipe;
    task.standardError = outputPipe; // 错误输出也合并到 output
    
    [task launch];
    [task waitUntilExit];
    
    NSData *outputData = [outputPipe.fileHandleForReading readDataToEndOfFile];
    NSString *outputStr = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    if (output) *output = outputStr;
    
    int exitCode = task.terminationStatus;
    if (exitCode != 0) {
        if (errorMsg) *errorMsg = [NSString stringWithFormat:@"命令执行失败（代码：%d）：%@", exitCode, outputStr];
        return CommandResultFailure;
    }
    
    return CommandResultSuccess;
}

- (CommandResult)executeRootCommand:(NSString *)command
                          arguments:(NSArray<NSString *> *)arguments
                              output:(NSString **)output
                               error:(NSString **)errorMsg {
    // 越狱环境下通过 su 或 sudo 获取 root 权限（需设备支持）
    NSMutableArray *rootArgs = [NSMutableArray arrayWithObject:command];
    if (arguments) [rootArgs addObjectsFromArray:arguments];
    
    return [self executeCommand:@"/usr/bin/su" // 或 @"/usr/bin/sudo"，取决于越狱工具
                      arguments:@[@"-c", [rootArgs componentsJoinedByString:@" "]]
                          output:output
                           error:errorMsg];
}

#pragma mark - 常用命令封装

- (BOOL)copyFrom:(NSString *)srcPath to:(NSString *)destPath overwrite:(BOOL)overwrite error:(NSError **)error {
    NSString *cpPath = [self pathForExecutable:@"cp"];
    if (!cpPath) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未找到 cp 工具"}];
        return NO;
    }
    
    NSMutableArray *args = [NSMutableArray array];
    if (overwrite) [args addObject:@"-f"];
    [args addObjectsFromArray:@[@"-rfp", srcPath, destPath]];
    
    NSString *output = nil;
    NSString *errorMsg = nil;
    CommandResult result = [self executeCommand:cpPath arguments:args output:&output error:&errorMsg];
    if (result != CommandResultSuccess) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:result userInfo:@{NSLocalizedDescriptionKey:errorMsg ?: output}];
        return NO;
    }
    return YES;
}

- (BOOL)moveFrom:(NSString *)srcPath to:(NSString *)destPath overwrite:(BOOL)overwrite error:(NSError **)error {
    NSString *mvPath = [self pathForExecutable:@"mv"];
    if (!mvPath) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未找到 mv 工具"}];
        return NO;
    }
    
    NSMutableArray *args = [NSMutableArray array];
    if (overwrite) [args addObject:@"-f"];
    [args addObjectsFromArray:@[srcPath, destPath]];
    
    NSString *output = nil;
    NSString *errorMsg = nil;
    CommandResult result = [self executeCommand:mvPath arguments:args output:&output error:&errorMsg];
    if (result != CommandResultSuccess) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:result userInfo:@{NSLocalizedDescriptionKey:errorMsg ?: output}];
        return NO;
    }
    return YES;
}

- (BOOL)removePath:(NSString *)path recursively:(BOOL)recursive error:(NSError **)error {
    NSString *rmPath = [self pathForExecutable:@"rm"];
    if (!rmPath) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未找到 rm 工具"}];
        return NO;
    }
    
    NSArray *args = recursive ? @[@"-rf", path] : @[@"-f", path];
    
    NSString *output = nil;
    NSString *errorMsg = nil;
    CommandResult result = [self executeCommand:rmPath arguments:args output:&output error:&errorMsg];
    if (result != CommandResultSuccess) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:result userInfo:@{NSLocalizedDescriptionKey:errorMsg ?: output}];
        return NO;
    }
    return YES;
}

- (BOOL)pseudoSignFile:(NSString *)filePath force:(BOOL)force error:(NSError **)error {
    NSString *ldidPath = [self pathForExecutable:@"ldid"];
    if (!ldidPath) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未找到 ldid 工具"}];
        return NO;
    }
    
    NSMutableArray *args = [NSMutableArray array];
    if (force) [args addObject:@"-S"]; // 强制签名（覆盖原有签名）
    [args addObject:filePath];
    
    NSString *output = nil;
    NSString *errorMsg = nil;
    CommandResult result = [self executeRootCommand:ldidPath arguments:args output:&output error:&errorMsg]; // 签名可能需要 root 权限
    if (result != CommandResultSuccess) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:result userInfo:@{NSLocalizedDescriptionKey:errorMsg ?: output}];
        return NO;
    }
    return YES;
}

- (BOOL)insertDylib:(NSString *)dylibPath intoMachO:(NSString *)machOPath weak:(BOOL)weak error:(NSError **)error {
    NSString *insertDylibPath = [self pathForExecutable:@"insert_dylib"];
    if (!insertDylibPath) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未找到 insert_dylib 工具"}];
        return NO;
    }
    
    NSMutableArray *args = [NSMutableArray array];
    if (weak) [args addObject:@"--weak"];
    [args addObjectsFromArray:@[dylibPath, machOPath, @"--inplace"]]; // --inplace 直接修改原文件
    
    NSString *output = nil;
    NSString *errorMsg = nil;
    CommandResult result = [self executeRootCommand:insertDylibPath arguments:args output:&output error:&errorMsg]; // 注入需要 root 权限
    if (result != CommandResultSuccess) {
        if (error) *error = [NSError errorWithDomain:@"CommandExecutor" code:result userInfo:@{NSLocalizedDescriptionKey:errorMsg ?: output}];
        return NO;
    }
    return YES;
}

@end
