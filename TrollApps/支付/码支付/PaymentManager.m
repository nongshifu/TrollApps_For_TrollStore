#import "PaymentManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#import "MZFConfig.h"

#pragma mark - 私有属性（通过延展声明）
@interface PaymentManager ()
@property (nonatomic, copy) PaymentCompletionBlock completionBlock;
@property (nonatomic, copy) NSString *currentReturnUrl; // 保存当前支付的return_url
@end



static PaymentManager *_sharedManager = nil;

@implementation PaymentManager

#pragma mark - 单例初始化
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _completionBlock = nil;
        _currentReturnUrl = nil;
        _merchantId = MZF_merchantId;
        _merchantKey = MZF_merchantKey;
    }
    return self;
}

#pragma mark - 发起支付核心方法（跳转浏览器）
- (void)startPaymentWithOrderNo:(NSString *)orderNo
                    productName:(NSString *)productName
                         amount:(NSString *)amount
                    paymentType:(PaymentType)paymentType
                      notifyUrl:(NSString *)notifyUrl
                      returnUrl:(NSString *)returnUrl
                       siteName:(NSString *)siteName
                     completion:(PaymentCompletionBlock)completion {
    self.completionBlock = completion;
    self.currentReturnUrl = [NSString stringWithFormat:@"%@?mch_orderid=%@",returnUrl,orderNo]; // 保存当前支付的return_url，用于后续校验
    // 1. 验证必填参数（新增 URL Scheme 验证）
    if (![self validateParamsWithOrderNo:orderNo
                             productName:productName
                                  amount:amount
                               notifyUrl:notifyUrl
                               returnUrl:returnUrl
                              completion:completion]) {
        return;
    }
    
    // 2. 保存回调和关键参数
    
    // 3. 构建请求参数字典
    NSMutableDictionary *paramsDict = [self buildParamsDictWithOrderNo:orderNo
                                                           productName:productName
                                                                amount:amount
                                                           paymentType:paymentType
                                                             notifyUrl:notifyUrl
                                                             returnUrl:returnUrl
                                                              siteName:siteName];
    
    // 4. 生成签名（保持与官方PHP一致的逻辑）
    NSString *sign = [self generateSignWithParams:paramsDict];
    [paramsDict setObject:sign forKey:@"sign"];
    [paramsDict setObject:@"MD5" forKey:@"sign_type"]; // 补充sign_type参数
    
    // 5. 生成支付GET链接（浏览器跳转用GET请求）
    NSString *paymentUrlString = [self buildPaymentUrlWithParams:paramsDict];
    if (!paymentUrlString.length) {
        if (completion) completion(NO, @"支付链接生成失败", nil);
        return;
    }
    
    NSURL *paymentUrl = [NSURL URLWithString:paymentUrlString];
    if (!paymentUrl) {
        if (completion) completion(NO, @"支付链接格式错误", nil);
        return;
    }
    
    // 6. 调用系统浏览器打开链接（iOS 10+ 推荐用 openURL:options:completionHandler:）
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:paymentUrl
                                           options:@{}
                                 completionHandler:^(BOOL success) {
            if (!success) {
                if (self.completionBlock) {
                    self.completionBlock(NO, @"打开浏览器失败，请检查浏览器是否可用", nil);
                    self.completionBlock = nil;
                }
            } else {
                // 打开浏览器成功，回调暂不触发，等待用户支付完成后跳转回APP
                NSLog(@"已跳转浏览器支付，等待回调...");
            }
        }];
    } else {
        // iOS 10 以下兼容
        BOOL success = [[UIApplication sharedApplication] openURL:paymentUrl];
        if (!success) {
            if (completion) completion(NO, @"打开浏览器失败，请检查浏览器是否可用", nil);
        }
    }
}

#pragma mark - 参数验证（新增 URL Scheme 验证）
- (BOOL)validateParamsWithOrderNo:(NSString *)orderNo
                      productName:(NSString *)productName
                           amount:(NSString *)amount
                        notifyUrl:(NSString *)notifyUrl
                        returnUrl:(NSString *)returnUrl
                       completion:(PaymentCompletionBlock)completion {
    if (!self.merchantId.length) {
        completion(NO, @"商户ID（merchantId）未配置", nil);
        return NO;
    }
    if (!self.merchantKey.length) {
        completion(NO, @"签名密钥（merchantKey）未配置", nil);
        return NO;
    }
    
    if (!orderNo.length) {
        completion(NO, @"商户订单号不能为空", nil);
        return NO;
    }
    if (!productName.length) {
        completion(NO, @"商品名称不能为空", nil);
        return NO;
    }
    if (!amount.length) {
        completion(NO, @"商品金额不能为空", nil);
        return NO;
    }
    // 验证金额格式（两位小数）
    NSString *regex = @"^\\d+\\.\\d{2}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if (![predicate evaluateWithObject:amount]) {
        completion(NO, @"金额格式错误（需两位小数，如1.00）", nil);
        return NO;
    }
    if (!notifyUrl.length) {
        completion(NO, @"异步通知地址不能为空", nil);
        return NO;
    }
    if (!returnUrl.length) {
        completion(NO, @"跳转通知地址不能为空", nil);
        return NO;
    }
    // 验证 return_url 包含 APP Scheme（确保能跳转回APP）
    if (![returnUrl hasPrefix:@"trollapps"]) {
        completion(NO, @"return_url 必须以配置的 APP Scheme 开头", nil);
        return NO;
    }
    return YES;
}

#pragma mark - 构建参数字典（与原逻辑一致）
- (NSMutableDictionary *)buildParamsDictWithOrderNo:(NSString *)orderNo
                                        productName:(NSString *)productName
                                             amount:(NSString *)amount
                                        paymentType:(PaymentType)paymentType
                                          notifyUrl:(NSString *)notifyUrl
                                          returnUrl:(NSString *)returnUrl
                                           siteName:(NSString *)siteName {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"pid"] = self.merchantId;
    dict[@"type"] = [self paymentTypeToString:paymentType];
    dict[@"out_trade_no"] = orderNo;
    dict[@"notify_url"] = notifyUrl;
    dict[@"return_url"] = returnUrl;
    dict[@"name"] = productName;
    dict[@"money"] = amount;
    // 网站名称可选（非空才添加）
    if (siteName.length > 0) {
        dict[@"sitename"] = siteName;
    }
    return dict;
}

#pragma mark - 支付方式转字符串（与原逻辑一致）
- (NSString *)paymentTypeToString:(PaymentType)type {
    switch (type) {
        case PaymentTypeAlipay: return @"alipay";
        case PaymentTypeQQPay: return @"qqpay";
        case PaymentTypeWeChatPay: return @"wxpay";
        default: return @"alipay";
    }
}

#pragma mark - 生成MD5签名（与原逻辑一致，保持和PHP对齐）
- (NSString *)generateSignWithParams:(NSMutableDictionary *)params {
    // 1. 过滤参数：排除 sign、sign_type，且值不为空
    NSMutableDictionary *validParams = [NSMutableDictionary dictionary];
    for (NSString *key in params.allKeys) {
        id value = params[key];
        if ([key isEqualToString:@"sign"] || [key isEqualToString:@"sign_type"]) {
            continue;
        }
        if (value && ![value isEqual:[NSNull null]] && ![value isEqualToString:@""]) {
            [validParams setObject:value forKey:key];
        }
    }
    
    // 2. 按参数名ASCII升序排序
    NSArray *sortedKeys = [validParams.allKeys sortedArrayUsingSelector:@selector(compare:)];
    
    // 3. 拼接成 key=value&key=value 格式
    NSMutableString *signSource = [NSMutableString string];
    for (NSString *key in sortedKeys) {
        NSString *value = [validParams[key] description];
        [signSource appendFormat:@"%@=%@&", key, value];
    }
    
    // 4. 移除末尾多余的 &
    if (signSource.length > 0) {
        [signSource deleteCharactersInRange:NSMakeRange(signSource.length - 1, 1)];
    }
    
    // 5. 拼接商户密钥
    [signSource appendString:self.merchantKey];
    
    // 6. MD5加密（返回小写，与PHP一致）
    return [self md5Encrypt:signSource];
}

#pragma mark - MD5加密工具（与原逻辑一致）
- (NSString *)md5Encrypt:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return result;
}

#pragma mark - 生成支付GET链接（核心：拼接参数为URL字符串）
- (NSString *)buildPaymentUrlWithParams:(NSDictionary *)params {
    if (!params || params.count == 0) return nil;
    NSString *url = [NSString stringWithFormat:@"%@?",MZF_PAY_URL];
    NSMutableString *urlString = [NSMutableString stringWithString:url];
    
    // 拼接参数（key=value&key=value，所有值需URL编码）
    for (NSString *key in params.allKeys) {
        id value = params[key];
        if (value && ![value isEqual:[NSNull null]] && ![value isEqualToString:@""]) {
            NSString *encodedKey = [self urlEncode:key];
            NSString *encodedValue = [self urlEncode:value];
            [urlString appendFormat:@"%@=%@&", encodedKey, encodedValue];
        }
    }
    
    // 移除最后一个 &
    if (urlString.length > 0 && [urlString hasSuffix:@"&"]) {
        [urlString deleteCharactersInRange:NSMakeRange(urlString.length - 1, 1)];
    }
    
    return urlString;
}

#pragma mark - URL编码工具（优化：适配特殊字符）
- (NSString *)urlEncode:(id)value {
    NSString *string = [value description];
    // 替换 URLQueryAllowedCharacterSet 中缺失的字符（如 +、& 等）
    NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedSet];
}

#pragma mark - 处理浏览器跳转回APP的URL（核心回调方法）
- (BOOL)handleOpenURL:(NSURL *)url {
    if (!url || !url.absoluteString.length) return NO;
    
    // 验证是否是当前支付的 return_url 回调
    if (![url.absoluteString hasPrefix:self.currentReturnUrl]) {
        return NO;
    }
    
    // 解析URL中的支付结果参数（如订单号、支付状态等）
    NSDictionary *resultDict = [self parseURLQuery:url.absoluteString];
    
    // 触发回调（注意：实际支付结果需以服务器异步通知为准）
    if (self.completionBlock) {
        // 这里根据 resultDict 中的状态判断（不同接口参数可能不同，需根据官方文档调整）
        NSString *status = resultDict[@"status"]; // 假设 status=1 为成功（以实际接口为准）
        if ([status isEqualToString:@"1"] || [url.absoluteString containsString:@"success"]) {
            self.completionBlock(YES, @"支付流程完成（待服务器确认）", resultDict);
        } else {
            self.completionBlock(NO, [NSString stringWithFormat:@"支付失败：%@", resultDict[@"msg"] ?: @"未知错误"], resultDict);
        }
        self.completionBlock = nil;
    }
    
    // 重置当前 return_url
    self.currentReturnUrl = nil;
    return YES;
}

#pragma mark - 解析URL参数（与原逻辑一致）
- (NSDictionary *)parseURLQuery:(NSString *)urlString {
    NSMutableDictionary *paramsDict = [NSMutableDictionary dictionary];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *query = url.query;
    if (!query) return paramsDict;
    
    NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
    for (NSString *component in queryComponents) {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            NSString *key = [keyValue[0] stringByRemovingPercentEncoding];
            NSString *value = [keyValue[1] stringByRemovingPercentEncoding];
            if (key && value) {
                paramsDict[key] = value;
            }
        }
    }
    return paramsDict;
}

#pragma mark - 取消支付（适配浏览器场景）
- (void)cancelPayment {
    if (self.completionBlock) {
        self.completionBlock(NO, @"用户取消支付", nil);
        self.completionBlock = nil;
    }
    self.currentReturnUrl = nil;
    
    // 提示用户：浏览器中的支付流程需手动关闭
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:@"已取消支付，请关闭浏览器返回APP"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *topVC = [self getTopViewController];
    [topVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 获取顶层控制器（保留，用于弹框提示）
- (UIViewController *)getTopViewController {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}


#pragma mark - 内存管理
- (void)dealloc {
    self.completionBlock = nil;
    self.currentReturnUrl = nil;
}
@end
