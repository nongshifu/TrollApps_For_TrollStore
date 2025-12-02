//
//  UserAppListViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/16.
//

#import "TemplateListController.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserListViewController : TemplateListController
//搜索关键词
@property (nonatomic, strong) NSString *keyword;
//分类
@property (nonatomic, strong) NSString *tag;

//全部APP 还是我的APP
@property (nonatomic, assign) BOOL showMyApp;
//查询用户的UDID
@property (nonatomic, strong) NSString *user_udid;
//切换列表
@property (nonatomic, assign) BOOL sort;
//列表类型
@property (nonatomic, assign) NSInteger selectedIndex;
@end

NS_ASSUME_NONNULL_END
