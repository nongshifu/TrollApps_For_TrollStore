//
//  TaskManager.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import "UploadManager.h"
NS_ASSUME_NONNULL_BEGIN


// 存储相关的宏定义
#define kUploadTasksKey @"com.trollapps.upload.tasks"
#define kUploadTaskPrefix @"com.trollapps.upload.task."



@interface TaskManager : NSObject

+ (instancetype)sharedManager;

// 保存任务
- (void)saveTask:(UploadTask *)task;

//更新任务
- (void)updateTask:(UploadTask *)task ;

// 删除任务
- (void)deleteTask:(UploadTask *)task;

// 获取所有任务
- (NSArray<UploadTask *> *)getAllTasks;

// 获取未完成的任务
- (NSArray<UploadTask *> *)getIncompleteTasks;

// 通过任务ID获取任务
- (UploadTask *)getTaskByID:(NSString *)taskID;

// 通过应用ID获取任务
- (UploadTask *)getTaskByAppID:(NSInteger)appID;
@end

NS_ASSUME_NONNULL_END
