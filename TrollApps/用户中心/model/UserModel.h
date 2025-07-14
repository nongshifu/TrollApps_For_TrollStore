//
//  UserModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import "Config.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserModel : NSObject<IGListDiffable>
@property (nonatomic, assign) NSInteger user_id;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) UIImage *avatarImage;
@property (nonatomic, copy) NSString *avatarBase64;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *wechat;
@property (nonatomic, copy) NSString *qq;
@property (nonatomic, copy) NSString *tg;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, assign) NSInteger gender;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *udid;
@property (nonatomic, copy) NSString *idfv;
@property (nonatomic, strong) NSDate *vip_expire_date;
@property (nonatomic, strong) NSDate *login_time;
@property (nonatomic, strong) NSDate *register_time;
@property (nonatomic, strong) NSDate *last_purchase_time;
@property (nonatomic, assign) NSInteger vip_level;
@property (nonatomic, assign) NSInteger downloads_number;
@property (nonatomic, strong) NSArray *search_category;//搜索分类字符串数组

/**
 判断VIP是否到期
 @param vipDateString VIP到期日期字符串（格式：yyyy-MM-dd HH:mm:ss）
 @return YES：已到期；NO：未到期
 */
+ (BOOL)isVIPExpiredWithDateString:(NSString *)vipDateString;

/**
 判断VIP是否到期
 @param vipExpireDate VIP到期日期字符串（格式：NSDate）
 @return YES：已到期；NO：未到期
 */
+ (BOOL)isVIPExpiredWithDate:(NSDate *)vipExpireDate ;


/**
 统一更新云端用户信息
 @param userModel 用户信息模型
 */
- (void)updateCloudUserInfoWithUserModel:(UserModel *)userModel;
@end

NS_ASSUME_NONNULL_END
