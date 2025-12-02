//
//  YSMPayRequestModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>
#import "YSMPaymentConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSMPayRequestModel : NSObject <IGListDiffable>

@property (nonatomic, copy) NSString *appid;          // 通道ID（YSM_APPID）
@property (nonatomic, copy) NSString *mch_orderid;    // 商户订单号（唯一）
@property (nonatomic, copy) NSString *goodsDesc;      // 商品描述（替换原description，避免冲突）
@property (nonatomic, assign) NSInteger total;        // 订单金额（单位：分）
@property (nonatomic, assign) YSMPayType payType;     // 支付方式（YSMPayType枚举）
@property (nonatomic, copy) NSString *notify_url;     // 支付成功通知地址（后端接口，公网可访问）
@property (nonatomic, copy) NSString *nopay_url;      // 未支付回调地址（前端页面URL）
@property (nonatomic, copy) NSString *callback_url;   // 支付成功跳转地址（前端页面URL）
@property (nonatomic, assign) NSInteger time;         // 10位时间戳（避免缓存）
@property (nonatomic, copy) NSString *nonce_str;      // 随机字符串（6-32位，避免缓存）
@property (nonatomic, copy) NSString *sign;           // 签名（必填）
@property (nonatomic, copy) NSString *attach;         // 附加数据（可选，可存packageId）

// 转为参数字典（用于生成签名）
- (NSDictionary *)toParamDictionary;

@end


NS_ASSUME_NONNULL_END
