//  vip_purchase_history_Model.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "VipPurchaseHistoryModel.h"

@implementation VipPurchaseHistoryModel

#pragma mark - IGListDiffable

- (id<NSObject>)diffIdentifier {
    // 用唯一主键作为diff标识
    return @(self.history_id);
}

- (BOOL)isEqualToDiffableObject:(nullable id<NSObject>)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[VipPurchaseHistoryModel class]]) return NO;
    
    VipPurchaseHistoryModel *model = (VipPurchaseHistoryModel *)object;
    
    // 比较所有属性是否相等
    if (self.history_id != model.history_id) return NO;
    if (![self.mch_orderid isEqualToString:model.mch_orderid]) return NO;
    if (![self.udid isEqualToString:model.udid]) return NO;
    if (!([self.idfv isEqualToString:model.idfv] || (self.idfv == nil && model.idfv == nil))) return NO;
    if (![self.packageId isEqualToString:model.packageId]) return NO;
    if (![self.vipDescription isEqualToString:model.vipDescription]) return NO;
    if (![self.packageTitle isEqualToString:model.packageTitle]) return NO;
    if (![self.price isEqualToString:model.price]) return NO;
    if (self.vipLevel != model.vipLevel) return NO;
    if (self.downloadsNumber != model.downloadsNumber) return NO;
    if (self.vipDay != model.vipDay) return NO;
    if (![self.purchaseTime isEqualToString:model.purchaseTime]) return NO;
    if (!([self.transactionId isEqualToString:model.transactionId] || (self.transactionId == nil && model.transactionId == nil))) return NO;
    if (self.status != model.status) return NO;
    
    return YES;
}

@end
