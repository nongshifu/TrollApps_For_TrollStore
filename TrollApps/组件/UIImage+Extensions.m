//
//  UIImage+Extensions.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/12.
//

#import "UIImage+Extensions.h"
#import <Photos/Photos.h>
@implementation UIImage (Extensions)

#pragma mark - 初始化方法
+ (nullable UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setFill];
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - 图像调整
- (nullable UIImage *)resizedImageToSize:(CGSize)targetSize contentMode:(UIViewContentMode)contentMode {
    CGSize imageSize = self.size;
    CGFloat widthRatio = targetSize.width / imageSize.width;
    CGFloat heightRatio = targetSize.height / imageSize.height;
    CGFloat scaleFactor = 0.0;
    
    switch (contentMode) {
        case UIViewContentModeScaleAspectFit:
            scaleFactor = MIN(widthRatio, heightRatio);
            break;
        case UIViewContentModeScaleAspectFill:
            scaleFactor = MAX(widthRatio, heightRatio);
            break;
        default:
            scaleFactor = 1.0;
            break;
    }
    
    CGFloat scaledWidth = imageSize.width * scaleFactor;
    CGFloat scaledHeight = imageSize.height * scaleFactor;
    CGPoint thumbnailPoint = CGPointMake((targetSize.width - scaledWidth) * 0.5,
                                         (targetSize.height - scaledHeight) * 0.5);
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    [self drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (nullable UIImage *)croppedImageWithRect:(CGRect)rect {
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

#pragma mark - 图像效果

- (nullable UIImage *)grayscaleImage {
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef context = CGBitmapContextCreate(nil,
                                                  imageRect.size.width,
                                                  imageRect.size.height,
                                                  8, // 8 bits per component
                                                  0,
                                                  colorSpace,
                                                  kCGImageAlphaNone);
    
    CGContextDrawImage(context, imageRect, self.CGImage);
    CGImageRef grayImageRef = CGBitmapContextCreateImage(context);
    UIImage *grayImage = [UIImage imageWithCGImage:grayImageRef];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(grayImageRef);
    
    return grayImage;
}

- (nullable UIImage *)blurredImageWithRadius:(CGFloat)radius {
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:self.CGImage];
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:inputImage forKey:kCIInputImageKey];
    [blurFilter setValue:@(radius) forKey:@"inputRadius"];
    
    CIImage *outputImage = [blurFilter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[inputImage extent]];
    UIImage *blurredImage = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    return blurredImage;
}

#pragma mark - 图像保存
- (void)saveToPhotosAlbumWithCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImage:self];
        [request placeholderForCreatedAsset];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    }];
}

#pragma mark - 主题支持

+ (UIImage *)imageWithLightImage:(UIImage *)lightImage darkImage:(UIImage *)darkImage {
    if (@available(iOS 13.0, *)) {
        UIImageAsset *imageAsset = [[UIImageAsset alloc] init];
        
        // 注册浅色模式图片
        [imageAsset registerImage:lightImage withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        
        // 注册深色模式图片
        [imageAsset registerImage:darkImage withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        
        // 返回可以自动适应主题的图片
        return [imageAsset imageWithTraitCollection:[UITraitCollection currentTraitCollection]];
    } else {
        return lightImage;
    }
}

@end
