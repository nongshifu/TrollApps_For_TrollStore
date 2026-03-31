//  ToolModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>
#import "config.h"
#import "UserModel.h"
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WebToolStatus) {
    WebToolStatusNormal = 0,      // 正常
    WebToolStatusInvalid = 1,     // 失效
    WebToolStatusUpdating = 2,    // 更新中
    WebToolStatusBanned = 3       // 禁止使用
};

@interface WebToolModel : NSObject<IGListDiffable>

/** 工具唯一标识（对应数据库tool_id） */
@property (nonatomic, assign) NSInteger tool_id;

/** 工具名称（对应数据库tool_name） */
@property (nonatomic, strong) NSString *tool_name;

/** 工具类型（对应数据库tool_type） */
@property (nonatomic, assign) NSInteger tool_type;

/** 工具简介（对应数据库tool_description） */
@property (nonatomic, strong) NSString *tool_description;

/** 工具核心内容（对应数据库content） */
@property (nonatomic, strong) NSString *html_content;

/** 工具文件存储路径（对应数据库tool_path） */
@property (nonatomic, strong) NSString *tool_path;

/** 工具标签（JSON数组，对应数据库tags） */
@property (nonatomic, strong) NSArray *tags;

/** @"正常发布", @"已失效", @"更新中", @"锁定", @"上传中", @"隐藏" */
@property (nonatomic, assign) NSInteger tool_status;

/** 点赞数量（对应数据库like_count） */
@property (nonatomic, assign) NSInteger like_count;
@property (nonatomic, assign) BOOL isLike;

/** 踩一踩数量（对应数据库like_count） */
@property (nonatomic, assign) NSInteger dislike_count;
@property (nonatomic, assign) BOOL isDislike;

/** 评论数量（对应数据库comment_count） */
@property (nonatomic, assign) NSInteger comment_count;
@property (nonatomic, assign) BOOL isComment;

/** 收藏数量（对应数据库collect_count） */
@property (nonatomic, assign) NSInteger collect_count;
@property (nonatomic, assign) BOOL isCollect;

/** 分享数量（对应数据库share_count） */
@property (nonatomic, assign) NSInteger share_count;
@property (nonatomic, assign) BOOL isShare;

/** 访问次数（对应数据库view_count） */
@property (nonatomic, assign) NSInteger view_count;

/** 创建时间（对应数据库create_time） */
@property (nonatomic, strong) NSString *create_time;

/** 更新时间（对应数据库update_time） */
@property (nonatomic, strong) NSString *update_time;

/** 发布用户ID（对应数据库user_id，可为空） */
@property (nonatomic, assign) NSInteger user_id;

/** 发布用户的设备唯一标识符（对应数据库udid） */
@property (nonatomic, strong) NSString *udid;

/** 用户模型（关联UserModel，通过user_id获取） */
@property (nonatomic, strong, nullable) UserModel *userModel;

/** 工具状态（本地扩展字段，非数据库字段） */
@property (nonatomic, assign) WebToolStatus status;

/** 版本号（本地扩展字段，非数据库字段） */
@property (nonatomic, strong) NSString *version;

/** 更新说明（本地扩展字段，非数据库字段） */
@property (nonatomic, strong) NSString *update_notes;

/** 管理员备注（本地扩展字段，非数据库字段） */
@property (nonatomic, strong) NSString *admin_notes;



/** 发布时间（本地扩展字段，非数据库字段） */
@property (nonatomic, strong) NSString *publish_time;

/** 存储目录（本地扩展字段，非数据库字段） */
@property (nonatomic, strong) NSString *storage_dir;

/** 当前版本文件名 */
@property (nonatomic, strong) NSString *html_file;


@property (nonatomic, strong, nullable) NSString * icon_url;//软件图标URL

@property (nonatomic, assign) BOOL isShowAll;

// 获取状态的字符串描述
- (NSString *)statusDescription;

// 获取标签的字符串表示
- (NSString *)tagsString;

// 设置标签的字符串表示
- (void)setTagsWithString:(NSString *)tagsString;

@end

NS_ASSUME_NONNULL_END
