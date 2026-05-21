//
//  UILabel+FAK.h
//  TrollApps
//
//  FontAwesomeKit 扩展 - UILabel便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FontAwesomeKit/FontAwesomeKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (FAK)

#pragma mark - 直接设置FAK图标文本

/**
 设置FAK图标到UILabel
 @param icon FAK图标对象
 @param color 图标颜色
 */
- (void)fak_setIcon:(FAKIcon *)icon
              color:(UIColor *)color;

/**
 根据FA图标名称设置图标
 @param iconName 图标名称（如 "fa-gift", "fa-heart"）
 @param color 图标颜色
 */
- (void)fak_setIconWithName:(NSString *)iconName
                      color:(UIColor *)color;

/**
 设置FAK图标+文字
 @param icon FAK图标对象
 @param text 文字
 @param color 颜色
 @param spacing 图标和文字间距
 */
- (void)fak_setIcon:(FAKIcon *)icon
               text:(NSString *)text
              color:(UIColor *)color
            spacing:(CGFloat)spacing;

/**
 根据FA图标名称设置图标+文字
 @param iconName 图标名称
 @param text 文字
 @param color 颜色
 @param spacing 图标和文字间距
 */
- (void)fak_setIconWithName:(NSString *)iconName
                       text:(NSString *)text
                      color:(UIColor *)color
                    spacing:(CGFloat)spacing;

@end

NS_ASSUME_NONNULL_END
