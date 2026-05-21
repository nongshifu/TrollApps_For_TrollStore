//
//  CellHeightCache.m
//  NewSoulChat
//
//  Created by 十三哥 on 2025/3/13.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "CellHeightCache.h"

@interface CellHeightCache ()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *cellHeightCache;
@end

@implementation CellHeightCache

+ (instancetype)sharedInstance {
    static CellHeightCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CellHeightCache alloc] init];
        instance.cellHeightCache = [NSMutableDictionary dictionary];
    });
    return instance;
}

/**
 生成缓存键
 @param model 模型对象
 @return 缓存键（NSNumber 类型）
 */
+ (NSNumber *)cacheKeyForModel:(id)model {
    if ([model respondsToSelector:@selector(diffIdentifier)]) {
        return @([model diffIdentifier].hash);
    }
    return nil;
}

/**
 缓存高度
 @param model 模型对象
 @param height 高度值
 */
+ (void)cacheHeightForModel:(id)model height:(CGFloat)height {
    NSNumber *key = [self cacheKeyForModel:model];
    if (key) {
        [CellHeightCache sharedInstance].cellHeightCache[key] = @(height);
    }
}

/**
 读取缓存高度
 @param model 模型对象
 @return 缓存的高度值，如果没有缓存则返回 CGFLOAT_MIN
 */
+ (CGFloat)getCachedHeightForModel:(id)model {
    NSNumber *key = [self cacheKeyForModel:model];
    if (key) {
        NSNumber *cachedHeight = [CellHeightCache sharedInstance].cellHeightCache[key];
        if (cachedHeight) {
            return [cachedHeight doubleValue];
        }
    }
    return CGFLOAT_MIN; // 返回一个无效值，表示没有缓存
}

/**
 删除缓存高度
 @param model 模型对象
 */
+ (void)removeCachedHeightForModel:(id)model {
    NSNumber *key = [self cacheKeyForModel:model];
    if (key) {
        [[CellHeightCache sharedInstance].cellHeightCache removeObjectForKey:key];
    }
}

@end
