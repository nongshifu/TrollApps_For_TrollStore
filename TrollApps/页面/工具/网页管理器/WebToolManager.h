//
//  WebToolManager.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebToolModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WebToolManager : NSObject
/// 获取单例实例
+ (instancetype)sharedManager;

/// 添加网页工具
- (void)addWebToolWithModel:(WebToolModel *)toolModel
                controller:(UIViewController *)controller;

/// 获取所有网页工具
- (NSArray<WebToolModel *> *)getAllWebTools;

/// 根据tool_id获取网页工具
- (WebToolModel *)getWebToolById:(NSInteger)toolId;

/// 根据索引获取网页工具
- (WebToolModel *)getWebToolAtIndex:(NSInteger)index;

/// 获取工具对应的控制器
- (UIViewController *)getControllerForToolId:(NSInteger)toolId;

/// 切换到指定tool_id的网页工具
- (void)switchToWebToolWithId:(NSInteger)toolId inNavigationController:(UINavigationController *)navController;

/// 切换到指定索引的网页工具
- (void)switchToWebToolAtIndex:(NSInteger)index inNavigationController:(UINavigationController *)navController;

/// 更新工具的打开时间
- (void)updateOpenTimeForToolId:(NSInteger)toolId;

/// 移除指定tool_id的网页工具
- (void)removeWebToolWithId:(NSInteger)toolId;

/// 移除所有网页工具
- (void)removeAllWebTools;

@end

NS_ASSUME_NONNULL_END
