//  vip_purchase_history_Model.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <IGListKit/IGListKit.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

/// 购买状态（0：失败，1：成功，2：退款，3 关闭，4 处理中）
typedef NS_ENUM(NSInteger, OrderStatusType) {
    /// 失败
    OrderStatusTypeFailure = 0,
    /// 成功
    OrderStatusTypeSuccess = 1,
    ///  退款
    OrderStatusTypeRefund = 2,
    ///  订单关闭
    OrderStatusTypeCLOSED = 3,
    ///  处理中。。。
    OrderStatusTypePROCESSING = 4
    
    
};
/// 购买状态（0：支付宝，1：QQ，2：微信，3 其他）
typedef NS_ENUM(NSInteger, PayType) {
    /// 支付宝
    PayTypeAliPay = 0,
    /// QQ
    PayTypeQQPay = 1,
    ///  微信
    PayTypeWXPay = 2,
    ///  其他
    PayTypeOtherPay = 3
    
    
    
};



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
/// 套餐介绍
@property (nonatomic, copy) NSString *vipDescription;
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
/// 购买状态（0：失败，1：成功，2：退款，3 关闭，4 处理中）
@property (nonatomic, assign) OrderStatusType status;
/// 支付类型（0：支付宝，1：QQ，2：微信，3 其他）
@property (nonatomic, assign) PayType payType;

// ✅ 新增属性（对应后端关联查询的字段）
@property (nonatomic, copy) NSString *nickname;  // 用户昵称
@property (nonatomic, assign) NSInteger user_id;// 用户ID（可选）


@end

NS_ASSUME_NONNULL_END
