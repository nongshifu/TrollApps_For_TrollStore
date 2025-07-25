//
//  HXPhotoURLConverter.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/7.
//

#import "HXPhotoURLConverter.h"
#import "SVProgressHUD.h"
#import "Demo9Model.h"
#import "HXCustomAssetModel.h"
#import "config.h"
#import "AppInfoModel.h"
@implementation HXPhotoURLConverter

+ (void)convertPhotoModelsToURLs:(NSArray<HXPhotoModel *> * _Nonnull)photoModels
                      completion:(HXPhotoURLConvertCompletion _Nonnull)completion {
    if (photoModels.count == 0) {
        completion(@[], @[]);
        return;
    }
    
    // 线程安全的数组（存储结果和错误）
    NSMutableArray<NSURL *> *resultURLs = [NSMutableArray array];
    NSMutableArray<NSError *> *errors = [NSMutableArray array];
    // 计数器，用于等待所有模型处理完成
    __block NSInteger remainingCount = photoModels.count;
    // 同步锁，避免多线程冲突
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    for (HXPhotoModel *model in photoModels) {
        NSLog(@"HXPhotoModel:%@ networkPhotoUrl:%@ URL:%@",model,model.networkPhotoUrl,model.imageURL);
        // 处理图片
        
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            NSLog(@"处理图片");
            [self handlePhotoModel:model completion:^(NSURL *url, NSError *error) {
                NSLog(@"处理图片返回：%@  error:%@",url,error);
                [self processResultWithURL:url error:error resultURLs:resultURLs errors:errors semaphore:semaphore remainingCount:&remainingCount completion:completion];
            }];
        }
        // 处理视频
        else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            NSLog(@"处理视频");
            [self handleVideoModel:model completion:^(NSURL *url, NSError *error) {
                NSLog(@"处理视频返回：%@  error:%@",url,error);
                [self processResultWithURL:url error:error resultURLs:resultURLs errors:errors semaphore:semaphore remainingCount:&remainingCount completion:completion];
            }];
        }
        // 不支持的类型
        else {
            NSError *error = [NSError errorWithDomain:@"HXPhotoURLConverter" code:1001 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"不支持的媒体类型: %ld", (long)model.subType]}];
            NSLog(@"不支持的类型错误 error:%@",error);
            [self processResultWithURL:nil error:error resultURLs:resultURLs errors:errors semaphore:semaphore remainingCount:&remainingCount completion:completion];
        }
    }
}

#pragma mark - 处理图片模型
+ (void)handlePhotoModel:(HXPhotoModel *)model completion:(void(^)(NSURL *url, NSError *error))completion {
    //优先使用已有的本地URL
    if (model.imageURL) {
        NSLog(@"先使用已有的本地URL:%@",model.imageURL);
        completion(model.imageURL, nil);
        return;
    }
    
    // 从PHAsset获取图片URL（支持iCloud资源）
   
    PHContentEditingInputRequestID requestID = [model requestImageURLStartRequestICloud:^(PHContentEditingInputRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
        NSLog(@"开始从iCloud下载图片...");
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"icloud.and.arrow.down.fill"] status:@"开始从iCloud下载图片..."];
        
        
    } progressHandler:^(double progress, HXPhotoModel * _Nullable model) {
        NSLog(@"图片下载进度: %.2f%%", progress * 100);
        [SVProgressHUD showProgress:progress status:@"图片开始iCloud下载..."];
        
    } success:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
        if (imageURL) {
            [SVProgressHUD showSuccessWithStatus:@"下载完成"];
            [SVProgressHUD dismissWithDelay:1];
            completion(imageURL, nil);
        } else {
            NSError *error = [NSError errorWithDomain:@"HXPhotoURLConverter" code:2001 userInfo:@{NSLocalizedDescriptionKey: @"获取图片URL失败（success回调但URL为空）"}];
            [SVProgressHUD showErrorWithStatus:@"获取图片URL失败（success回调但URL为空"];
            [SVProgressHUD dismissWithDelay:1];
            completion(nil, error);
        }
    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
        completion(nil, [NSError errorWithDomain:@"HXPhotoURLConverter" code:2002 userInfo:@{NSLocalizedDescriptionKey: @"获取图片URL失败"}]);
        [SVProgressHUD showErrorWithStatus:@"获取图片URL失败"];
        [SVProgressHUD dismissWithDelay:1];
    }];
    
    // 保存请求ID，便于需要时取消（可选）
    model.iCloudRequestID = requestID;
}

#pragma mark - 处理视频模型
+ (void)handleVideoModel:(HXPhotoModel *)model completion:(void(^)(NSURL *url, NSError *error))completion {
    // 优先使用已有的本地视频URL
    if (model.videoURL && [model.videoURL.scheme isEqualToString:@"file"]) {
        completion(model.videoURL, nil);
        return;
    }
    
    // 导出视频并获取URL（支持iCloud资源）
    
    [model exportVideoWithPresetName:AVAssetExportPresetHighestQuality startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
        NSLog(@"开始从iCloud下载视频...");
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"icloud.and.arrow.down.fill"] status:@"开始从iCloud下载视频..."];
        [SVProgressHUD dismissWithDelay:1];
        
    } iCloudProgressHandler:^(double progress, HXPhotoModel * _Nullable model) {
        NSLog(@"视频iCloud下载进度: %.2f%%", progress * 100);
        [SVProgressHUD showProgress:progress status:@"视频开始iCloud下载..."];
    } exportProgressHandler:^(float progress, HXPhotoModel * _Nullable model) {
        NSLog(@"视频导出进度: %.2f%%", progress * 100);
        [SVProgressHUD showProgress:progress status:@"视频导出进度"];
    } success:^(NSURL * _Nullable videoURL, HXPhotoModel * _Nullable model) {
        if (videoURL) {
            [SVProgressHUD showSuccessWithStatus:@"导出完成"];
            [SVProgressHUD dismissWithDelay:1];
            completion(videoURL, nil);
        } else {
            NSError *error = [NSError errorWithDomain:@"HXPhotoURLConverter" code:3001 userInfo:@{NSLocalizedDescriptionKey: @"获取视频URL失败（success回调但URL为空）"}];
            [SVProgressHUD showErrorWithStatus:@"获取视频URL失败"];
            [SVProgressHUD dismissWithDelay:1];
            completion(nil, error);
        }
    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
        completion(nil, [NSError errorWithDomain:@"HXPhotoURLConverter" code:3002 userInfo:@{NSLocalizedDescriptionKey: @"获取视频URL失败"}] );
    }];
}

#pragma mark - 处理结果（统一逻辑）
+ (void)processResultWithURL:(NSURL *)url
                       error:(NSError *)error
                  resultURLs:(NSMutableArray<NSURL *> *)resultURLs
                      errors:(NSMutableArray<NSError *> *)errors
                   semaphore:(dispatch_semaphore_t)semaphore
              remainingCount:(NSInteger *)remainingCount
                  completion:(HXPhotoURLConvertCompletion)completion {
    // 加锁，避免多线程修改数组冲突
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (url) {
        [resultURLs addObject:url];
    }
    if (error) {
        [errors addObject:error];
    }
    
    // 计数器减1，检查是否所有模型都处理完成
    (*remainingCount)--;
    if (*remainingCount == 0) {
        // 所有模型处理完成，调用回调
        completion([resultURLs copy], [errors copy]);
    }
    
    // 解锁
    dispatch_semaphore_signal(semaphore);
}


- (Demo9Model *)getAssetModels:(NSArray<NSString *> *)appFileModels{
    NSLog(@"传进来的:%@",appFileModels);
    
    Demo9Model *Models = [[Demo9Model alloc] init];
    
    NSMutableArray *assetModels = [NSMutableArray array];
    
    
    // 创建文件名到URL的映射，用于快速查找缩略图
    NSMutableDictionary<NSString *, NSString *> *fileNameToURLMap = [NSMutableDictionary dictionary];
    for (NSString *urlString in appFileModels) {
        if([urlString containsString:MAIN_File_KEY]) continue;
        NSURL *url = [NSURL URLWithString:urlString];
        NSString *fileName = [url lastPathComponent];
        NSLog(@"封装urlString：%@",urlString);
        [fileNameToURLMap setObject:urlString forKey:fileName];
    }
    
    for (NSString *urlString in appFileModels) {
        
        //排除主图图标
        if([urlString containsString:ICON_KEY]) continue;
        if([urlString containsString:MAIN_File_KEY]) continue;
        
        NSURL *fileURL = [NSURL URLWithString:urlString];
     
        
        // 2. 判断是否为媒体文件（图片/视频）
        if (![self isMediaFileWithURL:fileURL]) {
            NSLog(@"跳过非媒体文件：%@", fileURL);
            continue;
        }
        
        // 排除缩略图文件
        if ([urlString containsString:@"thumbnail"]) {
            NSLog(@"跳过缩略图文件：%@", urlString);
            continue;
        }
        
        if ([self isImageFileWithURL:fileURL]) {
            // 执行封装模型（图片文件）
            HXCustomAssetModel *assetModel = [HXCustomAssetModel assetWithNetworkImageURL:fileURL networkThumbURL:fileURL selected:YES];
            [assetModels addObject:assetModel];
        }
        else if ([self isVideoFileWithURL:fileURL]) {
            // 根据视频文件名查找对应的缩略图
            NSString *thumbnailURLString = nil;
            CGFloat videoDuration = 0;
            
            // 获取视频文件名（不含扩展名）
            NSString *videoNameWithoutExt = [urlString stringByDeletingPathExtension];
            
            // 构建可能的缩略图文件名
            NSString *expectedThumbnailName = [NSString stringWithFormat:@"%@_thumbnail", videoNameWithoutExt];
            
            // 在映射中查找匹配的缩略图
            for (NSString *possibleThumbnailName in fileNameToURLMap.keyEnumerator) {
                if ([possibleThumbnailName containsString:expectedThumbnailName] &&
                    [possibleThumbnailName containsString:@"thumbnail"] &&
                    [self isImageFileWithURL:[NSURL URLWithString:fileNameToURLMap[possibleThumbnailName]]]) {
                    thumbnailURLString = fileNameToURLMap[possibleThumbnailName];
                    
                    // 从缩略图文件名中提取时长信息
                    NSArray *components = [possibleThumbnailName componentsSeparatedByString:@"_thumbnail_"];
                    if (components.count == 2) {
                        NSString *durationPart = [components[1] stringByDeletingPathExtension];
                        videoDuration = [durationPart floatValue];
                        NSLog(@"从文件名提取视频时长: %@ -> %.1f秒", possibleThumbnailName, videoDuration);
                    }
                    break;
                }
            }
            
            // 如果找到缩略图，使用它；否则使用默认值
            NSURL *thumbnailURL = thumbnailURLString ? [NSURL URLWithString:thumbnailURLString] : [NSURL URLWithString:@""];
            
            // 视频（使用找到的缩略图URL和提取的时长）
            HXCustomAssetModel *assetModel = [HXCustomAssetModel assetWithNetworkVideoURL:fileURL
                                                                                videoCoverURL:thumbnailURL
                                                                                videoDuration:videoDuration
                                                                                    selected:YES];
            [assetModels addObject:assetModel];
        }
    }
    
    NSLog(@"最后的媒体数量:%lu", (unsigned long)assetModels.count);
    Models.customAssetModels = assetModels;
    return Models;
}

//填装图片视频文件
- (HXPhotoManager *)getManager:(Demo9Model *)model {
    HXPhotoManager *manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    manager.configuration.maxNum = 12;
    manager.configuration.photoMaxNum = 0;
    manager.configuration.videoMaxNum = 0;
    manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit =YES;//视频过大自动跳转编辑
    manager.configuration.videoMaximumDuration = 60;//视频最大时长
    manager.configuration.saveSystemAblum = YES;//是否保存系统相册
    manager.configuration.lookLivePhoto = YES; //是否开启查看LivePhoto功能呢 - 默认 NO
    manager.configuration.photoCanEdit = YES;
    manager.configuration.photoCanEdit = YES;
    manager.configuration.videoCanEdit = YES;
    manager.configuration.selectTogether = YES;//同时选择视频图片
    manager.configuration.showOriginalBytes =YES;//原图显示大小
    manager.configuration.showOriginalBytesLoading =YES;
    manager.configuration.requestOriginalImage = NO;//默认非圆图
    manager.configuration.clarityScale = 2.0f;
    manager.configuration.allowPreviewDirectLoadOriginalImage =NO;//预览大图时允许不先加载小图，直接加载原图
    manager.configuration.livePhotoAutoPlay =NO;//查看LivePhoto是否自动播放，为NO时需要长按才可播放
    manager.configuration.replacePhotoEditViewController = NO;
    manager.configuration.editAssetSaveSystemAblum = YES;
    manager.configuration.customAlbumName = @"TrollApps";
    
    [manager changeAfterCameraArray:model.endCameraList];
    [manager changeAfterCameraPhotoArray:model.endCameraPhotos];
    [manager changeAfterCameraVideoArray:model.endCameraVideos];
    [manager changeAfterSelectedCameraArray:model.endSelectedCameraList];
    [manager changeAfterSelectedCameraPhotoArray:model.endSelectedCameraPhotos];
    [manager changeAfterSelectedCameraVideoArray:model.endSelectedCameraVideos];
    [manager changeAfterSelectedArray:model.endSelectedList];
    [manager changeAfterSelectedPhotoArray:model.endSelectedPhotos];
    [manager changeAfterSelectedVideoArray:model.endSelectedVideos];
    [manager changeICloudUploadArray:model.iCloudUploadArray];
    
    // 这些操作需要放在manager赋值的后面，不然会出现重用..
    manager.configuration.albumShowMode = HXPhotoAlbumShowModePopup;
    manager.configuration.photoMaxNum = model.customAssetModels.count;
    manager.configuration.videoMaxNum = 1;
    if (!model.addCustomAssetComplete && model.customAssetModels.count) {
        [manager addCustomAssetModel:model.customAssetModels];
        model.addCustomAssetComplete = YES;
    }
    
    // 创建弱引用
    __weak typeof(manager) weakmanager = manager;
    
    manager.configuration.previewRespondsToLongPress = ^(UILongPressGestureRecognizer *longPress, HXPhotoModel *photoModel, HXPhotoManager *manager, HXPhotoPreviewViewController *previewViewController) {
        HXPhotoBottomViewModel *saveModel = [[HXPhotoBottomViewModel alloc] init];
        saveModel.title = @"保存";
        saveModel.customData = photoModel.tempImage;
        [HXPhotoBottomSelectView showSelectViewWithModels:@[saveModel] selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
            
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                if (photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWork ||
                    photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
                    NSSLog(@"需要自行保存网络图片");
                    
//                    return;
                }
            }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                if (photoModel.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                    NSSLog(@"需要自行保存网络视频");
//                    return;
                }
            }
            [previewViewController.view hx_showLoadingHUDText:@"保存中"];
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                [HXPhotoTools savePhotoToCustomAlbumWithName:weakmanager.configuration.customAlbumName photo:model.customData location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                    [previewViewController.view hx_handleLoading];
                    if (success) {
                        [previewViewController.view hx_showImageHUDText:@"保存成功"];
                    }else {
                        [previewViewController.view hx_showImageHUDText:@"保存失败"];
                    }
                }];
            }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                if (photoModel.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                    [[HXPhotoCommon photoCommon] downloadVideoWithURL:photoModel.videoURL progress:nil downloadSuccess:^(NSURL * _Nullable filePath, NSURL * _Nullable videoURL) {
                        [HXPhotoTools saveVideoToCustomAlbumWithName:nil videoURL:filePath location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                            [previewViewController.view hx_handleLoading];
                            if (success) {
                                [previewViewController.view hx_showImageHUDText:@"保存成功"];
                            }else {
                                [previewViewController.view hx_showImageHUDText:@"保存失败"];
                            }
                        }];
                    } downloadFailure:^(NSError * _Nullable error, NSURL * _Nullable videoURL) {
                        [previewViewController.view hx_handleLoading];
                        [previewViewController.view hx_showImageHUDText:@"保存失败"];
                    }];
                    return;
                }
                [HXPhotoTools saveVideoToCustomAlbumWithName:nil videoURL:photoModel.videoURL location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                    [previewViewController.view hx_handleLoading];
                    if (success) {
                        [previewViewController.view hx_showImageHUDText:@"保存成功"];
                    }else {
                        [previewViewController.view hx_showImageHUDText:@"保存失败"];
                    }
                }];
            }
        } cancelClick:nil];
        
    };
    return manager;
    
}

- (BOOL)isImageFileWithURL:(NSURL *)url {
    if (!url) return NO;
    // 常见图片扩展名
    NSArray *imageExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"heic", @"webp", @"bmp"];
    return [self _isFileWithURL:url inExtensions:imageExtensions];
}

- (BOOL)isVideoFileWithURL:(NSURL *)url {
    if (!url) return NO;
    // 常见视频扩展名
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi", @"mkv", @"flv", @"wmv", @"mpeg", @"mpg"];
    return [self _isFileWithURL:url inExtensions:videoExtensions];
}

- (BOOL)isMediaFileWithURL:(NSURL *)url {
    return [self isImageFileWithURL:url] || [self isVideoFileWithURL:url];
}
/// 私有方法：判断URL的扩展名是否在目标列表中
- (BOOL)_isFileWithURL:(NSURL *)url inExtensions:(NSArray<NSString *> *)extensions {
    NSString *ext = url.pathExtension.lowercaseString;
    return [extensions containsObject:ext];
}

@end
