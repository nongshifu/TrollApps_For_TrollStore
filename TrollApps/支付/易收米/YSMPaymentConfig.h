//
//  YSMPaymentConfig.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

// YSMPaymentConfig.h
#import <Foundation/Foundation.h>

// 易收米支付配置（需替换为你的签约信息）
static NSString *const YSM_APPID = @"YSM0ddb9a56";       // 易收米下发的通道ID
static NSString *const YSM_SECRET = @"378f1e199d561d101fc8156481a3e6ef";     // 易收米下发的密钥
static NSString *const YSM_PAY_URL = @"https://www.yishoumi.cn/u/payment"; // 支付接口URL

// 支付方式枚举（对应文档的payType）
typedef NS_ENUM(NSInteger, YSMPayType) {
    YSMPayTypeWechatInner = 1,    // 微信内支付
    YSMPayTypeWechatQRCode = 2,   // 微信扫码支付
    YSMPayTypeWechatH5 = 3,       // 微信H5支付
    YSMPayTypeAlipayH5 = 11       // 支付宝H5支付
};
