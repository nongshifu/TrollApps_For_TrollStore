//
//  UIImage+FAK.m
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIImage便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "UIImage+FAK.h"
#import "UIView+FAK.h"

@implementation UIImage (FAK)

#pragma mark - 从FAK图标创建UIImage

+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          color:(UIColor *)color {
    CGFloat size = icon.iconSize ?: 30.0;
    return [self fak_imageWithIcon:icon size:CGSizeMake(size, size) color:color];
}

+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          size:(CGSize)size
                         color:(UIColor *)color {
    [icon addAttribute:NSForegroundColorAttributeName value:color];
    icon.iconSize = size.width;
    return [icon imageWithSize:size];
}

#pragma mark - 从图标名称创建UIImage

+ (UIImage *)fak_imageWithIconName:(NSString *)iconName
                              size:(CGFloat)size
                             color:(UIColor *)color {
    return [self fak_imageWithIconName:iconName
                             imageSize:CGSizeMake(size, size)
                                 color:color];
}

+ (UIImage *)fak_imageWithIconName:(NSString *)iconName
                         imageSize:(CGSize)size
                             color:(UIColor *)color {
    FAKIcon *icon = [UIView fak_iconWithName:iconName size:size.width];
    if (!icon) {
        return nil;
    }
    return [self fak_imageWithIcon:icon size:size color:color];
}

#pragma mark - 渐变背景图标

+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          size:(CGSize)size
                     iconColor:(UIColor *)iconColor
                gradientColors:(NSArray<UIColor *> *)gradientColors
                    startPoint:(CGPoint)startPoint
                      endPoint:(CGPoint)endPoint {
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 绘制渐变背景
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    NSMutableArray *colors = [NSMutableArray array];
    for (UIColor *color in gradientColors) {
        [colors addObject:(id)color.CGColor];
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(context, gradient,
                                CGPointMake(startPoint.x * size.width, startPoint.y * size.height),
                                CGPointMake(endPoint.x * size.width, endPoint.y * size.height),
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    // 绘制图标
    UIImage *iconImage = [self fak_imageWithIcon:icon size:size color:iconColor];
    [iconImage drawInRect:rect];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

+ (UIImage *)fak_imageWithIcon:(FAKIcon *)icon
                          size:(CGSize)size
                     iconColor:(UIColor *)iconColor
               backgroundColor:(UIColor *)backgroundColor
                  cornerRadius:(CGFloat)cornerRadius {
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 绘制背景
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    [backgroundColor setFill];
    [path fill];
    
    // 绘制图标
    UIImage *iconImage = [self fak_imageWithIcon:icon size:size color:iconColor];
    [iconImage drawInRect:rect];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

@end
