//
//  UserProfileViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//

#import "DemoBaseViewController.h"
#import "UserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserProfileViewController : DemoBaseViewController

- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid;
/// 更新用户模型并刷新UI
- (void)updateWithUserModel:(UserModel *)userModel;

//查询用户的UDID
@property (nonatomic, strong) NSString *user_udid;

@end

NS_ASSUME_NONNULL_END
