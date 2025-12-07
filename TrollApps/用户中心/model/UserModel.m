//
//  UserModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import "UserModel.h"
#import "NetworkClient.h"
#import "UserModel.h"
#import "NewProfileViewController.h"

#undef MY_NSLog_ENABLED // 取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED NO // 当前文件单独启用

// 内存缓存字典（键：唯一标识，值：UserModel 实例）
static NSMutableDictionary<NSString *, UserModel *> *_userCacheDict = nil;
// 线程安全队列
static dispatch_queue_t _cacheQueue;


@implementation UserModel

#pragma mark - 初始化缓存环境
+ (void)initialize {
    if (self == [UserModel class]) {
        // 创建串行队列（线程安全）
        _cacheQueue = dispatch_queue_create("com.usermodel.cache.queue", DISPATCH_QUEUE_SERIAL);
        // 初始化缓存字典
        dispatch_sync(_cacheQueue, ^{
            _userCacheDict = [NSMutableDictionary dictionary];
        });
    }
}

#pragma mark - 缓存键生成辅助方法
/// 根据类型和值生成唯一缓存键
+ (NSString *)generateCacheKeyWithType:(NSString *)type value:(NSString *)value {
    if (!type || !value) return nil;
    return [NSString stringWithFormat:@"%@_%@", type, value];
}

/// 从 UserModel 实例中提取所有可能的缓存键
- (NSArray<NSString *> *)allPossibleCacheKeys {
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    
    // 根据 user_id 生成键
    if (self.user_id > 0) {
        [keys addObject:[UserModel generateCacheKeyWithType:@"user_id" value:@(self.user_id).stringValue]];
    }
    // 根据 udid 生成键
    if (self.udid.length > 0) {
        [keys addObject:[UserModel generateCacheKeyWithType:@"udid" value:self.udid]];
    }
    // 根据 idfv 生成键
    if (self.idfv.length > 0) {
        [keys addObject:[UserModel generateCacheKeyWithType:@"idfv" value:self.idfv]];
    }
    
    return keys;
}

#pragma mark - 多用户缓存核心方法

/// 缓存指定用户（自动关联所有可能的唯一键）
+ (void)cacheUserModel:(UserModel *)userModel {
    if (!userModel) return;
    
    dispatch_sync(_cacheQueue, ^{
        // 获取该用户的所有可能缓存键
        NSArray<NSString *> *keys = [userModel allPossibleCacheKeys];
        if (keys.count == 0) return;
        
        // 将用户模型关联到所有键（方便通过不同标识读取）
        for (NSString *key in keys) {
            _userCacheDict[key] = userModel;
        }
    });
}

/// 根据指定键读取缓存用户
+ (instancetype)cachedUserModelWithKey:(NSString *)key {
    if (!key) return nil;
    
    __block UserModel *result = nil;
    dispatch_sync(_cacheQueue, ^{
        result = _userCacheDict[key];
    });
    return result;
}

/// 根据 user_id 读取缓存
+ (instancetype)cachedUserModelWithUserId:(NSString *)userId {
    NSString *key = [self generateCacheKeyWithType:@"user_id" value:userId];
    return [self cachedUserModelWithKey:key];
}

/// 根据 udid 读取缓存
+ (instancetype)cachedUserModelWithUdid:(NSString *)udid {
    NSString *key = [self generateCacheKeyWithType:@"udid" value:udid];
    return [self cachedUserModelWithKey:key];
}

/// 根据 idfv 读取缓存
+ (instancetype)cachedUserModelWithIdfv:(NSString *)idfv {
    NSString *key = [self generateCacheKeyWithType:@"idfv" value:idfv];
    return [self cachedUserModelWithKey:key];
}

/// 根据指定键清空缓存
+ (void)clearCachedUserModelWithKey:(NSString *)key {
    if (!key) return;
    
    dispatch_sync(_cacheQueue, ^{
        [_userCacheDict removeObjectForKey:key];
    });
}

/// 根据 user_id 清空缓存
+ (void)clearCachedUserModelWithUserId:(NSString *)userId {
    NSString *key = [self generateCacheKeyWithType:@"user_id" value:userId];
    [self clearCachedUserModelWithKey:key];
}

/// 根据 udid 清空缓存
+ (void)clearCachedUserModelWithUdid:(NSString *)udid {
    NSString *key = [self generateCacheKeyWithType:@"udid" value:udid];
    [self clearCachedUserModelWithKey:key];
}

/// 根据 idfv 清空缓存
+ (void)clearCachedUserModelWithIdfv:(NSString *)idfv {
    NSString *key = [self generateCacheKeyWithType:@"idfv" value:idfv];
    [self clearCachedUserModelWithKey:key];
}

/// 清空所有用户缓存
+ (void)clearAllCachedUserModels {
    dispatch_sync(_cacheQueue, ^{
        [_userCacheDict removeAllObjects];
    });
}



/**
 * 用于判断两个对象是否为同一实例（通常基于唯一标识符）
 * 这里使用 user_id 作为唯一标识（数据库自增主键）
 */
- (nonnull id<NSObject>)diffIdentifier {
    return @(self.user_id); // user_id 是数据库唯一主键，确保唯一性
}

/**
 * 用于判断两个对象的内容是否相同
 * 对比所有关键属性，确保UI展示内容一致时不会触发不必要的刷新
 */
- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES; // 同一实例直接返回YES
    if (![object isKindOfClass:[UserModel class]]) return NO; // 类型不同返回NO
    
    UserModel *other = (UserModel *)object;
    
    // 基础信息对比
    if (self.user_id != other.user_id) return NO;
    if (![self.nickname isEqualToString:other.nickname]) return NO;
    if (![self.avatar isEqualToString:other.avatar]) return NO;
    if (![self.phone isEqualToString:other.phone]) return NO;
    if (![self.email isEqualToString:other.email]) return NO;
    if (![self.udid isEqualToString:other.udid]) return NO;
    if (![self.idfv isEqualToString:other.idfv]) return NO;
    
    // 社交信息对比
    if (![self.wechat isEqualToString:other.wechat]) return NO;
    if (![self.qq isEqualToString:other.qq]) return NO;
    if (![self.tg isEqualToString:other.tg]) return NO;
    if (![self.bio isEqualToString:other.bio]) return NO;
    if (![self.moodStatus isEqualToString:other.moodStatus]) return NO;
    
    // 状态信息对比
    if (self.gender != other.gender) return NO;
    if (self.isFollow != other.isFollow) return NO;
    if (self.isShowFollows != other.isShowFollows) return NO;
    if (self.is_online != other.is_online) return NO;
    
    
    if (self.vip_level != other.vip_level) return NO;
    if (self.downloads_number != other.downloads_number) return NO;
    if (self.like_count != other.like_count) return NO;
    if (self.reply_count != other.reply_count) return NO;
    if (self.follower_count != other.follower_count) return NO;
    if (self.following_count != other.following_count) return NO;
    if (self.app_count != other.app_count) return NO;
    if (self.role != other.role) return NO;
    
    
    
    // 日期对比
    if (![self.vip_expire_date isEqualToDate:other.vip_expire_date]) return NO;
    if (![self.login_time isEqualToDate:other.login_time]) return NO;
    if (![self.register_time isEqualToDate:other.register_time]) return NO;
    if (![self.last_purchase_time isEqualToDate:other.last_purchase_time]) return NO;
    
    // 数组对比（搜索分类）
    if (![self.search_category isEqualToArray:other.search_category]) return NO;
    
    // 所有关键属性相同，返回YES
    return YES;
}


#pragma mark - 业务接口

/**
 判断VIP是否到期
 @param vipDateString VIP到期日期字符串（格式：yyyy-MM-dd HH:mm:ss）
 @return YES：已到期；NO：未到期
 */
+ (BOOL)isVIPExpiredWithDateString:(NSString *)vipDateString {
    // 空值处理：无到期日期视为未开通（已到期）
    if (vipDateString.length == 0) {
        return YES;
    }
    
    // 日期格式化器
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]; // 解决不同地区时间格式问题
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss"; // 与输入字符串格式匹配
    
    // 将字符串转为NSDate
    NSDate *vipExpireDate = [formatter dateFromString:vipDateString];
    if (!vipExpireDate) {
        // 格式错误视为已到期
        NSLog(@"VIP日期格式错误：%@（正确格式应为yyyy-MM-dd HH:mm:ss）", vipDateString);
        return YES;
    }
    
    // 获取当前时间（忽略毫秒，避免精度问题）
    NSDate *currentDate = [NSDate date];
    
    // 比较时间：如果当前时间晚于到期时间，说明已到期
    return [currentDate compare:vipExpireDate] == NSOrderedDescending;
}
/**
 判断VIP是否到期
 @param vipExpireDate VIP到期日期字符串（格式：NSDate）
 @return YES：已到期；NO：未到期
 */
+ (BOOL)isVIPExpiredWithDate:(NSDate *)vipExpireDate {
 
    if (!vipExpireDate) {
        // 格式错误视为已到期
        NSLog(@"VIP日期格式错误：%@（正确格式应为yyyy-MM-dd HH:mm:ss）", vipExpireDate);
        return YES;
    }
    
    // 获取当前时间（忽略毫秒，避免精度问题）
    NSDate *currentDate = [NSDate date];
    
    // 比较时间：如果当前时间晚于到期时间，说明已到期
    return [currentDate compare:vipExpireDate] == NSOrderedDescending;
}

/**
 统一更新云端用户信息
 @param userModel 用户信息模型
 */
+ (void)updateCloudUserInfoWithUserModel:(UserModel *)userModel {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[userModel yy_modelToJSONObject]];
    [dic setValue:@"updateProfile" forKey:@"action"];
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :@"";
    if(udid.length<5){
        [SVProgressHUD showInfoWithStatus:@"UDID获取失败\n请先登录绑定哦"];
        [SVProgressHUD dismissWithDelay:4];
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php",localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url
                                             parameters:dic
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        if(!jsonResult){
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"数据读取失败\n%@",stringResult]];
            [SVProgressHUD dismissWithDelay:3];
            return;
        }
        NSInteger code = [jsonResult[@"code"] intValue];
        NSString *msg = jsonResult[@"msg"];
        if(code ==200){
            [SVProgressHUD showSuccessWithStatus:msg];
            [SVProgressHUD dismissWithDelay:2];
        }else{
            [SVProgressHUD showErrorWithStatus:msg];
            [SVProgressHUD dismissWithDelay:3];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",error]];
        [SVProgressHUD dismissWithDelay:3];
    }];
    
}

#pragma mark - 通用获取用户信息（内部统一处理）
+ (void)getUserInfoWithType:(NSString *)type
                 queryValue:(NSString *)queryValue
                    success:(UserInfoSuccessBlock)success
                    failure:(UserInfoFailureBlock)failure {
    if (!queryValue || queryValue.length == 0) {
        NSError *error = [NSError errorWithDomain:@"UserInfoError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"参数不能为空"}];
        if (failure) failure(error, @"参数不能为空");
        return;
    }
    
    // 公共参数
    NSDictionary *params = @{
        @"action": @"getUserInfo",
        @"type": type, // type 为 @"user_id" 或 @"udid"
        @"queryValue": queryValue
    };
    NSLog(@"查询用户数据请求：%@",params);
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php", localURL];
    NSString *udid = [KeychainTool readStringForKey:TROLLAPPS_SAVE_UDID_KEY] ? [KeychainTool readStringForKey:TROLLAPPS_SAVE_UDID_KEY] :@"";
    if(udid.length<5){
        [SVProgressHUD showInfoWithStatus:@"UDID获取失败\n请先登录绑定哦"];
        [SVProgressHUD dismissWithDelay:4];
        return;
    }
    // 发起请求（复用已有POST方法）
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                      urlString:url
                     parameters:params
                           udid:udid
                       progress:nil
                        success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"查询用户数据返回jsonResult：%@",jsonResult);
            NSLog(@"查询用户数据返回stringResult：%@",stringResult);
            if (!jsonResult && stringResult) {
                NSError *error = [NSError errorWithDomain:@"UserInfoError" code:-2 userInfo:@{NSLocalizedDescriptionKey: stringResult}];
                if (failure) failure(error, stringResult);
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"] ?: @"获取用户信息失败";
            if (code == 200) {
                NSLog(@"查询用户数据返回：%@",jsonResult[@"data"]);
                UserModel *userModel = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
                // 关键修改：自动更新内存缓存
                [self cacheUserModel:userModel];
                if (success) success(userModel);
            } else {
                NSError *error = [NSError errorWithDomain:@"UserInfoError" code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
                if (failure) failure(error, msg);
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(error, error.localizedDescription);
        });
    }];
}

#pragma mark - 外部调用接口（通过user_id获取）
+ (void)getUserInfoWithUserId:(NSString *)userId
                     success:(UserInfoSuccessBlock)success
                     failure:(UserInfoFailureBlock)failure {
    [self getUserInfoWithType:@"user_id" queryValue:userId success:success failure:failure];
}

#pragma mark - 外部调用接口（通过udid获取）
+ (void)getUserInfoWithUdid:(NSString *)udid
                    success:(UserInfoSuccessBlock)success
                    failure:(UserInfoFailureBlock)failure {
    [self getUserInfoWithType:@"udid" queryValue:udid success:success failure:failure];
}
#pragma mark - 外部调用接口（通过idfv获取）
+ (void)getUserInfoWithIDFV:(NSString *)idfv
                    success:(UserInfoSuccessBlock)success
                    failure:(UserInfoFailureBlock)failure {
    [self getUserInfoWithType:@"idfv" queryValue:idfv success:success failure:failure];
}

#pragma mark - 外部调用接口（通过关系状态）
- (NSString *)statusDescription {
    switch (_mutualFollowStatus) {
        case UserFollowMutualStatus_None:
            return @"相互未关注";
        case UserFollowMutualStatus_HimFollowMe:
            return @"他关注我";
        case UserFollowMutualStatus_IFollowHim:
            return @"我关注他";
        case UserFollowMutualStatus_Mutual:
            return @"互关";
        default:
            return @"未知状态";
    }
}
// 在 UserModel.m 中实现
+ (void)getMutualFollowStatusWithTargetUdid:(NSString *)targetUdid
                                    success:(void(^)(UserFollowMutualStatus status, NSString *statusDesc))success
                                    failure:(UserInfoFailureBlock)failure {
    // 获取当前用户的 UDID 和 Token（从本地存储获取，如 UserDefaults）
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :@"";
    if(udid.length<5){
        [SVProgressHUD showInfoWithStatus:@"UDID获取失败\n请先登录绑定哦"];
        [SVProgressHUD dismissWithDelay:4];
        return;
    }
    NSDictionary *params = @{
        @"action" : @"getMutualFollowStatus",
        @"udid" : udid,
        @"data" : @{@"target_udid" : targetUdid}
    };
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php",localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url parameters:params
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSInteger statusCode = [jsonResult[@"data"][@"status"] integerValue];
        UserFollowMutualStatus status = (UserFollowMutualStatus)statusCode;
        if (success) {
            success(status, jsonResult[@"data"][@"statusText"]);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error, @"查询关注状态失败");
        }
    }];
    
}

#pragma mark - 缓存优先获取用户信息（核心实现）

/// 通用缓存优先逻辑（内部调用）
+ (void)getUserInfoWithTypeCacheFirst:(NSString *)type
                           queryValue:(NSString *)queryValue
                              success:(UserInfoSuccessBlock)success
                              failure:(UserInfoFailureBlock)failure {
    // 1. 参数验证
    if (!type || !queryValue || queryValue.length == 0) {
        NSError *error = [NSError errorWithDomain:@"UserInfoError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"参数不能为空"}];
        if (failure) failure(error, @"参数不能为空");
        return;
    }
    
    // 2. 尝试从缓存读取（优先使用内存缓存）
    NSString *cacheKey = [self generateCacheKeyWithType:type value:queryValue];
    UserModel *cachedModel = [self cachedUserModelWithKey:cacheKey];
    if (cachedModel) {
        // 缓存存在，直接返回（确保主线程回调，避免UI更新问题）
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(cachedModel);
            });
        }
        return;
    }
    
    // 3. 缓存不存在，发起网络请求（网络请求成功后会自动更新缓存）
    [self getUserInfoWithType:type queryValue:queryValue success:success failure:failure];
}

/// 根据 user_id 缓存优先获取
+ (void)getUserInfoWithUserIdCacheFirst:(NSString *)userId
                                success:(UserInfoSuccessBlock)success
                                failure:(UserInfoFailureBlock)failure {
    [self getUserInfoWithTypeCacheFirst:@"user_id" queryValue:userId success:success failure:failure];
}

/// 根据 udid 缓存优先获取
+ (void)getUserInfoWithUdidCacheFirst:(NSString *)udid
                               success:(UserInfoSuccessBlock)success
                               failure:(UserInfoFailureBlock)failure {
    [self getUserInfoWithTypeCacheFirst:@"udid" queryValue:udid success:success failure:failure];
}

/// 根据 idfv 缓存优先获取
+ (void)getUserInfoWithIdfvCacheFirst:(NSString *)idfv
                               success:(UserInfoSuccessBlock)success
                               failure:(UserInfoFailureBlock)failure {
    [self getUserInfoWithTypeCacheFirst:@"idfv" queryValue:idfv success:success failure:failure];
}

/// 设置用户在线状态
+ (void)setOnlineStatusWithTargetUdid:(NSString *)targetUdid
                               status:(BOOL)status
                               success:(void(^)(NSString *message))success
                               failure:(UserInfoFailureBlock)failure {
    // 1. 参数校验
    if (!targetUdid || targetUdid.length < 5) {
        NSError *error = [NSError errorWithDomain:@"UserInfoError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"目标UDID无效"}];
        if (failure) failure(error, @"目标UDID无效");
        return;
    }
    
    
    // 2. 获取当前用户UDID（用于身份验证）
    NSString *currentUdid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    if (currentUdid.length < 5) {
        [SVProgressHUD showInfoWithStatus:@"UDID获取失败\n请先登录绑定哦"];
        [SVProgressHUD dismissWithDelay:4];
        NSError *error = [NSError errorWithDomain:@"UserInfoError" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"当前用户未登录"}];
        if (failure) failure(error, @"当前用户未登录");
        return;
    }
    
    // 3. 构建请求参数
    NSDictionary *params = @{
        @"action" : @"setOnlineStatus", // 路由action：设置在线状态
        @"target_udid" : targetUdid,          // 当前用户UDID（身份验证）
        @"is_online" : @(status)
        
    };
    NSLog(@"设置在线状态请求：%@", params);
    
    // 4. 发起网络请求
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php", localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url
                                             parameters:params
                                                   udid:currentUdid
                                               progress:^(NSProgress *progress) {
        // 进度回调（可选，当前无需处理）
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"设置在线状态返回jsonResult：%@", jsonResult);
            NSLog(@"设置在线状态返回stringResult：%@", stringResult);
            
            // 5. 解析成功响应
            if (!jsonResult && stringResult) {
                NSError *error = [NSError errorWithDomain:@"UserInfoError" code:-4 userInfo:@{NSLocalizedDescriptionKey: stringResult}];
                if (failure) failure(error, stringResult);
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] integerValue];
            NSString *msg = jsonResult[@"msg"] ?: @"设置成功";
            if (code == 200) {
                // 成功：返回服务器提示信息
                if (success) success(msg);
            } else {
                // 失败：返回错误信息
                NSError *error = [NSError errorWithDomain:@"UserInfoError" code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
                if (failure) failure(error, msg);
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 网络请求失败：返回错误信息
            if (failure) failure(error, [NSString stringWithFormat:@"网络错误：%@", error.localizedDescription]);
        });
    }];
}

@end
