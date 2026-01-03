//
//  PostPublisher.m
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "PostPublisher.h"
#import "AFNetworking.h"
#import "YYModel.h"
#import "NewProfileViewController.h"
#import "TokenGenerator.h"
#import "MediaItem.h"
#import "PostModel.h"
// 宏定义
#define kPostAPIUrl @"https://niceiphone.com/post/post_api.php"
#define kRequestTimeout 30.0

#undef MY_NSLog_ENABLED // 取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // 当前文件单独启用
// PostPublisher.h 保持不变，此处省略


@implementation PostPublisher

+ (instancetype)sharedInstance {
    static PostPublisher *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PostPublisher alloc] init];
    });
    return instance;
}

- (void)publishPost:(PostModel *)postModel
           progress:(PublishProgressBlock)progress
         completion:(PublishCompletionBlock)completion {
    self.mediaItems = postModel.mediaItems;
    // 第一步：上传基本信息
    [self uploadBasicInfo:postModel completion:^(BOOL success, NSString *message, PostModel *updatedPost) {
        if (!success) {
            completion(NO, message, nil);
            return;
        }
        
        // 第二步：上传附件
        [self uploadAttachments:updatedPost progress:progress completion:^(BOOL attachSuccess, NSString *attachMsg ,PostModel *newModel) {
            if (!attachSuccess) {
                completion(NO, attachMsg, updatedPost);
                return;
            }
            
            // 第三步：更新帖子状态为已发布（状态2表示发布成功）
            [self updatePostStatus:2 postModel:newModel completion:^(BOOL statusSuccess, NSString *statusMsg, PostModel *finalPost) {
                completion(statusSuccess, statusMsg, finalPost);
            }];
        }];
    }];
}

#pragma mark - 私有方法：上传基本信息
- (void)uploadBasicInfo:(PostModel *)postModel
             completion:(void(^)(BOOL success, NSString *message, PostModel *updatedPost))completion {
    // 1. PostModel转字典
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[postModel yy_modelToJSONObject]];
    
    // 2. 插入路由action（区分新增/更新）
    params[@"action"] = postModel.post_id > 0 ? @"update_post" : @"publish_post";
    
    // 3. 补充时间戳
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (postModel.post_id == 0) { // 新增
        params[@"post_create_time"] = @(currentTime);
        params[@"post_status"] = @(1); // 初始状态：待上传附件
    }
    params[@"post_update_time"] = @(currentTime);
    
    // 4. 构建请求（内部会处理UDID/Token请求头）
    NSMutableURLRequest *request = [self buildRequestWithParams:params];
    
    // 5. 执行请求
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request
                                                  uploadProgress:nil
                                                downloadProgress:nil
                                               completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"responseObject:%@",responseObject);
        if (error) {
            NSLog(@"上传基本信息错误返回:%@",responseObject);
            completion(NO, error.localizedDescription, nil);
            return;
        }
        
        NSDictionary *result = (NSDictionary *)responseObject;
        NSLog(@"上传基本信息返回:%@",result);
        if ([result[@"code"] integerValue] == 200) {
            PostModel *updatedPost = [PostModel yy_modelWithDictionary:result[@"data"]];
            completion(YES, @"基本信息上传成功", updatedPost);
        } else {
            completion(NO, result[@"msg"] ?: @"基本信息上传失败", nil);
        }
    }];
    [task resume];
}

#pragma mark - 私有方法：上传附件
- (void)uploadAttachments:(PostModel *)postModel
                 progress:(PublishProgressBlock)progress
               completion:(void(^)(BOOL success, NSString *message,PostModel *updatedPost))completion {
    NSLog(@"开始上传附件");
    if (!postModel.post_id) {
        NSLog(@"上传附件 帖子ID不存在，无法上传附件");
        completion(NO, @"帖子ID不存在，无法上传附件",postModel);
        return;
    }
    
    // 收集所有附件（假设MediaItem包含本地路径和类型）
    NSLog(@"收集所有附件");
    
    if (self.mediaItems.count == 0) {
        NSLog(@"无附件需要上传");
        completion(YES, @"无附件需要上传",postModel);
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    __block PostModel *model = postModel;
    __block NSInteger successCount = 0;
    __block NSString *errorMsg = @"";
    __block CGFloat totalProgress = 0;
    CGFloat singleProgressUnit = 1.0 / self.mediaItems.count;
    
    for (MediaItem *item in self.mediaItems) {
        dispatch_group_enter(group);
        [self uploadSingleMedia:item
                      postModel:postModel
                       progress:^(CGFloat singleProgress) {
            totalProgress = successCount * singleProgressUnit + singleProgress * singleProgressUnit;
            if (progress) progress(totalProgress);
        } completion:^(BOOL success, NSString *msg, PostModel *postModel) {
            
            if (success) {
                successCount++;
                model = postModel;
            } else {
                errorMsg = msg;
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (successCount == self.mediaItems.count) {
            NSLog(@"所有附件上传成功");
            completion(YES, @"所有附件上传成功",model);
        } else {
            NSLog(@"部分附件上传失败：%@",errorMsg);
            completion(NO, errorMsg ?: @"部分附件上传失败",model);
        }
    });
}

#pragma mark - 私有方法：更新帖子状态
- (void)updatePostStatus:(NSInteger)status
               postModel:(PostModel *)postModel
              completion:(void(^)(BOOL success, NSString *message, PostModel *postModel))completion {
    // 1. 构建状态更新参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"action"] = @"complete_publish";
    params[@"post_id"] = @(postModel.post_id);
    params[@"post_uuid"] = postModel.post_uuid;
    params[@"post_status"] = @(status);
    params[@"post_publish_time"] = @([[NSDate date] timeIntervalSince1970]);
    
    // 2. 构建请求
    NSMutableURLRequest *request = [self buildRequestWithParams:params];
    
    // 3. 执行请求
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request
                                                  uploadProgress:nil
                                                downloadProgress:nil
                                               completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"responseObject:%@",responseObject);
        if (error) {
            completion(NO, error.localizedDescription, postModel);
            return;
        }
        
        NSDictionary *result = (NSDictionary *)responseObject;
        if ([result[@"code"] integerValue] == 200) {
            PostModel *updatedPost = [PostModel yy_modelWithDictionary:result[@"data"]];
            completion(YES, @"帖子发布成功", updatedPost);
        } else {
            completion(NO, result[@"msg"] ?: @"更新状态失败", postModel);
        }
    }];
    [task resume];
}

#pragma mark - 私有方法：上传单个媒体文件
- (void)uploadSingleMedia:(MediaItem *)item
                postModel:(PostModel *)postModel
                 progress:(void(^)(CGFloat progress))progress
               completion:(void(^)(BOOL success, NSString *message, PostModel *postModel))completion {
    // ========== 1. 区分图片/视频，视频通过PHAsset导出数据 ==========
    __block NSData *fileData = item.fileData;
    NSString *fileName = item.fileName;
    NSString *mimeType = item.fileType;
    
    if (!fileData){
        if (!item.asset) {
            completion(NO, @"视频资源对象为空", nil);
            return;
        }
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:item.asset
                                                          options:options
                                                    resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)asset;
                fileData = [NSData dataWithContentsOfURL:urlAsset.URL];
            }
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (!fileData) {
            completion(NO, @"读取数据失败", nil);
            return;
        }
    }
    
    
    
    
    
    // ========== 2. 构建上传请求 ==========
    // 1. 构建请求头（包含UDID和Token）
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    TokenGenerator *tokenInit = [[TokenGenerator alloc] init];
    NSString *token = [tokenInit generateTokenWithUDID:udid];
    if (udid.length > 0) [headers setObject:udid forKey:@"X-UDID"];
    if (token.length > 0) [headers setObject:token forKey:@"X-Token"];
    
    // 2. 执行文件上传请求（确保action参数正确传递）
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", @"multipart/form-data", nil];
    manager.requestSerializer.timeoutInterval = 30.0; // 延长超时时间（视频上传慢）
    
    // 关键：确保action=upload_attachment在POST参数里
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[postModel yy_modelToJSONObject]];
    [params setValue:@"upload_attachment" forKey:@"action"];
    
    NSLog(@"文件名:%@ mimeType:%@ fileData:%@",fileName,mimeType,fileData);
    [manager POST:kPostAPIUrl
       parameters:params
          headers:headers
constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        // 上传文件数据（必选：name="attachment" 与PHP端$_FILES['attachment']对应）
        [formData appendPartWithFileData:fileData
                                    name:@"attachment"
                                fileName:fileName
                                mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.fractionCompleted);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *result = (NSDictionary *)responseObject;
        NSLog(@"上传成功响应：%@", result);
        if ([result[@"code"] integerValue] == 200) {
            PostModel * postModel= [PostModel yy_modelWithDictionary:result[@"data"]];
            completion(YES, @"上传成功", postModel);
        } else {
            completion(NO, result[@"msg"] ?: @"附件上传失败", nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"上传失败：%@", error.localizedDescription);
        completion(NO, error.localizedDescription, nil);
    }];
}




#pragma mark - 工具方法
- (NSMutableURLRequest *)buildRequestWithParams:(NSDictionary *)params {
    // 1. 基础URL配置
    NSURL *url = [NSURL URLWithString:kPostAPIUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // 2. 请求方法与超时
    request.HTTPMethod = @"POST";
    request.timeoutInterval = kRequestTimeout;
    
    // 3. 补充认证头（UDID/Token）
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    TokenGenerator *tokenInit = [[TokenGenerator alloc] init];
    NSString *token = [tokenInit generateTokenWithUDID:udid];
    if (udid.length > 0) {
        [request setValue:udid forHTTPHeaderField:@"X-UDID"];
    }
    if (token.length > 0) {
        [request setValue:token forHTTPHeaderField:@"X-Token"];
    }
    
    // 4. 处理请求参数（转为JSON数据）
    NSError *jsonError = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError];
    if (jsonError) {
        NSLog(@"[构建请求失败] JSON序列化错误: %@", jsonError.localizedDescription);
        postData = [NSData data]; // 空数据兜底
    }
    request.HTTPBody = postData;
    
    // 5. 设置Content-Type
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // 6. 日志输出（调试用）
    NSString *paramsStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
    NSLog(@"[构建请求成功] URL: %@, 参数: %@", kPostAPIUrl, paramsStr);
    
    return request;
}


#pragma mark - 辅助方法：查找媒体项在本地路径数组中的索引
- (NSInteger)indexOfMediaItem:(MediaItem *)item inLocalPaths:(NSArray<NSString *> *)localPaths {
    // 假设MediaItem的localPath属性存储本地文件路径，用于匹配索引
    if (!item.localPath || !localPaths.count) return NSNotFound;
    
    for (NSInteger i = 0; i < localPaths.count; i++) {
        NSString *localPath = localPaths[i];
        if ([localPath isEqualToString:item.localPath]) {
            return i;
        }
    }
    return NSNotFound;
}
@end
