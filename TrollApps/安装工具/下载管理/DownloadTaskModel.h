//
//  DownloadTaskModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/22.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, DownloadStatus) {
    DownloadStatusWaiting,   // 等待中
    DownloadStatusDownloading, // 下载中
    DownloadStatusPaused,    // 已暂停
    DownloadStatusCompleted, // 已完成
    DownloadStatusFailed     // 已失败
};

@interface DownloadTaskModel : NSObject

/// 任务ID（唯一标识）
@property (nonatomic, copy) NSString *taskId;
/// 下载URL
@property (nonatomic, strong) NSURL *url;
/// 文件名
@property (nonatomic, copy) NSString *fileName;
/// 本地文件路径
@property (nonatomic, copy) NSString *localPath;
/// 总大小（字节）
@property (nonatomic, assign) int64_t totalSize;
/// 已下载大小（字节）
@property (nonatomic, assign) int64_t downloadedSize;
/// 下载进度（0~1）
@property (nonatomic, assign) CGFloat progress;
/// 下载状态
@property (nonatomic, assign) DownloadStatus status;
/// 下载任务实例
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
/// 恢复下载所需的数据
@property (nonatomic, strong) NSData *resumeData;

/// 初始化方法
+ (instancetype)taskWithURL:(NSURL *)url fileName:(NSString *)fileName;


@end

NS_ASSUME_NONNULL_END
