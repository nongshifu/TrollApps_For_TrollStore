//
//  WebToolManager.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "WebToolManager.h"

@interface WebToolManager ()

@property (nonatomic, strong) NSMutableArray<WebToolModel *> *webTools;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIViewController *> *controllerMap;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSDate *> *openTimeMap;

@end

@implementation WebToolManager

// 单例实现
+ (instancetype)sharedManager {
    static WebToolManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _webTools = [NSMutableArray array];
        _controllerMap = [NSMutableDictionary dictionary];
        _openTimeMap = [NSMutableDictionary dictionary];
    }
    return self;
}

// 添加网页工具
- (void)addWebToolWithModel:(WebToolModel *)toolModel
                controller:(UIViewController *)controller {
    if (!toolModel || !controller) {
        return;
    }
    
    NSNumber *toolId = @(toolModel.tool_id);
    
    // 检查是否已存在相同tool_id的工具
    WebToolModel *existingTool = [self getWebToolById:toolModel.tool_id];
    if (existingTool) {
        // 如果存在，更新打开时间
        [self updateOpenTimeForToolId:toolModel.tool_id];
        // 更新控制器
        self.controllerMap[toolId] = controller;
        return;
    }
    
    // 添加到数组
    [self.webTools addObject:toolModel];
    // 存储控制器
    self.controllerMap[toolId] = controller;
    // 记录打开时间
    self.openTimeMap[toolId] = [NSDate date];
    
    // 可以限制数组最大长度，比如只保留最近的10个工具
    if (self.webTools.count > 10) {
        WebToolModel *oldestTool = self.webTools.firstObject;
        [self removeWebToolWithId:oldestTool.tool_id];
    }
}

// 获取所有网页工具（按打开时间排序）
- (NSArray<WebToolModel *> *)getAllWebTools {
    return [self.webTools sortedArrayUsingComparator:^NSComparisonResult(WebToolModel *obj1, WebToolModel *obj2) {
        NSDate *time1 = self.openTimeMap[@(obj1.tool_id)];
        NSDate *time2 = self.openTimeMap[@(obj2.tool_id)];
        
        if (!time1 || !time2) {
            return NSOrderedSame;
        }
        
        return [time2 compare:time1]; // 最新的在前面
    }];
}

// 根据tool_id获取网页工具
- (WebToolModel *)getWebToolById:(NSInteger)toolId {
    for (WebToolModel *tool in self.webTools) {
        if (tool.tool_id == toolId) {
            return tool;
        }
    }
    return nil;
}

// 根据索引获取网页工具
- (WebToolModel *)getWebToolAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.webTools.count) {
        return self.webTools[index];
    }
    return nil;
}

// 获取工具对应的控制器
- (UIViewController *)getControllerForToolId:(NSInteger)toolId {
    return self.controllerMap[@(toolId)];
}

// 切换到指定tool_id的网页工具
- (void)switchToWebToolWithId:(NSInteger)toolId inNavigationController:(UINavigationController *)navController {
    WebToolModel *tool = [self getWebToolById:toolId];
    UIViewController *controller = [self getControllerForToolId:toolId];
    
    if (tool && controller && navController) {
        // 更新打开时间
        [self updateOpenTimeForToolId:toolId];
        
        // 如果控制器已经在导航栈中，将其弹出到该控制器
        for (UIViewController *vc in navController.viewControllers) {
            if (vc == controller) {
                [navController popToViewController:vc animated:YES];
                return;
            }
        }
        
        // 如果控制器不在导航栈中，将其推入
        [navController pushViewController:controller animated:YES];
    }
}

// 切换到指定索引的网页工具
- (void)switchToWebToolAtIndex:(NSInteger)index inNavigationController:(UINavigationController *)navController {
    WebToolModel *tool = [self getWebToolAtIndex:index];
    if (tool) {
        [self switchToWebToolWithId:tool.tool_id inNavigationController:navController];
    }
}

// 更新工具的打开时间
- (void)updateOpenTimeForToolId:(NSInteger)toolId {
    self.openTimeMap[@(toolId)] = [NSDate date];
}

// 移除指定tool_id的网页工具
- (void)removeWebToolWithId:(NSInteger)toolId {
    WebToolModel *tool = [self getWebToolById:toolId];
    if (tool) {
        [self.webTools removeObject:tool];
        [self.controllerMap removeObjectForKey:@(toolId)];
        [self.openTimeMap removeObjectForKey:@(toolId)];
    }
}

// 移除所有网页工具
- (void)removeAllWebTools {
    [self.webTools removeAllObjects];
    [self.controllerMap removeAllObjects];
    [self.openTimeMap removeAllObjects];
}

@end
