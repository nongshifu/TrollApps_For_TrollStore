//
//  PostModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/31.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>
#import "PostAttachmentModel.h"
#import "UserModel.h"
#import "MediaItem.h"

#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

/** 帖子状态 */
typedef NS_ENUM(NSInteger, PostStatus) {
    PostStatusDraft = 0,        // 草稿
    PostStatusPendingAudit = 1, // 待上传附件
    PostStatusPublished = 2,    // 已发布
    PostStatusRemoved = 3,      // 已下架
    PostStatusDeleted = 4       // 已删除
};

/** 帖子审核状态 */
typedef NS_ENUM(NSInteger, PostAuditStatus) {
    PostAuditStatusNotAudited = 0, // 未审核
    PostAuditStatusApproved = 1,   // 审核通过
    PostAuditStatusRejected = 2    // 审核驳回
};

/** 帖子可见范围 */
typedef NS_ENUM(NSInteger, PostVisibility) {
    PostVisibilityPublic = 0,    // 公开
    PostVisibilityOnlyFans = 1,  // 仅粉丝可见
    PostVisibilityOnlySelf = 2   // 仅自己可见
};

/** 帖子排序类型（配套sort_type字段） */
typedef NS_ENUM(NSInteger, PostSortType) {
    PostSortTypeCreateTime = 0,  // 按创建时间
    PostSortTypeHot = 1,         // 按热度
    PostSortTypeRecommend = 2,   // 按推荐权重
    PostSortTypeLastComment = 3  // 按最后评论时间
};


@interface PostModel : NSObject <IGListDiffable,YYModel>

#pragma mark - 基础信息（主键/唯一标识）
/// 帖子ID（数据库主键，自增）
@property (nonatomic, assign) long long post_id;
/// 帖子唯一UUID（避免ID冲突，跨端/跨库兼容）
@property (nonatomic, copy) NSString *post_uuid;
/// 帖子标题（可选，短文本）
@property (nonatomic, copy) NSString *post_title;
/// 帖子分类ID（如「美食」「旅行」，关联分类表）
@property (nonatomic, assign) NSInteger category_id;
/// 帖子标签ID数组（如@[@1,@2,@3]，字符串数组/数值数组，适配YYModel）
@property (nonatomic, strong) NSArray<NSNumber *> *topic_ids;

#pragma mark - 内容信息（文字/图片/视频/附件）
/// 帖子正文（富文本/纯文本，支持HTML）
@property (nonatomic, copy) NSString *post_content;
/// 图片URL数组（原图地址，如@[@"url1",@"url2"]）
@property (nonatomic, strong) NSArray<NSString *> *post_images;
/// 图片缩略图URL数组（优化加载，和post_images一一对应）
@property (nonatomic, strong) NSArray<NSString *> *post_images_thumb;
/// 视频URL（原视频地址）
@property (nonatomic, copy) NSString *post_video_url;
/// 视频封面URL
@property (nonatomic, copy) NSString *post_video_thumb_url;
/// 视频时长（秒）
@property (nonatomic, assign) NSTimeInterval post_video_duration;
/// 视频文件大小（字节）
@property (nonatomic, assign) long long post_video_size;
/// 录音URL数组（如@[@"url1",@"url2"]）
@property (nonatomic, strong) NSArray<NSString *> *post_audio_urls;
/// 录音时长数组（秒，和post_audio_urls一一对应）
@property (nonatomic, strong) NSArray<NSNumber *> *post_audio_durations;
/// 录音文件大小数组（字节，和post_audio_urls一一对应）
@property (nonatomic, strong) NSArray<NSNumber *> *post_audio_sizes;

/// 地理位置（可选，如「北京市朝阳区」）
@property (nonatomic, copy) NSString *post_location;
/// 经纬度（格式："lat,lng"，如@"39.908823,116.397470"）
@property (nonatomic, copy) NSString *post_latlng;
/// 附件目录
@property (nonatomic, copy) NSString *post_dir;

////统一管理所有媒体
@property (nonatomic, strong) NSMutableArray<MediaItem *> *mediaItems;
/// 附件模型数组（PostAttachmentModel）
@property (nonatomic, strong) NSArray<PostAttachmentModel *> *post_attachments;

@property (nonatomic, assign) BOOL isUpdating; // （本地属性）是否为更新模式



#pragma mark - 用户关联信息（发布者）
/// 发布者用户ID
@property (nonatomic, assign) NSInteger user_id;
/// 帖子发布者用户UDID
@property (nonatomic, copy) NSString *udid;
/// 发布者用户名
@property (nonatomic, copy) NSString *author_name;

/// 发布token
@property (nonatomic, copy) NSString *token;
/// 用户头像地址
@property (nonatomic, copy) NSString *author_avatar;
/// 发布者用户模型
@property (nonatomic, strong) UserModel * user_model;


#pragma mark - 时间/排序属性（核心排序维度）
/// 帖子创建时间（时间戳，草稿保存时间）
@property (nonatomic, assign) NSTimeInterval post_create_time;
/// 帖子更新时间（时间戳，编辑后更新）
@property (nonatomic, assign) NSTimeInterval post_update_time;
/// 帖子发布时间（时间戳，审核通过后发布时间）
@property (nonatomic, assign) NSTimeInterval post_publish_time;
/// 最后评论时间（时间戳，用于「最新回复」排序）
@property (nonatomic, assign) NSTimeInterval post_last_comment_time;
/// 排序权重（数值越大越靠前，用于置顶/推荐）
@property (nonatomic, assign) NSInteger post_sort_weight;
/// 排序类型（0-按创建时间 1-按热度 2-按推荐 3-按最后评论）
@property (nonatomic, assign) NSInteger post_sort_type;

#pragma mark - 状态/管理属性（运营/审核/权限）
/// 帖子状态（0-草稿 1-待上传附件 2-已发布 3-已下架 4-已删除）
@property (nonatomic, assign) PostStatus post_status;
/// 审核状态（0-未审核 1-审核通过 2-审核驳回）
@property (nonatomic, assign) PostAuditStatus post_audit_status;
/// 驳回原因（审核不通过时填写）
@property (nonatomic, copy) NSString *post_reject_reason;
/// 审核次数（多次审核）
@property (nonatomic, assign) NSInteger post_audit_count;
/// 是否置顶（0-否 1-是）
@property (nonatomic, assign) BOOL post_is_top;
/// 是否热门（0-否 1-是）
@property (nonatomic, assign) BOOL post_is_hot;
/// 是否推荐（0-否 1-是）
@property (nonatomic, assign) BOOL post_is_recommend;
/// 可见范围（0-公开 1-仅粉丝 2-仅自己）
@property (nonatomic, assign) PostVisibility post_visibility;
/// 是否禁止评论（0-允许 1-禁止）
@property (nonatomic, assign) BOOL post_is_comment_forbidden;
/// 是否禁止分享（0-允许 1-禁止）
@property (nonatomic, assign) BOOL post_is_share_forbidden;

#pragma mark - 统计属性（互动数据）
/// 浏览数
@property (nonatomic, assign) NSInteger post_view_count;
/// 点赞数
@property (nonatomic, assign) NSInteger post_like_count;
/// 评论数
@property (nonatomic, assign) NSInteger post_comment_count;
/// 分享数
@property (nonatomic, assign) NSInteger post_share_count;
/// 收藏数
@property (nonatomic, assign) NSInteger post_collect_count;
/// 举报数
@property (nonatomic, assign) NSInteger post_report_count;
/// 当前用户是否点赞（0-否 1-是，前端展示用）
@property (nonatomic, assign) BOOL post_is_liked;
/// 当前用户是否收藏（0-否 1-是，前端展示用）
@property (nonatomic, assign) BOOL post_is_collected;

#pragma mark - 扩展字段（兼容个性化需求）
/// 扩展字段（字典，存自定义数据，如@{"is_anonymous":@1, "activity_id":@123}）
@property (nonatomic, strong) NSDictionary *post_extra;

///是否显示全部完整数据
@property (nonatomic, assign) BOOL showAllData;

@end

NS_ASSUME_NONNULL_END
