//
//  UploadManager.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import "UploadManager.h"
#import "TaskManager.h"
#import "AFNetworking.h"
#import "YYModel.h"
#import "NetworkClient.h"
#import "config.h"

@interface UploadManager ()

@property (nonatomic, strong) NetworkClient *networkClient;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionTask *> *uploadTasks;  // 统一管理任务（包括数据任务和上传任务）

@property (nonatomic, strong) NSMutableDictionary<NSString *, UploadProgressOnlyBlock> *progressBlocks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UploadSuccessBlock> *successBlocks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UploadFailureBlock> *failureBlocks;

@end

@implementation UploadManager

+ (instancetype)sharedManager {
    static UploadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _networkClient = [NetworkClient sharedClient];  // 初始化 NetworkClient
        _uploadTasks = [NSMutableDictionary dictionary];
        _progressBlocks = [NSMutableDictionary dictionary];
        _successBlocks = [NSMutableDictionary dictionary];
        _failureBlocks = [NSMutableDictionary dictionary];
    }
    return self;
}


- (UploadTask *)createTaskWithAppName:(NSString *)appName
                             bundleID:(NSString *)bundleID
                          versionName:(NSString *)versionName
                         releaseNotes:(NSString *)releaseNotes
                                 tags:(NSArray *)tags
                                 udid:(NSString *)udid
                                 idfv:(NSString *)idfv
                           dictionary:(NSDictionary *)dictionary {
    UploadTask *task = [[UploadTask alloc] init];
    task.task_id = [[NSUUID UUID] UUIDString];
    task.app_name = appName;
    task.bundle_id = bundleID;
    task.version_name = versionName;
    task.release_notes = releaseNotes;
    task.tags = tags;
    task.udid = udid;
    task.idfv = idfv;
    task.status = UploadTaskStatusReady;
    task.fileItems = [NSMutableArray array];
    task.dictionary = dictionary;
    // 保存任务
    [[TaskManager sharedManager] saveTask:task];
    
    return task;
}

- (void)addFileData:(NSData *)fileData fileName:(NSString *)fileName toTask:(UploadTask *)task {
    NSLog(@"开始添加追加文件data到缓存目录");
    
    // 检查是否已存在同名文件
    for (UploadFileItem *existingItem in task.fileItems) {
        if ([existingItem.fileName isEqualToString:fileName]) {
            NSLog(@"文件已存在，跳过添加: %@", fileName);
            return;
        }
    }
    
    // 文件不存在，执行原有逻辑
    UploadFileItem *fileItem = [[UploadFileItem alloc] init];
    fileItem.fileName = fileName;
    fileItem.status = UploadFileStatusReady;
    
    if (!task.fileItems) {
        task.fileItems = [NSMutableArray array];
    }
    
    // 保存文件数据到临时目录
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"upload_temp/%@", fileName]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    // 创建目录（如果不存在）
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:[fileURL URLByDeletingLastPathComponent].path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"创建目录失败: %@", error.localizedDescription);
        return;
    }
    
    // 写入文件
    [fileData writeToURL:fileURL atomically:YES];
    fileItem.fileURL = fileURL.absoluteString;
    NSLog(@"写入文件后fileURL: %@", fileItem.fileURL);
    
    // 添加到任务
    [task.fileItems addObject:fileItem];
    NSLog(@"添加到任务fileItems: %@", task.fileItems);
    
    // 保存任务
    [[TaskManager sharedManager] saveTask:task];
}
- (void)startTask:(UploadTask *)task
         progress:(UploadProgressOnlyBlock)progressBlock
          success:(UploadSuccessBlock)successBlock
          failure:(UploadFailureBlock)failureBlock {
    NSLog(@"开始执行任务 task_id:%@",task.task_id);
    // 从 TaskManager 重新读取任务，确保数据最新
//    UploadTask *latestTask = [[TaskManager sharedManager] getTaskByID:task.task_id];
//    if (!latestTask) {
//        NSLog(@"任务不存在，无法启动");
//        if (failureBlock) {
//            failureBlock([NSError errorWithDomain:@"UploadError" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"任务不存在"}]);
//        }
//        return;
//    }
//    task = latestTask; // 替换为最新任务对象
    
    // 保存回调
    self.progressBlocks[task.task_id] = [progressBlock copy];
    self.successBlocks[task.task_id] = [successBlock copy];
    self.failureBlocks[task.task_id] = [failureBlock copy];
    
    // 更新任务状态
    NSLog(@"更新任务状态 task_appid:%ld 读取任务的文件列表:%@",task.app_id,task.fileItems);
    task.status = UploadTaskStatusUploading;
    [[TaskManager sharedManager] saveTask:task];
    
    // 如果是发布新应用，先创建应用信息
    if (!task.app_id) {
        NSLog(@"传入的app_id为空");
    } else {
        // 如果是更新应用，直接上传文件
        NSLog(@"如果是更新应用，直接上传文件");
        [self uploadFilesForTask:task];
    }
}

- (void)pauseTask:(UploadTask *)task {
    // 更新任务状态
    task.status = UploadTaskStatusPaused;
    [[TaskManager sharedManager] saveTask:task];
    
    // 暂停所有上传任务
    NSURLSessionTask *taskOperation = self.uploadTasks[task.task_id];
    if (taskOperation && taskOperation.state == NSURLSessionTaskStateRunning) {
        [taskOperation suspend];
    }
}

- (void)resumeTask:(UploadTask *)task
          progress:(UploadProgressOnlyBlock)progressBlock
           success:(UploadSuccessBlock)successBlock
           failure:(UploadFailureBlock)failureBlock {
    // 如果任务已完成，直接回调成功
    if (task.status == UploadTaskStatusCompleted) {
        if (successBlock) {
            successBlock(nil);
        }
        return;
    }
    
    // 保存回调
    self.progressBlocks[task.task_id] = [progressBlock copy];
    self.successBlocks[task.task_id] = [successBlock copy];
    self.failureBlocks[task.task_id] = [failureBlock copy];
    
    // 更新任务状态
    task.status = UploadTaskStatusUploading;
    [[TaskManager sharedManager] saveTask:task];
    
    // 继续上传文件
    [self uploadFilesForTask:task];
}

#pragma mark - Private Methods

- (void)uploadFilesForTask:(UploadTask *)task {
    // 确保 fileItems 不为 nil
    if (!task.fileItems) {
        task.fileItems = [NSMutableArray array];
        NSLog(@"警告：任务 %@ 的 fileItems 为 nil，已初始化为空数组", task.task_id);
    }
    // 查找下一个未完成的文件
    NSLog(@"查找下一个未完成的文件task.fileItems：%@",task.fileItems);
    NSInteger nextIndex = -1;
    for (NSInteger i = 0; i < task.fileItems.count; i++) {
        UploadFileItem *fileItem = task.fileItems[i];
        NSLog(@"遍历fileItem：%@ fileURL:%@ status:%ld",fileItem.fileName,fileItem.fileURL,fileItem.status);
        if (fileItem.status != UploadFileStatusCompleted) {
            nextIndex = i;
            break;
        }
    }
    NSLog(@"遍历nextIndex后:%ld",nextIndex);
    if (nextIndex >= 0) {
        UploadFileItem *fileItem = task.fileItems[nextIndex];
        
        // 如果文件处于失败状态，重置它
        if (fileItem.status == UploadFileStatusFailed) {
            fileItem.status = UploadFileStatusReady;
            
            [[TaskManager sharedManager] saveTask:task];
        }
        
        // 更新任务状态
        NSLog(@"查找完成 更新任务状态");
        task.status = UploadTaskStatusUploading;
        [[TaskManager sharedManager] saveTask:task];
        
        // 上传文件
        NSLog(@"开始上传发送文件fileItem：%@  task:%@",fileItem,task);
        [self uploadFile:fileItem atIndex:nextIndex forTask:task];
    } else {
        // 所有文件上传完成，完成任务
        [self finalizeTask:task];
    }
}

- (void)uploadFile:(UploadFileItem *)fileItem atIndex:(NSInteger)index forTask:(UploadTask *)task {
    // 原始参数（会被 NetworkClient 封装到 data 中）
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"app_id"] = @(task.app_id);
    params[@"task_id"] = task.task_id;
    params[@"action"] = @"uploadFile";
    
    NSLog(@"开始上传发送字典数据：%@ ",params);
    
    // 获取文件数据（从本地路径读取）
    NSURL *fileURL = [NSURL URLWithString:fileItem.fileURL];
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    if (!fileData) {
        NSLog(@"文件数据读取失败 不是data");
        [self handleFileFailureWithFile:fileItem atIndex:index forTask:task error:[NSError errorWithDomain:@"UploadError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"文件数据读取失败"}]];
        return;
    }
    
    // 更新文件状态
    fileItem.status = UploadFileStatusUploading;
    [[TaskManager sharedManager] saveTask:task];
    
    // 调用 NetworkClient 的文件上传方法，自动添加 udid 和 token
    NSLog(@"NetworkClient 的文件上传方法，自动添加 udid 和 token");
    NSURLSessionUploadTask *uploadTask = [self.networkClient uploadFileWithURLString:[NSString stringWithFormat:@"%@/app/app_api.php",localURL]
                                                                            fileData:fileData
                                                                            fileName:fileItem.fileName
                                                                          parameters:params  // 原始参数，会被封装到 data 中
                                                                                udid:task.udid  // 传入 udid，自动生成 token
                                                                            progress:^(NSProgress *progress) {
        // 进度回调（与原逻辑一致）
        NSLog(@"进度回调");
        fileItem.progress = progress.fractionCompleted;
        
        
        // 计算总进度
        float totalProgress = 0;
        for (UploadFileItem *item in task.fileItems) {
            totalProgress += item.progress;
        }
        totalProgress /= task.fileItems.count;
        
        task.progress = totalProgress;
        
        NSLog(@"进度:%f",task.progress);
        [[TaskManager sharedManager] saveTask:task];
        
        // 回调进度
        UploadProgressOnlyBlock progressBlock = self.progressBlocks[task.task_id];
        if (progressBlock) {
            progressBlock(totalProgress);
        }
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        // 解析响应（与原逻辑一致）
        NSLog(@"解析上传响应stringResult：%@",stringResult);
        if ([jsonResult isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = jsonResult;
            NSLog(@"解析上传响应response：%@",response);
            NSString *msg = response[@"msg"];
            
            NSInteger code = [response[@"code"] intValue];
            if (code == 200) {
                
                fileItem.status = UploadFileStatusCompleted;
                [[TaskManager sharedManager] saveTask:task];
                NSLog(@"继续上传下一个文件");
                [self uploadFilesForTask:task];  // 继续上传下一个文件
            } else {
                NSLog(@"解析上传响应msg：%@",msg);
                [self handleFileFailureWithFile:fileItem atIndex:index forTask:task error:[NSError errorWithDomain:@"UploadError" code:code userInfo:@{NSLocalizedDescriptionKey: msg}]];
                
            }
        } else {
            NSLog(@"解析上传响应非字典：%@",stringResult);
            
            [self handleFileFailureWithFile:fileItem atIndex:index forTask:task error:[NSError errorWithDomain:@"UploadError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"服务器响应格式错误"}]];
        }
    } failure:^(NSError *error) {
        NSLog(@"解析上传响应失败error：%@",error);
        
        [self handleFileFailureWithFile:fileItem atIndex:index forTask:task error:error];
    }];
    
    // 保存任务引用
    self.uploadTasks[task.task_id] = uploadTask;
}


// 改造：最终确认任务（调用 NetworkClient 的 POST 方法）
- (void)finalizeTask:(UploadTask *)task {
    NSLog(@"最终确认任务完成");
    
    
    task.status = UploadTaskStatusCompleted;
    task.progress = 1.0;
    
    UploadSuccessBlock successBlock = self.successBlocks[task.task_id];
    if (successBlock) {
        successBlock(nil);
    }
    
    // 清理
    [self.uploadTasks removeObjectForKey:task.task_id];
    [self.progressBlocks removeObjectForKey:task.task_id];
    [self.successBlocks removeObjectForKey:task.task_id];
    [self.failureBlocks removeObjectForKey:task.task_id];
    
    [[TaskManager sharedManager] saveTask:task];
}


- (void)handleFileFailureWithFile:(UploadFileItem *)fileItem atIndex:(NSInteger)index forTask:(UploadTask *)task error:(NSError *)error {
    // 标记文件为失败
    fileItem.status = UploadFileStatusFailed;
    
    [[TaskManager sharedManager] saveTask:task];
    
    // 标记任务为失败
    task.status = UploadTaskStatusFailed;
    [[TaskManager sharedManager] saveTask:task];
    
    // 回调失败
    UploadFailureBlock failureBlock = self.failureBlocks[task.task_id];
    if (failureBlock) {
        failureBlock(error);
    }
    
    // 清理
    [self.uploadTasks removeObjectForKey:task.task_id];
    [self.progressBlocks removeObjectForKey:task.task_id];
    [self.successBlocks removeObjectForKey:task.task_id];
    [self.failureBlocks removeObjectForKey:task.task_id];
}

- (void)handleTaskFailureWithTask:(UploadTask *)task error:(NSError *)error {
    // 标记任务为失败
    task.status = UploadTaskStatusFailed;
    [[TaskManager sharedManager] saveTask:task];
    
    // 回调失败
    UploadFailureBlock failureBlock = self.failureBlocks[task.task_id];
    if (failureBlock) {
        failureBlock(error);
    }
    
    // 清理
    [self.uploadTasks removeObjectForKey:task.task_id];
    [self.progressBlocks removeObjectForKey:task.task_id];
    [self.successBlocks removeObjectForKey:task.task_id];
    [self.failureBlocks removeObjectForKey:task.task_id];
}

@end
