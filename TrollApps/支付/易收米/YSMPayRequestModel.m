//
//  YSMPayRequestModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "YSMPayRequestModel.h"

@implementation YSMPayRequestModel 
#pragma mark - IGListDiffable
- (nonnull id<NSObject>)diffIdentifier {
    // 用订单号作为唯一标识（确保列表刷新时能正确 diff）
    return self.mch_orderid ?: [NSUUID UUID].UUIDString;
}

- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[YSMPayRequestModel class]]) return NO;
    
    YSMPayRequestModel *other = (YSMPayRequestModel *)object;
    return [self.appid isEqualToString:other.appid] &&
           [self.mch_orderid isEqualToString:other.mch_orderid] &&
           [self.goodsDesc isEqualToString:other.goodsDesc] &&
           self.total == other.total &&
           self.payType == other.payType &&
           [self.notify_url isEqualToString:other.notify_url] &&
           [self.nopay_url isEqualToString:other.nopay_url] &&
           [self.callback_url isEqualToString:other.callback_url] &&
           self.time == other.time &&
           [self.nonce_str isEqualToString:other.nonce_str] &&
           [self.sign isEqualToString:other.sign] &&
           [self.attach isEqualToString:other.attach];
}

#pragma mark - 转为参数字典
- (NSDictionary *)toParamDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // 只添加非空参数（符合签名规则）
    if (self.appid) dict[@"appid"] = self.appid;
    if (self.mch_orderid) dict[@"mch_orderid"] = self.mch_orderid;
    if (self.goodsDesc) dict[@"description"] = self.goodsDesc; // 接口要求参数名是description，这里映射
    if (self.total > 0) dict[@"total"] = @(self.total);
    dict[@"payType"] = @(self.payType);
    if (self.notify_url) dict[@"notify_url"] = self.notify_url;
    if (self.nopay_url) dict[@"nopay_url"] = self.nopay_url;
    if (self.callback_url) dict[@"callback_url"] = self.callback_url;
    if (self.time > 0) dict[@"time"] = @(self.time);
    if (self.nonce_str) dict[@"nonce_str"] = self.nonce_str;
    if (self.attach) dict[@"attach"] = self.attach;
    
    return dict;
}
@end
