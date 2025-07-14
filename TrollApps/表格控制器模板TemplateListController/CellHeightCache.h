//
//  CellHeightCache.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/3/13.
//  Copyright © 2025 D-James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"


NS_ASSUME_NONNULL_BEGIN

@interface CellHeightCache : NSObject

/**
 缓存高度
 @param model 模型对象（需实现 `diffIdentifier` 方法）
 @param height 高度值
 */
+ (void)cacheHeightForModel:(id)model height:(CGFloat)height;

/**
 读取缓存高度
 @param model 模型对象（需实现 `diffIdentifier` 方法）
 @return 缓存的高度值，如果没有缓存则返回 CGFLOAT_MIN
 */
+ (CGFloat)getCachedHeightForModel:(id)model;

/**
 删除缓存高度
 @param model 模型对象（需实现 `diffIdentifier` 方法）
 */
+ (void)removeCachedHeightForModel:(id)model;

@end

NS_ASSUME_NONNULL_END


