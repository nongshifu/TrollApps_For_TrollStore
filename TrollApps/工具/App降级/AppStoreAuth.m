//
//  AppStoreAuth.m
//  TrollApps
//
//  Created by 十三哥 on 2026/3/31.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "AppStoreAuth.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#undef MY_NSLog_ENABLED
#define MY_NSLog_ENABLED YES

@interface AppStoreAuth ()
@property (nonatomic, strong) AppStoreAccount *currentAccount;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation AppStoreAuth

+ (instancetype)sharedInstance {
    static AppStoreAuth *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppStoreAuth alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.session = [NSURLSession sharedSession];
        [self loadAccountFromKeychain];
    }
    return self;
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)password completion:(void(^)(AppStoreAccount *account, NSError *error))completion {
    // 首先获取 bag 以获取认证端点
    [self getBagEndpoint:^(NSString *authEndpoint, NSError *error) {
        if (error || !authEndpoint) {
            completion(nil, error ?: [NSError errorWithDomain:@"AppStoreAuth" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"获取认证端点失败"}]);
            return;
        }
        
        // 获取设备 GUID
        NSString *guid = [self getDeviceGUID];
        if (!guid) {
            completion(nil, [NSError errorWithDomain:@"AppStoreAuth" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"获取设备 GUID 失败"}]);
            return;
        }
        
        // 执行登录请求
        [self performLoginWithEmail:email password:password authCode:@"" guid:guid endpoint:authEndpoint attempt:1 completion:completion];
    }];
}

- (void)getBagEndpoint:(void(^)(NSString *authEndpoint, NSError *error))completion {
    NSString *guid = [self getDeviceGUID];
    if (!guid) {
        completion(nil, [NSError errorWithDomain:@"AppStoreAuth" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"获取设备 GUID 失败"}]);
        return;
    }
    
    // 尝试多个不同的 bag.xml URL，因为 Apple 可能会更改端点
    NSArray *bagUrls = @[
        [NSString stringWithFormat:@"https://init.itunes.apple.com/bag.xml?guid=%@", guid],
        [NSString stringWithFormat:@"https://init.apple.com/bag.xml?guid=%@", guid],
        [NSString stringWithFormat:@"https://apple.com/bag.xml?guid=%@", guid]
    ];
    
    [self tryBagUrls:bagUrls index:0 completion:completion];
}

- (void)tryBagUrls:(NSArray *)urls index:(NSInteger)index completion:(void(^)(NSString *authEndpoint, NSError *error))completion {
    if (index >= urls.count) {
        // 如果所有 URL 都失败，使用默认的认证端点
        NSString *defaultEndpoint = @"https://idmsa.apple.com/authenticate";
        NSLog(@"所有 bag.xml 请求失败，使用默认认证端点: %@", defaultEndpoint);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(defaultEndpoint, nil);
        });
        return;
    }
    
    NSString *urlString = urls[index];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1" forHTTPHeaderField:@"User-Agent"];
    
    NSLog(@"尝试获取 bag.xml: %@", urlString);
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"获取 bag.xml 失败: %@", error.localizedDescription);
            // 尝试下一个 URL
            [self tryBagUrls:urls index:index + 1 completion:completion];
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"获取 bag.xml 成功，状态码: %ld", (long)httpResponse.statusCode);
        
        // 解析 XML 响应
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"bag.xml 响应长度: %ld", (long)responseString.length);
        
        // 打印部分响应内容用于调试
        if (responseString.length > 1000) {
            NSString *partialResponse = [responseString substringToIndex:1000];
            NSLog(@"bag.xml 部分响应: %@", partialResponse);
        }
        
        NSString *authEndpoint = [self parseBagResponse:responseString];
        if (authEndpoint) {
            NSLog(@"找到认证端点: %@", authEndpoint);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(authEndpoint, nil);
            });
        } else {
            NSLog(@"未找到认证端点，尝试下一个 URL");
            // 尝试下一个 URL
            [self tryBagUrls:urls index:index + 1 completion:completion];
        }
    }];
    [task resume];
}

- (void)performLoginWithEmail:(NSString *)email password:(NSString *)password authCode:(NSString *)authCode guid:(NSString *)guid endpoint:(NSString *)endpoint attempt:(NSInteger)attempt completion:(void(^)(AppStoreAccount *account, NSError *error))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // 构建请求体
    NSString *passwordWithAuthCode = [NSString stringWithFormat:@"%@%@", password, [authCode stringByReplacingOccurrencesOfString:@" " withString:@""]];
    NSString *bodyString = [NSString stringWithFormat:@"appleId=%@&attempt=%ld&guid=%@&password=%@&rmp=0&why=signIn",
                           [self urlEncode:email], (long)attempt, guid, [self urlEncode:passwordWithAuthCode]];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // 处理重定向
        if (httpResponse.statusCode == 302) {
            NSString *redirectURL = httpResponse.allHeaderFields[@"Location"];
            if (redirectURL && attempt < 4) {
                [self performLoginWithEmail:email password:password authCode:authCode guid:guid endpoint:redirectURL attempt:attempt + 1 completion:completion];
                return;
            }
        }
        
        // 解析响应
        if (data) {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            AppStoreAccount *account = [self parseLoginResponse:responseString headers:httpResponse.allHeaderFields password:password];
            if (account) {
                self.currentAccount = account;
                [self saveAccountToKeychain];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(account, nil);
                });
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, [NSError errorWithDomain:@"AppStoreAuth" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"登录失败"}]);
        });
    }];
    [task resume];
}

- (AppStoreAccount *)parseLoginResponse:(NSString *)responseString headers:(NSDictionary *)headers password:(NSString *)password {
    // 解析 XML 响应，提取账户信息
    // 这里使用简单的字符串解析，实际项目中应该使用 XML 解析器
    AppStoreAccount *account = [[AppStoreAccount alloc] init];
    account.password = password;
    
    // 提取 storeFront
    account.storeFront = headers[@"X-Set-Apple-Store-Front"];
    
    // 提取 pod
    account.pod = headers[@"pod"];
    
    // 提取 accountInfo
    NSRange accountInfoRange = [responseString rangeOfString:@"<accountInfo>"];
    if (accountInfoRange.location != NSNotFound) {
        NSRange endRange = [responseString rangeOfString:@"</accountInfo>" options:NSCaseInsensitiveSearch range:NSMakeRange(accountInfoRange.location, responseString.length - accountInfoRange.location)];
        if (endRange.location != NSNotFound) {
            NSString *accountInfo = [responseString substringWithRange:NSMakeRange(accountInfoRange.location, endRange.location + endRange.length - accountInfoRange.location)];
            
            // 提取 appleId
            NSRange appleIdRange = [accountInfo rangeOfString:@"<appleId>"];
            if (appleIdRange.location != NSNotFound) {
                NSRange appleIdEndRange = [accountInfo rangeOfString:@"</appleId>" options:NSCaseInsensitiveSearch range:NSMakeRange(appleIdRange.location, accountInfo.length - appleIdRange.location)];
                if (appleIdEndRange.location != NSNotFound) {
                    account.email = [accountInfo substringWithRange:NSMakeRange(appleIdRange.location + 8, appleIdEndRange.location - (appleIdRange.location + 8))];
                }
            }
            
            // 提取 address
            NSRange addressRange = [accountInfo rangeOfString:@"<address>"];
            if (addressRange.location != NSNotFound) {
                NSRange addressEndRange = [accountInfo rangeOfString:@"</address>" options:NSCaseInsensitiveSearch range:NSMakeRange(addressRange.location, accountInfo.length - addressRange.location)];
                if (addressEndRange.location != NSNotFound) {
                    NSString *address = [accountInfo substringWithRange:NSMakeRange(addressRange.location, addressEndRange.location + addressEndRange.length - addressRange.location)];
                    
                    // 提取 firstName
                    NSRange firstNameRange = [address rangeOfString:@"<firstName>"];
                    NSString *firstName = @"";
                    if (firstNameRange.location != NSNotFound) {
                        NSRange firstNameEndRange = [address rangeOfString:@"</firstName>" options:NSCaseInsensitiveSearch range:NSMakeRange(firstNameRange.location, address.length - firstNameRange.location)];
                        if (firstNameEndRange.location != NSNotFound) {
                            firstName = [address substringWithRange:NSMakeRange(firstNameRange.location + 10, firstNameEndRange.location - (firstNameRange.location + 10))];
                        }
                    }
                    
                    // 提取 lastName
                    NSRange lastNameRange = [address rangeOfString:@"<lastName>"];
                    NSString *lastName = @"";
                    if (lastNameRange.location != NSNotFound) {
                        NSRange lastNameEndRange = [address rangeOfString:@"</lastName>" options:NSCaseInsensitiveSearch range:NSMakeRange(lastNameRange.location, address.length - lastNameRange.location)];
                        if (lastNameEndRange.location != NSNotFound) {
                            lastName = [address substringWithRange:NSMakeRange(lastNameRange.location + 9, lastNameEndRange.location - (lastNameRange.location + 9))];
                        }
                    }
                    
                    account.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                }
            }
        }
    }
    
    // 提取 passwordToken
    NSRange passwordTokenRange = [responseString rangeOfString:@"<passwordToken>"];
    if (passwordTokenRange.location != NSNotFound) {
        NSRange passwordTokenEndRange = [responseString rangeOfString:@"</passwordToken>" options:NSCaseInsensitiveSearch range:NSMakeRange(passwordTokenRange.location, responseString.length - passwordTokenRange.location)];
        if (passwordTokenEndRange.location != NSNotFound) {
            account.passwordToken = [responseString substringWithRange:NSMakeRange(passwordTokenRange.location + 14, passwordTokenEndRange.location - (passwordTokenRange.location + 14))];
        }
    }
    
    // 提取 dsPersonId
    NSRange dsPersonIdRange = [responseString rangeOfString:@"<dsPersonId>"];
    if (dsPersonIdRange.location != NSNotFound) {
        NSRange dsPersonIdEndRange = [responseString rangeOfString:@"</dsPersonId>" options:NSCaseInsensitiveSearch range:NSMakeRange(dsPersonIdRange.location, responseString.length - dsPersonIdRange.location)];
        if (dsPersonIdEndRange.location != NSNotFound) {
            account.directoryServicesID = [responseString substringWithRange:NSMakeRange(dsPersonIdRange.location + 11, dsPersonIdEndRange.location - (dsPersonIdRange.location + 11))];
        }
    }
    
    // 检查是否成功获取所有必要信息
    if (account.email && account.passwordToken && account.directoryServicesID) {
        return account;
    }
    
    return nil;
}

- (NSString *)parseBagResponse:(NSString *)responseString {
    // 解析 XML 响应，提取认证端点
    // 尝试使用不同的标签名，因为 XML 结构可能会变化
    NSArray *possibleTags = @[@"<authenticateAccount>", @"<authentication>", @"<auth>"];
    
    for (NSString *tag in possibleTags) {
        NSRange authEndpointRange = [responseString rangeOfString:tag];
        if (authEndpointRange.location != NSNotFound) {
            NSString *closingTag = [tag stringByReplacingOccurrencesOfString:@"<" withString:@"</"];
            NSRange authEndpointEndRange = [responseString rangeOfString:closingTag options:NSCaseInsensitiveSearch range:NSMakeRange(authEndpointRange.location, responseString.length - authEndpointRange.location)];
            if (authEndpointEndRange.location != NSNotFound) {
                NSString *endpoint = [responseString substringWithRange:NSMakeRange(authEndpointRange.location + tag.length, authEndpointEndRange.location - (authEndpointRange.location + tag.length))];
                return [endpoint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
    }
    
    // 如果没有找到认证端点，尝试直接从 XML 中搜索可能的 URL
    // 如果没有找到认证端点，尝试直接从 XML 中搜索可能的 URL
        NSString *pattern = @"https?://[^\\s<>\"']+";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:responseString options:0 range:NSMakeRange(0, responseString.length)];
        
    
    for (NSTextCheckingResult *match in matches) {
        NSString *url = [responseString substringWithRange:match.range];
        if ([url containsString:@"authenticate"] || [url containsString:@"auth"] || [url containsString:@"login"]) {
            return url;
        }
    }
    
    return nil;
}

- (NSString *)getDeviceGUID {
    // 生成一个唯一的设备标识符
    // 在实际项目中，应该使用更可靠的方法获取设备标识符
    NSString *uuid = [[NSUUID UUID] UUIDString];
    return [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

- (NSString *)urlEncode:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

- (void)saveAccountToKeychain {
    if (!self.currentAccount) return;
    
    // 将账户信息保存到钥匙串
    NSData *accountData = [NSKeyedArchiver archivedDataWithRootObject:self.currentAccount requiringSecureCoding:NO error:nil];
    if (accountData) {
        NSMutableDictionary *query = [NSMutableDictionary dictionary];
        [query setObject:@"appstore.account" forKey:(__bridge id)kSecAttrAccount];
        [query setObject:accountData forKey:(__bridge id)kSecValueData];
        [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        
        SecItemDelete((__bridge CFDictionaryRef)query);
        SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
}

- (void)loadAccountFromKeychain {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:@"appstore.account" forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:@YES forKey:(__bridge id)kSecReturnData];
    
    CFDataRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataRef);
    if (status == errSecSuccess && dataRef) {
        NSData *accountData = (__bridge_transfer NSData *)dataRef;
        AppStoreAccount *account = [NSKeyedUnarchiver unarchivedObjectOfClass:[AppStoreAccount class] fromData:accountData error:nil];
        if (account) {
            self.currentAccount = account;
        }
    }
}

- (AppStoreAccount *)getCurrentAccount {
    return self.currentAccount;
}

- (BOOL)isLoggedIn {
    return self.currentAccount != nil;
}

- (void)logout {
    // 从钥匙串中删除账户信息
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:@"appstore.account" forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    SecItemDelete((__bridge CFDictionaryRef)query);
    
    self.currentAccount = nil;
}

@end

@implementation AppStoreAccount

// 实现 NSCoding 协议以支持归档和反归档
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.passwordToken forKey:@"passwordToken"];
    [coder encodeObject:self.directoryServicesID forKey:@"directoryServicesID"];
    [coder encodeObject:self.storeFront forKey:@"storeFront"];
    [coder encodeObject:self.password forKey:@"password"];
    [coder encodeObject:self.pod forKey:@"pod"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.name = [coder decodeObjectForKey:@"name"];
        self.email = [coder decodeObjectForKey:@"email"];
        self.passwordToken = [coder decodeObjectForKey:@"passwordToken"];
        self.directoryServicesID = [coder decodeObjectForKey:@"directoryServicesID"];
        self.storeFront = [coder decodeObjectForKey:@"storeFront"];
        self.password = [coder decodeObjectForKey:@"password"];
        self.pod = [coder decodeObjectForKey:@"pod"];
    }
    return self;
}

@end
