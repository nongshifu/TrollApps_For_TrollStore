//
//  FileInstallManager.h
//  TrollApps
//
//  负责文件的下载、安装、类型判断等核心功能
//

#import <Foundation/Foundation.h>
#import "NewAppFileModel.h"
#import "DownloadTaskModel.h"

NS_ASSUME_NONNULL_BEGIN

// 安装结果回调：success表示是否成功，error为错误信息（失败时非空）
typedef void(^InstallCompletionHandler)(BOOL success, NSError * _Nullable error);
// 下载完成回调：localURL为本地文件路径（成功时非空），error为错误信息
typedef void(^DownloadCompletionBlock)(NSURL * _Nullable localUrl, NSError * _Nullable error);
// 下载任务状态变化回调（用于刷新UI）
typedef void(^TaskStatusChangedBlock)(void);

@interface FileInstallManager : NSObject

/// 获取单例实例
+ (instancetype)sharedManager;

#pragma mark - 文件安装

/**
 根据文件URL安装（自动区分本地/网络文件）
 @param fileURL 本地或网络文件的URL
 @param completion 安装完成后的回调
 */
- (void)installFileWithURL:(NSURL *)fileURL completion:(InstallCompletionHandler)completion;

/**
 根据URL字符串安装文件（自动编码特殊字符）
 @param urlString 本地或网络文件的URL字符串
 @param completion 安装完成后的回调
 */
- (void)installFileWithURLString:(NSString *)urlString completion:(InstallCompletionHandler)completion;

/**
 根据文件类型、数据和文件名安装
 @param fileType 文件类型（如IPA、DEB等）
 @param fileData 文件二进制数据
 @param fileName 文件名（用于确认类型和显示）
 @param completion 安装完成后的回调
 */
- (void)installFileWithType:(FileType)fileType
                   fileData:(NSData *)fileData
                   fileName:(NSString *)fileName
                 completion:(InstallCompletionHandler)completion;

#pragma mark - 文件下载

/**
 下载网络文件（接收URL字符串，自动处理中文编码）
 @param urlString 网络文件的URL字符串
 @param completion 下载完成后的回调
 */
- (void)downloadFileWithURLString:(NSString *)urlString completion:(DownloadCompletionBlock)completion;

/**
 下载网络文件（接收NSURL对象）
 @param url 网络文件的NSURL
 @param completion 下载完成后的回调
 */
- (void)downloadFileWithURL:(NSURL *)url completion:(DownloadCompletionBlock)completion;

#pragma mark - 工具方法

/**
 判断URL是否为本地文件URL
 @param url 待判断的URL
 @return 是本地URL返回YES，否则返回NO
 */
- (BOOL)isLocalURL:(NSURL *)url;


/**
 判断URL是否为网络文件URL
 @param url 待判断的URL
 @return 是网络URL返回YES，否则返回NO
 */
- (BOOL)isWebURL:(NSURL *)url;

/**
 根据文件路径判断文件类型
 @param filePath 文件名或完整路径
 @return 文件类型枚举（如FileTypeIPA、FileTypeDEB等）
 */
- (FileType)fileTypeForPath:(NSString *)filePath;

#pragma mark - 下载任务管理

/**
 注册下载任务状态变化的回调（用于刷新UI）
 @param callback 状态变化时触发的回调
 */
- (void)registerTaskStatusChangedCallback:(TaskStatusChangedBlock)callback;

/**
 获取所有下载任务
 @return 下载任务数组（包含DownloadTaskModel实例）
 */
- (NSArray<DownloadTaskModel *> *)allDownloadTasks;

/**
 暂停下载任务
 @param task 要暂停的任务模型
 */
- (void)pauseTask:(DownloadTaskModel *)task;

/**
 恢复下载任务
 @param task 要恢复的任务模型
 */
- (void)resumeTask:(DownloadTaskModel *)task;

/**
 取消下载任务
 @param task 要取消的任务模型
 */
- (void)cancelTask:(DownloadTaskModel *)task;

/**
 重新下载任务
 @param task 要重新下载的任务模型
 */
- (void)restartTask:(DownloadTaskModel *)task;

/**
 删除任务
 @param task 任务模型
 */
- (void)removeTask:(DownloadTaskModel *)task;

@end

NS_ASSUME_NONNULL_END
