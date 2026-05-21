//
//  ColorGenerator.h
//  SoulChat
//
//  Created by 十三哥 on 2023/12/14.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "config.h"

NS_ASSUME_NONNULL_BEGIN

/// 定义色调枚举类型
typedef NS_ENUM(NSInteger, ColorType) {
    /// 粉色调
    PinkColor,
    /// 暖色调
    WarmColor,
    /// 亮色调
    BrightColor,
    /// 暗色调
    DarkColor,
    /// 主题切换色
    SystemBackageColor,
    ///随机色
    randomColor
};

///集成颜色工具
@interface UIColor (myColor)

///任意随机单色
+ (UIColor *)randomColorWithAlpha:(CGFloat)alpha;

///随机粉色 单色
+ (UIColor *)randomPinkColor:(CGFloat)alpha;
///随机暖色 单色
+ (UIColor *)randomWarmColor:(CGFloat)alpha;
///随机明亮色 单色
+ (UIColor *)randomBrightColor:(CGFloat)alpha;
///随机黑暗色 单色
+ (UIColor *)randomDarkColor:(CGFloat)alpha;

///渐变主题切换背景色
+ (NSArray<UIColor *> *)randomSystemBackageColorsWithSize:(NSUInteger)size alpha:(CGFloat)alpha;

////获取反差色
+ (UIColor *)getContrastColorForBackground:(UIColor *)backgroundColor;

///给视图添加渐变色 参数 渐变色数量 透明度 视图对象 色调
+ (void)setColor:(NSUInteger)arrSize desiredAlpha:(CGFloat)alpha uiview:(UIView*)uiview ColorType:(ColorType)type;


/// 给视图添加多个随机渐变色<随机方向> 参数:  颜色数量 透明度 和需要添加背景色的视图 颜色类型
+ (void)setRandomGradientWithColorCount:(NSUInteger)colorCount desiredAlpha:(CGFloat)alpha forView:(UIView *)view ColorType:(ColorType)type;

/// 给视图添加 动态球毛-玻璃视图背景  参数：传入小球数量 ，半径 ，需要添加背景的视图， 小球屏幕中运动动画最小时间，最大时间
+ (void)addColorBallsWithCount:(NSUInteger)count ballradius:(CGFloat)radius toView:(UIView *)view minDuration:(CGFloat)minDuration maxDuration:(CGFloat)maxDuration UIBlurEffect:(CGFloat)alpha ballalpha:(CGFloat)ballalpha;

/// 渐变色
- (void)colorGradientFrom:(UIColor*)color0 toColor:(UIColor*)color1 startP:(CGPoint)point0 EndP:(CGPoint)point1 SubView:(UIView*)subView;

///双主题颜色
+ (UIColor *)colorWithLightColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor;

/// 字符串转颜色 #34C759
+ (UIColor *)colorWithHexString:(NSString *)hexString;
@end

NS_ASSUME_NONNULL_END
