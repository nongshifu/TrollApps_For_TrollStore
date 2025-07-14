//
//  KeychainTool.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeychainTool : NSObject
/// 存储数据到钥匙串
+ (BOOL)saveData:(NSData *)data forKey:(NSString *)key;

/// 从钥匙串读取数据
+ (NSData *)readDataForKey:(NSString *)key;

/// 从钥匙串删除数据
+ (BOOL)deleteDataForKey:(NSString *)key;

/// 存储字符串到钥匙串
+ (BOOL)saveString:(NSString *)string forKey:(NSString *)key;

/// 从钥匙串读取字符串
+ (NSString *)readStringForKey:(NSString *)key;

/**
 * 读取钥匙串中存储的IDFV（若没有则返回nil）
 */
+ (NSString *)readIDFV;

/**
 * 读取当前设备的原始IDFV，并自动存入钥匙串（若钥匙串中已有则直接返回存储的值）
 * 【核心方法】：确保首次调用时存储，后续调用直接读取，实现持久化
 */
+ (NSString *)readAndSaveIDFV;

/**
 * 重置IDFV：删除钥匙串中已存储的IDFV，重新生成并存储新的IDFV
 */
+ (NSString *)resetAndSaveIDFV;


@end

NS_ASSUME_NONNULL_END
