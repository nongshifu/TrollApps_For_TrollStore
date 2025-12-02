//
//  YSMPayResponseModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "YSMPayResponseModel.h"

@implementation YSMPayResponseModel
#pragma mark - IGListDiffable
- (nonnull id<NSObject>)diffIdentifier {
    // 用订单号作为唯一标识（无订单号时用状态码+提示信息）
    return self.ordeid ?: [NSString stringWithFormat:@"%ld_%@", self.code, self.msg];
}

- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[YSMPayResponseModel class]]) return NO;
    
    YSMPayResponseModel *other = (YSMPayResponseModel *)object;
    return self.code == other.code &&
           [self.msg isEqualToString:other.msg] &&
           [self.ordeid isEqualToString:other.ordeid] &&
           [self.sign isEqualToString:other.sign] &&
           [self.url isEqualToString:other.url];
}

#pragma mark - JSON转模型
+ (instancetype)modelWithJSONDictionary:(NSDictionary *)dict {
    if (!dict || dict.count == 0) return nil;
    
    YSMPayResponseModel *model = [[self alloc] init];
    model.code = [dict[@"code"] integerValue];
    model.msg = dict[@"msg"] ?: @"";
    model.ordeid = dict[@"ordeid"] ?: @"";
    model.sign = dict[@"sign"] ?: @"";
    model.url = dict[@"url"] ?: @"";
    
    return model;
}

@end
