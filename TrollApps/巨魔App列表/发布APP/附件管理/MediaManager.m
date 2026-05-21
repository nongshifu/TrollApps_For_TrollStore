//
//  MediaManager.m
//  TrollApps
//
//  媒体管理器 - 处理截图/视频的上传、删除
//

#import "MediaManager.h"
#import "config.h"
#import "MediaItemModel.h"
#import "NetworkClient.h"
#import "TokenGenerator.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用
@interface MediaManager ()

@property (nonatomic, strong) NSURLSession *uploadSession;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionTask *> *uploadTasks;
@property (nonatomic, assign) BOOL isCancelled;

@end

@implementation MediaManager

+ (instancetype)sharedInstance {
    static MediaManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MediaManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 60;
        config.timeoutIntervalForResource = 300;
        _uploadSession = [NSURLSession sessionWithConfiguration:config];
        _uploadTasks = [NSMutableDictionary dictionary];
        _isCancelled = NO;
    }
    return self;
}

#pragma mark - 上传单个文件

- (void)uploadImage:(UIImage *)image completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSError * _Nullable error))completion {
    if (!image) {
        if (completion) completion(NO, nil, nil, [NSError errorWithDomain:@"MediaManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"图片不能为空"}]);
        NSLog(@"图片文件数为空");
        return;
    }
    
    // 压缩图片
    NSLog(@"压缩图片0.8");
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) {
        imageData = UIImagePNGRepresentation(image);
    }
    NSLog(@"压缩图片imageData:%@",imageData);
    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSMutableData *body = [NSMutableData data];
    
    // 添加文件数据
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"screenshot.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 准备data字典
    NSDictionary *dataDict = @{
        @"app_id": @(self.appId > 0 ? self.appId : 0),
        @"version_code": @(self.versionCode > 0 ? self.versionCode : 1),
        @"file_type": @"screenshot"
    };
    
    // 将data字典序列化为JSON字符串
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:nil];
    NSString *jsonString = jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"";
    
    // 生成新token
    NSString *newToken = [[TokenGenerator sharedGenerator] generateTokenWithUDID:self.udid];
    
    // 添加其他参数
    NSDictionary *params = @{
        @"udid": self.udid ?: @"",
        @"token": newToken,
        @"data": jsonString
    };
    NSLog(@"上传图片：%@",params);
    for (NSString *key in params) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", params[key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/modules/app/api.php", localURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self.uploadSession uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"上传图片返回错误：%@",error);
                if (completion) completion(NO, nil, nil, error);
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"上传图片返回json：%@",json);
            if ([json[@"code"] integerValue] == 0) {
                NSDictionary *fileInfo = json[@"data"][@"files"][0];
                NSString *fileName = fileInfo[@"fileName"];
                NSString *fileURL = fileInfo[@"fileURL"];
                if (completion) completion(YES, fileName, fileURL, nil);
            } else {
                NSError *serverError = [NSError errorWithDomain:@"MediaManager" code:[json[@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey: json[@"msg"] ?: @"上传失败"}];
                if (completion) completion(NO, nil, nil, serverError);
            }
        });
    }];
    
    [task resume];
}

- (void)uploadIconImage:(UIImage *)image completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSError * _Nullable error))completion {
    if (!image) {
        if (completion) completion(NO, nil, nil, [NSError errorWithDomain:@"MediaManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"图片不能为空"}]);
        NSLog(@"图片文件数为空");
        return;
    }
    
    // 压缩图片
    NSLog(@"压缩图片0.8");
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) {
        imageData = UIImagePNGRepresentation(image);
    }
    NSLog(@"压缩图片imageData:%@",imageData);
    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSMutableData *body = [NSMutableData data];
    
    // 添加文件数据
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"icon.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 准备data字典
    NSDictionary *dataDict = @{
        @"app_id": @(self.appId > 0 ? self.appId : 0),
        @"version_code": @(self.versionCode > 0 ? self.versionCode : 1),
        @"file_type": @"icon"
    };
    
    // 将data字典序列化为JSON字符串
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:nil];
    NSString *jsonString = jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"";
    
    // 生成新token
    NSString *newToken = [[TokenGenerator sharedGenerator] generateTokenWithUDID:self.udid];
    
    // 添加其他参数
    NSDictionary *params = @{
        @"udid": self.udid ?: @"",
        @"token": newToken,
        @"data": jsonString
    };
    NSLog(@"上传图片：%@",params);
    for (NSString *key in params) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", params[key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/modules/app/api.php", localURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self.uploadSession uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"上传图片返回错误：%@",error);
                if (completion) completion(NO, nil, nil, error);
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"上传图片返回json：%@",json);
            if ([json[@"code"] integerValue] == 0) {
                NSDictionary *fileInfo = json[@"data"][@"files"][0];
                NSString *fileName = fileInfo[@"fileName"];
                NSString *fileURL = fileInfo[@"fileURL"];
                if (completion) completion(YES, fileName, fileURL, nil);
            } else {
                NSError *serverError = [NSError errorWithDomain:@"MediaManager" code:[json[@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey: json[@"msg"] ?: @"上传失败"}];
                if (completion) completion(NO, nil, nil, serverError);
            }
        });
    }];
    
    [task resume];
}

- (void)uploadVideo:(NSURL *)videoURL completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSString * _Nullable thumbnailFileName, NSString * _Nullable thumbnailURL, CGFloat duration, NSError * _Nullable error))completion {
    if (!videoURL) {
        if (completion) completion(NO, nil, nil, nil, nil, 0, [NSError errorWithDomain:@"MediaManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"视频不能为空"}]);
        return;
    }
    
    // 先获取视频时长
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    CGFloat duration = CMTimeGetSeconds(asset.duration);
    
    // 读取视频数据
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    if (!videoData) {
        if (completion) completion(NO, nil, nil, nil, nil, 0, [NSError errorWithDomain:@"MediaManager" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"无法读取视频文件"}]);
        return;
    }
    
    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSMutableData *body = [NSMutableData data];
    
    // 获取文件扩展名
    NSString *fileExtension = videoURL.pathExtension ?: @"mp4";
    NSString *fileName = [NSString stringWithFormat:@"video.%@", fileExtension];
    
    // 添加文件数据
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: video/%@\r\n\r\n", fileExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:videoData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 准备data字典
    NSDictionary *dataDict = @{
        @"app_id": @(self.appId > 0 ? self.appId : 0),
        @"version_code": @(self.versionCode > 0 ? self.versionCode : 1),
        @"file_type": @"video"
    };
    
    // 将data字典序列化为JSON字符串
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:nil];
    NSString *jsonString = jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"";
    
    // 生成新token
    NSString *newToken = [[TokenGenerator sharedGenerator] generateTokenWithUDID:self.udid];
    
    // 添加其他参数
    NSDictionary *params = @{
        @"udid": self.udid ?: @"",
        @"token": newToken,
        @"data": jsonString
    };
    
    for (NSString *key in params) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", params[key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/modules/app/api.php", localURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self.uploadSession uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"上传视频返回错误：%@",error);
                if (completion) completion(NO, nil, nil, nil, nil, 0, error);
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"上传视频返回json：%@",json);
            if ([json[@"code"] integerValue] == 0) {
                NSDictionary *fileInfo = json[@"data"][@"files"][0];
                NSString *fileName = fileInfo[@"fileName"];
                NSString *fileURL = fileInfo[@"fileURL"];
                NSString *thumbURL = fileInfo[@"thumbnailURL"];
                
                // 提取缩略图文件名
                NSString *thumbnailFileName = nil;
                if (thumbURL && thumbURL.length > 0) {
                    thumbnailFileName = [thumbURL lastPathComponent];
                }
                
                if (completion) completion(YES, fileName, fileURL, thumbnailFileName, thumbURL, duration, nil);
            } else {
                NSError *serverError = [NSError errorWithDomain:@"MediaManager" code:[json[@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey: json[@"msg"] ?: @"上传失败"}];
                if (completion) completion(NO, nil, nil, nil, nil, 0, serverError);
            }
        });
    }];
    
    [task resume];
}

- (void)uploadMainFile:(NSData *)fileData fileName:(NSString *)fileName completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSError * _Nullable error))completion {
    if (!fileData) {
        if (completion) completion(NO, nil, nil, [NSError errorWithDomain:@"MediaManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"主文件不能为空"}]);
        return;
    }
    
    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSMutableData *body = [NSMutableData data];
    
    // 获取文件扩展名
    NSString *fileExtension = fileName.pathExtension ?: @"file";
    NSLog(@"获取文件扩展名：%@",fileExtension);
    // 添加文件数据
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:fileData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 准备data字典
    NSDictionary *dataDict = @{
        @"app_id": @(self.appId > 0 ? self.appId : 0),
        @"version_code": @(self.versionCode > 0 ? self.versionCode : 1),
        @"file_type": @"main"
    };
    
    // 将data字典序列化为JSON字符串
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:nil];
    NSString *jsonString = jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"";
    
    // 生成新token
    NSString *newToken = [[TokenGenerator sharedGenerator] generateTokenWithUDID:self.udid];
    
    // 添加其他参数
    NSDictionary *params = @{
        @"udid": self.udid ?: @"",
        @"token": newToken,
        @"data": jsonString
    };
    
    for (NSString *key in params) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", params[key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/modules/app/api.php", localURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self.uploadSession uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"上传主文件返回错误：%@",error);
                if (completion) completion(NO, nil, nil, error);
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"上传主文件返回json：%@",json);
            if ([json[@"code"] integerValue] == 0) {
                NSDictionary *fileInfo = json[@"data"][@"files"][0];
                NSString *fileName = fileInfo[@"fileName"];
                NSString *fileURL = fileInfo[@"fileURL"];
                if (completion) completion(YES, fileName, fileURL, nil);
            } else {
                NSError *serverError = [NSError errorWithDomain:@"MediaManager" code:[json[@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey: json[@"msg"] ?: @"上传失败"}];
                if (completion) completion(NO, nil, nil, serverError);
            }
        });
    }];
    
    [task resume];
}

#pragma mark - 批量上传

- (void)uploadMediaItems:(NSArray<MediaItem *> *)items
                progress:(void(^)(NSInteger completed, NSInteger total, CGFloat progress))progressCallback
              completion:(void(^)(NSDictionary *results))completion {
    if (items.count == 0) {
        if (completion) completion(@{});
        return;
    }
    
    self.isCancelled = NO;
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    __block NSInteger completedCount = 0;
    
    dispatch_group_t group = dispatch_group_create();
    
    for (MediaItemModel *item in items) {
        if (self.isCancelled) break;
        
        dispatch_group_enter(group);
        
        if (item.mediaType == MediaItemTypeIcon) {
            // 上传图片
            UIImage *image = item.localImage;
            if (!image && item.localData) {
                image = [UIImage imageWithData:item.localData];
            }
            [self uploadIconImage:image completion:^(BOOL success, NSString *fileName, NSString *fileURL, NSError *error) {
                @synchronized (results) {
                    results[item.identifier] = @{
                        @"success": @(success),
                        @"fileName": fileName ?: [NSNull null],
                        @"fileURL": fileURL ?: [NSNull null],
                        @"error": error ?: [NSNull null]
                    };
                    completedCount++;
                    if (progressCallback) {
                        progressCallback(completedCount, items.count, (CGFloat)completedCount / items.count);
                    }
                }
                dispatch_group_leave(group);
            }];
        }else if (item.mediaType == MediaItemTypeImage) {
            // 上传图片
            UIImage *image = item.localImage;
            if (!image && item.localData) {
                image = [UIImage imageWithData:item.localData];
            }
            [self uploadImage:image completion:^(BOOL success, NSString *fileName, NSString *fileURL, NSError *error) {
                @synchronized (results) {
                    results[item.identifier] = @{
                        @"success": @(success),
                        @"fileName": fileName ?: [NSNull null],
                        @"fileURL": fileURL ?: [NSNull null],
                        @"error": error ?: [NSNull null]
                    };
                    completedCount++;
                    if (progressCallback) {
                        progressCallback(completedCount, items.count, (CGFloat)completedCount / items.count);
                    }
                }
                dispatch_group_leave(group);
            }];
        } else if (item.mediaType == MediaItemTypeVideo) {
            // 上传视频
            [self uploadVideo:item.localVideoURL completion:^(BOOL success, NSString *fileName, NSString *fileURL, NSString *thumbnailFileName, NSString *thumbnailURL, CGFloat duration, NSError *error) {
                @synchronized (results) {
                    results[item.identifier] = @{
                        @"success": @(success),
                        @"fileName": fileName ?: [NSNull null],
                        @"fileURL": fileURL ?: [NSNull null],
                        @"thumbnailFileName": thumbnailFileName ?: [NSNull null],
                        @"thumbnailURL": thumbnailURL ?: [NSNull null],
                        @"duration": @(duration),
                        @"error": error ?: [NSNull null]
                    };
                    completedCount++;
                    if (progressCallback) {
                        progressCallback(completedCount, items.count, (CGFloat)completedCount / items.count);
                    }
                }
                dispatch_group_leave(group);
            }];
        } else {
            dispatch_group_leave(group);
        }
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) completion(results);
    });
}

#pragma mark - 删除文件

- (void)deleteMediaFile:(NSString *)fileName completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    NSDictionary *params = @{
        @"action": @"deleteAppFile",
        @"app_id": @(self.appId),
        @"file_name": fileName
    };
    
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                modules:@"app" parameters:params
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        //返回主线程UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult){
                NSLog(@"\n附件上传管理返回失败stringResult:%@",stringResult);
                NSError *error = [NSError errorWithDomain:@"setupForEditWithAppId" code:413 userInfo:@{NSLocalizedDescriptionKey: stringResult ?: @"加载失败"}];
                if (completion) completion(NO, error);
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if (code !=200) {
                NSLog(@"\n附件上传管理返回失败stringResult:%@",stringResult);
                NSError *error = [NSError errorWithDomain:@"setupForEditWithAppId" code:414 userInfo:@{NSLocalizedDescriptionKey: msg ?: @"加载失败"}];
                if (completion) completion(NO, error);
                return;
            }
            NSLog(@"\n附件上传管理jsonResult:%@",jsonResult);
            if (completion) completion(YES, nil);
        });
        
    } failure:^(NSError *error) {
        //返回主线程UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(NO, error);
        });
    }];
}

- (void)deleteMediaFiles:(NSArray<NSString *> *)fileNames completion:(void(^)(NSDictionary *results))completion {
    if (fileNames.count == 0) {
        if (completion) completion(@{});
        return;
    }
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    dispatch_group_t group = dispatch_group_create();
    
    for (NSString *fileName in fileNames) {
        dispatch_group_enter(group);
        [self deleteMediaFile:fileName completion:^(BOOL success, NSError *error) {
            @synchronized (results) {
                results[fileName] = @{
                    @"success": @(success),
                    @"error": error ?: [NSNull null]
                };
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) completion(results);
    });
}

#pragma mark - 工具方法

- (void)cancelAllUploads {
    self.isCancelled = YES;
    for (NSURLSessionTask *task in self.uploadTasks.allValues) {
        [task cancel];
    }
    [self.uploadTasks removeAllObjects];
}

+ (void)generateVideoThumbnail:(NSURL *)videoURL completion:(void(^)(UIImage * _Nullable thumbnail, CGFloat duration))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(640, 640);
        
        CGFloat duration = CMTimeGetSeconds(asset.duration);
        
        NSError *error = nil;
        CGImageRef imageRef = [generator copyCGImageAtTime:CMTimeMake(1, 60) actualTime:NULL error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (imageRef) {
                UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
                if (completion) completion(thumbnail, duration);
            } else {
                if (completion) completion(nil, duration);
            }
        });
    });
}

+ (BOOL)isVideoFile:(NSString *)fileName {
    NSString *ext = [[fileName pathExtension] lowercaseString];
    NSArray *videoExts = @[@"mp4", @"mov", @"m4v", @"avi", @"mkv", @"flv", @"wmv"];
    return [videoExts containsObject:ext];
}

+ (BOOL)isImageFile:(NSString *)fileName {
    NSString *ext = [[fileName pathExtension] lowercaseString];
    NSArray *imageExts = @[@"jpg", @"jpeg", @"png", @"gif", @"webp", @"heic", @"bmp"];
    return [imageExts containsObject:ext];
}

@end
