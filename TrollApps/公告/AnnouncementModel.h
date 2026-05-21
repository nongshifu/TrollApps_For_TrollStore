//
//  AnnouncementModel.h
//  TrollApps
// 系统公告模型 - 与数据库 announcements 表字段一一对应
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <IGListKit/IGListKit.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AnnouncementStatus) {
    AnnouncementStatusDraft = 0,       // 草稿
    AnnouncementStatusPublished = 1,    // 已发布
    AnnouncementStatusOffline = 2,      // 已下架
    AnnouncementStatusDeleted = 3      // 已删除
};

typedef NS_ENUM(NSInteger, AnnouncementPriority) {
    AnnouncementPriorityNormal = 0,    // 普通
    AnnouncementPriorityImportant = 1, // 重要
    AnnouncementPriorityUrgent = 2     // 紧急
};

typedef NS_ENUM(NSInteger, AnnouncementType) {
    AnnouncementTypeNormal = 0,        // 普通公告
    AnnouncementTypeSystem = 1,         // 系统公告
    AnnouncementTypeActivity = 2,       // 活动公告
    AnnouncementTypeMaintenance = 3    // 维护公告
};

typedef NS_ENUM(NSInteger, AnnouncementPopupMode) {
    AnnouncementPopupModeNone = 0,             // 不弹窗
    AnnouncementPopupModeClosable = 1,         // 可关闭弹窗
    AnnouncementPopupModeForced = 2,           // 强制弹窗
    AnnouncementPopupModeOnce = 3              // 仅弹窗一次
};

@interface AnnouncementModel : NSObject <IGListDiffable, YYModel, NSCoding>

@property (nonatomic, assign) NSInteger announcement_id;
@property (nonatomic, copy) NSString *announcement_uuid;
@property (nonatomic, copy) NSString *announcement_title;
@property (nonatomic, copy) NSString *announcement_content;
@property (nonatomic, copy) NSString *announcement_summary;
@property (nonatomic, strong, nullable) NSArray<NSString *> *announcement_images;
@property (nonatomic, strong, nullable) NSArray<NSString *> *announcement_images_thumb;
@property (nonatomic, assign) NSInteger announcement_author_id;
@property (nonatomic, copy) NSString *announcement_author_name;
@property (nonatomic, copy) NSString *announcement_create_time;
@property (nonatomic, copy) NSString *announcement_update_time;
@property (nonatomic, copy) NSString *announcement_publish_time;
@property (nonatomic, copy) NSString *announcement_expire_time;
@property (nonatomic, assign) NSInteger announcement_sort_weight;
@property (nonatomic, assign) AnnouncementStatus announcement_status;
@property (nonatomic, assign) BOOL announcement_is_active;
@property (nonatomic, assign) NSInteger announcement_view_count;
@property (nonatomic, assign) NSInteger announcement_click_count;
@property (nonatomic, assign) AnnouncementPriority announcement_priority;
@property (nonatomic, assign) AnnouncementType announcement_type;
@property (nonatomic, copy) NSString *announcement_target;
@property (nonatomic, copy) NSString *announcement_target_value;
@property (nonatomic, assign) AnnouncementPopupMode announcement_popup_mode;
@property (nonatomic, assign) NSInteger announcement_popup_count;
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *announcement_popup_once_users;
@property (nonatomic, copy) NSString *announcement_color;
@property (nonatomic, copy) NSString *announcement_icon;
@property (nonatomic, copy) NSString *announcement_link;
@property (nonatomic, copy) NSString *announcement_link_text;
@property (nonatomic, strong, nullable) NSDictionary *announcement_extra;

#pragma mark - IGListDiffable

- (BOOL)isEqualToDictionary:(NSDictionary *)dictionary;

#pragma mark - YYModel

+ (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict;
+ (id)modelCustomPropertyToDictionaryBlock;

#pragma mark - Helper Methods

- (BOOL)isExpired;
- (BOOL)isActive;
- (NSString *)formattedCreateTime;
- (NSString *)formattedPublishTime;

@end

NS_ASSUME_NONNULL_END

