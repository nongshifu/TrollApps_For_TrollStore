//
//  UIView+FAK.h
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIView便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FontAwesomeKit/FontAwesomeKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (FAK)

#pragma mark - 设置FAK图标到视图

/**
 给当前UIView设置FAK图标背景
 @param icon FAK图标对象
 @param size 图标大小
 @param color 图标颜色
 */
- (void)fak_setIcon:(FAKIcon *)icon
               size:(CGSize)size
              color:(UIColor *)color;

/**
 给当前UIView设置FAK图标背景（使用图标大小）
 @param icon FAK图标对象
 @param color 图标颜色
 */
- (void)fak_setIcon:(FAKIcon *)icon
              color:(UIColor *)color;

#pragma mark - 根据图标名称设置

/**
 根据FA图标名称设置图标
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param size 图标大小
 @param color 图标颜色
 */
- (void)fak_setIconWithName:(NSString *)iconName
                       size:(CGSize)size
                      color:(UIColor *)color;

/**
 根据FA图标名称设置图标（使用图标大小）
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param color 图标颜色
 */
- (void)fak_setIconWithName:(NSString *)iconName
                      color:(UIColor *)color;

#pragma mark - 获取FAK图标对象

/**
 根据图标名称获取FAKIcon对象
 @param iconName 图标名称
 @param size 图标大小
 @return FAKIcon对象
 */
+ (FAKIcon *)fak_iconWithName:(NSString *)iconName
                         size:(CGFloat)size;

/**
 根据图标名称获取UIImage
 @param iconName 图标名称
 @param size 图标大小
 @param color 图标颜色
 @return UIImage对象
 */
+ (UIImage *)fak_imageWithIconName:(NSString *)iconName
                              size:(CGFloat)size
                             color:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
