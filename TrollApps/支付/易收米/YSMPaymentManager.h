//
//  YSMPaymentManager.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSMPayRequestModel.h"
#import "YSMPayResponseModel.h"
#import "VIPPackage.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^YSMPaymentCompleteBlock)(YSMPayResponseModel * _Nullable response, NSError * _Nullable error);


@interface YSMPaymentManager : NSObject

+ (instancetype)sharedManager;

// 生成唯一商户订单号（前缀+时间戳+随机数）
- (NSString *)generateOrderIdWithPrefix:(NSString *)prefix;

// 生成随机字符串（用于nonce_str）
- (NSString *)generateNonceStrWithLength:(NSInteger)length;

// 生成签名（按易收米文档规则：ASCII排序 + SHA256加密）
- (NSString *)generateSignWithParams:(NSDictionary *)params secret:(NSString *)secret;

// 发起支付请求（传入选中的套餐、支付方式、回调地址）
- (void)requestPaymentWithPackage:(VIPPackage *)package
                          payType:(YSMPayType)payType
                        notifyURL:(NSString *)notifyURL
                         nopayURL:(NSString *)nopayURL
                      callbackURL:(NSString *)callbackURL
                             udid:(NSString *)udid
                      mch_orderid:(NSString *)mch_orderid
                         complete:(YSMPaymentCompleteBlock)complete;

@end

NS_ASSUME_NONNULL_END
