//
//  PaymentManager.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZFConfig.h"
NS_ASSUME_NONNULL_BEGIN



// 支付结果回调Block
typedef void(^PaymentCompletionBlock)(BOOL isSuccess, NSString *message, NSDictionary * _Nullable resultDict);

@interface PaymentManager : NSObject

// 单例实例
+ (instancetype)sharedManager;

// 配置参数（必填：从商户后台获取）
@property (nonatomic, copy) NSString *merchantId;   // 商户ID（pid）
@property (nonatomic, copy) NSString *merchantKey;  // 签名密钥


// 发起支付请求（跳转系统浏览器）
/// @param orderNo 商户订单号（唯一）
/// @param productName 商品名称
/// @param amount 商品金额（两位小数字符串，如@"1.00"）
/// @param paymentType 支付方式
/// @param notifyUrl 服务器异步通知地址（必填）
/// @param returnUrl 页面跳转通知地址（必填，需拼接APP Scheme，如 "appscheme://payment/return"）
/// @param siteName 网站名称（可选，可为nil）
/// @param completion 支付结果回调（需配合URL Scheme回调触发）
- (void)startPaymentWithOrderNo:(NSString *)orderNo
                    productName:(NSString *)productName
                        amount:(NSString *)amount
                    paymentType:(PaymentType)paymentType
                     notifyUrl:(NSString *)notifyUrl
                      returnUrl:(NSString *)returnUrl
                     siteName:(NSString *)siteName
                   completion:(PaymentCompletionBlock)completion;

// 取消支付（仅触发回调，浏览器操作需用户手动处理）
- (void)cancelPayment;

// 处理浏览器跳转回APP的URL（需在AppDelegate/SceneDelegate中调用）
- (BOOL)handleOpenURL:(NSURL *)url;

@end
NS_ASSUME_NONNULL_END
