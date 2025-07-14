//
//  KeychainTool.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//


#import "KeychainTool.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

@implementation KeychainTool

// 定义IDFV在钥匙串中的存储键（唯一标识，避免与其他数据冲突）
static NSString *const kIDFVKeychainKey = @"com.trollapps.default.keychain.idfv";


/// 生成钥匙串查询字典（自动获取App唯一标识）
+ (NSDictionary *)keychainQueryForKey:(NSString *)key {
    // 自动获取App的bundle identifier（如"com.company.appname"）
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    // 若获取失败，使用默认值（避免空值）
    if (!bundleID || bundleID.length == 0) {
        bundleID = @"com.trollapps.default.keychain.service";
    }
    
    return @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: key,
        (__bridge id)kSecAttrService: bundleID, // 自动使用App的bundle identifier
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock
    };
}

/// 存储数据到钥匙串
+ (BOOL)saveData:(NSData *)data forKey:(NSString *)key {
    // 先删除旧数据（避免重复存储）
    [self deleteDataForKey:key];
    
    // 构建存储字典
    NSMutableDictionary *query = [self keychainQueryForKey:key].mutableCopy;
    [query setObject:data forKey:(__bridge id)kSecValueData];
    
    // 执行存储
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    return status == errSecSuccess;
}

/// 从钥匙串读取数据
+ (NSData *)readDataForKey:(NSString *)key {
    // 构建查询字典（指定返回数据）
    NSMutableDictionary *query = [self keychainQueryForKey:key].mutableCopy;
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    // 执行查询
    CFDataRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataRef);
    
    if (status == errSecSuccess && dataRef) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        return data;
    }
    return nil;
}

/// 从钥匙串删除数据
+ (BOOL)deleteDataForKey:(NSString *)key {
    NSDictionary *query = [self keychainQueryForKey:key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    return status == errSecSuccess;
}

/// 存储字符串到钥匙串
+ (BOOL)saveString:(NSString *)string forKey:(NSString *)key {
    if (!string) return NO;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self saveData:data forKey:key];
}

/// 从钥匙串读取字符串
+ (NSString *)readStringForKey:(NSString *)key {
    NSData *data = [self readDataForKey:key];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}
#pragma mark - 新增：IDFV专属管理方法
/**
 * 读取钥匙串中存储的IDFV（仅读取，不生成新值）
 */
+ (NSString *)readIDFV {
    NSString *storedIDFV = [self readStringForKey:kIDFVKeychainKey];
    if (storedIDFV) {
        NSLog(@"✅ 从钥匙串读取到IDFV: %@", storedIDFV);
    } else {
        NSLog(@"⚠️ 钥匙串中无存储的IDFV");
    }
    return storedIDFV;
}

/**
 * 读取并存储IDFV：
 * 1. 若钥匙串中已有IDFV，直接返回存储的值
 * 2. 若没有，生成当前设备的原始IDFV并存入钥匙串，然后返回新值
 */
+ (NSString *)readAndSaveIDFV {
    // 先尝试读取钥匙串中已有的IDFV
    NSString *storedIDFV = [self readIDFV];
    if (storedIDFV) {
        return storedIDFV;
    }
    
    // 钥匙串中没有，生成当前设备的原始IDFV
    NSUUID *vendorID = [UIDevice currentDevice].identifierForVendor;
    NSString *originalIDFV = vendorID ? [vendorID UUIDString] : [[NSUUID UUID] UUIDString];
    NSLog(@"🔄 生成原始IDFV: %@", originalIDFV);
    
    // 存入钥匙串
    BOOL saveSuccess = [self saveString:originalIDFV forKey:kIDFVKeychainKey];
    if (saveSuccess) {
        NSLog(@"✅ 新IDFV已存入钥匙串");
    } else {
        NSLog(@"❌ 钥匙串存储IDFV失败");
    }
    
    return originalIDFV;
}

/**
 * 重置IDFV：删除已有值，重新生成并存储新的IDFV
 */
+ (NSString *)resetAndSaveIDFV {
    // 1. 删除钥匙串中已存储的旧IDFV
    BOOL deleteSuccess = [self deleteDataForKey:kIDFVKeychainKey];
    if (deleteSuccess) {
        NSLog(@"🗑️ 已删除旧IDFV");
    } else {
        NSLog(@"⚠️ 删除旧IDFV失败（可能原本就没有）");
    }
    
    // 2. 生成新的IDFV并存储（直接调用readAndSaveIDFV，复用逻辑）
    return [self readAndSaveIDFV];
}
@end
