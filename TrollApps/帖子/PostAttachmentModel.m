//
//  PostAttachmentModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/31.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "PostAttachmentModel.h"

@implementation PostAttachmentModel

/// YYModel 自动映射（字段名和数据库/接口一致，可省略，此处仅示例扩展场景）
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        // 若接口字段和模型字段不一致，可在这里映射，比如接口是attachId → 模型attachment_id
        // @"attachment_id": @"attachId"
    };
}

@end
