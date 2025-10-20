// TokenGenerator.m
#import "TokenGenerator.h"
#import <CommonCrypto/CommonCrypto.h>
//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}
@implementation TokenGenerator

#pragma mark - Lifecycle

+ (instancetype)sharedGenerator {
    static TokenGenerator *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 与PHP端保持一致的预设值
        _defaultSecretKey = @"a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q";
        _defaultExpireTime = 1800; // 30分钟
    }
    return self;
}

#pragma mark - Token Generation

- (NSString *)generateTokenWithUDID:(NSString *)udid
                             timeout:(NSTimeInterval)timeout
                             secret:(NSString *)secret {
    // 验证参数
    if (udid.length == 0) {
        NSLog(@"Error: UDID不能为空");
        return nil;
    }
    
    if (secret.length == 0) {
        NSLog(@"Error: 密钥不能为空");
        return nil;
    }
    
    // 获取当前时间戳（毫秒级）
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    // 生成随机数（防碰撞）
    uint32_t random = arc4random_uniform(1000000);
    
    // 生成签名
    NSString *signature = [self generateSignatureWithUDID:udid
                                                 timestamp:timestamp
                                                   random:random
                                                    secret:secret];
    
    // 组合Token（格式：timestamp_random_signature）
    return [NSString stringWithFormat:@"%.0f_%u_%@", timestamp, random, signature];
}

- (NSString *)generateTokenWithUDID:(NSString *)udid
                             secret:(NSString *)secret {
    return [self generateTokenWithUDID:udid
                               timeout:self.defaultExpireTime
                               secret:secret];
}

- (NSString *)generateTokenWithUDID:(NSString *)udid {
    return [self generateTokenWithUDID:udid
                               timeout:self.defaultExpireTime
                               secret:self.defaultSecretKey];
}

#pragma mark - Signature Generation

- (NSString *)generateSignatureWithUDID:(NSString *)udid
                              timestamp:(NSTimeInterval)timestamp
                                random:(uint32_t)random
                                 secret:(NSString *)secret {
    // 构建签名数据（与PHP端保持一致）
    NSString *data = [NSString stringWithFormat:@"udid=%@&timestamp=%.0f&random=%u&key=%@",
                     udid, timestamp, random, secret];
    NSLog(@"签名之前:%@", data);
    
    // 计算SHA-256哈希
    const char *str = [data UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), result);
    
    // 转换为十六进制字符串
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", result[i]];
    }
    
    return hash;
}

@end
