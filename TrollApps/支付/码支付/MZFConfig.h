//
//  MZFConfig.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#ifndef MZFConfig_h
#define MZFConfig_h


#endif /* MZFConfig_h */

// 易收米支付配置（需替换为你的签约信息）
static NSString *const MZF_merchantId = @"3949";       // 商户ID
static NSString *const MZF_merchantKey = @"n0WUP9rxPnEFu5x21n9jlqXLSR7OyHeq";     // 商户秘钥KEY
static NSString *const MZF_PAY_URL = @"https://code.akwl.net/submit.php"; // 支付接口URL

// 支付方式枚举（对应接口的 type 参数）
typedef NS_ENUM(NSInteger, PaymentType) {
    PaymentTypeAlipay = 0,    // 支付宝
    PaymentTypeQQPay = 1,         // QQ钱包
    PaymentTypeWeChatPay = 2      // 微信支付
};
