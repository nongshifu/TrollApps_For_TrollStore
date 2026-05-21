//
//  MediaManager.h
//  TrollApps
//
//  媒体管理器 - 处理截图/视频的上传、删除
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MediaItem.h"

NS_ASSUME_NONNULL_BEGIN

@class MediaManager;

@protocol MediaManagerDelegate <NSObject>
@optional
/// 单个文件上传进度
- (void)mediaManager:(MediaManager *)manager didUpdateProgress:(CGFloat)progress forItem:(MediaItem *)item;
/// 单个文件上传完成
- (void)mediaManager:(MediaManager *)manager didFinishUploadingItem:(MediaItem *)item withResult:(BOOL)success error:(nullable NSError *)error;
/// 所有上传任务完成
- (void)mediaManager:(MediaManager *)manager didFinishAllUploadsWithResults:(NSDictionary *)results;
/// 删除文件完成
- (void)mediaManager:(MediaManager *)manager didFinishDeletingFile:(NSString *)fileName withResult:(BOOL)success error:(nullable NSError *)error;
@end

@interface MediaManager : NSObject

@property (nonatomic, weak) id<MediaManagerDelegate> delegate;
@property (nonatomic, assign) NSInteger appId;           // 应用ID
@property (nonatomic, assign) NSInteger versionCode;     // 版本号
@property (nonatomic, copy) NSString *udid;             // 用户UDID
@property (nonatomic, copy) NSString *token;            // 用户Token

/// 单例访问
+ (instancetype)sharedInstance;

/// 上传图片
/// @param image 图片
/// @param completion 完成回调 (返回服务器文件名)
- (void)uploadImage:(UIImage *)image completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSError * _Nullable error))completion;

/// 上传图标
/// @param image 图片
/// @param completion 完成回调 (返回服务器文件名)
- (void)uploadIconImage:(UIImage *)image completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSError * _Nullable error))completion;

/// 上传视频
/// @param videoURL 视频本地URL
/// @param completion 完成回调 (返回服务器文件名和缩略图信息)
- (void)uploadVideo:(NSURL *)videoURL completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSString * _Nullable thumbnailFileName, NSString * _Nullable thumbnailURL, CGFloat duration, NSError * _Nullable error))completion;

/// 上传主文件
/// @param fileData 主文件数据
/// @param fileName 文件名
/// @param completion 完成回调 (返回服务器文件名)
- (void)uploadMainFile:(NSData *)fileData fileName:(NSString *)fileName completion:(void(^)(BOOL success, NSString * _Nullable fileName, NSString * _Nullable fileURL, NSError * _Nullable error))completion;

/// 批量上传媒体文件
/// @param items 媒体文件数组
/// @param progressCallback 进度回调
/// @param completion 完成回调
- (void)uploadMediaItems:(NSArray<MediaItem *> *)items
                progress:(void(^)(NSInteger completed, NSInteger total, CGFloat progress))progressCallback
              completion:(void(^)(NSDictionary *results))completion;

/// 删除现有媒体文件
/// @param fileName 要删除的文件名
/// @param completion 完成回调
- (void)deleteMediaFile:(NSString *)fileName completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

/// 批量删除媒体文件
/// @param fileNames 要删除的文件名数组
/// @param completion 完成回调
- (void)deleteMediaFiles:(NSArray<NSString *> *)fileNames completion:(void(^)(NSDictionary *results))completion;

/// 取消所有上传任务
- (void)cancelAllUploads;

/// 生成视频缩略图
/// @param videoURL 视频URL
/// @param completion 完成回调
+ (void)generateVideoThumbnail:(NSURL *)videoURL completion:(void(^)(UIImage * _Nullable thumbnail, CGFloat duration))completion;

/// 检查文件是否是视频
+ (BOOL)isVideoFile:(NSString *)fileName;

/// 检查文件是否是图片
+ (BOOL)isImageFile:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
