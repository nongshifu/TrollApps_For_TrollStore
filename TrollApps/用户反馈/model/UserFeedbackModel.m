//
//  UserFeedbackModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//

#import "UserFeedbackModel.h"

@implementation UserFeedbackModel


// 处理进度状态文本描述
- (NSString *)progress_status_text {
    switch (self.progress_status) {
        case 0: return @"未处理";
        case 1: return @"处理中";
        case 2: return @"已解决";
        case 3: return @"已关闭";
        default: return @"未知状态";
    }
}

// 反馈类型文本描述
- (NSString *)feedback_type_text {
    switch (self.feedback_type) {
        case 1: return @"功能建议";
        case 2: return @"程序Bug";
        case 3: return @"界面优化";
        case 4: return @"内容错误";
        case 5: return @"账号问题";
        case 6: return @"其他";
        default: return @"未知类型";
    }
}

#pragma mark - IGListDiffable 协议实现

- (id<NSObject>)diffIdentifier {
    // 使用反馈ID作为唯一标识符
    return @(self.feedback_id);
}

- (BOOL)isEqualToDiffableObject:(id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[UserFeedbackModel class]]) return NO;
    
    UserFeedbackModel *other = (UserFeedbackModel *)object;
    return [self diffIdentifier] == [other diffIdentifier] &&
           [self isEqualToFeedback:other];
}

// 自定义比较方法，检查所有属性是否相同
- (BOOL)isEqualToFeedback:(UserFeedbackModel *)other {
    if (!other) return NO;
    
    BOOL haveEqualIds = (self.feedback_id == other.feedback_id);
    BOOL haveEqualUserIds = [self.user_id isEqualToString:other.user_id];
    BOOL haveEqualUdid = [self.udid isEqualToString:other.udid];
    BOOL haveEqualContent = [self.feedback_content isEqualToString:other.feedback_content];
    BOOL haveEqualStatus = (self.progress_status == other.progress_status);
    BOOL haveEqualType = (self.feedback_type == other.feedback_type);
    BOOL haveEqualContact = [self.contact_way isEqualToString:other.contact_way];
    BOOL haveEqualBeizhu = [self.admin_beizhu isEqualToString:other.admin_beizhu];
    
    // 比较日期（允许空值）
    BOOL haveEqualFeedbackTime = YES;
    if (self.feedback_time && other.feedback_time) {
        haveEqualFeedbackTime = [self.feedback_time isEqualToDate:other.feedback_time];
    } else if ((self.feedback_time && !other.feedback_time) || (!self.feedback_time && other.feedback_time)) {
        haveEqualFeedbackTime = NO;
    }
    
    BOOL haveEqualHandleTime = YES;
    if (self.handle_time && other.handle_time) {
        haveEqualHandleTime = [self.handle_time isEqualToDate:other.handle_time];
    } else if ((self.handle_time && !other.handle_time) || (!self.handle_time && other.handle_time)) {
        haveEqualHandleTime = NO;
    }
    
    return haveEqualIds && haveEqualUserIds && haveEqualUdid &&
           haveEqualContent && haveEqualStatus && haveEqualType &&
           haveEqualContact && haveEqualFeedbackTime && haveEqualHandleTime && haveEqualBeizhu;
}

@end
