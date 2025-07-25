//
//  HXPhotoURLConverter.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"
#import "Demo9Model.h"
#import "HXCustomAssetModel.h"
#import "HXPhotoManager.h"

/// URL转换完成的回调
/// @param urls 成功获取的本地文件URL数组（均为file://协议）
/// @param errors 错误信息数组（记录获取失败的模型和原因）
typedef void(^HXPhotoURLConvertCompletion)(NSArray<NSURL *> * _Nonnull urls, NSArray<NSError *> * _Nonnull errors);

@interface HXPhotoURLConverter : NSObject

/// 将HXPhotoModel数组转换为本地文件URL数组
/// @param photoModels 从afterSelectedArray获取的HXPhotoModel数组
/// @param completion 转换完成的回调（异步执行）
+ (void)convertPhotoModelsToURLs:(NSArray<HXPhotoModel *> * _Nonnull)photoModels
                      completion:(HXPhotoURLConvertCompletion _Nonnull)completion;

- (HXPhotoManager * _Nonnull)getManager:(Demo9Model * _Nonnull)model;
- (Demo9Model * _Nonnull)getAssetModels:(NSArray<NSString *> *_Nonnull)appFileModels;

@end
