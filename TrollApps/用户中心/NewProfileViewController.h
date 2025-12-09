//
//  NewProfileViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/10.
//


#import "TemplateListController.h"
#import "UserModel.h"
#import "config.h"
#import "UserModel.h"

// 定义头像缓存相关的常量
#define kAvatarCacheKey @"UserAvatarImage"
#define kAvatarCachePath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"user_avatar.png"]


NS_ASSUME_NONNULL_BEGIN

@interface NewProfileViewController : TemplateListController

@property (nonatomic, strong) UserModel *userInfo;
@property (nonatomic, strong) UIImage *minImage;
+ (instancetype)sharedInstance;
- (NSString *)getIDFV;
- (NSString *)getUDID;
- (void)loadUserInfo;

// 保存头像到本地缓存
- (void)saveAvatarToCache:(UIImage *)avatar;

// 从本地缓存加载头像
- (UIImage *)loadAvatarFromCache;

// 清除头像缓存（可在用户登出等场景调用）
- (void)clearAvatarCache;

@end

NS_ASSUME_NONNULL_END
