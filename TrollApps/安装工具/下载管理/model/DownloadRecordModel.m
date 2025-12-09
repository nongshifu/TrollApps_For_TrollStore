//
//  DownloadRecordModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/9.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DownloadRecordModel.h"

@implementation DownloadRecordModel
/// 用于比较两个对象是否是同一个实例（使用唯一主键recordId）
- (id<NSObject>)diffIdentifier {
    return @(self.recordId);
}

/// 2. 完整实现内容比较逻辑（用于判断对象内容是否相同）
- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    
    // 步骤1：指针相等，直接返回YES
    if (self == object) {
        return YES;
    }
    
    // 步骤2：类型不匹配，返回NO
    if (![object isKindOfClass:[DownloadRecordModel class]]) {
        return NO;
    }
    
    // 步骤3：转换为当前类类型
    DownloadRecordModel *otherRecord = (DownloadRecordModel *)object;
    
    // 步骤4：比较所有关键属性（手动比较/YYModel自动比较二选一）
    // 方式A：手动比较所有属性（精确控制，适合属性较少的情况）
    BOOL isEqual =
        (self.recordId == otherRecord.recordId) &&
        (self.appId == otherRecord.appId) &&
        [self.userUdid isEqualToString:otherRecord.userUdid] &&
        (self.downloadUrl == otherRecord.downloadUrl) &&
        [self.downloadTime isEqualToString:otherRecord.downloadTime] &&
        (self.downloadPoints == otherRecord.downloadPoints) &&
        (self.status == otherRecord.status) &&
        [self.ipAddress isEqualToString:otherRecord.ipAddress] &&
        [self.deviceInfo isEqualToString:otherRecord.deviceInfo] &&
        [self.versionName isEqualToString:otherRecord.versionName] &&
        [self.createdAt isEqualToString:otherRecord.createdAt] &&
        [self.updatedAt isEqualToString:otherRecord.updatedAt];
    
    // 方式B：使用YYModel自动比较（高效便捷，适合属性较多的情况）
    // BOOL isEqual = [self yy_modelIsEqual:otherRecord];
    
    return isEqual;
}
@end
