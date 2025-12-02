//
//  YSMPaymentManager.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "YSMPaymentManager.h"
#import <CommonCrypto/CommonCrypto.h>
#import "YSMPaymentConfig.h"
#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用
@implementation YSMPaymentManager

+ (instancetype)sharedManager {
    static YSMPaymentManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}


#pragma mark - 生成随机字符串
- (NSString *)generateNonceStrWithLength:(NSInteger)length {
    if (length < 6) length = 6; // 最小6位（符合文档要求）
    if (length > 32) length = 32; // 最大32位（符合文档要求）
    
    NSString *chars = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-*";
    NSMutableString *nonceStr = [NSMutableString stringWithCapacity:length];
    
    for (NSInteger i = 0; i < length; i++) {
        NSInteger randomIndex = arc4random_uniform((uint32_t)chars.length);
        [nonceStr appendFormat:@"%C", [chars characterAtIndex:randomIndex]];
    }
    
    return nonceStr;
}
#pragma mark - 生成签名（核心逻辑）

- (NSString *)generateSignWithParams:(NSDictionary *)params secret:(NSString *)secret {
    if (!params || params.count == 0 || !secret || secret.length == 0) return @"";
    
    // 1. 按参数名ASCII码从小到大排序（字典序）
    NSLog(@"按参数名ASCII码从小到大排序（字典序）");
    NSArray *sortedKeys = [params.allKeys sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
    
    // 2. 拼接stringA（key1=value1&key2=value2...）：跳过空值和sign参数
    NSLog(@"拼接stringA（key1=value1&key2=value2...）：跳过空值和sign参数");
    NSMutableString *stringA = [NSMutableString string];
    for (NSString *key in sortedKeys) {
        id value = params[key];
        NSLog(@"遍历key：%@，value：%@，value类型：%@", key, value, [value class]);
        
        // 跳过空值、NSNull、sign参数
        if (!value || [value isEqual:[NSNull null]] || [key isEqualToString:@"sign"]) {
            NSLog(@"跳过key：%@（空值/NSNull/sign参数）", key);
            continue;
        }
        
        // 针对不同类型做空值校验
        BOOL isEmptyValue = NO;
        if ([value isKindOfClass:[NSString class]]) {
            // 字符串类型：判断是否为空字符串
            isEmptyValue = [((NSString *)value) isEqualToString:@""];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            // 数值类型：判断是否为0（根据易收米文档，数值参数如total/payType不能为0）
            isEmptyValue = [((NSNumber *)value) isEqualToNumber:@0];
        } else {
            // 其他类型（如NSArray/NSDictionary）：直接视为非空（根据易收米文档，参数应为基础类型）
            isEmptyValue = NO;
        }
        
        if (isEmptyValue) {
            NSLog(@"跳过key：%@（值为空）", key);
            continue;
        }
        
        if (stringA.length > 0) {
            [stringA appendString:@"&"];
        }
        
        // 数值类型转字符串（避免NSNumber类型直接拼接）
        if ([value isKindOfClass:[NSNumber class]]) {
            [stringA appendFormat:@"%@=%@", key, [value stringValue]];
        } else {
            [stringA appendFormat:@"%@=%@", key, value];
        }
    }
    
    // 3. 拼接secret生成stringSignTemp
    NSString *stringSignTemp = [stringA stringByAppendingString:secret];
    NSLog(@"【易收米支付】签名原始字符串：%@", stringSignTemp);
    
    // 4. SHA256加密（64位小写）
    const char *cStr = [stringSignTemp UTF8String];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *sign = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [sign appendFormat:@"%02x", digest[i]];
    }
    
    NSLog(@"【易收米支付】生成签名：%@", sign);
    return sign;
}

#pragma mark - 发起支付请求
- (void)requestPaymentWithPackage:(VIPPackage *)package
                          payType:(YSMPayType)payType
                        notifyURL:(NSString *)notifyURL
                         nopayURL:(NSString *)nopayURL
                      callbackURL:(NSString *)callbackURL
                             udid:(NSString *)udid
                      mch_orderid:(NSString *)mch_orderid
                         complete:(YSMPaymentCompleteBlock)complete {
    // 前置参数校验
    NSLog(@"前置参数校验");
    if (!package || !notifyURL || notifyURL.length == 0 || !nopayURL || nopayURL.length == 0 || !callbackURL || callbackURL.length == 0 || udid.length == 0) {
        NSError *error = [NSError errorWithDomain:@"YSMPayment" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"支付参数不完整（套餐/回调地址/udid不能为空）"}];
        if (complete) complete(nil, error);
        return;
    }
    
    if (package.price <= 0) {
        NSError *error = [NSError errorWithDomain:@"YSMPayment" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"套餐价格无效"}];
        if (complete) complete(nil, error);
        return;
    }
    
    // 1. 构建支付请求模型
    YSMPayRequestModel *requestModel = [[YSMPayRequestModel alloc] init];
    requestModel.appid = YSM_APPID;
    requestModel.mch_orderid = mch_orderid; // 订单号前缀：VIP
    requestModel.goodsDesc = package.title; // 商品描述=套餐标题（如"永久VIP会员"）
    requestModel.total = package.price * 100; // 金额转分（1元=100分）
    requestModel.payType = payType;
    requestModel.notify_url = notifyURL; // 后端通知接口（公网可访问）
    requestModel.nopay_url = nopayURL;   // 未支付跳转页（如套餐选择页）
    requestModel.callback_url = callbackURL; // 支付成功跳转页（如会员中心）
    requestModel.time = (NSInteger)[[NSDate date] timeIntervalSince1970]; // 10位时间戳
    requestModel.nonce_str = [self generateNonceStrWithLength:16]; // 16位随机数
    requestModel.attach = package.packageId; // 附加数据：存储套餐ID（后端可解析）
    NSLog(@"构建支付请求模型");
    // 2. 生成签名
    NSDictionary *paramDict = [requestModel toParamDictionary];
    requestModel.sign = [self generateSignWithParams:paramDict secret:YSM_SECRET];
    NSLog(@"构建支付请求模型签名:%@",requestModel.sign);
    // 3. 构建最终请求参数（包含sign）
    NSMutableDictionary *finalParams = [paramDict mutableCopy];
    finalParams[@"sign"] = requestModel.sign;
    
    // 4. 配置网络请求
    NSURL *url = [NSURL URLWithString:YSM_PAY_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30; // 超时时间30秒
    [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // 5. 序列化参数为JSON数据
    NSError *serializeError = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:finalParams options:0 error:&serializeError];
    if (serializeError) {
        NSLog(@"【易收米支付】参数序列化失败：%@", serializeError.localizedDescription);
        if (complete) complete(nil, serializeError);
        return;
    }
    request.HTTPBody = requestData;
    NSLog(@"【易收米支付】请求参数：%@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);
    
    // 6. 发送网络请求（NSURLSession异步请求）
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"【易收米支付】请求失败：%@", error.localizedDescription);
                if (complete) complete(nil, error);
                return;
            }
            
            NSError *jsonError;
            // 7. 解析返回结果
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                NSLog(@"【易收米支付】结果解析失败：%@", error.localizedDescription);
                if (complete) complete(nil, jsonError);
                return;
            }
            NSLog(@"【易收米支付】返回结果：%@", responseDict);
            
            // 8. 转为模型并回调
            YSMPayResponseModel *responseModel = [YSMPayResponseModel modelWithJSONDictionary:responseDict];
            if (complete) complete(responseModel, nil);
        });
    }] resume];
}

@end
