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

@property (nonatomic, assign) NSInteger key_id;
@property (nonatomic, copy) NSString *config_key;
@property (nonatomic, copy) NSString *config_value;
@property (nonatomic, assign) NSInteger config_type;
@property (nonatomic, copy) NSString *db_description;
@property (nonatomic, assign) BOOL is_required;
@property (nonatomic, assign) NSInteger sort;
@property (nonatomic, copy) NSString *create_time;
@property (nonatomic, copy) NSString *update_time;
@property (nonatomic, assign) NSInteger updated_by;

@property (nonatomic, assign) BOOL isModified; // 新增：标记是否被修改过
@end

NS_ASSUME_NONNULL_END
