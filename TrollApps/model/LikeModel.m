//
//  LikeModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/15.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "LikeModel.h"

@implementation LikeModel
#pragma mark - IGListDiffable

- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[LikeModel class]]) return NO;
    return [self isEqual:object];
}

- (id<NSObject>)diffIdentifier {
    return [NSString stringWithFormat:@"%ld-%@", (long)self.like_id, self.create_time];;
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[LikeModel class]]) return NO;
    LikeModel *other = (LikeModel *)object;
    return self.like_id == other.like_id &&
           [self.to_id isEqualToString:other.to_id] &&
           [self.user_udid isEqualToString:other.user_udid] &&
           self.userInfo == other.userInfo &&
           self.like_type == other.like_type &&
    
    
           [self.create_time isEqualToString:other.create_time] &&
           [self.update_time isEqualToString:other.update_time];
}
// 2. 声明嵌套模型类（关键：告诉YYModel如何解析userInfo）
+ (NSDictionary *)modelContainerPropertyGenericClass {
    // 对于嵌套的对象属性，指定其对应的类，YYModel会自动递归解析
    return @{
        @"userInfo" : [UserModel class] // "userInfo"属性是UserModel类型
    };
}

@end
