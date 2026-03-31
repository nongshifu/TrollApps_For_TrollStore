//
//  ToolModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "WebToolModel.h"

@implementation WebToolModel

/**
 *  唯一标识：使用 tool_id 作为区分不同模型的唯一依据
 */
- (id<NSObject>)diffIdentifier {
    return @(self.tool_id); // 基本类型包装为 NSNumber，确保实现 NSCopying
}

/**
 *  属性比较：判断两个模型是否「内容相等」
 *  当 diffIdentifier 相同时，会调用此方法比较具体属性
 */
- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES; // 同一对象直接返回相等
    if (![object isKindOfClass:[WebToolModel class]]) return NO; // 类型不同返回不等
    
    WebToolModel *other = (WebToolModel *)object;
    
    // 比较所有重要属性（按字母顺序排列）
    BOOL isEqual = (self.tool_id == other.tool_id)
                && [self.tool_name isEqualToString:other.tool_name]
                && (self.tool_type == other.tool_type)
                && [self.tool_description isEqualToString:other.tool_description]
                && [self.html_content isEqualToString:other.html_content]
                && [self.tool_path isEqualToString:other.tool_path]
                && [self.tags isEqualToArray:other.tags]
                && (self.tool_status == other.tool_status)
    
                && (self.isShowAll == other.isShowAll)
                && (self.like_count == other.like_count)
                && (self.isLike == other.isLike)
                && (self.dislike_count == other.dislike_count)
                && (self.isDislike == other.isDislike)
                && (self.collect_count == other.collect_count)
                && (self.isCollect == other.isCollect)
                && (self.share_count == other.share_count)
                && (self.isShare == other.isShare)
                && (self.comment_count == other.comment_count)
                && (self.isComment == other.isComment)
                && (self.view_count == other.view_count)
    
    
                && [self.create_time isEqualToString:other.create_time]
                && [self.update_time isEqualToString:other.update_time]
                && (self.user_id == other.user_id)
                && [self.udid isEqualToString:other.udid]
                && (self.status == other.status)
                && [self.version isEqualToString:other.version]
                && [self.html_file isEqualToString:other.html_file]
    
                && [self.icon_url isEqualToString:other.icon_url]
                && [self.update_notes isEqualToString:other.update_notes]
                && [self.admin_notes isEqualToString:other.admin_notes]
                && (self.share_count == other.share_count);
    
    // 比较关联对象（如果存在）
    if (self.userModel && other.userModel) {
        isEqual = isEqual && [self.userModel isEqualToDiffableObject:other.userModel];
    } else if (self.userModel || other.userModel) {
        // 一个有userModel，另一个没有
        isEqual = NO;
    }
    
    return isEqual;
}

// 获取状态的字符串描述
- (NSString *)statusDescription {
    switch (self.status) {
        case WebToolStatusNormal:
            return @"正常";
        case WebToolStatusInvalid:
            return @"失效";
        case WebToolStatusUpdating:
            return @"更新中";
        case WebToolStatusBanned:
            return @"禁止使用";
        default:
            return @"未知";
    }
}

// 获取标签的字符串表示
- (NSString *)tagsString {
    if (!self.tags || self.tags.count == 0) {
        return @"";
    }
    return [self.tags componentsJoinedByString:@","];
}

// 设置标签的字符串表示
- (void)setTagsWithString:(NSString *)tagsString {
    if (!tagsString || tagsString.length == 0) {
        self.tags = @[];
        return;
    }
    self.tags = [tagsString componentsSeparatedByString:@","];
}

@end
