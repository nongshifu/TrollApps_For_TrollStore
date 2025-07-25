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
@implementation UserModel

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
    
    // 状态信息对比
    if (self.gender != other.gender) return NO;
    if (self.vip_level != other.vip_level) return NO;
    if (self.downloads_number != other.downloads_number) return NO;
    if (self.like_count != other.like_count) return NO;
    if (self.reply_count != other.reply_count) return NO;
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
    NSString *url = [NSString stringWithFormat:@"%@/user_api.php",localURL];
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
    NSString *url = [NSString stringWithFormat:@"%@/user_api.php", localURL];
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :@"";
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
            if (!jsonResult && stringResult) {
                NSError *error = [NSError errorWithDomain:@"UserInfoError" code:-2 userInfo:@{NSLocalizedDescriptionKey: stringResult}];
                if (failure) failure(error, stringResult);
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"] ?: @"获取用户信息失败";
            if (code == 200) {
                UserModel *userModel = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
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

@end
