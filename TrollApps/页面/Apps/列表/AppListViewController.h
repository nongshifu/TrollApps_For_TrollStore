//
//  AppListViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/1.
//

#import "TemplateListController.h"

#import "CommentModel.h"
#import "AppInfoModel.h"

#define LOAD_DATA_Notice_KEY @"LOAD_DATA_Notice_KEY"

NS_ASSUME_NONNULL_BEGIN

@interface AppListViewController : TemplateListController
//搜索关键词
@property (nonatomic, strong) NSString *keyword;
//分类
@property (nonatomic, strong) NSString *tag;
//页面下标
@property (nonatomic, assign) NSInteger tagPageIndex;
//全部APP 还是我的APP
@property (nonatomic, assign) BOOL showMyApp;
@end

NS_ASSUME_NONNULL_END
