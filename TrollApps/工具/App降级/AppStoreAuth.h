//
//  AppStoreAuth.h
//  TrollApps
//
//  Created by 十三哥 on 2026/3/31.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface AppStoreAccount : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *passwordToken;
@property (nonatomic, copy) NSString *directoryServicesID;
@property (nonatomic, copy) NSString *storeFront;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *pod;
@end

@interface AppStoreAuth : NSObject

+ (instancetype)sharedInstance;

// 登录方法
- (void)loginWithEmail:(NSString *)email password:(NSString *)password completion:(void(^)(AppStoreAccount *account, NSError *error))completion;

// 获取当前登录账号信息
- (AppStoreAccount *)getCurrentAccount;

// 检查是否已登录
- (BOOL)isLoggedIn;

// 登出
- (void)logout;

@end


NS_ASSUME_NONNULL_END
