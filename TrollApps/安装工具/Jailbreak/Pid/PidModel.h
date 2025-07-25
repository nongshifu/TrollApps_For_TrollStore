//
//  PidModel.h
//  BeautyList
//
//  Created by HaoCold on 2020/11/23.
//  Copyright © 2020 HaoCold. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach-o/dyld_images.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
NS_ASSUME_NONNULL_BEGIN

@interface PidModel : NSObject

@property (nonatomic,    copy) NSString *name;
@property (nonatomic,    copy) NSString *pid;
@property (nonatomic,  assign) BOOL  selected;

+ (NSArray *)modelArray:(NSString *)input;

+ (NSArray *)refreshModelArray;

/// 通过 PID 和布尔值控制进程（暂停/恢复）
+ (void)controlProcessWithPid:(NSInteger)pid isResume:(BOOL)isResume;

/// 通过进程名控制进程（暂停/恢复）
+ (void)controlProcessWithName:(NSString *)processName isResume:(BOOL)isResume;

/// 查找指定进程名对应的所有 PID
+ (NSArray<NSNumber *> *)findPidsForProcessName:(NSString *)processName;

///暂停进程
+ (void)pauseProcessWithPid:(NSInteger)pid;
///恢复进程
+ (void)startProcessWithPid:(NSInteger)pid;

/// 读取系统进程和用户进程数组，包含名称和PID
/// @return 数组格式：@[用户进程数组, 系统进程数组]，每个元素为字典@{@"name": 进程名, @"pid": PID}
+ (NSArray<NSArray<NSDictionary *> *> *)getAllProcessesWithNameAndPid;

#pragma mark - 辅助方法

/// 获取原始进程数据（通过ps命令）
+ (NSString *)getRawProcessData ;

/// 将PidModel数组转换为包含名称和PID的字典数组
+ (NSArray<NSDictionary *> *)convertModelsToNameAndPid:(NSArray<PidModel *> *)models;

@end

NS_ASSUME_NONNULL_END
