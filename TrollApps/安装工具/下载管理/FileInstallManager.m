//
//  FileInstallManager.m
//  TrollApps
//
//  实现文件安装、下载、类型判断等具体逻辑
//

#import "FileInstallManager.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"
#import "DownloadProgressView.h"
#import "NSTask.h"
#import "InjectMainController.h"
#import "DownloadManagerViewController.h"
#import <UIKit/UIKit.h>

@interface FileInstallManager () <DownloadProgressViewDelegate>

/// 网络会话管理器（用于下载任务）
@property (nonatomic, strong) AFURLSessionManager *sessionManager;
/// 统一下载目录（Documents/Downloads）
@property (nonatomic, strong) NSString *tempDirectory;
/// 所有下载任务的数组
@property (nonatomic, strong) NSMutableArray<DownloadTaskModel *> *downloadTasks;
/// 任务状态变化的回调（供UI刷新使用）
@property (nonatomic, copy) TaskStatusChangedBlock taskStatusChanged;

@end

@implementation FileInstallManager

#pragma mark - 单例初始化

+ (instancetype)sharedManager {
    static FileInstallManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化网络会话
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        // 创建统一下载目录（Documents/Downloads）
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                            stringByAppendingPathComponent:@"Downloads"];
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:docDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:docDir
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
        }
        self.tempDirectory = docDir;
        if (error) {
            NSLog(@"创建下载目录失败: %@", error.localizedDescription);
        }
        
        // 初始化任务数组
        self.downloadTasks = [NSMutableArray array];
    }
    return self;
}

#pragma mark - 实现回调注册方法

- (void)registerTaskStatusChangedCallback:(void(^)(void))callback {
    self.taskStatusChanged = callback;
}

#pragma mark - 文件安装核心逻辑

- (void)installFileWithURL:(NSURL *)fileURL completion:(InstallCompletionHandler)completion {
    if (!fileURL) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"FileInstallManager"
                                              code:1001
                                          userInfo:@{NSLocalizedDescriptionKey: @"无效的文件URL"}]);
        }
        return;
    }
    
    // 本地文件直接处理，网络文件先下载
    if ([self isLocalURL:fileURL]) {
        [self handleLocalFileWithURL:fileURL completion:completion];
    } else {
        [self downloadFileWithURL:fileURL completion:^(NSURL * _Nullable localUrl, NSError * _Nullable error) {
            if (error || !localUrl) {
                if(completion){
                    completion(NO, error ?: [NSError errorWithDomain:@"FileInstallManager"
                                                                 code:1002
                                                             userInfo:@{NSLocalizedDescriptionKey: @"下载文件失败"}]);
                }
                
                return;
            }
            [self handleLocalFileWithURL:localUrl completion:completion];
        }];
    }
}

- (void)installFileWithURLString:(NSString *)urlString completion:(InstallCompletionHandler)completion {
    if (!urlString.length) {
        if(completion){
            completion(NO, [NSError errorWithDomain:@"FileInstallManager"
                                                 code:1003
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的URL字符串"}]);
        }
        
        return;
    }
    
    // 对URL字符串进行编码（处理中文、空格等特殊字符）
    NSString *encodedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    
    if (!url) {
        if(completion){
            completion(NO, [NSError errorWithDomain:@"FileInstallManager"
                                                 code:1004
                                             userInfo:@{NSLocalizedDescriptionKey: @"无法解析URL"}]);
        }
        
        return;
    }
    
    [self installFileWithURL:url completion:completion];
}

- (void)installFileWithType:(FileType)fileType fileData:(NSData *)fileData fileName:(NSString *)fileName completion:(InstallCompletionHandler)completion {
    if (!fileData.length) {
        if(completion){
            completion(NO, [NSError errorWithDomain:@"FileInstallManager"
                                                 code:1005
                                             userInfo:@{NSLocalizedDescriptionKey: @"文件数据为空"}]);
        }
        
        return;
    }
    
    // 生成临时文件名（若未指定）
    if (!fileName.length) {
        NSString *ext = [self fileExtensionForType:fileType];
        fileName = [NSString stringWithFormat:@"temp_%ld.%@", (long)NSDate.date.timeIntervalSince1970, ext];
    }
    
    // 保存数据到本地临时文件
    NSString *filePath = [self.tempDirectory stringByAppendingPathComponent:fileName];
    NSError *error;
    if (![fileData writeToFile:filePath options:NSDataWritingAtomic error:&error]) {
        if(completion){
            completion(NO, error);
        }
        
        return;
    }
    
    [self handleLocalFileWithURL:[NSURL fileURLWithPath:filePath] completion:completion];
}

#pragma mark - 本地文件处理

/// 处理本地文件（根据类型执行安装逻辑）
- (void)handleLocalFileWithURL:(NSURL *)fileURL completion:(InstallCompletionHandler)completion {
    NSString *filePath = fileURL.path;
    FileType fileType = [self fileTypeForPath:filePath];
    NSString *fileName = fileURL.lastPathComponent;
    
    [self installFileWithType:fileType fileURL:fileURL fileName:fileName completion:completion];
}

/// 根据文件类型执行具体安装逻辑
- (void)installFileWithType:(FileType)fileType fileURL:(NSURL *)fileURL fileName:(NSString *)fileName completion:(InstallCompletionHandler)completion {
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"准备安装 %@...", fileName]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = NO;
        NSError *error = nil;
        
        // 根据文件类型执行不同安装逻辑
        switch (fileType) {
            case FileTypeIPA:
            case FileTypeTIPA:
                success = [self installFileWithTrollStore:fileURL error:&error];
                break;
            case FileTypeDEB:
                success = [self installDEBFileWithURL:fileURL error:&error];
                break;
            case FileTypeZIP:
                success = [self unzipFileWithURL:fileURL error:&error];
                break;
            case FileTypePLIST:
                success = [self processPLISTFileWithURL:fileURL error:&error];
                break;
            case FileTypeDYLIB:
                success = [self installDYLIBFileWithURL:fileURL error:&error];
                break;
            default:
                error = [NSError errorWithDomain:@"FileInstallManager"
                                           code:1009
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"不支持安装 %@ 类型文件", [self stringForFileType:fileType]]}];
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if(completion){
                completion(success, error);
            }
            
        });
    });
}

#pragma mark - 具体文件类型安装实现

/// 安装IPA/TIPA文件
/**
 使用TrollStore协议安装文件（需设备已安装TrollStore）
 @param fileURL 本地文件的完整路径（如 /var/mobile/Documents/test.ipa）
 @param error 错误信息（传出参数）
 @return 能否正常发起安装请求
 */
- (BOOL)installFileWithTrollStore:(NSURL *)fileURL error:(NSError **)error {
    if (!fileURL ) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1001
                                    userInfo:@{NSLocalizedDescriptionKey: @"文件路径为空"}];
        }
        return NO;
    }
    
    // 1. 将本地文件路径转换为 file:// 协议的URL（关键步骤）
    
    if (!fileURL) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1002
                                    userInfo:@{NSLocalizedDescriptionKey: @"无效的文件路径"}];
        }
        return NO;
    }
    NSString *fileURLString = fileURL.absoluteString; // 确保是 file:// 开头的完整URL
    
    // 2. 对文件URL进行编码（与JS的 encodeURIComponent 对应）
    // URLQueryAllowedCharacterSet 包含 ?&= 等特殊字符，需排除避免破坏协议格式
    NSCharacterSet *allowedChars = [NSCharacterSet URLQueryAllowedCharacterSet].mutableCopy;
    
    NSString *encodedURL = [fileURLString stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
    if (!encodedURL) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1003
                                    userInfo:@{NSLocalizedDescriptionKey: @"URL编码失败"}];
        }
        return NO;
    }
    
    // 3. 构建TrollStore安装协议URL
    NSString *installURLString = [NSString stringWithFormat:@"apple-magnifier://install?url=%@", encodedURL];
    NSURL *installURL = [NSURL URLWithString:installURLString];
    if (!installURL) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1004
                                    userInfo:@{NSLocalizedDescriptionKey: @"安装协议URL无效"}];
        }
        return NO;
    }
    
    // 4. 检查并打开协议
    if ([[UIApplication sharedApplication] canOpenURL:installURL]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:installURL options:@{} completionHandler:^(BOOL success) {
                    if (!success) {
                        NSLog(@"TrollStore协议调用失败");
                    }
                }];
            } else {
                [[UIApplication sharedApplication] openURL:installURL];
            }
        });
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1011
                                    userInfo:@{NSLocalizedDescriptionKey: @"安装失败，请确保已安装TrollStore"}];
        }
        return NO;
    }
}

/// 安装DEB文件（需越狱环境）
- (BOOL)installDEBFileWithURL:(NSURL *)debURL error:(NSError **)error {
    // 检查URL是否有效
    if (!debURL || !debURL.path) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1010
                                    userInfo:@{NSLocalizedDescriptionKey: @"无效的DEB文件URL"}];
        }
        return NO;
    }
    
    // 检查文件是否存在
    NSString *filePath = debURL.path;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1013
                                    userInfo:@{NSLocalizedDescriptionKey: @"DEB文件不存在"}];
        }
        return NO;
    }
    
    // 查找dpkg命令的实际路径
    NSString *dpkgPath = [self findPathForCommand:@"dpkg"];
    if (!dpkgPath) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1015
                                    userInfo:@{NSLocalizedDescriptionKey: @"未找到dpkg命令，请确保已安装dpkg"}];
        }
        return NO;
    }
    
    // 使用找到的dpkg路径执行安装
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = dpkgPath;
    task.arguments = @[@"-i", filePath];
    
    NSPipe *outputPipe = [NSPipe pipe];
    task.standardOutput = outputPipe;
    
    NSPipe *errorPipe = [NSPipe pipe];
    task.standardError = errorPipe;
    
    [task launch];
    [task waitUntilExit];
    
    int exitCode = task.terminationStatus;
    
    // 读取输出信息
    NSData *outputData = [outputPipe.fileHandleForReading readDataToEndOfFile];
    NSString *outputMsg = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    // 读取错误信息
    NSData *errorData = [errorPipe.fileHandleForReading readDataToEndOfFile];
    NSString *errorMsg = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
    
    NSLog(@"dpkg输出: %@", outputMsg);
    NSLog(@"dpkg错误: %@", errorMsg);
    
    if (exitCode != 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1014
                                    userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"DEB安装失败 (退出代码: %d)", exitCode],
                                               NSLocalizedFailureReasonErrorKey: errorMsg}];
        }
        return NO;
    }
    
    return YES;
}


/// 安装DYLIB文件（需越狱环境）
- (BOOL)installDYLIBFileWithURL:(NSURL *)dylibURL error:(NSError **)error {
    // 检查URL是否有效
    if (!dylibURL || !dylibURL.path) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1010
                                    userInfo:@{NSLocalizedDescriptionKey: @"无效的DEB文件URL"}];
        }
        return NO;
    }
    
    // 检查文件是否存在
    NSString *filePath = dylibURL.path;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1013
                                    userInfo:@{NSLocalizedDescriptionKey: @"DEB文件不存在"}];
        }
        return NO;
    }
    
    // 查找命令的实际路径
    NSLog(@"弹窗控制器安装dylib");
    dispatch_async(dispatch_get_main_queue(), ^{
        InjectMainController *vc = [InjectMainController new];
        vc.selectedDylibURL = dylibURL;
        [[vc.view getTopViewController] presentPanModal:vc];
    });
    
    
    return YES;
}

/// 查找命令的路径
- (NSString *)findPathForCommand:(NSString *)command {
    NSArray *possiblePaths = @[
        @"/usr/bin", @"/bin", @"/usr/local/bin", @"/sbin", @"/usr/sbin"
    ];
    
    for (NSString *path in possiblePaths) {
        NSString *fullPath = [path stringByAppendingPathComponent:command];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            return fullPath;
        }
    }
    
    return nil;
}

/// 解压ZIP文件（需引入SSZipArchive等解压缩库，当前为示例）
- (BOOL)unzipFileWithURL:(NSURL *)zipURL error:(NSError **)error {
    NSString *fileName = [[zipURL lastPathComponent] stringByDeletingPathExtension];
    NSString *destPath = [self.tempDirectory stringByAppendingPathComponent:fileName];
    
    // 创建解压目录
    NSError *dirError;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:destPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&dirError]) {
        if (error) *error = dirError;
        return NO;
    }
    
    // 实际使用时需替换为真实解压逻辑（如SSZipArchive）
    // 示例：[SSZipArchive unzipFileAtPath:zipURL.path toDestination:destPath error:error];
    return YES;
}

/// 处理PLIST文件（读取配置）
- (BOOL)processPLISTFileWithURL:(NSURL *)plistURL error:(NSError **)error {
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfURL:plistURL];
    if (!plistDict) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager"
                                        code:1015
                                    userInfo:@{NSLocalizedDescriptionKey: @"无法解析PLIST文件"}];
        }
        return NO;
    }
    
    NSLog(@"PLIST文件内容: %@", plistDict);
    return YES;
}

#pragma mark - 文件下载实现

- (void)downloadFileWithURLString:(NSString *)urlString completion:(DownloadCompletionBlock)completion {
    // 处理URL编码（如中文、空格等）
    NSString *encodedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    
    if (!url) {
        if(completion){
            completion(nil, [NSError errorWithDomain:@"FileInstallManager"
                                                 code:1016
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的URL字符串"}]);
        }
        
        return;
    }
    
    [self downloadFileWithURL:url completion:completion];
}

- (void)downloadFileWithURL:(NSURL *)url completion:(DownloadCompletionBlock)completion {
    // 创建下载任务模型
    DownloadTaskModel *taskModel = [DownloadTaskModel taskWithURL:url fileName:[url lastPathComponent]];
    [self.downloadTasks addObject:taskModel];
    
    // 显示下载进度条
    [self showDownloadProgressWithTask:taskModel];
    
    // 开始下载
    __weak typeof(self) weakSelf = self;
    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:[NSURLRequest requestWithURL:url]
                                                                         progress:^(NSProgress *progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新任务进度
            taskModel.totalSize = progress.totalUnitCount;
            taskModel.downloadedSize = progress.completedUnitCount;
            taskModel.progress = progress.fractionCompleted;
            taskModel.status = DownloadStatusDownloading;
            
            // 更新UI进度
            [[DownloadProgressView sharedView] updateProgress:taskModel.progress];
            
            
            // 通知任务状态变化
            if (weakSelf.taskStatusChanged) {
                weakSelf.taskStatusChanged();
            }
        });
    } destination:^NSURL * _Nonnull(NSURL *targetPath, NSURLResponse *response) {
        // 生成本地保存路径
        NSString *savePath = [self.tempDirectory stringByAppendingPathComponent:taskModel.fileName];
        taskModel.localPath = savePath;
        return [NSURL fileURLWithPath:savePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 隐藏进度条
            [[DownloadProgressView sharedView] dismiss];
            
            // 更新任务状态
            if (error) {
                taskModel.status = DownloadStatusFailed;
                if(completion){
                    completion(nil, error);
                }
                
            } else {
                taskModel.status = DownloadStatusCompleted;
                if(completion){
                    completion(filePath, nil);
                }
                
            }
            
            
            // 通知任务状态变化
            if (weakSelf.taskStatusChanged) {
                weakSelf.taskStatusChanged();
            }
        });
    }];
    
    taskModel.task = task;
    [task resume];
    // 通知任务开始
    if (weakSelf.taskStatusChanged) {
        weakSelf.taskStatusChanged();
    }
}

#pragma mark - 下载进度显示

/// 显示下载进度条
- (void)showDownloadProgressWithTask:(DownloadTaskModel *)taskModel {
    DownloadProgressView *progressView = [DownloadProgressView sharedView];
    progressView.delegate = self;
    [progressView showWithTask:taskModel.task fileName:taskModel.fileName];
}

#pragma mark - DownloadProgressViewDelegate 实现

- (void)downloadPause:(NSURLSessionDownloadTask *)task {
    DownloadTaskModel *taskModel = [self taskModelForTask:task];
    [self pauseTask:taskModel];
}

- (void)downloadResume:(NSURLSessionDownloadTask *)task {
    DownloadTaskModel *taskModel = [self taskModelForTask:task];
    [self resumeTask:taskModel];
}

- (void)downloadCancel:(NSURLSessionDownloadTask *)task {
    DownloadTaskModel *taskModel = [self taskModelForTask:task];
    [self cancelTask:taskModel];
}

- (void)downloadRestart:(NSURLSessionDownloadTask *)task {
    DownloadTaskModel *taskModel = [self taskModelForTask:task];
    [self restartTask:taskModel];
}

- (void)iconClick:(NSURLSessionDownloadTask *)task{
    DownloadManagerViewController *vc =[DownloadManagerViewController sharedInstance];
    [[vc.view getTopViewController] presentPanModal:vc];
}

#pragma mark - 下载任务管理

/// 根据系统任务找到对应的模型
- (DownloadTaskModel *)taskModelForTask:(NSURLSessionTask *)task {
    for (DownloadTaskModel *model in self.downloadTasks) {
        if (model.task == task) {
            return model;
        }
    }
    return nil;
}

- (NSArray<DownloadTaskModel *> *)allDownloadTasks {
    return [self.downloadTasks copy];
}

- (void)pauseTask:(DownloadTaskModel *)task {
    if (task.status != DownloadStatusDownloading) return;
    [task.task suspend];
    task.status = DownloadStatusPaused;
    if(self.taskStatusChanged){
        self.taskStatusChanged();
    }
    
}

- (void)resumeTask:(DownloadTaskModel *)task {
    if (task.status != DownloadStatusPaused) return;
    [task.task resume];
    task.status = DownloadStatusDownloading;
    
    if(self.taskStatusChanged){
        self.taskStatusChanged();
    }
}

- (void)cancelTask:(DownloadTaskModel *)task {
    [task.task cancelByProducingResumeData:^(NSData *resumeData) {
        task.resumeData = resumeData;
        task.status = DownloadStatusFailed;
        if(self.taskStatusChanged){
            self.taskStatusChanged();
        }
    }];
}

- (void)restartTask:(DownloadTaskModel *)task {
    // 移除旧任务，重新创建下载
    [self.downloadTasks removeObject:task];
    [self downloadFileWithURL:task.url completion:^(NSURL *fileURL, NSError *error) {
        // 复用原有回调逻辑
    }];
}

- (void)removeTask:(DownloadTaskModel *)task {
    if (task && [self.downloadTasks containsObject:task]) {
        [self.downloadTasks removeObject:task];
        // 通知状态变化（触发UI刷新）
        if (self.taskStatusChanged) {
            self.taskStatusChanged();
        }
    }
}

#pragma mark - 辅助方法

/// 根据文件类型获取扩展名
- (NSString *)fileExtensionForType:(FileType)fileType {
    switch (fileType) {
        case FileTypeIPA: return @"ipa";
        case FileTypeTIPA: return @"tipa";
        case FileTypeDEB: return @"deb";
        case FileTypeZIP: return @"zip";
        case FileTypePLIST: return @"plist";
        default: return @"unknown";
    }
}

/// 将文件类型转换为字符串描述
- (NSString *)stringForFileType:(FileType)fileType {
    switch (fileType) {
        case FileTypeIPA: return @"IPA应用";
        case FileTypeTIPA: return @"TIPA巨魔包";
        case FileTypeDEB: return @"DEB插件";
        case FileTypeZIP: return @"ZIP压缩包";
        case FileTypePLIST: return @"PLIST配置";
        default: return @"未知类型";
    }
}

#pragma mark - 判断URL方法

- (BOOL)isLocalURL:(NSURL *)url {
    if (!url) {
        return NO;
    }
    
    // 1. 检查是否为 file:// 协议
    if ([url isFileURL]) {
        return YES;
    }
    
    // 2. 检查是否为 data: 协议（本地数据 URL）
    NSString *scheme = [url scheme];
    if ([scheme.lowercaseString isEqualToString:@"data"]) {
        return YES;
    }
    
    // 3. 检查是否为应用自定义的本地协议（如 app://、bundle:// 等）
    // 这里列出常见的自定义协议，可根据应用实际情况扩展
    NSArray *localSchemes = @[
        @"app", @"bundle", @"resource", @"local", @"assets", @"documents", @"library", @"cache"
    ];
    if ([localSchemes containsObject:scheme.lowercaseString]) {
        return YES;
    }
    
    // 4. 检查是否为本地网络 URL（可选，根据需求决定是否包含）
    // 例如：http://localhost 或 http://127.0.0.1
    /*
    if ([scheme.lowercaseString isEqualToString:@"http"] || [scheme.lowercaseString isEqualToString:@"https"]) {
        NSString *host = [url host];
        if ([host isEqualToString:@"localhost"] || [host isEqualToString:@"127.0.0.1"]) {
            return YES;
        }
    }
    */
    
    return NO;
}

- (BOOL)isWebURL:(NSURL *)url {
    if (!url) {
        return NO;
    }
    
    // 1. 检查是否为 file:// 协议
    if ([url isFileURL]) {
        return YES;
    }
    
    // 2. 检查是否为 data: 协议（本地数据 URL）
    NSString *scheme = [url scheme];
    if ([scheme.lowercaseString isEqualToString:@"data"]) {
        return YES;
    }
    
    // 4. 检查是否为本地网络 URL（可选，根据需求决定是否包含）
    // 例如：http://localhost 或 http://127.0.0.1
   
    if ([scheme.lowercaseString isEqualToString:@"http"] || [scheme.lowercaseString isEqualToString:@"https"]) {
        NSString *host = [url host];
        if ([host isEqualToString:@"localhost"] || [host isEqualToString:@"127.0.0.1"]) {
            return YES;
        }
    }
  
    
    return NO;
}

- (FileType)fileTypeForPath:(NSString *)filePath {
    if (!filePath || filePath.length == 0) {
        return FileTypeUnknown;
    }
    
    // 获取文件扩展名并转为小写
    NSString *extension = [[filePath pathExtension] lowercaseString];
    
    // 根据扩展名判断文件类型
    if ([extension isEqualToString:@"ipa"]) {
        return FileTypeIPA;
    } else if ([extension isEqualToString:@"tipa"]) {
        return FileTypeTIPA;
    } else if ([extension isEqualToString:@"deb"]) {
        return FileTypeDEB;
    } else if ([extension isEqualToString:@"js"]) {
        return FileTypeJS;
    } else if ([extension isEqualToString:@"html"] || [extension isEqualToString:@"htm"]) {
        return FileTypeHTML;
    } else if ([extension isEqualToString:@"json"]) {
        return FileTypeJSON;
    } else if ([extension isEqualToString:@"sh"]) {
        return FileTypeSH;
    } else if ([extension isEqualToString:@"plist"]) {
        return FileTypePLIST;
    } else if ([extension isEqualToString:@"dylib"] || [extension isEqualToString:@"framework"]) {
        return FileTypeDYLIB;
    } else if ([extension isEqualToString:@"zip"] || [extension isEqualToString:@"rar"] ||
               [extension isEqualToString:@"7z"] || [extension isEqualToString:@"tar"] ||
               [extension isEqualToString:@"gz"]) {
        return FileTypeZIP;
    } else {
        return FileTypeOther;
    }
}

@end
