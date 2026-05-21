//
//  UIImageView+FAK.h
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIImageView便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FontAwesomeKit/FontAwesomeKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (FAK)

#pragma mark - 直接设置FAK图标

/**
 设置FAK图标到UIImageView
 @param icon FAK图标对象
 @param color 图标颜色
 */
- (void)fak_setIcon:(FAKIcon *)icon
              color:(UIColor *)color;

/**
 设置FAK图标到UIImageView（指定大小）
 @param icon FAK图标对象
 @param size 图标大小
 @param color 图标颜色
 */
- (void)fak_setIcon:(FAKIcon *)icon
               size:(CGSize)size
              color:(UIColor *)color;

#pragma mark - 根据图标名称设置

/**
 根据FA图标名称设置图标
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param color 图标颜色
 */
- (void)fak_setIconWithName:(NSString *)iconName
                      color:(UIColor *)color;

/**
 根据FA图标名称设置图标（指定大小）
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param size 图标大小
 @param color 图标颜色
 */
- (void)fak_setIconWithName:(NSString *)iconName
                       size:(CGSize)size
                      color:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
