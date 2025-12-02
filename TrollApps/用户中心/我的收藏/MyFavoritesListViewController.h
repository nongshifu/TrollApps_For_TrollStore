//
//  MyFavoritesListViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/2.
//

#import "TemplateListController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MyFavoritesListViewController : TemplateListController
//搜索关键词
@property (nonatomic, strong) NSString *keyword;
//分类
@property (nonatomic, strong) NSString *tag;
//切换列表
@property (nonatomic, assign) NSInteger sort;
//列表类型
@property (nonatomic, assign) NSInteger selectedIndex;
//查询目标
@property (nonatomic, strong) NSString *target_udid;
@end

NS_ASSUME_NONNULL_END
