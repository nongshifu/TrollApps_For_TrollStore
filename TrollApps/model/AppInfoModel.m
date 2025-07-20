#import "AppInfoModel.h"

@implementation AppInfoModel

#pragma mark - IGListDiffable

/**
 * 用于判断两个对象是否为同一实例（通常基于唯一标识符）
 * 这里使用 app_id 作为唯一标识（数据库自增主键）
 */
- (nonnull id<NSObject>)diffIdentifier {
    return @(self.app_id); // app_id 是数据库唯一主键，确保唯一性
}

/**
 * 用于判断两个对象的内容是否相同
 * 对比所有关键属性，确保UI展示内容一致时不会触发不必要的刷新
 */
- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES; // 同一实例直接返回YES
    if (![object isKindOfClass:[AppInfoModel class]]) return NO; // 类型不同返回NO
    
    AppInfoModel *other = (AppInfoModel *)object;
    
    // 基础信息对比
    if (self.app_id != other.app_id) return NO;
    if (![self.bundle_id isEqualToString:other.bundle_id]) return NO;
    if (![self.app_name isEqualToString:other.app_name]) return NO;
    
    
    // 状态信息对比
    if (self.upload_status != other.upload_status) return NO;
    if (self.app_status != other.app_status) return NO;
    
    // 互动数据对比（影响UI展示的计数）
    if (self.like_count != other.like_count) return NO;
    if (self.collect_count != other.collect_count) return NO;
    if (self.dislike_count != other.dislike_count) return NO;
    if (self.download_count != other.download_count) return NO;
    if (self.comment_count != other.comment_count) return NO;
    
    // 布尔状态对比（用户操作状态）
    if (self.isLike != other.isLike) return NO;
    if (self.isCollect != other.isCollect) return NO;
    if (self.isDislike != other.isDislike) return NO;
    if (self.isShowAll != other.isShowAll) return NO;
    if (self.isComment != other.isComment) return NO;
    if (self.isShare != other.isShare) return NO;
    
    // 内容信息对比（影响展示的文本/URL）
    if (![self.app_description isEqualToString:other.app_description]) return NO;
    if (![self.version_name isEqualToString:other.version_name]) return NO;
    if (![self.icon_url isEqualToString:other.icon_url]) return NO;
    if (![self.release_notes isEqualToString:other.release_notes]) return NO;
    if (![self.track_id isEqualToString:other.track_id]) return NO;
    if (![self.add_date isEqualToString:other.add_date]) return NO;
    if (![self.update_date isEqualToString:other.update_date]) return NO;
    if (![self.mainFileUrl isEqualToString:other.mainFileUrl]) return NO;
    
    // 数组对比（标签和文件名）
    if (![self.tags isEqualToArray:other.tags]) return NO;
    if (![self.fileNames isEqualToArray:other.fileNames]) return NO;
    
    
    // 所有关键属性相同，返回YES
    return YES;
}

@end
