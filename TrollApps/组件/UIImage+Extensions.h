//
//  UIImage+Extensions.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Extensions)
#pragma mark - 初始化方法
/**
 * 从颜色创建图像
 * @param color 图像颜色
 * @param size 图像尺寸，默认为 1x1
 * @return 图像对象
 */
+ (nullable UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

#pragma mark - 图像调整
/**
 * 调整图像尺寸
 * @param targetSize 目标尺寸
 * @param contentMode 内容模式，默认为 UIViewContentModeScaleAspectFit
 * @return 调整后的图像
 */
- (nullable UIImage *)resizedImageToSize:(CGSize)targetSize contentMode:(UIViewContentMode)contentMode;

/**
 * 裁剪图像
 * @param rect 裁剪区域
 * @return 裁剪后的图像
 */
- (nullable UIImage *)croppedImageWithRect:(CGRect)rect;

#pragma mark - 图像效果

/**
 * 应用灰度效果
 * @return 灰度图像
 */
- (nullable UIImage *)grayscaleImage;

/**
 * 应用模糊效果
 * @param radius 模糊半径
 * @return 模糊后的图像
 */
- (nullable UIImage *)blurredImageWithRadius:(CGFloat)radius;

#pragma mark - 图像保存
/**
 * 保存图像到相册
 * @param completion 完成回调，成功与否及错误信息
 */
- (void)saveToPhotosAlbumWithCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;

#pragma mark - 主题支持
/**
 * 获取主题相关图像
 * @param lightImage 浅色模式图像
 * @param darkImage 深色模式图像
 * @return 支持主题的图像
 */
+ (UIImage *)imageWithLightImage:(UIImage *)lightImage darkImage:(UIImage *)darkImage;

@end

NS_ASSUME_NONNULL_END
