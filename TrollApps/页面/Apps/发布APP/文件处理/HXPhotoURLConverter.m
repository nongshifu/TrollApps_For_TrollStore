//
//  HXPhotoURLConverter.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/7.
//

#import "HXPhotoURLConverter.h"
#import "SVProgressHUD.h"
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

@end
