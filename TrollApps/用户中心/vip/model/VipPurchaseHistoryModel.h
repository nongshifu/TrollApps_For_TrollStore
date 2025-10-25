//  vip_purchase_history_Model.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VipPurchaseHistoryModel : NSObject <IGListDiffable>

/// 记录ID（自增主键）
@property (nonatomic, assign) NSInteger history_id;
/// 订单ID
@property (nonatomic, copy) NSString *mch_orderid;
/// 用户设备唯一标识（UDID）
@property (nonatomic, copy) NSString *udid;
/// 用户设备标识符（IDFV，可选，用于辅助查询）
@property (nonatomic, copy, nullable) NSString *idfv;
/// 套餐ID（如pkg1、pkg2）
@property (nonatomic, copy) NSString *packageId;
/// 套餐名称（如"1个月VIP会员"）
@property (nonatomic, copy) NSString *packageTitle;
/// 套餐价格（如"¥68"）
@property (nonatomic, copy) NSString *price;
/// VIP等级（1-5）
@property (nonatomic, assign) NSInteger vipLevel;
/// 购买的安装次数（0表示无限）
@property (nonatomic, assign) NSInteger downloadsNumber;
/// 购买的VIP天数（0表示永久）
@property (nonatomic, assign) NSInteger vipDay;
/// 购买时间
@property (nonatomic, copy) NSString *purchaseTime;
/// 支付平台交易ID（如苹果内购订单号，可选）
@property (nonatomic, copy, nullable) NSString *transactionId;
/// 购买状态（1：成功，0：失败，2：退款）
@property (nonatomic, assign) NSInteger status;

@end

NS_ASSUME_NONNULL_END
