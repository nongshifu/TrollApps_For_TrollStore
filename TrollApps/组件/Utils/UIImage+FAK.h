//
//  UIImage+FAK.h
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIImage便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FontAwesomeKit/FontAwesomeKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (FAK)

#pragma mark - 从FAK图标创建UIImage

/**
 从FAK图标创建UIImage
 @param icon FAK图标对象
 @param color 图标颜色
 @return UIImage对象
 */
+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          color:(UIColor *)color;

/**
 从FAK图标创建UIImage（指定大小）
 @param icon FAK图标对象
 @param size 图标大小
 @param color 图标颜色
 @return UIImage对象
 */
+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          size:(CGSize)size
                         color:(UIColor *)color;

#pragma mark - 从图标名称创建UIImage

/**
 从图标名称创建UIImage
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param size 图标大小
 @param color 图标颜色
 @return UIImage对象
 */
+ (UIImage *)fak_imageWithIconName:(NSString *)iconName
                              size:(CGFloat)size
                             color:(UIColor *)color;

/**
 从图标名称创建UIImage（指定大小）
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param size 图标大小
 @param color 图标颜色
 @return UIImage对象
 */
+ (UIImage *)fak_imageWithIconName:(NSString *)iconName
                         imageSize:(CGSize)size
                             color:(UIColor *)color;

#pragma mark - 渐变背景图标

/**
 创建带渐变背景的图标
 @param icon FAK图标对象
 @param size 图标大小
 @param iconColor 图标颜色
 @param gradientColors 渐变颜色数组
 @param startPoint 渐变起点
 @param endPoint 渐变终点
 @return UIImage对象
 */
+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          size:(CGSize)size
                     iconColor:(UIColor *)iconColor
                gradientColors:(NSArray<UIColor *> *)gradientColors
                    startPoint:(CGPoint)startPoint
                      endPoint:(CGPoint)endPoint;

/**
 创建带圆角背景的图标
 @param icon FAK图标对象
 @param size 图标大小
 @param iconColor 图标颜色
 @param backgroundColor 背景颜色
 @param cornerRadius 圆角半径
 @return UIImage对象
 */
+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          size:(CGSize)size
                     iconColor:(UIColor *)iconColor
               backgroundColor:(UIColor *)backgroundColor
                  cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
