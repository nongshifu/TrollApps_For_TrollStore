//
//  FindFriendsViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/11/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//
#import "TemplateListController.h"
#import <UIKit/UIKit.h>

// 用户搜索排序枚举
typedef NS_ENUM(NSInteger, UserSearchSortType) {
    UserSearchSortType_RegisterTime    = 1,  // 注册时间（默认）
    UserSearchSortType_OnlineTime      = 2,  // 最新在线
    UserSearchSortType_AppCount   = 3,  // app数量
    UserSearchSortType_LikeCount       = 4,  // 点赞数量
    UserSearchSortType_CommentCount    = 5,  // 评论数量
    UserSearchSortType_OnlyAdmin       = 99  // 只看管理员（role=1）
};

NS_ASSUME_NONNULL_BEGIN

@interface FindFriendsViewController : TemplateListController

@end

NS_ASSUME_NONNULL_END
