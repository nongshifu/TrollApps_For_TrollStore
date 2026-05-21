//
//  AppVersionHistoryModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "AppVersionHistoryModel.h"

@implementation AppVersionHistoryModel

#pragma mark - YYModel 映射（字段名与属性名一致，无需额外映射）
+ (BOOL)yy_modelShouldUseClassPropertyName {
    return YES; // 直接使用类属性名作为JSON字段名（与数据库字段匹配）
}

#pragma mark - IGListDiffable 协议实现（用于IGListKit刷新判断）
- (nonnull id<NSObject>)diffIdentifier {
    // 用唯一主键作为差异标识
    return @(self.app_id);
}

- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES; // 同一对象直接返回YES
    if (![object isKindOfClass:[AppVersionHistoryModel class]]) return NO; // 类型不一致返回NO
    
    AppVersionHistoryModel *other = (AppVersionHistoryModel *)object;
    
    // 对比所有属性（与数据库字段一一对应）
    return self.app_id == other.app_id &&
           [self.bundle_id isEqualToString:other.bundle_id] &&
           [self.app_name isEqualToString:other.app_name] &&
           self.version_code == other.version_code &&
           [self.version_name isEqualToString:other.version_name] &&
           self.build_number == other.build_number &&
           [self.release_notes isEqualToString:other.release_notes] &&
           [self.release_date isEqualToString:other.release_date] &&
           [self.min_supported_os isEqualToString:other.min_supported_os] &&
           [self.max_supported_os isEqualToString:other.max_supported_os] &&
           [self.download_url isEqualToString:other.download_url] &&
           self.file_size == other.file_size &&
           [self.md5_checksum isEqualToString:other.md5_checksum] &&
           self.is_mandatory == other.is_mandatory &&
           self.status == other.status &&
           [self.created_by isEqualToString:other.created_by] &&
           [self.created_at isEqualToString:other.created_at] &&
           [self.updated_at isEqualToString:other.updated_at];
}

@end
