//
//  ImageModel.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "ImageModel.h"
#import <UIKit/UIKit.h>
#import <SDWebImage.h>
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
    ImageModel * model = [[self alloc] initWithImage:image url:url];
    model.localUrl = [self getLocalFileURLWithImageModel:model];
    return model;
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

+ (NSURL *)getLocalFileURLWithImageModel:(ImageModel *)model {
    if (!model || !model.url) {
        NSLog(@"ImageModel或URL为空");
        return nil;
    }
    
    NSString *urlStr = model.url;
    UIImage *image = model.image;
    NSURL *imageURL = [NSURL URLWithString:urlStr];
    
    // 1. 尝试获取SDWebImage的缓存路径
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:imageURL];
    NSString *sdCachePath = [[SDImageCache sharedImageCache] cachePathForKey:cacheKey];
    
    // 2. 判断SD缓存是否存在，并获取格式后缀
    NSString *fileExtension = [self _getImageExtensionWithURL:imageURL image:image];
    NSURL *localURL = [self _getValidLocalURLWithOriginalPath:sdCachePath
                                                  extension:fileExtension
                                                       image:image
                                                        url:urlStr];
    
    return localURL;
}

#pragma mark - 私有方法：获取图片格式后缀
+ (NSString *)_getImageExtensionWithURL:(NSURL *)url image:(UIImage *)image {
    // 从URL提取后缀
    NSString *extension = [url pathExtension].lowercaseString;
    if ([self _isValidImageExtension:extension]) {
        return extension;
    }
    
    // 从图片数据识别格式
    if (image) {
        NSData *imageData = UIImagePNGRepresentation(image);
        if (imageData && [self _isPNGData:imageData]) {
            return @"png";
        } else {
            return @"jpg"; // 默认JPG
        }
    }
    
    return @"jpg"; // 最终默认
}

#pragma mark - 私有方法：验证有效图片后缀
+ (BOOL)_isValidImageExtension:(NSString *)extension {
    NSSet *validExtensions = [NSSet setWithObjects:@"png", @"jpg", @"jpeg", @"gif", @"webp", nil];
    return extension.length > 0 && [validExtensions containsObject:extension];
}

#pragma mark - 私有方法：判断是否为PNG数据
+ (BOOL)_isPNGData:(NSData *)data {
    if (data.length < 8) return NO;
    uint8_t header[8];
    [data getBytes:header length:8];
    // PNG文件头标识：89 50 4E 47 0D 0A 1A 0A
    return header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47;
}

#pragma mark - 私有方法：获取有效的本地URL（带后缀）
+ (NSURL *)_getValidLocalURLWithOriginalPath:(NSString *)originalPath
                                   extension:(NSString *)extension
                                        image:(UIImage *)image
                                         url:(NSString *)urlStr {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 处理SD缓存路径（添加后缀）
    if (originalPath && [fm fileExistsAtPath:originalPath]) {
        NSString *sdPathWithExt = [originalPath stringByAppendingPathExtension:extension];
        // 若带后缀的文件不存在，则复制一份
        if (![fm fileExistsAtPath:sdPathWithExt]) {
            [fm copyItemAtPath:originalPath toPath:sdPathWithExt error:nil];
        }
        return [NSURL fileURLWithPath:sdPathWithExt];
    }
    
    // SD缓存不存在，手动缓存图片到本地
    return [self _saveImageToLocal:image urlStr:urlStr extension:extension];
}

#pragma mark - 私有方法：手动缓存图片到本地
+ (NSURL *)_saveImageToLocal:(UIImage *)image urlStr:(NSString *)urlStr extension:(NSString *)extension {
    if (!image) return nil;
    
    // 生成时间戳文件名（避免重复）
    NSString *timestamp = [NSString stringWithFormat:@"%lld", (long long)[[NSDate date] timeIntervalSince1970] * 1000];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", timestamp, extension];
    
    // 保存路径：沙盒Caches/ImageCache
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *saveDir = [cacheDir stringByAppendingPathComponent:@"ImageCache"];
   
    [[NSFileManager defaultManager] createDirectoryAtPath:saveDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *savePath = [saveDir stringByAppendingPathComponent:fileName];
    
    // 写入图片数据
    NSData *imageData = ([extension isEqualToString:@"png"]) ? UIImagePNGRepresentation(image) : UIImageJPEGRepresentation(image, 0.9);
    [imageData writeToFile:savePath atomically:YES];
    
    return [NSURL fileURLWithPath:savePath];
}

@end
