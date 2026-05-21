//
//  AnnouncementModel.m
//  TrollApps
//
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//


#import "AnnouncementModel.h"

@implementation AnnouncementModel

#pragma mark - IGListDiffable
- (nonnull id<NSObject>)diffIdentifier {
    return [NSString stringWithFormat:@"%ld", (long)self.announcement_id];
}

- (BOOL)isEqualToDiffableObject:(nullable id<IGListDiffable>)object {
    return [self isEqual:object];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[AnnouncementModel class]] && [self.announcement_uuid isEqualToString:((AnnouncementModel *)object).announcement_uuid];
}

- (NSUInteger)hash {
    return self.announcement_uuid.hash;
}

- (BOOL)isEqualToDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    return [self.announcement_uuid isEqualToString:dictionary[@"announcement_uuid"]];
}

#pragma mark - Helper Methods

- (BOOL)isExpired {
    if (self.announcement_expire_time.length == 0 || [self.announcement_expire_time isEqualToString:@"<null>"]) {
        return NO;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *expireDate = [formatter dateFromString:self.announcement_expire_time];
    if (!expireDate) {
        return NO;
    }
    return [[NSDate date] compare:expireDate] == NSOrderedDescending;
}

- (BOOL)isActive {
    if (self.announcement_status != AnnouncementStatusPublished) {
        return NO;
    }
    if ([self isExpired]) {
        return NO;
    }
    return self.announcement_is_active;
}

- (NSString *)formattedCreateTime {
    return self.announcement_create_time ?: @"";
}

- (NSString *)formattedPublishTime {
    return self.announcement_publish_time ?: @"";
}

#pragma mark - YYModel

+ (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    return YES;
}

+ (id)modelCustomPropertyToDictionaryBlock {
    return nil;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.announcement_id = [coder decodeIntegerForKey:@"announcement_id"];
        self.announcement_uuid = [coder decodeObjectForKey:@"announcement_uuid"];
        self.announcement_title = [coder decodeObjectForKey:@"announcement_title"];
        self.announcement_content = [coder decodeObjectForKey:@"announcement_content"];
        self.announcement_summary = [coder decodeObjectForKey:@"announcement_summary"];
        self.announcement_images = [coder decodeObjectForKey:@"announcement_images"];
        self.announcement_images_thumb = [coder decodeObjectForKey:@"announcement_images_thumb"];
        self.announcement_author_id = [coder decodeIntegerForKey:@"announcement_author_id"];
        self.announcement_author_name = [coder decodeObjectForKey:@"announcement_author_name"];
        self.announcement_create_time = [coder decodeObjectForKey:@"announcement_create_time"];
        self.announcement_update_time = [coder decodeObjectForKey:@"announcement_update_time"];
        self.announcement_publish_time = [coder decodeObjectForKey:@"announcement_publish_time"];
        self.announcement_expire_time = [coder decodeObjectForKey:@"announcement_expire_time"];
        self.announcement_sort_weight = [coder decodeIntegerForKey:@"announcement_sort_weight"];
        self.announcement_status = [coder decodeIntegerForKey:@"announcement_status"];
        self.announcement_is_active = [coder decodeBoolForKey:@"announcement_is_active"];
        self.announcement_view_count = [coder decodeIntegerForKey:@"announcement_view_count"];
        self.announcement_click_count = [coder decodeIntegerForKey:@"announcement_click_count"];
        self.announcement_priority = [coder decodeIntegerForKey:@"announcement_priority"];
        self.announcement_type = [coder decodeIntegerForKey:@"announcement_type"];
        self.announcement_target = [coder decodeObjectForKey:@"announcement_target"];
        self.announcement_target_value = [coder decodeObjectForKey:@"announcement_target_value"];
        self.announcement_popup_mode = [coder decodeIntegerForKey:@"announcement_popup_mode"];
        self.announcement_popup_count = [coder decodeIntegerForKey:@"announcement_popup_count"];
        self.announcement_popup_once_users = [coder decodeObjectForKey:@"announcement_popup_once_users"];
        self.announcement_color = [coder decodeObjectForKey:@"announcement_color"];
        self.announcement_icon = [coder decodeObjectForKey:@"announcement_icon"];
        self.announcement_link = [coder decodeObjectForKey:@"announcement_link"];
        self.announcement_link_text = [coder decodeObjectForKey:@"announcement_link_text"];
        self.announcement_extra = [coder decodeObjectForKey:@"announcement_extra"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.announcement_id forKey:@"announcement_id"];
    [coder encodeObject:self.announcement_uuid forKey:@"announcement_uuid"];
    [coder encodeObject:self.announcement_title forKey:@"announcement_title"];
    [coder encodeObject:self.announcement_content forKey:@"announcement_content"];
    [coder encodeObject:self.announcement_summary forKey:@"announcement_summary"];
    [coder encodeObject:self.announcement_images forKey:@"announcement_images"];
    [coder encodeObject:self.announcement_images_thumb forKey:@"announcement_images_thumb"];
    [coder encodeInteger:self.announcement_author_id forKey:@"announcement_author_id"];
    [coder encodeObject:self.announcement_author_name forKey:@"announcement_author_name"];
    [coder encodeObject:self.announcement_create_time forKey:@"announcement_create_time"];
    [coder encodeObject:self.announcement_update_time forKey:@"announcement_update_time"];
    [coder encodeObject:self.announcement_publish_time forKey:@"announcement_publish_time"];
    [coder encodeObject:self.announcement_expire_time forKey:@"announcement_expire_time"];
    [coder encodeInteger:self.announcement_sort_weight forKey:@"announcement_sort_weight"];
    [coder encodeInteger:self.announcement_status forKey:@"announcement_status"];
    [coder encodeBool:self.announcement_is_active forKey:@"announcement_is_active"];
    [coder encodeInteger:self.announcement_view_count forKey:@"announcement_view_count"];
    [coder encodeInteger:self.announcement_click_count forKey:@"announcement_click_count"];
    [coder encodeInteger:self.announcement_priority forKey:@"announcement_priority"];
    [coder encodeInteger:self.announcement_type forKey:@"announcement_type"];
    [coder encodeObject:self.announcement_target forKey:@"announcement_target"];
    [coder encodeObject:self.announcement_target_value forKey:@"announcement_target_value"];
    [coder encodeInteger:self.announcement_popup_mode forKey:@"announcement_popup_mode"];
    [coder encodeInteger:self.announcement_popup_count forKey:@"announcement_popup_count"];
    [coder encodeObject:self.announcement_popup_once_users forKey:@"announcement_popup_once_users"];
    [coder encodeObject:self.announcement_color forKey:@"announcement_color"];
    [coder encodeObject:self.announcement_icon forKey:@"announcement_icon"];
    [coder encodeObject:self.announcement_link forKey:@"announcement_link"];
    [coder encodeObject:self.announcement_link_text forKey:@"announcement_link_text"];
    [coder encodeObject:self.announcement_extra forKey:@"announcement_extra"];
}

@end
