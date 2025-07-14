//
//  UploadFileItem.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import "UploadFileItem.h"

@implementation UploadFileItem
// 指定容器属性的泛型类型（如果有嵌套容器）
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{};
}

// 如果属性名与JSON键不匹配，需要指定映射关系
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{};
}
@end
