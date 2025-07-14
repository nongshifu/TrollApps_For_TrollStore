//
//  VIPPackage.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "VIPPackage.h"
#import "config.h"

@implementation VIPPackage

- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[self class]]) return NO;
    
    VIPPackage *other = (VIPPackage *)object;
    
    // 比较所有有意义的属性
    return [self.packageId isEqualToString:other.packageId] &&
           [self.title isEqualToString:other.title] &&
           [self.vipDescription isEqualToString:other.vipDescription] &&
           [self.price isEqualToString:other.price] &&
           self.level == other.level &&
           [self.themeColor isEqualToString:other.themeColor] &&
           self.isRecommended == other.isRecommended &&
           [self.recommendedTitle isEqualToString:other.recommendedTitle];
}

- (id<NSObject>)diffIdentifier {
    // 使用packageId作为唯一标识符，比level更可靠
    return self.packageId;
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToDiffableObject:object];
}

// 建议同时实现hash方法，确保对象在集合中能正常工作
- (NSUInteger)hash {
    return [self.packageId hash];
}

@end
