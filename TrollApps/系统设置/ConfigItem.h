//
//  ConfigItem.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>
NS_ASSUME_NONNULL_BEGIN

@interface ConfigItem : NSObject<YYModel>
///id
@property (nonatomic, assign) NSInteger key_id;
/// 配置建KEY
@property (nonatomic, copy) NSString *config_key;
/// 配置建值
@property (nonatomic, copy) NSString *config_value;
/// 配置类型
@property (nonatomic, assign) NSInteger config_type;
/// 配置简介
@property (nonatomic, copy) NSString *db_description;
/// 配置是否必填
@property (nonatomic, assign) BOOL is_required;
/// 配置是排序权重
@property (nonatomic, assign) NSInteger sort;
/// 配置创建时间
@property (nonatomic, copy) NSString *create_time;
/// 配置更新时间
@property (nonatomic, copy) NSString *update_time;
@property (nonatomic, assign) NSInteger updated_by;
/// 新增：标记是否被修改过
@property (nonatomic, assign) BOOL isModified;
@end

NS_ASSUME_NONNULL_END
