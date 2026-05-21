//
//  UIButton+FAK.h
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIButton便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FontAwesomeKit/FontAwesomeKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (FAK)

#pragma mark - 设置按钮图标

/**
 设置按钮图标
 @param icon FAK图标对象
 @param state 按钮状态
 @param color 图标颜色
 */
- (void)fak_setIcon:(FAKIcon *)icon
            forState:(UIControlState)state
              color:(UIColor *)color;

/**
 根据FA图标名称设置按钮图标
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param state 按钮状态
 @param color 图标颜色
 */
- (void)fak_setIconWithName:(NSString *)iconName
                  forState:(UIControlState)state
                     color:(UIColor *)color;

/**
 设置按钮图标+文字（左右布局）
 @param icon FAK图标对象
 @param title 文字
 @param state 按钮状态
 @param color 颜色
 @param spacing 图标和文字间距
 */
- (void)fak_setIcon:(FAKIcon *)icon
               title:(NSString *)title
            forState:(UIControlState)state
              color:(UIColor *)color
            spacing:(CGFloat)spacing;

/**
 根据FA图标名称设置按钮图标+文字（左右布局）
 @param iconName 图标名称
 @param title 文字
 @param state 按钮状态
 @param color 颜色
 @param spacing 图标和文字间距
 */
- (void)fak_setIconWithName:(NSString *)iconName
                      title:(NSString *)title
                   forState:(UIControlState)state
                      color:(UIColor *)color
                    spacing:(CGFloat)spacing;

@end

NS_ASSUME_NONNULL_END
