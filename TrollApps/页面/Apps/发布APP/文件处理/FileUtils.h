//
//  FileUtils.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileUtils : NSObject

/// 判断URL对应的文件是否为图片
+ (BOOL)isImageFileWithURL:(NSURL *)url;

/// 判断URL对应的文件是否为视频
+ (BOOL)isVideoFileWithURL:(NSURL *)url;

/// 判断URL对应的文件是否为图片或视频（媒体文件）
+ (BOOL)isMediaFileWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
