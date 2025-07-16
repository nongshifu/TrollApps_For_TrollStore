//
//  AppComment.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/1.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>
#import "config.h"
#import "UserModel.h"
#import <YYModel/YYModel.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, Comment_type) {
    Comment_type_AppComment = 0,     // App评论
    Comment_type_UserComment = 1, // 用户评论
    Comment_type_AppSecondComment = 2, //  App评论二级评论
    Comment_type_UserSecondComment = 3     // 用户评论二级评论
};

@interface AppComment : NSObject <IGListDiffable,YYModel>

@property (nonatomic, assign) NSInteger comment_id;
@property (nonatomic, copy, nullable) NSString * to_id;//之前NSInteger 改成NSString 评论的对方id （二级）可以是comment_id 评论id 或者是对方的udid
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy, nullable) NSString *user_udid;
@property (nonatomic, copy, nullable) NSString *idfv;
@property (nonatomic, strong) NSString *create_time;
@property (nonatomic, strong) NSString *update_time;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) BOOL isLiked;
@property (nonatomic, assign) NSInteger like_count;
@property (nonatomic, assign) Comment_type comment_type;
@property (nonatomic, strong) UserModel *userInfo;


@end

NS_ASSUME_NONNULL_END
