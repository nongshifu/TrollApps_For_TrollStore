//
//  SystemViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"
#import "ConfigItem.h"
#import "ConfigField.h"
#import "config.h"
#import "NetworkClient.h"
#import "NewProfileViewController.h"
#import "loadData.h"
NS_ASSUME_NONNULL_BEGIN

@interface SystemViewController : DemoBaseViewController
@property (nonatomic, strong) NSMutableArray<ConfigItem *> *configItems; // 所有配置项

/// 单例实例（全局唯一）
+ (instancetype)sharedInstance;

/// 根据配置键查询对应的ConfigItem
/// @param key 配置键（config_key）
/// @return 匹配的ConfigItem，未找到返回nil
- (ConfigItem *)configItemForKey:(NSString *)key;

/// 主动刷新配置数据（供外部调用）
- (void)refreshConfigData;
/// 从新加载数据
- (void)loadConfigData;
@end

NS_ASSUME_NONNULL_END
