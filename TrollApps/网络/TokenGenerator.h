//
//  TokenGenerator.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenGenerator : NSObject

// 预设常量
@property (nonatomic, strong, readonly) NSString *defaultSecretKey;
@property (nonatomic, assign, readonly) NSTimeInterval defaultExpireTime; // 秒

// 单例方法
+ (instancetype)sharedGenerator;

// 生成Token的方法
- (NSString *)generateTokenWithUDID:(NSString *)udid
                             timeout:(NSTimeInterval)timeout
                             secret:(NSString *)secret;

- (NSString *)generateTokenWithUDID:(NSString *)udid
                             secret:(NSString *)secret;

- (NSString *)generateTokenWithUDID:(NSString *)udid;

@end

NS_ASSUME_NONNULL_END
