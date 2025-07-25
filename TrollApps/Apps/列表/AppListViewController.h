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
// 定义排序类型枚举
typedef NS_ENUM(NSInteger, SortType) {
    SortTypeRecentUpdate = 0,    // 最近更新
    SortTypeEarliestRelease = 1, // 最早发布
    SortTypeMostComments = 2,    // 最多评论
    SortTypeMostLikes = 3,       // 最多点赞
    SortTypeMostFavorites = 4,   // 最多收藏
    SortTypeMostShares  = 5      // 最多分享
};

NS_ASSUME_NONNULL_BEGIN

@interface AppListViewController : TemplateListController
//搜索关键词
@property (nonatomic, strong) NSString *keyword;
//tag分类
@property (nonatomic, strong) NSString *tag;
//排序类型
@property (nonatomic, assign) SortType sortType;
//全部APP 还是我的APP
@property (nonatomic, assign) BOOL showMyApp;
@end

NS_ASSUME_NONNULL_END
