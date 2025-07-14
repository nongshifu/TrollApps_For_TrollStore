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
@end

NS_ASSUME_NONNULL_END
