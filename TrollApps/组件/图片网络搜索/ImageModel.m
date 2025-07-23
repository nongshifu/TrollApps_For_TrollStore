//
//  ImageModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "ImageModel.h"

@implementation ImageModel

#pragma mark - 初始化

- (instancetype)initWithImage:(UIImage *)image url:(NSString *)url {
    self = [super init];
    if (self) {
        _image = image;
        _url = url;
        _isSelected = NO; // 默认未选中
    }
    return self;
}

+ (instancetype)modelWithImage:(UIImage *)image url:(NSString *)url {
    return [[self alloc] initWithImage:image url:url];
}

#pragma mark - 数据转换

- (NSDictionary *)toDictionary {
    return @{
        @"image": self.image, // 注意：UIImage对象可直接存入字典，但可能需要特殊处理（见下文）
        @"url": self.url ?: @""
    };
}

+ (instancetype)modelFromDictionary:(NSDictionary *)dict {
    UIImage *image = dict[@"image"];
    NSString *url = dict[@"url"];
    
    if (!image || !url) return nil;
    
    return [self modelWithImage:image url:url];
}

#pragma mark - 描述

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: image=%@, url=%@>",
            NSStringFromClass([self class]),
            self.image ? @"[UIImage]" : @"nil",
            self.url];
}
@end
