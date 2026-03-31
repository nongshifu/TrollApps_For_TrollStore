//
//  MediaProcessor.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"
#import "HXAssetManager.h"
#import "HXPhotoTools.h"
// 压缩类型
typedef NS_ENUM(NSInteger, CompressionType) {
    CompressionTypeNone,               // 不压缩
    CompressionTypeFileSize,           // 按文件大小压缩
    CompressionTypeImageDimension,     // 按图片宽高乘积压缩
    CompressionTypeMaxHeight,          // 按最大高度压缩
    CompressionTypeMaxWidth            // 按最大宽度压缩
};

// 处理结果回调
typedef void(^MediaProcessCompletion)(NSData * _Nullable fileData, NSString * _Nullable fileName, NSError * _Nullable error);

@interface MediaProcessor : NSObject

// 图片压缩参数
@property (nonatomic, assign) CGFloat maxImageFileSize;      // 最大文件大小(字节)，默认10MB
@property (nonatomic, assign) CGFloat maxImageDimension;     // 最大宽高乘积，默认1000*1000
@property (nonatomic, assign) CGFloat maxImageHeight;        // 最大高度，默认1000
@property (nonatomic, assign) CGFloat maxImageWidth;         // 最大宽度，默认1000
@property (nonatomic, assign) CGFloat defaultCompression;    // 默认压缩质量，0.8

// 视频压缩参数
@property (nonatomic, assign) CGFloat maxVideoFileSize;      // 最大文件大小(字节)，默认50MB
@property (nonatomic, assign) CGFloat maxVideoDuration;      // 最大时长(秒)，默认60秒

+ (instancetype)sharedProcessor;

/**
 处理媒体文件（自动判断图片/视频）
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param compressionType 压缩类型
 @param completion 处理完成回调
 */
- (void)processMediaModel:(HXPhotoModel * _Nonnull)model
                   index:(NSInteger)index
                   appId:(NSInteger)appId
         compressionType:(CompressionType)compressionType
              completion:(MediaProcessCompletion _Nullable)completion;

/**
 处理图片（无压缩）
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param completion 处理完成回调
 */
- (void)processImageWithoutCompression:(HXPhotoModel * _Nonnull)model
                                 index:(NSInteger)index
                                 appId:(NSInteger)appId
                            completion:(MediaProcessCompletion _Nullable)completion;

/**
 按文件大小压缩图片
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param maxFileSize 最大文件大小(字节)
 @param completion 处理完成回调
 */
- (void)processImageWithMaxFileSize:(HXPhotoModel * _Nonnull)model
                              index:(NSInteger)index
                              appId:(NSInteger)appId
                        maxFileSize:(CGFloat)maxFileSize
                         completion:(MediaProcessCompletion _Nullable)completion;

/**
 按宽高乘积压缩图片
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param maxDimension 最大宽高乘积
 @param completion 处理完成回调
 */
- (void)processImageWithMaxDimension:(HXPhotoModel * _Nonnull)model
                               index:(NSInteger)index
                               appId:(NSInteger)appId
                         maxDimension:(CGFloat)maxDimension
                          completion:(MediaProcessCompletion _Nullable)completion;

/**
 按最大高度压缩图片
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param maxHeight 最大高度
 @param completion 处理完成回调
 */
- (void)processImageWithMaxHeight:(HXPhotoModel * _Nonnull)model
                            index:(NSInteger)index
                            appId:(NSInteger)appId
                        maxHeight:(CGFloat)maxHeight
                       completion:(MediaProcessCompletion _Nullable)completion;

/**
 按最大宽度压缩图片
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param maxWidth 最大宽度
 @param completion 处理完成回调
 */
- (void)processImageWithMaxWidth:(HXPhotoModel * _Nonnull)model
                           index:(NSInteger)index
                           appId:(NSInteger)appId
                        maxWidth:(CGFloat)maxWidth
                      completion:(MediaProcessCompletion _Nullable)completion;

/**
 按默认设置处理图片（使用预设的最大文件大小和质量）
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param completion 处理完成回调
 */
- (void)processImageWithDefaultSettings:(HXPhotoModel * _Nonnull)model
                                 index:(NSInteger)index
                                 appId:(NSInteger)appId
                             completion:(MediaProcessCompletion _Nullable)completion ;


/**
 处理视频（无压缩）
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param completion 处理完成回调
 */
- (void)processVideoWithoutCompression:(HXPhotoModel * _Nonnull)model
                                 index:(NSInteger)index
                                 appId:(NSInteger)appId
                            completion:(MediaProcessCompletion _Nullable)completion;

/**
 按文件大小压缩视频
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param maxFileSize 最大文件大小(字节)
 @param completion 处理完成回调
 */
- (void)processVideoWithMaxFileSize:(HXPhotoModel * _Nonnull)model
                              index:(NSInteger)index
                              appId:(NSInteger)appId
                        maxFileSize:(CGFloat)maxFileSize
                         completion:(MediaProcessCompletion _Nullable)completion;

/**
 按默认设置处理视频（使用预设的最大文件大小和时长）
 
 @param model HXPhotoModel对象
 @param index 媒体文件下标
 @param appId 应用ID
 @param completion 处理完成回调
 */
- (void)processVideoWithDefaultSettings:(HXPhotoModel * _Nonnull)model
                                 index:(NSInteger)index
                                 appId:(NSInteger)appId
                             completion:(MediaProcessCompletion _Nullable)completion;

@end
