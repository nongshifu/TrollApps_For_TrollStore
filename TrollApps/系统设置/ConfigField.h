//
//  ConfigField.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <YYModel/YYModel.h>
NS_ASSUME_NONNULL_BEGIN

@interface ConfigField : NSObject <YYModel>
@property (nonatomic, copy) NSString *fieldName; // 字段名称
@property (nonatomic, copy) NSString *fieldKey;  // 字段键
@property (nonatomic, copy) NSString *value;     // 字段值
@property (nonatomic, assign) BOOL editable;     // 是否可编辑
@end

NS_ASSUME_NONNULL_END
