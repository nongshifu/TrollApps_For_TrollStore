//
//  DownloadProgressView.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/22.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import "DownloadTaskModel.h"

NS_ASSUME_NONNULL_BEGIN


@protocol DownloadProgressViewDelegate <NSObject>
@optional
/// 暂停下载
- (void)downloadPause:(NSURLSessionDownloadTask *)task;
/// 恢复下载
- (void)downloadResume:(NSURLSessionDownloadTask *)task;
/// 取消下载
- (void)downloadCancel:(NSURLSessionDownloadTask *)task;
/// 重新下载
- (void)downloadRestart:(NSURLSessionDownloadTask *)task;
@end

@interface DownloadProgressView : UIView

/// 单例
+ (instancetype)sharedView;

/// 代理
@property (nonatomic, weak) id<DownloadProgressViewDelegate> delegate;

/// 是否自动贴边（默认YES）
@property (nonatomic, assign) BOOL autoSnapToEdge;

/// 当前下载任务
@property (nonatomic, strong) NSURLSessionDownloadTask *currentTask;

/// 显示进度视图
/// @param task 下载任务
/// @param fileName 文件名（用于展开时显示）
- (void)showWithTask:(NSURLSessionDownloadTask *)task fileName:(NSString *)fileName;

/// 更新进度
/// @param progress 0~1
- (void)updateProgress:(CGFloat)progress;

/// 隐藏视图
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
