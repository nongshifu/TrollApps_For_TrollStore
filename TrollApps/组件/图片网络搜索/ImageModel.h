//
//  ImageModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageModel : NSObject

@property (nonatomic, strong) UIImage *image;       // 图片对象
@property (nonatomic, copy) NSString *url;          // 图片URL
@property (nonatomic, assign) BOOL isSelected;      // 是否选中（可选，用于多选状态管理）
@property (nonatomic, strong) NSURL *localUrl;      // 本地URL
// 初始化方法
- (instancetype)initWithImage:(UIImage *)image url:(NSString *)url;
+ (instancetype)modelWithImage:(UIImage *)image url:(NSString *)url;

// 转换为字典（用于存储或传输）
- (NSDictionary *)toDictionary;

// 从字典创建模型
+ (instancetype)modelFromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
