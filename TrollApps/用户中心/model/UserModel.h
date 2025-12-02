//
//  UserModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <IGListKit/IGListKit.h>
#import <YYModel/YYModel.h>


NS_ASSUME_NONNULL_BEGIN
@class UserModel;

typedef void(^UserInfoSuccessBlock)(UserModel *userModel);
typedef void(^UserInfoFailureBlock)(NSError *error, NSString *errorMsg);

// 双向关注状态枚举（对应后端返回的 0-3 状态码）
typedef NS_ENUM(NSInteger, UserFollowMutualStatus) {
    UserFollowMutualStatus_None = 0,    // 0: 相互未关注
    UserFollowMutualStatus_HimFollowMe, // 1: 他关注我
    UserFollowMutualStatus_IFollowHim,  // 2: 我关注他
    UserFollowMutualStatus_Mutual       // 3: 互关
};


@interface UserModel : NSObject<IGListDiffable,YYModel>
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
@property (nonatomic, copy) NSString *moodStatus;
@property (nonatomic, assign) NSInteger gender;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *udid;
@property (nonatomic, copy) NSString *idfv;
@property (nonatomic, strong) NSDate *vip_expire_date;
@property (nonatomic, strong) NSDate *login_time;
@property (nonatomic, strong) NSDate *register_time;
@property (nonatomic, strong) NSDate *last_purchase_time;
@property (nonatomic, assign) NSInteger vip_level;//vip等级
@property (nonatomic, assign) NSInteger downloads_number;//下载次数
@property (nonatomic, assign) NSInteger like_count;//点赞数量
@property (nonatomic, assign) NSInteger reply_count;//评论数量
@property (nonatomic, assign) NSInteger app_count;//APP数量
@property (nonatomic, assign) NSInteger role; //是否管理员
@property (nonatomic, strong) NSArray *search_category;//搜索分类字符串数组
@property (nonatomic, assign) NSInteger follower_count;//粉丝量
@property (nonatomic, assign) NSInteger following_count;//关注量
@property (nonatomic, assign) BOOL isFollow;//是否已经关注
@property (nonatomic, assign) UserFollowMutualStatus mutualFollowStatus;// 新增：双向关注状态（核心属性）
@property (nonatomic, copy) NSString * mutualFollowStatusText; // 新增：双向关注状态（文本提示）

@property (nonatomic, assign) BOOL isShowFollows;//是否显示收藏列表 关注列表等隐私内容
@property (nonatomic, assign) BOOL is_online;//是否在线
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
+ (void)updateCloudUserInfoWithUserModel:(UserModel *)userModel;


/// 通过 user_id 获取用户信息
+ (void)getUserInfoWithUserId:(NSString *)userId
                     success:(UserInfoSuccessBlock)success
                     failure:(UserInfoFailureBlock)failure;

/// 通过 udid 获取用户信息
+ (void)getUserInfoWithUdid:(NSString *)udid
                    success:(UserInfoSuccessBlock)success
                    failure:(UserInfoFailureBlock)failure;

/// 通过 idfv 获取用户信息
+ (void)getUserInfoWithIDFV:(NSString *)idfv
                    success:(UserInfoSuccessBlock)success
                    failure:(UserInfoFailureBlock)failure;
///查询好友关系
+ (void)getMutualFollowStatusWithTargetUdid:(NSString *)targetUdid
                                    success:(void(^)(UserFollowMutualStatus status, NSString *statusDesc))success
                                    failure:(UserInfoFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
