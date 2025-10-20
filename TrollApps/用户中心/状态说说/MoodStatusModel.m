//
//  moodStatusModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "MoodStatusModel.h"

@implementation MoodStatusModel
/// 返回唯一标识（用于判断两个模型是否为同一对象）
- (id<NSObject>)diffIdentifier {
    // 若有唯一ID字段可替换为ID，这里简化用内存地址
    return @(self.mood_id);
}

/// 判断两个模型内容是否一致（用于更新UI）
- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[MoodStatusModel class]]) return NO;
    MoodStatusModel *other = (MoodStatusModel *)object;
    
    // 比较所有字段（mood_id相同但内容不同时，视为需要更新UI）
    return self.mood_id == other.mood_id &&
           [self.user_udid isEqualToString:other.user_udid] &&
           [self.content isEqualToString:other.content] &&
           [self.publish_time isEqualToString:other.publish_time];
}
@end
