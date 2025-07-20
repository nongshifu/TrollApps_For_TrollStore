//
//  AppComment.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/1.
//

#import "CommentModel.h"

@implementation CommentModel

#pragma mark - IGListDiffable

- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[CommentModel class]]) return NO;
    return [self isEqual:object];
}

- (id<NSObject>)diffIdentifier {
    return [NSString stringWithFormat:@"%ld-%@-%@", (long)self.comment_id, self.content, self.create_time];;
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[CommentModel class]]) return NO;
    CommentModel *other = (CommentModel *)object;
    return self.comment_id == other.comment_id &&
           [self.content isEqualToString:other.content] &&
           [self.user_udid isEqualToString:other.user_udid] &&
           [self.idfv isEqualToString:other.idfv] &&
           self.userInfo == other.userInfo &&
           self.like_count == other.like_count &&
           self.isLiked == other.isLiked &&
           self.status == other.status &&
           self.action_type == other.action_type &&
    
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
