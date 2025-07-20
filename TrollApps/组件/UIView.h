//
//  UIView.h
//  NewSoulChat
//
//  Created by 十三哥 on 2024/12/17.
//  Copyright © 2024 D-James. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN



@interface UIView (GradientBackground)

/**
 *  设置视图的渐变色背景。
 *
 *  @param colors 一个包含 UIColor 类型的数组，用于指定渐变所使用的颜色序列，数组中至少需要包含两个颜色元素，这样才能形成有效的渐变效果。颜色顺序决定了渐变的颜色过渡顺序，例如，若传入 [color1, color2]，则渐变将从 color1 过渡到 color2。
 *  @param alpha  一个 CGFloat 类型的值，用于指定渐变色背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 */
- (void)setGradientBackgroundWithColors:(NSArray<UIColor *> *)colors alpha:(CGFloat)alpha;
/**
 *  设置视图的渐变色背景。
 *
 *  @param colors 一个包含 UIColor 类型的数组，用于指定渐变所使用的颜色序列，数组中至少需要包含两个颜色元素，这样才能形成有效的渐变效果。颜色顺序决定了渐变的颜色过渡顺序，例如，若传入 [color1, color2]，则渐变将从 color1 过渡到 color2。
 *  @param alpha  一个 CGFloat 类型的值，用于指定渐变色背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 *  @param horizontal  一个 BOOL 类型的值，用于指定渐变色左右渐变还是上下渐变。
 */
- (void)setGradientBackgroundWithColors:(NSArray<UIColor *> *)colors alpha:(CGFloat)alpha horizontal:(BOOL)horizontal;
/**
 *  设置视图的渐变色背景。
 *
 *  @param colorCount 渐变色数量 随机颜色生成。
 *  @param alpha  一个 CGFloat 类型的值，用于指定渐变色背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 */
- (void)setRandomGradientBackgroundWithColorCount:(NSInteger)colorCount alpha:(CGFloat)alpha;
/**
 *  设置视图的渐变色背景。
 *
 *  @param colorCount 渐变色数量 随机颜色生成。
 *  @param alpha  一个 CGFloat 类型的值，用于指定渐变色背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 *  @param horizontal  一个 BOOL 类型的值，用于指定渐变色左右渐变还是上下渐变。
 */
- (void)setRandomGradientBackgroundWithColorCount:(NSInteger)colorCount alpha:(CGFloat)alpha horizontal:(BOOL)horizontal;
/**
 *  设置视图的渐变色背景。
 *
 *  @param colorCount 渐变色数量 随机颜色生成。
 *  @param alpha  一个 CGFloat 类型的值，用于指定渐变色背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 *  @param horizontal  一个 BOOL 类型的值，用于指定渐变色左右渐变还是上下渐变。
 *  @param atIndex  插入的视图层级
 */
- (void)setRandomGradientBackgroundWithColorCount:(NSInteger)colorCount alpha:(CGFloat)alpha horizontal:(BOOL)horizontal insertSublayer:(int)atIndex;

/**
 *  设置视图的渐变色背景。
 *
 *  @param colors 渐变色数量 随机颜色生成。
 *  @param alpha  一个 CGFloat 类型的值，用于指定渐变色背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 *  @param horizontal  一个 BOOL 类型的值，用于指定渐变色左右渐变还是上下渐变。
 *  @param atIndex  插入的视图层级
 */
- (void)setGradientBackgroundWithColors:(NSArray<UIColor *> *)colors alpha:(CGFloat)alpha horizontal:(BOOL)horizontal insertSublayer:(int)atIndex;

/**
 *  为视图添加毛玻璃样式的背景，并可设置其透明度。
 *
 *  @param style 一个 UIBlurEffectStyle 类型的枚举值，用于指定毛玻璃的具体模糊样式，可用的样式如下：
 *              - UIBlurEffectStyleExtraLight: 超轻度模糊效果，通常适用于希望背景有轻微模糊以突出前景内容，且整体背景看起来较为明亮、柔和的场景，常用于一些信息展示类界面的背景虚化。
 *              - UIBlurEffectStyleLight: 轻度模糊效果，使背景产生适度模糊，给人一种柔和、朦胧的视觉感受，常用于在亮色背景上添加毛玻璃效果来凸显主要内容，比如在白色或浅色系的视图上应用这种模糊样式来弱化背景干扰。
 *              - UIBlurEffectStyleDark: 重度模糊效果，会让背景变得比较模糊且颜色相对暗沉，适合用于营造出深沉、聚焦的视觉氛围，比如在模态视图或者需要突出显示重要信息的界面中，将底层背景使用这种样式模糊处理，让用户的注意力更集中在前景元素上。
 *              - UIBlurEffectStyleRegular: 常规模糊效果，提供一种适中的模糊程度，具体视觉效果介于轻度和重度模糊之间，可根据实际的界面设计风格和需求来选用，通用性相对较强。
 *              - UIBlurEffectStyleProminent: 显著模糊效果，相比其他样式，会使背景呈现出更强烈的模糊感，可用于需要强调前景元素，且希望背景尽可能虚化的特定设计场景中。
 *              - UIBlurEffectStyleUltraBlur: 超模糊效果，是一种非常强烈的模糊样式，会使背景极度模糊，一般在一些特殊的、追求极致虚化背景以突出核心元素的界面设计中会考虑使用。
 *  @param alpha  一个 CGFloat 类型的值，用于指定毛玻璃背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 */
- (void)setFrostedGlassBackgroundWithStyle:(UIBlurEffectStyle)style alpha:(CGFloat)alpha;


/**
 *  为视图添加毛玻璃样式的背景，并可设置其透明度。 和随机运动的小球
 *  @param count 小球数量
 *  @param radius 小球半径
 *  @param minDuration 最小运动时间
 *  @param maxDuration 最大运动时间
 *  @param style 一个 UIBlurEffectStyle 类型的枚举值，用于指定毛玻璃的具体模糊样式，可用的样式如下：
 *              - UIBlurEffectStyleExtraLight: 超轻度模糊效果，通常适用于希望背景有轻微模糊以突出前景内容，且整体背景看起来较为明亮、柔和的场景，常用于一些信息展示类界面的背景虚化。
 *              - UIBlurEffectStyleLight: 轻度模糊效果，使背景产生适度模糊，给人一种柔和、朦胧的视觉感受，常用于在亮色背景上添加毛玻璃效果来凸显主要内容，比如在白色或浅色系的视图上应用这种模糊样式来弱化背景干扰。
 *              - UIBlurEffectStyleDark: 重度模糊效果，会让背景变得比较模糊且颜色相对暗沉，适合用于营造出深沉、聚焦的视觉氛围，比如在模态视图或者需要突出显示重要信息的界面中，将底层背景使用这种样式模糊处理，让用户的注意力更集中在前景元素上。
 *              - UIBlurEffectStyleRegular: 常规模糊效果，提供一种适中的模糊程度，具体视觉效果介于轻度和重度模糊之间，可根据实际的界面设计风格和需求来选用，通用性相对较强。
 *              - UIBlurEffectStyleProminent: 显著模糊效果，相比其他样式，会使背景呈现出更强烈的模糊感，可用于需要强调前景元素，且希望背景尽可能虚化的特定设计场景中。
 *              - UIBlurEffectStyleUltraBlur: 超模糊效果，是一种非常强烈的模糊样式，会使背景极度模糊，一般在一些特殊的、追求极致虚化背景以突出核心元素的界面设计中会考虑使用。
 *  @param alpha  一个 CGFloat 类型的值，用于指定毛玻璃背景的整体透明度，取值范围是 0.0（完全透明）到 1.0（完全不透明）。
 *  @param ballalpha 小球透明度
 */
- (void)addColorBallsWithCount:(NSUInteger)count ballradius:(CGFloat)radius minDuration:(CGFloat)minDuration maxDuration:(CGFloat)maxDuration UIBlurEffectStyle:(UIBlurEffectStyle)style UIBlurEffectAlpha:(CGFloat)alpha ballalpha:(CGFloat)ballalpha;



/**
 *  为当前视图添加外发光效果
 *
 *  @param color           外发光的颜色
 *  @param shadowOffset    阴影的偏移量，默认为 CGSizeZero 以实现四周扩散效果。
 *                         该参数指定了阴影相对于视图的偏移方向和距离。
 *                         例如，CGSizeMake(0, 0) 表示无偏移，阴影将均匀地围绕视图；
 *                         CGSizeMake(5, 5) 表示阴影向右下方偏移 5 个点。
 *  @param shadowOpacity   阴影的透明度，取值范围为 0.0（完全透明）到 1.0（完全不透明）
 *  @param shadowRadius    阴影的模糊半径，值越大，阴影越模糊、扩散范围越广
 */
- (void)addGlowEffectWithColor:(UIColor *)color
                 shadowOffset:(CGSize)shadowOffset
                shadowOpacity:(CGFloat)shadowOpacity
                 shadowRadius:(CGFloat)shadowRadius;

/**
 *  为当前视图添加外发光效果，阴影偏移量默认设置为 CGSizeZero 以实现四周扩散效果
 *
 *  @param color           外发光的颜色
 *  @param shadowOpacity   阴影的透明度，取值范围为 0.0（完全透明）到 1.0（完全不透明）
 *  @param shadowRadius    阴影的模糊半径，值越大，阴影越模糊、扩散范围越广
 */
- (void)addGlowEffectWithColor:(UIColor *)color
                shadowOpacity:(CGFloat)shadowOpacity
                 shadowRadius:(CGFloat)shadowRadius;

/**
 设置视图四个角的圆角

 @param topLeftRadius 左上角圆角半径
 @param topRightRadius 右上角圆角半径
 @param bottomLeftRadius 左下角圆角半径
 @param bottomRightRadius 右下角圆角半径
 */
- (void)setViewRadiusWithTopLeft:(CGFloat)topLeftRadius
                         topRight:(CGFloat)topRightRadius
                      bottomLeft:(CGFloat)bottomLeftRadius
                     bottomRight:(CGFloat)bottomRightRadius;


///获取顶层视图控制器
- (UIViewController *)getTopViewController;

/// 获取视图所属的视图控制器的方法
- (UIViewController *)getviewController;
///移除动态球
- (void)removeDynamicBackground;


/**
 * 为视图添加四周虚化效果
 * @param radius 虚化半径，控制虚化范围
 */
- (void)addBlurEdgeWithRadius:(CGFloat)radius;

/**
 * 为视图添加四周虚化效果，并指定内部保留区域的圆角
 * @param radius 虚化半径，控制虚化范围
 * @param cornerRadius 内部保留区域的圆角半径
 */
- (void)addBlurEdgeWithRadius:(CGFloat)radius cornerRadius:(CGFloat)cornerRadius;

//获取顶层视图控制器
+ (UIViewController *)getTopViewController;

+ (UIImage *)convertViewToPNG:(UIView *)view;
///渐变色模型
@property (nonatomic, weak) CAGradientLayer *currentGradientLayer;
///渐变色模型
@property (nonatomic, weak) CALayer *colorBallsContainerLayer;

- (void)updateColorBallsPositions;

- (void)showAlertFromViewController:(UIViewController *)viewController
                                  title:(NSString *)title
                            message:(NSString *)message;

- (void)showAlertWithConfirmationFromViewController:(UIViewController *)viewController
                                              title:(NSString *)title
                                            message:(NSString *)message
                                       confirmTitle:(NSString *)confirmTitle
                                        cancelTitle:(NSString *)cancelTitle
                                        onConfirmed:(void (^)(void))onConfirm
                                        onCancelled:(void (^)(void))onCancel;
@end


NS_ASSUME_NONNULL_END
