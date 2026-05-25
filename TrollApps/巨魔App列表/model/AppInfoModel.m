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
    if (self.app_rmb != other.app_rmb) return NO;
    
    
    // 布尔状态对比（用户操作状态）
    if (self.isLike != other.isLike) return NO;
    if (self.isCollect != other.isCollect) return NO;
    if (self.isDislike != other.isDislike) return NO;
    if (self.isShowAll != other.isShowAll) return NO;
    if (self.isComment != other.isComment) return NO;
    if (self.isShare != other.isShare) return NO;
    if (self.is_cloud != other.is_cloud) return NO;
    if (self.hasPurchased != other.hasPurchased) return NO;
    
    
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
                         success:(void(^)(DownloadRecordModel *recordModel, NSURL *downloadURL, NSDictionary *json))success
                         failure:(void(^)(NSError *error))failure {
    // 1. 传递 app_id 到接口参数
    NSDictionary *parameters = @{@"app_id": @(app_id), @"action": @"getDownloadLink"}; // 注意：参数结构需与接口匹配！
    
   
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                modules:@"app"
                                            parameters:parameters
                                              progress:^(NSProgress *progress) {
        // 可选：进度回调
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"jsonResult:%@", jsonResult);
            NSLog(@"stringResult:%@", stringResult);
            NSInteger code = [jsonResult[@"code"] integerValue];
            NSString * msg = jsonResult[@"msg"];
            if (code == 200) {
                // 核心修复：对 URL 字符串进行编码处理
                NSString *downloadLink = jsonResult[@"data"][@"downloadUrl"];
                // 核心修复：对 URL 字符串进行编码处理
                NSString *encodedURLString = [downloadLink stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                // 3. 创建 NSURL
                NSURL *downloadURL = [NSURL URLWithString:encodedURLString];
                BOOL hasPurchased = [jsonResult[@"data"][@"hasPurchased"] boolValue];
                if (hasPurchased && downloadURL) {
                    // 构造记录模型（直接用链接数据返回）
                    
                    DownloadRecordModel *model = [DownloadRecordModel yy_modelWithDictionary:jsonResult[@"data"]];
                    model.downloadUrl = encodedURLString;
                    
                    if (success) success(model,downloadURL, jsonResult[@"data"]);
                    return;
                }
                
            }
            
            // 解析失败：构造错误信息
            NSError *parseError = [NSError errorWithDomain:@"DownloadLinkError"
                                                     code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: msg}];
            if (failure) failure(parseError);
        });
        
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(error);
        });
        
    }];
}

/// 新版：先获取下载链接状态，未购买则确认购买，已购买直接返回链接
+ (void)getDownloadLinkAndRecordHistoryWithAppId:(NSInteger)app_id
                                         success:(void(^)(DownloadRecordModel *recordModel, NSDictionary *json))success
                                         failure:(void(^)(NSError *error))failure {

    NSString *udid = [[NewProfileViewController sharedInstance] getUDID];
    if (!udid || udid.length < 5) {
        if (failure) failure([NSError errorWithDomain:@"UDID错误" code:0 userInfo:nil]);
        return;
    }

    // ==========================
    // 第一步：先调用 getDownloadLink 查询状态
    // ==========================
    NSDictionary *getLinkParams = @{
        @"app_id": @(app_id),
        @"action": @"getDownloadLink"
    };

    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                modules:@"app"
                                             parameters:getLinkParams
                                               progress:nil
                                                success:^(NSDictionary *linkJson, NSString *stringResult, NSData *dataResult) {

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([linkJson[@"code"] integerValue] != 200) {
                failure([NSError errorWithDomain:linkJson[@"msg"] ?: @"获取链接失败" code:0 userInfo:nil]);
                return;
            }

            // 取出接口返回状态
            NSDictionary *data = linkJson[@"data"];
            NSLog(@"取出接口返回linkJson:%@",linkJson);
            BOOL hasPurchased = [data[@"hasPurchased"] boolValue];
            NSString *downloadUrl = data[@"downloadUrl"];
           
            // 核心修复：对 URL 字符串进行编码处理
            NSString *encodedURLString = [downloadUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            // 3. 创建 NSURL
            NSURL *downloadURL = [NSURL URLWithString:encodedURLString];

            NSLog(@"获取链接成功：hasPurchased = %d, url = %@ hasRecord :%@", hasPurchased, encodedURLString,data[@"hasRecord"]);

            // ==============================================
            // 已购买 → 直接返回链接（不扣积分）
            // ==============================================
            if (hasPurchased) {
                // 构造记录模型（直接用链接数据返回）
                
                DownloadRecordModel *model = [DownloadRecordModel yy_modelWithDictionary:data];
                model.downloadUrl = encodedURLString;
                
                if (success) success(model, linkJson);
                return;
            }

            // ==============================================
            // 未购买 → 必须调用 recordDownload 确认购买（扣积分）
            // ==============================================
            NSDictionary *recordParams = @{
                @"app_id": @(app_id),
                @"action": @"recordDownload",
                @"device_info": udid
            };

            [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                        modules:@"app"
                                                     parameters:recordParams
                                                       progress:nil
                                                        success:^(NSDictionary *recordJson, NSString *stringResult, NSData *dataResult) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([recordJson[@"code"] integerValue] != 200) {
                        NSString *msg = recordJson[@"msg"] ?: @"购买失败";
                        failure([NSError errorWithDomain:msg code:0 userInfo:nil]);
                        return;
                    }

                    // 购买成功 → 返回 recordDownload 里的完整数据（含下载链接）
                    DownloadRecordModel *recordModel = [DownloadRecordModel yy_modelWithDictionary:recordJson[@"data"]];
                    if (success) success(recordModel, recordJson);
                });

            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{ failure(error); });
            }];
        });

    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ failure(error); });
    }];
}

/// 辅助方法：获取当前时间字符串
+ (NSString *)currentDateTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:[NSDate date]];
}


@end
