//
//  LikeModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/15.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>
#import "config.h"
#import "UserModel.h"
#import <YYModel/YYModel.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, Like_type) {
    Like_type_AppCommentLike = 0,     // App评论点赞
    Like_type_UserCommentLike = 1, // 用户评论点赞
    Like_type_AppSecondCommentLike = 2, //  App评论二级评论点赞
    Like_type_UserSecondCommentLike = 3,     // 用户评论二级评论点赞
    Like_type_ToolCommentLike = 4,     // 工具评论点赞
    Like_type_ToolSecondCommentLike = 5, // 工具二级评论点赞
};


@interface LikeModel : NSObject <IGListDiffable,YYModel>
@property (nonatomic, assign) NSInteger like_id;
@property (nonatomic, copy, nullable) NSString * to_id;
@property (nonatomic, copy, nullable) NSString *user_udid;

@property (nonatomic, strong) NSString *create_time;
@property (nonatomic, strong) NSString *update_time;
@property (nonatomic, assign) NSInteger status;


@property (nonatomic, assign) Like_type like_type;
@property (nonatomic, strong) UserModel *userInfo;

@end

NS_ASSUME_NONNULL_END
