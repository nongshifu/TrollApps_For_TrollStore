//
//  BubbleTipManager.h
//  TrollApps
//
//  Created by 十三哥 on 2025/11/28.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BubbleTipManager : NSObject
/// 显示原生气泡提示（自动3秒隐藏）
/// @param text 提示文本
/// @param targetView 气泡箭头指向的目标视图（比如cell中的按钮、label）
/// @param superVC 父控制器（用于present气泡）
+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC;

/// 显示原生气泡提示（可自定义隐藏时间）
/// @param text 提示文本
/// @param targetView 气泡箭头指向的目标视图
/// @param superVC 父控制器
/// @param dismissDelay 自动隐藏时间（秒）
+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC
                 dismissDelay:(NSTimeInterval)dismissDelay;

/// 新增：显示原生气泡提示（自动3秒隐藏，支持自定义箭头方向）
/// @param text 提示文本
/// @param targetView 气泡箭头指向的目标视图
/// @param superVC 父控制器
/// @param arrowDirection 箭头方向（默认 UIPopoverArrowDirectionAny，可指定 Up/Down/Left/Right）
+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC
                arrowDirection:(UIPopoverArrowDirection)arrowDirection;

/// 新增：显示原生气泡提示（可自定义隐藏时间+箭头方向）
/// @param text 提示文本
/// @param targetView 气泡箭头指向的目标视图
/// @param superVC 父控制器
/// @param dismissDelay 自动隐藏时间（秒）
/// @param arrowDirection 箭头方向（默认 UIPopoverArrowDirectionAny，可指定 Up/Down/Left/Right）
+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC
                 dismissDelay:(NSTimeInterval)dismissDelay
                arrowDirection:(UIPopoverArrowDirection)arrowDirection;
@end

NS_ASSUME_NONNULL_END
