//
//  PostListViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "TemplateListController.h"
#import "MediaItem.h"
NS_ASSUME_NONNULL_BEGIN

@interface PostListViewController : TemplateListController
/// 帖子搜索关键字
@property (nonatomic, strong) NSString *keyword;
/// 帖子类型分类ID
@property (nonatomic, assign) NSInteger category_id;
/// 帖子标签筛选
@property (nonatomic, assign) NSInteger topic_id;
/// 帖子开始时间筛选
@property (nonatomic, assign) long long start_time;
/// 帖子结束时间筛选
@property (nonatomic, assign) long long end_time;
/// 帖子排序类型（0-创建时间 1-热度 2-推荐 3-最后评论）
@property (nonatomic, assign) NSInteger post_sort_type;
@end

NS_ASSUME_NONNULL_END
