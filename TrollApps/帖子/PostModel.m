
//
//  PostModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/31.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "PostModel.h"

@implementation PostModel

#pragma mark - <YYModel> 协议实现
/// 1. 指定数组类型属性对应的模型类（核心：YYModel解析数组时自动转模型）
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        // ✅ 正确：数组属性 → 对应模型类
        @"post_attachments": [PostAttachmentModel class], // 附件数组（NSArray<PostAttachmentModel *>）
        @"topic_ids": [NSNumber class],                   // 标签ID数组（NSArray<NSNumber *>）
        @"post_images": [NSString class],                 // 可选：补充图片URL数组的泛型（NSString）
        @"post_images_thumb": [NSString class]            // 可选：补充缩略图数组的泛型（NSString）
        // ❌ 错误：单个对象属性（非容器），必须移除
        // @"user_model": [UserModel class],
    };
}


#pragma mark - <IGListDiffable> 协议实现
/// 1. 返回唯一标识（IGListKit用于区分不同Item）
- (id<NSObject>)diffIdentifier {
    
    return @(self.post_id);
}

/// 2. 比较两个模型是否相等（IGListKit用于判断是否需要刷新UI）
/// 核心：对比所有影响UI展示的核心字段，避免漏对比导致UI不刷新
- (BOOL)isEqualToDiffableObject:(id<NSObject>)object {
    // 1. 类型判断
    if (self == object) return YES;
    
    
    if (![object isKindOfClass:[PostModel class]]) {
        return NO;
    }
    PostModel *otherPost = (PostModel *)object;
    
    // 2. 主键对比（基础校验）
    if (self.post_id != otherPost.post_id) {
        return NO;
    }
    if (![self.post_uuid isEqualToString:otherPost.post_uuid]) {
        return NO;
    }
    if (self.user_id != otherPost.user_id) {
        return NO;
    }
    
    // 3. 基础内容对比
    if (![self.post_title isEqualToString:otherPost.post_title]) return NO;
    if (![self.post_uuid isEqualToString:otherPost.post_uuid]) return NO;
    if (![self.author_avatar isEqualToString:otherPost.author_avatar]) return NO;
    if (![self.author_name isEqualToString:otherPost.author_name]) return NO;
    if (![self.post_content isEqualToString:otherPost.post_content]) return NO;
    if (self.category_id != otherPost.category_id) return NO;
    if (![self.topic_ids isEqualToArray:otherPost.topic_ids]) return NO;
    
    // 4. 多媒体内容对比
    if (![self.post_images isEqualToArray:otherPost.post_images]) return NO;
    if (![self.post_images_thumb isEqualToArray:otherPost.post_images_thumb]) return NO;
    if (![self.post_video_url isEqualToString:otherPost.post_video_url]) return NO;
    if (![self.post_video_thumb_url isEqualToString:otherPost.post_video_thumb_url]) return NO;
    if (self.post_video_duration != otherPost.post_video_duration) return NO;
    if (self.post_video_size != otherPost.post_video_size) return NO;
    if (![self.post_attachments isEqualToArray:otherPost.post_attachments]) return NO;
    
    // 5. 地理位置对比
    if (![self.post_location isEqualToString:otherPost.post_location]) return NO;
    if (![self.post_latlng isEqualToString:otherPost.post_latlng]) return NO;
    
    // 6. 用户信息对比（UserModel需实现isEqual方法）
    if (![self.user_model isEqual:otherPost.user_model]) return NO;
    
    // 7. 时间属性对比
    if (self.post_create_time != otherPost.post_create_time) return NO;
    if (self.post_update_time != otherPost.post_update_time) return NO;
    if (self.post_publish_time != otherPost.post_publish_time) return NO;
    if (self.post_last_comment_time != otherPost.post_last_comment_time) return NO;
    if (self.post_sort_weight != otherPost.post_sort_weight) return NO;
    if (self.post_sort_type != otherPost.post_sort_type) return NO;
    
    // 8. 状态属性对比
    if (self.post_status != otherPost.post_status) return NO;
    if (self.post_audit_status != otherPost.post_audit_status) return NO;
    if (![self.post_reject_reason isEqualToString:otherPost.post_reject_reason]) return NO;
    if (self.post_audit_count != otherPost.post_audit_count) return NO;
    if (self.post_is_top != otherPost.post_is_top) return NO;
    if (self.post_is_hot != otherPost.post_is_hot) return NO;
    if (self.isUpdating != otherPost.isUpdating) return NO;
    if (self.post_is_recommend != otherPost.post_is_recommend) return NO;
    if (self.post_visibility != otherPost.post_visibility) return NO;
    if (self.post_is_comment_forbidden != otherPost.post_is_comment_forbidden) return NO;
    if (self.post_is_share_forbidden != otherPost.post_is_share_forbidden) return NO;
    
    // 9. 统计属性对比（点赞/评论数等影响UI展示的字段）
    if (self.post_view_count != otherPost.post_view_count) return NO;
    if (self.post_like_count != otherPost.post_like_count) return NO;
    if (self.post_comment_count != otherPost.post_comment_count) return NO;
    if (self.post_share_count != otherPost.post_share_count) return NO;
    if (self.post_collect_count != otherPost.post_collect_count) return NO;
    if (self.post_report_count != otherPost.post_report_count) return NO;
    if (self.post_is_liked != otherPost.post_is_liked) return NO;
    if (self.post_is_collected != otherPost.post_is_collected) return NO;
    
    // 10. 扩展字段对比
    if (![self.post_extra isEqualToDictionary:otherPost.post_extra]) return NO;
    
    // 所有核心字段都相等 → 无需刷新UI
    return YES;
}


@end
