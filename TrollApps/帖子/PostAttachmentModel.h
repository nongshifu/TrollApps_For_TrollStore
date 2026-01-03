//
//  PostAttachmentModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/31.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <YYModel/YYModel.h>
NS_ASSUME_NONNULL_BEGIN

/** 附件类型 */
typedef NS_ENUM(NSInteger, AttachmentType) {
    AttachmentTypeUnknown = 0, // 未知类型
    AttachmentTypeImage = 1,   // 图片
    AttachmentTypeVideo = 2,   // 视频
    AttachmentTypeAudio = 3,   // 录音
    AttachmentTypeDocument = 4, // 文档
    AttachmentTypeOther = 5    // 其他
    
};


@interface PostAttachmentModel : NSObject <YYModel>

/// 附件ID（数据库主键）
@property (nonatomic, assign) NSInteger attachment_id;
/// 关联帖子ID
@property (nonatomic, assign) NSInteger post_id;
/// 附件名称（如「简历.pdf」）
@property (nonatomic, copy) NSString *attachment_name;
/// 附件URL（远程地址）
@property (nonatomic, copy) NSString *attachment_url;
/// 附件本地路径（可选，发布前临时存储）
@property (nonatomic, copy) NSString *attachment_local_path;
/// 附件大小（字节）
@property (nonatomic, assign) long long attachment_size;
/// 附件类型（如pdf、doc、zip，统一小写）
@property (nonatomic, assign) AttachmentType attachment_type;
/// 附件MIME类型（如image/jpeg、video/mp4）
@property (nonatomic, copy) NSString *attachment_mime_type;
/// 附件上传状态（0-未上传 1-上传中 2-已上传 3-上传失败）
@property (nonatomic, assign) NSInteger upload_status;
/// 附件创建时间（时间戳）
@property (nonatomic, assign) NSTimeInterval create_time;
/// 附件来源类型（0:本地文件 1:URL）
@property (nonatomic, assign) NSInteger attachment_source_type;

/// 图片Base64数据（可选，用于直接上传Base64图片）
@property (nonatomic, copy) NSString *attachment_base64;

/// 视频时长（秒，仅视频类型使用）
@property (nonatomic, assign) NSTimeInterval attachment_video_duration;
/// 视频缩略图URL（仅视频类型使用）
@property (nonatomic, copy) NSString *attachment_video_thumb_url;
/// 视频缩略图本地路径（仅视频类型使用，上传前临时存储）
@property (nonatomic, copy) NSString *attachment_video_thumb_local_path;

/// 录音时长（秒，仅录音类型使用）
@property (nonatomic, assign) NSTimeInterval attachment_audio_duration;

@end


NS_ASSUME_NONNULL_END
