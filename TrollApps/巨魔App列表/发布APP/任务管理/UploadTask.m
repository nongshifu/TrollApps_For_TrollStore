//
//  UploadTask.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import "UploadTask.h"

@implementation UploadTask
// 指定fileItems数组的元素类型
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"fileItems" : [UploadFileItem class]};
}

// 如果有属性需要特殊映射，添加到这里
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{};
}

@end
