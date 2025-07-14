//
//  MediaProcessor.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/7.
//

#import "MediaProcessor.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import "config.h"


@implementation MediaProcessor

+ (instancetype)sharedProcessor {
    static MediaProcessor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MediaProcessor alloc] init];
        instance.maxImageFileSize = 10 * 1024 * 1024; // 默认10MB
        instance.maxImageDimension = 1000 * 1000;     // 默认1000x1000
        instance.maxImageHeight = 1000;                // 默认最大高度1000
        instance.maxImageWidth = 1000;                 // 默认最大宽度1000
        instance.maxVideoFileSize = 50 * 1024 * 1024;  // 默认50MB
        instance.maxVideoDuration = 60;                 // 默认60秒
        instance.defaultCompression = 0.8;             // 默认压缩质量
    });
    return instance;
}

#pragma mark - 公共方法

- (void)processMediaModel:(HXPhotoModel *)model
                   index:(NSInteger)index
                   appId:(NSInteger)appId
         compressionType:(CompressionType)compressionType
              completion:(MediaProcessCompletion)completion {
    if (!model) {
        NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"无效的媒体模型"}];
        completion(nil, nil, error);
        return;
    }
    
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        switch (compressionType) {
            case CompressionTypeNone:
                [self processImageWithoutCompression:model index:index appId:appId completion:completion];
                break;
            case CompressionTypeFileSize:
                [self processImageWithMaxFileSize:model index:index appId:appId maxFileSize:self.maxImageFileSize completion:completion];
                break;
            case CompressionTypeImageDimension:
                [self processImageWithMaxDimension:model index:index appId:appId maxDimension:self.maxImageDimension completion:completion];
                break;
            case CompressionTypeMaxHeight:
                [self processImageWithMaxHeight:model index:index appId:appId maxHeight:self.maxImageHeight completion:completion];
                break;
            case CompressionTypeMaxWidth:
                [self processImageWithMaxWidth:model index:index appId:appId maxWidth:self.maxImageWidth completion:completion];
                break;
        }
    } else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self processVideoWithMaxFileSize:model index:index appId:appId maxFileSize:self.maxVideoFileSize completion:completion];
    } else {
        NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"不支持的媒体类型"}];
        completion(nil, nil, error);
    }
}

#pragma mark - 图片处理方法
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
                            completion:(MediaProcessCompletion _Nullable)completion {
    [self processImageWithMaxFileSize:model
                               index:index
                               appId:appId
                         maxFileSize:self.maxImageFileSize
                          completion:completion];
}

- (void)processImageWithoutCompression:(HXPhotoModel *)model
                                 index:(NSInteger)index
                                 appId:(NSInteger)appId
                            completion:(MediaProcessCompletion)completion {
    [self requestImageData:model completion:^(NSData *imageData, NSString *extension) {
        if (imageData && extension) {
            NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:extension];
            completion(imageData, fileName, nil);
        } else {
            NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:2001 userInfo:@{NSLocalizedDescriptionKey: @"获取图片数据失败"}];
            completion(nil, nil, error);
        }
    }];
}

- (void)processImageWithMaxFileSize:(HXPhotoModel *)model
                              index:(NSInteger)index
                              appId:(NSInteger)appId
                        maxFileSize:(CGFloat)maxFileSize
                         completion:(MediaProcessCompletion)completion {
    [self requestImageData:model completion:^(NSData *originalData, NSString *extension) {
        if (!originalData || !extension) {
            NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:2001 userInfo:@{NSLocalizedDescriptionKey: @"获取图片数据失败"}];
            completion(nil, nil, error);
            return;
        }
        
        // 如果原始数据小于最大限制，直接返回
        if (originalData.length <= maxFileSize) {
            NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:extension];
            completion(originalData, fileName, nil);
            return;
        }
        
        // 否则进行压缩
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:originalData];
            CGFloat compressionQuality = [self calculateCompressionQuality:originalData.length targetSize:maxFileSize];
            
            NSData *compressedData;
            NSString *newExtension = extension;
            
            // 处理HEIC格式
            if ([extension.lowercaseString isEqualToString:@"heic"]) {
                compressedData = UIImageJPEGRepresentation(image, compressionQuality);
                newExtension = @"jpg";
            } else if ([extension.lowercaseString isEqualToString:@"png"]) {
                compressedData = UIImagePNGRepresentation(image);
            } else {
                compressedData = UIImageJPEGRepresentation(image, compressionQuality);
                newExtension = @"jpg";
            }
            
            // 如果一次压缩还不够，进行二次压缩
            if (compressedData.length > maxFileSize) {
                compressionQuality *= 0.5;
                if ([newExtension.lowercaseString isEqualToString:@"png"]) {
                    compressedData = UIImagePNGRepresentation(image);
                } else {
                    compressedData = UIImageJPEGRepresentation(image, compressionQuality);
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:newExtension];
                completion(compressedData, fileName, nil);
            });
        });
    }];
}

- (void)processImageWithMaxDimension:(HXPhotoModel *)model
                               index:(NSInteger)index
                               appId:(NSInteger)appId
                         maxDimension:(CGFloat)maxDimension
                          completion:(MediaProcessCompletion)completion {
    [self requestImageData:model completion:^(NSData *originalData, NSString *extension) {
        if (!originalData || !extension) {
            NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:2001 userInfo:@{NSLocalizedDescriptionKey: @"获取图片数据失败"}];
            completion(nil, nil, error);
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:originalData];
            CGSize originalSize = image.size;
            CGFloat originalDimension = originalSize.width * originalSize.height;
            
            // 如果原始尺寸乘积小于最大限制，直接返回
            if (originalDimension <= maxDimension) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:extension];
                    completion(originalData, fileName, nil);
                });
                return;
            }
            
            // 计算新尺寸
            CGFloat scaleFactor = sqrt(maxDimension / originalDimension);
            CGSize newSize = CGSizeMake(originalSize.width * scaleFactor, originalSize.height * scaleFactor);
            
            // 缩放图片
            UIImage *scaledImage = [self scaleImage:image toSize:newSize];
            NSData *compressedData = UIImageJPEGRepresentation(scaledImage, self.defaultCompression);
            NSString *newExtension = @"jpg";
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:newExtension];
                completion(compressedData, fileName, nil);
            });
        });
    }];
}

- (void)processImageWithMaxHeight:(HXPhotoModel *)model
                            index:(NSInteger)index
                            appId:(NSInteger)appId
                        maxHeight:(CGFloat)maxHeight
                       completion:(MediaProcessCompletion)completion {
    [self requestImageData:model completion:^(NSData *originalData, NSString *extension) {
        if (!originalData || !extension) {
            NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:2001 userInfo:@{NSLocalizedDescriptionKey: @"获取图片数据失败"}];
            completion(nil, nil, error);
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:originalData];
            CGSize originalSize = image.size;
            
            // 如果原始高度小于最大限制，直接返回
            if (originalSize.height <= maxHeight) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:extension];
                    completion(originalData, fileName, nil);
                });
                return;
            }
            
            // 按高度比例缩放
            CGFloat scaleFactor = maxHeight / originalSize.height;
            CGSize newSize = CGSizeMake(originalSize.width * scaleFactor, maxHeight);
            
            // 缩放图片
            UIImage *scaledImage = [self scaleImage:image toSize:newSize];
            NSData *compressedData = UIImageJPEGRepresentation(scaledImage, self.defaultCompression);
            NSString *newExtension = @"jpg";
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:newExtension];
                completion(compressedData, fileName, nil);
            });
        });
    }];
}

- (void)processImageWithMaxWidth:(HXPhotoModel *)model
                           index:(NSInteger)index
                           appId:(NSInteger)appId
                        maxWidth:(CGFloat)maxWidth
                      completion:(MediaProcessCompletion)completion {
    [self requestImageData:model completion:^(NSData *originalData, NSString *extension) {
        if (!originalData || !extension) {
            NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:2001 userInfo:@{NSLocalizedDescriptionKey: @"获取图片数据失败"}];
            completion(nil, nil, error);
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:originalData];
            CGSize originalSize = image.size;
            
            // 如果原始宽度小于最大限制，直接返回
            if (originalSize.width <= maxWidth) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:extension];
                    completion(originalData, fileName, nil);
                });
                return;
            }
            
            // 按宽度比例缩放
            CGFloat scaleFactor = maxWidth / originalSize.width;
            CGSize newSize = CGSizeMake(maxWidth, originalSize.height * scaleFactor);
            
            // 缩放图片
            UIImage *scaledImage = [self scaleImage:image toSize:newSize];
            NSData *compressedData = UIImageJPEGRepresentation(scaledImage, self.defaultCompression);
            NSString *newExtension = @"jpg";
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:newExtension];
                completion(compressedData, fileName, nil);
            });
        });
    }];
}

#pragma mark - 视频处理方法

- (void)processVideoWithoutCompression:(HXPhotoModel *)model
                                 index:(NSInteger)index
                                 appId:(NSInteger)appId
                            completion:(MediaProcessCompletion)completion {
    [self requestVideoURL:model completion:^(NSURL *videoURL) {
        if (videoURL) {
            NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
            if (videoData) {
                NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:@"mp4"];
                completion(videoData, fileName, nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:3001 userInfo:@{NSLocalizedDescriptionKey: @"获取视频数据失败"}];
                completion(nil, nil, error);
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:3002 userInfo:@{NSLocalizedDescriptionKey: @"获取视频URL失败"}];
            completion(nil, nil, error);
        }
    }];
}

- (void)processVideoWithMaxFileSize:(HXPhotoModel *)model
                              index:(NSInteger)index
                              appId:(NSInteger)appId
                        maxFileSize:(CGFloat)maxFileSize
                         completion:(MediaProcessCompletion)completion {
    [self requestVideoURL:model completion:^(NSURL *originalURL) {
        if (!originalURL) {
            NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:3002 userInfo:@{NSLocalizedDescriptionKey: @"获取视频URL失败"}];
            completion(nil, nil, error);
            return;
        }
        
        // 获取原始视频大小
        NSNumber *fileSizeValue;
        [originalURL getResourceValue:&fileSizeValue forKey:NSURLFileSizeKey error:nil];
        CGFloat originalFileSize = fileSizeValue.floatValue;
        
        // 如果原始大小小于最大限制，直接返回
        if (originalFileSize <= maxFileSize) {
            NSData *videoData = [NSData dataWithContentsOfURL:originalURL];
            if (videoData) {
                NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:@"mp4"];
                completion(videoData, fileName, nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:3001 userInfo:@{NSLocalizedDescriptionKey: @"获取视频数据失败"}];
                completion(nil, nil, error);
            }
            return;
        }
        
        // 否则进行压缩
        [self compressVideo:originalURL maxFileSize:maxFileSize completion:^(NSData *compressedData) {
            if (compressedData) {
                NSString *fileName = [self generateFileNameWithIndex:index appId:appId extension:@"mp4"];
                completion(compressedData, fileName, nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"MediaProcessor" code:3003 userInfo:@{NSLocalizedDescriptionKey: @"视频压缩失败"}];
                completion(nil, nil, error);
            }
        }];
    }];
}
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
                            completion:(MediaProcessCompletion _Nullable)completion {
    [self processVideoWithMaxFileSize:model
                               index:index
                               appId:appId
                         maxFileSize:self.maxVideoFileSize
                          completion:completion];
}

#pragma mark - 辅助方法

// 请求图片数据
- (void)requestImageData:(HXPhotoModel *)model completion:(void(^)(NSData *imageData, NSString *extension))completion {
    
    if (model.photoEdit && model.photoEdit.editPreviewData) {
        completion(model.photoEdit.editPreviewData, [self getExtensionForImageFormat:model.photoFormat]);
        return;
    }
    [HXAssetManager requestImageDataForAsset:model.asset
                                   version:PHImageRequestOptionsVersionCurrent
                                resizeMode:PHImageRequestOptionsResizeModeNone
                     networkAccessAllowed:YES
                            progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"iCloud下载中%%%.1f",progress);
            [SVProgressHUD showProgress:progress status:@"图片iCloud下载中"];
        });
    } completion:^(NSData *imageData, UIImageOrientation orientation, NSDictionary *info) {
        
        if (imageData) {
            completion(imageData, [self getExtensionForImageFormat:model.photoFormat]);
        } else {
            completion(nil, nil);
        }
    }];
    
}

// 请求视频URL
- (void)requestVideoURL:(HXPhotoModel *)model completion:(void(^)(NSURL *videoURL))completion {
    [HXAssetManager requestAVAssetForAsset:model.asset
                     networkAccessAllowed:YES
                          progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"视频处理中下载中 %%%.2f",progress);
            [SVProgressHUD showProgress:progress status:@"视频iCloud下载中"];
        });
    } completion:^(AVAsset *avasset, AVAudioMix *audioMix, NSDictionary *info) {
        if (![avasset isKindOfClass:[AVURLAsset class]]) {
            completion(nil);
        }
        
        AVURLAsset *urlAsset = (AVURLAsset *)avasset;
        NSURL *fileURL = urlAsset.URL;
        completion(fileURL);
    }];
    
}

// 压缩视频
- (void)compressVideo:(NSURL *)videoURL maxFileSize:(CGFloat)maxFileSize completion:(void(^)(NSData *compressedData))completion {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    
    // 计算压缩质量
    NSNumber *fileSizeValue;
    [videoURL getResourceValue:&fileSizeValue forKey:NSURLFileSizeKey error:nil];
    CGFloat originalSize = fileSizeValue.floatValue;
    
    // 根据文件大小选择合适的预设
    if (originalSize > 2 * maxFileSize) {
        exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetLowQuality];
    } else if (originalSize > maxFileSize) {
        exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    }
    
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    // 创建临时输出路径
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"compressed_%@.mp4", [NSUUID UUID].UUIDString]];
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            NSData *compressedData = [NSData dataWithContentsOfURL:exportSession.outputURL];
            
            // 清理临时文件
            [[NSFileManager defaultManager] removeItemAtURL:exportSession.outputURL error:nil];
            
            completion(compressedData);
        } else {
            completion(nil);
        }
    }];
}

// 缩放图片
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

// 计算压缩质量
- (CGFloat)calculateCompressionQuality:(NSUInteger)originalSize targetSize:(NSUInteger)targetSize {
    CGFloat ratio = (CGFloat)targetSize / originalSize;
    return MAX(ratio * 0.9, 0.1); // 确保压缩质量不低于0.1
}

// 获取图片格式对应的扩展名
- (NSString *)getExtensionForImageFormat:(HXPhotoModelFormat)format {
    switch (format) {
        case HXPhotoModelFormatPNG:
            return @"png";
        case HXPhotoModelFormatJPG:
            return @"jpg";
        case HXPhotoModelFormatGIF:
            return @"gif";
        case HXPhotoModelFormatHEIC:
            return @"heic";
        default:
            return @"jpg";
    }
}

// 生成文件名（符合服务器要求）
- (NSString *)generateFileNameWithIndex:(NSInteger)index appId:(NSInteger)appId extension:(NSString *)extension {
    // 格式：index_appId_uuid.extension
    return [NSString stringWithFormat:@"%ld_%ld_%@.%@", (long)index, (long)appId, [[NSUUID UUID] UUIDString], extension];
}

@end
