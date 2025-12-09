#import "AppInfoModel.h"


#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@implementation AppInfoModel

#pragma mark - IGListDiffable

/**
 * 用于判断两个对象是否为同一实例（通常基于唯一标识符）
 * 这里使用 app_id 作为唯一标识（数据库自增主键）
 */
- (nonnull id<NSObject>)diffIdentifier {
    return [NSString stringWithFormat:@"%ld_%@",self.app_id,self.app_name]; // app_id 是数据库唯一主键，确保唯一性
}

/**
 * 用于判断两个对象的内容是否相同
 * 对比所有关键属性，确保UI展示内容一致时不会触发不必要的刷新
 */
- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES; // 同一实例直接返回YES
    if (![object isKindOfClass:[AppInfoModel class]]) return NO; // 类型不同返回NO
    
    AppInfoModel *other = (AppInfoModel *)object;
    
    // 基础信息对比
    if (self.app_id != other.app_id) return NO;
    if (![self.bundle_id isEqualToString:other.bundle_id]) return NO;
    if (![self.app_name isEqualToString:other.app_name]) return NO;
    
    
    // 状态信息对比
    if (self.upload_status != other.upload_status) return NO;
    if (self.app_status != other.app_status) return NO;
    
    // 互动数据对比（影响UI展示的计数）
    if (self.like_count != other.like_count) return NO;
    if (self.collect_count != other.collect_count) return NO;
    if (self.dislike_count != other.dislike_count) return NO;
    if (self.download_count != other.download_count) return NO;
    if (self.comment_count != other.comment_count) return NO;
    
    // 布尔状态对比（用户操作状态）
    if (self.isLike != other.isLike) return NO;
    if (self.isCollect != other.isCollect) return NO;
    if (self.isDislike != other.isDislike) return NO;
    if (self.isShowAll != other.isShowAll) return NO;
    if (self.isComment != other.isComment) return NO;
    if (self.isShare != other.isShare) return NO;
    if (self.is_cloud != other.is_cloud) return NO;
    
    
    // 内容信息对比（影响展示的文本/URL）
    if (![self.app_description isEqualToString:other.app_description]) return NO;
    
    if (![self.version_name isEqualToString:other.version_name]) return NO;
    if (![self.icon_url isEqualToString:other.icon_url]) return NO;
    if (![self.release_notes isEqualToString:other.release_notes]) return NO;
    if (![self.track_id isEqualToString:other.track_id]) return NO;
    if (![self.add_date isEqualToString:other.add_date]) return NO;
    if (![self.update_date isEqualToString:other.update_date]) return NO;
    if (![self.mainFileUrl isEqualToString:other.mainFileUrl]) return NO;
    
    // 数组对比（标签和文件名）
    if (![self.tags isEqualToArray:other.tags]) return NO;
    if (![self.fileNames isEqualToArray:other.fileNames]) return NO;
    
    
    // 所有关键属性相同，返回YES
    return YES;
}

+ (void)getDownloadLinkWithAppId:(NSInteger)app_id
                         success:(void(^)(NSURL *downloadURL, NSDictionary *json))success
                         failure:(void(^)(NSError *error))failure {
    // 1. 传递 app_id 到接口参数
    NSDictionary *parameters = @{@"app_id": @(app_id), @"action": @"getDownloadLink"}; // 注意：参数结构需与接口匹配！
    NSString *urlString = [NSString stringWithFormat:@"%@/app/app_api.php", localURL];
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                             urlString:urlString
                                            parameters:parameters
                                                 udid:udid
                                              progress:^(NSProgress *progress) {
        // 可选：进度回调
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"jsonResult:%@", jsonResult);
            NSLog(@"stringResult:%@", stringResult);
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code == 200) {
                NSString *downloadLink = jsonResult[@"data"][@"download_url"];
                if (downloadLink.length > 0) {
                    // 核心修复：对 URL 字符串进行编码处理
                    NSString *encodedURLString = [downloadLink stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    // 3. 创建 NSURL
                    NSURL *downloadURL = [NSURL URLWithString:encodedURLString];
                    if (downloadURL) {
                        if (success) success(downloadURL,jsonResult[@"data"]);
                        return;
                    } else {
                        NSLog(@"URL 创建失败，原始链接：%@，编码后：%@", downloadLink, encodedURLString);
                    }
                }
            }
            
            // 解析失败：构造错误信息
            NSError *parseError = [NSError errorWithDomain:@"DownloadLinkError"
                                                     code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: @"解析下载链接失败"}];
            if (failure) failure(parseError);
        });
        
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(error);
        });
        
    }];
}

/// 获取下载链接并插入下载历史
+ (void)getDownloadLinkAndRecordHistoryWithAppId:(NSInteger)app_id
                                         success:(void(^)(DownloadRecordModel *recordModel , NSDictionary *json))success
                                         failure:(void(^)(NSError *error))failure {
    // 1. 先获取下载链接
    [self getDownloadLinkWithAppId:app_id success:^(NSURL *downloadURL, NSDictionary *jsonData) {
        // 2. 下载链接获取成功，准备插入下载历史
        NSString *downloadUrlString = jsonData[@"download_url"];
        NSString *appName = jsonData[@"app_name"];
        NSString *versionName = jsonData[@"version_name"];
        NSString *udid = [[NewProfileViewController sharedInstance] getUDID] ?[[NewProfileViewController sharedInstance] getUDID]:[[NewProfileViewController sharedInstance] getIDFV];
        // 3. 构造插入历史记录的参数
        NSDictionary *recordParams = @{
            @"app_id": @(app_id),
            @"action": @"recordDownload",
            @"download_url": downloadUrlString,
            @"device_info": udid // 设备信息，可根据需求扩展
        };
        
        NSString *urlString = [NSString stringWithFormat:@"%@/app/app_api.php", localURL];
        
        
        // 4. 调用插入下载历史的API
        [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                 urlString:urlString
                                                parameters:recordParams
                                                     udid:udid
                                                  progress:nil
                                                   success:^(NSDictionary *recordJson, NSString *stringResult, NSData *dataResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"插入下载历史成功：%@", recordJson);
                
                // 5. 解析响应，构建完整的下载记录模型
                DownloadRecordModel *recordModel = [[DownloadRecordModel alloc] init];
                
                // 设置从getDownloadLink返回的数据
                recordModel.appId = app_id;
                recordModel.appName = appName;
                recordModel.versionName = versionName;
                recordModel.downloadUrl = [NSString stringWithFormat:@"%@",downloadURL];
                recordModel.downloadTime = [self currentDateTimeString];
                
                // 设置从recordDownload返回的数据
                if ([recordJson[@"code"] integerValue] == 200) {
                    recordModel.recordId = [recordJson[@"data"][@"recordId"] integerValue];
                    recordModel.status = 0; // 下载成功
                } else {
                    recordModel.status = 1; // 插入记录失败
                }
                
                // 6. 返回完整模型
                if (success) {
                    success(recordModel,recordJson);
                }
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"插入下载历史失败：%@", error);
                
                // 即使插入历史失败，也要返回下载链接（核心功能优先）
                DownloadRecordModel *recordModel = [[DownloadRecordModel alloc] init];
                recordModel.appId = app_id;
                recordModel.appName = appName;
                recordModel.versionName = versionName;
                recordModel.downloadUrl = [NSString stringWithFormat:@"%@",downloadURL];
                
                recordModel.downloadTime = [self currentDateTimeString];
                recordModel.status = 1; // 插入记录失败
                
                if (success) {
                    success(recordModel,nil);
                }
            });
        }];
    } failure:^(NSError *error) {
        // 获取下载链接失败，直接返回错误
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) {
                failure(error);
            }
        });
    }];
}

/// 辅助方法：获取当前时间字符串
+ (NSString *)currentDateTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:[NSDate date]];
}


@end
