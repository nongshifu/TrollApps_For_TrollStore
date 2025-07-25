//
//  UploadManager.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import "UploadTask.h"

typedef void(^UploadProgressOnlyBlock)(float progress);
typedef void(^UploadSuccessBlock)(NSDictionary *response);
typedef void(^UploadFailureBlock)(NSError *error);

@interface UploadManager : NSObject

+ (instancetype)sharedManager;

/**
 创建新的上传任务

 @param appName 应用名称
 @param bundleID 应用Bundle ID
 @param versionName 版本号
 @param releaseNotes 发布说明
 @param tags 标签数组
 @param udid 用户设备唯一标识
 @param idfv 应用安装唯一标识
 @return 新创建的上传任务
 */
- (UploadTask *)createTaskWithAppName:(NSString *)appName
                             bundleID:(NSString *)bundleID
                          versionName:(NSString *)versionName
                         releaseNotes:(NSString *)releaseNotes
                                tags:(NSArray *)tags
                                udid:(NSString *)udid
                                idfv:(NSString *)idfv
                           dictionary:(NSDictionary *)dictionary;

/**
 向任务添加文件

 @param fileData 文件数据
 @param fileName 文件名
 @param task 目标任务
 */
- (void)addFileData:(NSData *)fileData fileName:(NSString *)fileName toTask:(UploadTask *)task;

/**
 开始上传任务

 @param task 要上传的任务
 @param progressBlock 进度回调
 @param successBlock 成功回调
 @param failureBlock 失败回调
 */
- (void)startTask:(UploadTask *)task
         progress:(UploadProgressOnlyBlock)progressBlock
          success:(UploadSuccessBlock)successBlock
          failure:(UploadFailureBlock)failureBlock;

/**
 暂停上传任务

 @param task 要暂停的任务
 */
- (void)pauseTask:(UploadTask *)task;

/**
 恢复上传任务

 @param task 要恢复的任务
 @param progressBlock 进度回调
 @param successBlock 成功回调
 @param failureBlock 失败回调
 */
- (void)resumeTask:(UploadTask *)task
          progress:(UploadProgressOnlyBlock)progressBlock
           success:(UploadSuccessBlock)successBlock
           failure:(UploadFailureBlock)failureBlock;

@end    
