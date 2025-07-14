//
//  UserProfileViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TemplateListController.h"
#import "UserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserProfileViewController : TemplateListController

- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid;
/// 更新用户模型并刷新UI
- (void)updateWithUserModel:(UserModel *)userModel;

@property (nonatomic, strong) UserModel *userInfo;

//搜索关键词
@property (nonatomic, strong) NSString *keyword;
//分类
@property (nonatomic, strong) NSString *tag;
//页面下标
@property (nonatomic, assign) NSInteger tagPageIndex;
//全部APP 还是我的APP
@property (nonatomic, assign) BOOL showMyApp;
//查询用户的UDID
@property (nonatomic, strong) NSString *udid;

@end

NS_ASSUME_NONNULL_END
