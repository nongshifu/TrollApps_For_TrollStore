// TaskManager.m
#import "TaskManager.h"
#import "UploadTask.h"
#import "UploadFileItem.h"
#import "YYModel.h"

@implementation TaskManager

+ (instancetype)sharedManager {
    static TaskManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)updateTask:(UploadTask *)task {
    // 直接保存更新后的任务
    [[TaskManager sharedManager] saveTask:task];
}
- (void)saveTask:(UploadTask *)task {
    NSLog(@"保存任务前 fileItems 数量: %lu", (unsigned long)task.fileItems.count);
    
    // 直接使用 YYModel 转换为 JSON 数据
    NSData *taskData = [task yy_modelToJSONData];
    if (!taskData) {
        NSLog(@"任务序列化失败，fileItems 可能包含不可序列化对象");
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *taskIDs = [[defaults objectForKey:kUploadTasksKey] mutableCopy] ?: [NSMutableArray array];
    if (![taskIDs containsObject:task.task_id]) {
        [taskIDs addObject:task.task_id];
        [defaults setObject:taskIDs forKey:kUploadTasksKey];
    }
    
    // 保存 JSON 数据
    [defaults setObject:taskData forKey:[NSString stringWithFormat:@"%@%@", kUploadTaskPrefix, task.task_id]];
    [defaults synchronize];
}

- (void)deleteTask:(UploadTask *)task {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 从任务ID列表中移除
    NSMutableArray *taskIDs = [[defaults objectForKey:kUploadTasksKey] mutableCopy];
    if (taskIDs && [taskIDs containsObject:task.task_id]) {
        [taskIDs removeObject:task.task_id];
        [defaults setObject:taskIDs forKey:kUploadTasksKey];
    }
    
    // 删除任务数据
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@%@", kUploadTaskPrefix, task.task_id]];
    [defaults synchronize];
}

- (NSArray<UploadTask *> *)getAllTasks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *taskIDs = [defaults objectForKey:kUploadTasksKey];
    
    NSMutableArray *tasks = [NSMutableArray array];
    if (taskIDs) {
        for (NSString *taskID in taskIDs) {
            UploadTask *task = [self getTaskByID:taskID];
            if (task) {
                [tasks addObject:task];
            }
        }
    }
    
    return tasks;
}

- (NSArray<UploadTask *> *)getIncompleteTasks {
    NSArray *allTasks = [self getAllTasks];
    NSMutableArray *incompleteTasks = [NSMutableArray array];
    
    for (UploadTask *task in allTasks) {
        if (task.status != UploadTaskStatusCompleted && task.status != UploadTaskStatusFailed) {
            [incompleteTasks addObject:task];
        }
    }
    
    return incompleteTasks;
}


// 修改 getTaskByID: 方法
- (UploadTask *)getTaskByID:(NSString *)taskID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *taskData = [defaults objectForKey:[NSString stringWithFormat:@"%@%@", kUploadTaskPrefix, taskID]];
    if (!taskData) return nil;
    
    // 直接用 YYModel 解析 JSON 数据
    UploadTask *task = [UploadTask yy_modelWithJSON:taskData];
    NSLog(@"读取任务后 fileItems 数量: %lu", (unsigned long)task.fileItems.count);
    return task;
}

- (UploadTask *)getTaskByAppID:(NSInteger)appID {
    NSArray *allTasks = [self getAllTasks];
    
    for (UploadTask *task in allTasks) {
        if (task.app_id == appID) {
            return task;
        }
    }
    
    return nil;
}

@end
