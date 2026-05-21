//
//  PidModel.m
//  BeautyList
//
//  Created by HaoCold on 2020/11/23.
//  Copyright © 2020 HaoCold. All rights reserved.
//

#import "PidModel.h"
#import "NSTask.h"
#import "YYModel.h"
#import <UIKit/UIKit.h>

@implementation PidModel


+ (void)pauseProcessWithPid:(NSInteger)pid{
   
    //脚本方式冻结进程
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSString *cmd=[NSString stringWithFormat:@"kill -STOP %ld",pid];
    
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    
    // 获取运行结果
    NSData *data = [file readDataToEndOfFile];
    NSString* string= [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"got\n %@", string);
    
    
    //内存方式冻结进程 ==
    mach_port_t task_port;
    int longValue = (int)pid;
    kern_return_t kr = task_for_pid(mach_task_self(), longValue, &task_port);
    if (kr != KERN_SUCCESS) {
        NSLog(@"获取 task_port 失败: %d", kr);
        return;
    }
    kr = task_suspend(task_port); // 暂停进程
    
    if (kr != KERN_SUCCESS) {
        NSLog(@"操作失败: %d", kr);
    }
    
}

+ (void)startProcessWithPid:(NSInteger)pid{
   
    //脚本方式恢复进程
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSString *cmd =[NSString stringWithFormat:@"kill -CONT %ld",pid];
    
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    
    // 获取运行结果
    NSData *data = [file readDataToEndOfFile];
    NSString* string= [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"got\n %@", string);
    
    
    //内存方式恢复进程====
    mach_port_t task_port;
    int longValue = (int)pid;
    kern_return_t kr = task_for_pid(mach_task_self(), longValue, &task_port);
    if (kr != KERN_SUCCESS) {
        NSLog(@"获取 task_port 失败: %d", kr);
        return;
    }
    kr = task_resume(task_port);  // 恢复进程
    
    if (kr != KERN_SUCCESS) {
        NSLog(@"操作失败: %d", kr);
    }
    
}

// 通过 PID 和布尔值控制进程（暂停/恢复）
+ (void)controlProcessWithPid:(NSInteger)pid isResume:(BOOL)isResume {
    if (pid <= 0) {
        NSLog(@"无效的 PID: %ld", (long)pid);
        return;
    }
    
    if (isResume) {
        [self startProcessWithPid:pid];
    } else {
        [self pauseProcessWithPid:pid];
    }
}

// 通过进程名控制进程（暂停/恢复）
+ (void)controlProcessWithName:(NSString *)processName isResume:(BOOL)isResume {
    if (!processName || processName.length == 0) {
        NSLog(@"无效的进程名");
        return;
    }
    
    NSArray<NSNumber *> *pids = [self findPidsForProcessName:processName];
    if (pids.count == 0) {
        NSLog(@"未找到进程名为 '%@' 的进程", processName);
        return;
    }
    
    NSLog(@"找到 %lu 个匹配的进程", (unsigned long)pids.count);
    for (NSNumber *pidNumber in pids) {
        NSInteger pid = [pidNumber integerValue];
        [self controlProcessWithPid:pid isResume:isResume];
    }
}

// 查找指定进程名对应的所有 PID
+ (NSArray<NSNumber *> *)findPidsForProcessName:(NSString *)processName {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    
    // 使用 shell 命令 "ps -ax" 获取所有进程信息
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/ps"];
    [task setArguments:@[@"-ax", @"-o", @"pid,comm"]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    [task launch];
    NSFileHandle *file = [pipe fileHandleForReading];
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 解析输出，查找匹配的进程名
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    BOOL isHeader = YES; // 跳过标题行
    
    for (__strong NSString *line in lines) {
        if (isHeader) {
            isHeader = NO;
            continue;
        }
        
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (line.length == 0) continue;
        
        // 分割行：PID 和 进程名
        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (components.count < 2) continue;
        
        NSString *pidString = components[0];
        NSString *comm = components[1];
        
        // 检查进程名是否匹配
        if ([comm containsString:processName]) {
            NSInteger pid = [pidString integerValue];
            [result addObject:@(pid)];
        }
    }
    
    return result;
}


+ (NSArray *)refreshModelArray;
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/bin/ps"];
    [task setArguments:[NSArray arrayWithObjects:@"aux", nil, nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    
    NSString * string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog(@"**** Result: %@", string);
    
    NSArray *array = [self modelArray:string];
//    NSString *json = [array yy_modelToJSONString];
//    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"pidlog.txt"];
//    [json writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];

//    [self showText:json];
    
    return array;
}

+ (NSArray *)modelArray:(NSString *)input
{
    NSString *str = input;
    
    NSArray *arr = [str componentsSeparatedByString:@"\n"];
    //NSLog(@"arr = %@", @(arr.count));
    
    NSMutableArray *marr = @[].mutableCopy;
    NSMutableArray *marr1 = @[].mutableCopy;
    NSString *pre = @" /var/containers/Bundle/Application/";
    NSString *pre1 = @" /Applications/";
    for (NSString *s in arr) {
        if ([s containsString:pre]) {
            [marr addObject:s];
        }else if ([s containsString:pre1]) {
            [marr1 addObject:s];
        }
    }
    
    //NSLog(@"marr = %@", @(marr.count));
    
    // 用户程序
    NSArray *arr1 = [self getModel:marr pre:pre];
    // 系统
    NSArray *arr2 = [self getModel:marr1 pre:pre1];
    
    return @[arr1, arr2];
}

/*
 NSString *log = nil;
 log = [NSString stringWithFormat:@"strs = %@", strs];
 kJHCacheLog(log)
 [[JHLog share] save];
 */

+ (NSArray *)getModel:(NSArray *)marr pre:(NSString *)pre
{
    NSMutableArray *result = @[].mutableCopy;
    for (NSString *s in marr) {
        NSArray *arr = [NSMutableArray arrayWithArray:[s componentsSeparatedByString:pre]];
        
        NSMutableArray *strs = [arr[0] componentsSeparatedByString:@" "].mutableCopy;
        [strs removeObject:@""];
        //NSLog(@"strs = %@", strs);
        
        NSString *name = [[arr[1] componentsSeparatedByString:@".app/"] lastObject];
        if ([name containsString:@"/"]) {
            break;
        }
        
        //
        PidModel *model = [[PidModel alloc] init];
        model.name = name;
        model.pid = strs[1];
        
        [result addObject:model];
    }
    return result;
}

+ (void)showText:(NSString *)text
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:text preferredStyle:UIAlertControllerStyleAlert];
    [[UIApplication sharedApplication].windows[0].rootViewController presentViewController:alert animated:YES completion:nil];
}


/// 读取系统进程和用户进程数组，包含名称和PID
/// @return 数组格式：@[用户进程数组, 系统进程数组]，每个元素为字典@{@"name": 进程名, @"pid": PID}
+ (NSArray<NSArray<NSDictionary *> *> *)getAllProcessesWithNameAndPid {
    // 1. 获取所有进程原始数据
    NSString *processRawData = [self getRawProcessData];
    if (!processRawData) {
        NSLog(@"获取进程数据失败");
        return @[[NSArray array], [NSArray array]];
    }
    
    // 2. 解析为用户进程和系统进程数组（PidModel对象）
    NSArray *modelArrays = [self modelArray:processRawData];
    NSArray *userModels = modelArrays[0];    // 用户进程模型数组
    NSArray *systemModels = modelArrays[1];  // 系统进程模型数组
    
    // 3. 转换为包含名称和PID的字典数组
    NSArray *userProcesses = [self convertModelsToNameAndPid:userModels];
    NSArray *systemProcesses = [self convertModelsToNameAndPid:systemModels];
    
    return @[userProcesses, systemProcesses];
}

#pragma mark - 辅助方法

/// 获取原始进程数据（通过ps命令）
+ (NSString *)getRawProcessData {
    NSTask *task = [NSTask new];
    task.launchPath = @"/bin/ps";
    task.arguments = @[@"aux"];  // 显示所有进程的详细信息
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    
    [task launch];
    [task waitUntilExit];  // 等待命令执行完成
    
    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

/// 将PidModel数组转换为包含名称和PID的字典数组
+ (NSArray<NSDictionary *> *)convertModelsToNameAndPid:(NSArray<PidModel *> *)models {
    NSMutableArray *result = [NSMutableArray array];
    for (PidModel *model in models) {
        if (!model.name || !model.pid) continue;
        
        // 过滤无效PID（确保是数字）
        if ([model.pid integerValue] <= 0) continue;
        
        NSDictionary *processInfo = @{
            @"name": model.name,  // 进程名称
            @"pid": model.pid     // 进程PID（字符串类型，可转为NSInteger）
        };
        [result addObject:processInfo];
    }
    return result;
}

@end
