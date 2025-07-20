//
//  FileInstallManager.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/17.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewAppFileModel.h"

NS_ASSUME_NONNULL_BEGIN
// 安装结果回调
typedef void(^InstallCompletionHandler)(BOOL success, NSError * _Nullable error);

@interface FileInstallManager : NSObject

// 单例方法
+ (instancetype)sharedManager;

/**
 * 根据文件URL自动判断类型并安装
 * @param fileURL 文件URL（本地或网络URL）
 * @param completion 安装完成回调
 */
- (void)installFileWithURL:(NSURL *)fileURL completion:(InstallCompletionHandler)completion;

/**
 * 根据文件URL字符串自动判断类型并安装
 * @param urlString 文件URL字符串（本地或网络URL）
 * @param completion 安装完成回调
 */
- (void)installFileWithURLString:(NSString *)urlString completion:(InstallCompletionHandler)completion;

/**
 * 根据文件类型和数据进行安装
 * @param fileType 文件类型
 * @param fileData 文件数据
 * @param fileName 文件名（用于显示和类型确认）
 * @param completion 安装完成回调
 */
- (void)installFileWithType:(FileType)fileType
                   fileData:(NSData *)fileData
                   fileName:(NSString *)fileName
                 completion:(InstallCompletionHandler)completion;

/**
 * 判断URL是本地URL还是网络URL
 * @param url 文件URL
 * @return YES表示本地URL，NO表示网络URL
 */
- (BOOL)isLocalURL:(NSURL *)url;

/**
 * 根据文件名或URL路径判断文件类型
 * @param filePath 文件名或文件路径
 * @return 文件类型枚举值
 */
- (FileType)fileTypeForPath:(NSString *)filePath;

/**
 * 下载远程URL文件 自带URL中文编码
 * @param urlString 文件URL
 */
- (void)downloadFileWithURLString:(NSString *)urlString completion:(void(^)(NSURL * _Nullable fileLocalURL, NSError * _Nullable error))completion ;
/**
 * 下载远程URL文件
 * @param url 文件URL
 */
- (void)downloadFileWithURL:(NSURL *)url completion:(void(^)(NSURL * _Nullable fileLocalURL, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
