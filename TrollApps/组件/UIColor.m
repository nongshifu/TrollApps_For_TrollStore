//
//  ColorGenerator.m
//  SoulChat
//
//  Created by 十三哥 on 2023/12/14.
//
#import <UIKit/UIKit.h>
#import "UIColor.h"

@implementation UIColor(myColor)

//任意随机色
+ (UIColor *)randomColorWithAlpha:(CGFloat)alpha {
    CGFloat red = (CGFloat)arc4random_uniform(256) / 255.0;
    CGFloat green = (CGFloat)arc4random_uniform(256) / 255.0;
    CGFloat blue = (CGFloat)arc4random_uniform(256) / 255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}
// 随机冷色调
+ (UIColor *)randomPinkColor:(CGFloat)alpha {
    // 冷色调通常蓝色和绿色分量较高
    CGFloat red = ((float)arc4random_uniform(100) / 255.0); // 较低的红色值
    CGFloat green = ((float)arc4random_uniform(150) + 100) / 255.0; // 较高的绿色值
    CGFloat blue = ((float)arc4random_uniform(150) + 100) / 255.0; // 较高的蓝色值
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

// 随机暖色调
+ (UIColor *)randomWarmColor:(CGFloat)alpha {
    // 暖色调通常红色和黄色分量较高
    CGFloat red = ((float)arc4random_uniform(150) + 100) / 255.0; // 较高的红色值
    CGFloat green = ((float)arc4random_uniform(150) + 50) / 255.0; // 中等的绿色值
    CGFloat blue = ((float)arc4random_uniform(100)) / 255.0; // 较低的蓝色值
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

// 随机亮色调
+ (UIColor *)randomBrightColor:(CGFloat)alpha {
    // 亮色调通常各分量值较高
    CGFloat red = ((float)arc4random_uniform(100) + 155) / 255.0; // 较高的红色值
    CGFloat green = ((float)arc4random_uniform(100) + 155) / 255.0; // 较高的绿色值
    CGFloat blue = ((float)arc4random_uniform(100) + 155) / 255.0; // 较高的蓝色值
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

// 随机黑暗色调
+ (UIColor *)randomDarkColor:(CGFloat)alpha {
    // 黑暗色调通常各分量值较低
    CGFloat red = ((float)arc4random_uniform(100)) / 255.0; // 较低的红色值
    CGFloat green = ((float)arc4random_uniform(100)) / 255.0; // 较低的绿色值
    CGFloat blue = ((float)arc4random_uniform(100)) / 255.0; // 较低的蓝色值
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

//取渐变色数组
+ (NSArray<UIColor *> *)randomGradientColorsFromColor:(UIColor *)startColor toColor:(UIColor *)endColor withSize:(NSUInteger)size alpha:(CGFloat)alpha {
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:size];
    
    
    const CGFloat *startComponents = CGColorGetComponents(startColor.CGColor);
    const CGFloat *endComponents = CGColorGetComponents(endColor.CGColor);
    
    for (NSUInteger i = 0; i < size; i++) {
        CGFloat ratio = (CGFloat)i / (size - 1);
        
        CGFloat red = startComponents[0] + (endComponents[0] - startComponents[0]) * ratio;
        CGFloat green = startComponents[1] + (endComponents[1] - startComponents[1]) * ratio;
        CGFloat blue = startComponents[2] + (endComponents[2] - startComponents[2]) * ratio;
        
        UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [colors addObject:color];
    }
    
    return [colors copy];
}

//渐变的暖色
+ (NSArray<UIColor *> *)randomWarmGradientColorsWithSize:(NSUInteger)size alpha:(CGFloat)alpha {
    UIColor *startColor = [self randomWarmColor:alpha];
    UIColor *endColor = [self randomWarmColor:alpha];
    
    return [self randomGradientColorsFromColor:startColor toColor:endColor withSize:size alpha:alpha];
}
//渐变的暖色
+ (NSArray<UIColor *> *)randomPinkGradientColorsWithSize:(NSUInteger)size alpha:(CGFloat)alpha {
    UIColor *startColor = [self randomWarmColor:alpha];
    UIColor *endColor = [self randomWarmColor:alpha];
    
    return [self randomGradientColorsFromColor:startColor toColor:endColor withSize:size alpha:alpha];
}
//渐变的亮色
+ (NSArray<UIColor *> *)randomBrightGradientColorsWithSize:(NSUInteger)size alpha:(CGFloat)alpha {
    UIColor *startColor = [self randomBrightColor:alpha];
    UIColor *endColor = [self randomBrightColor:alpha];
    
    return [self randomGradientColorsFromColor:startColor toColor:endColor withSize:size alpha:alpha];
}
//渐变的黑暗色
+ (NSArray<UIColor *> *)randomDarkGradientColorsWithSize:(NSUInteger)size alpha:(CGFloat)alpha {
    UIColor *startColor = [self randomDarkColor:alpha];
    UIColor *endColor = [self randomDarkColor:alpha];
    
    return [self randomGradientColorsFromColor:startColor toColor:endColor withSize:size alpha:alpha];
}
//渐变主题切换背景色
+ (NSArray<UIColor *> *)randomSystemBackageColorsWithSize:(NSUInteger)size alpha:(CGFloat)alpha {
    UIColor *startColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:alpha];
    UIColor *endColor = [[UIColor tertiarySystemBackgroundColor] colorWithAlphaComponent:alpha];
    
    return [self randomGradientColorsFromColor:startColor toColor:endColor withSize:size alpha:alpha];
}
//随机色
+ (NSArray<UIColor *> *)randomColorsWithSize:(NSUInteger)size alpha:(CGFloat)alpha {
    UIColor *startColor = [self randomColorWithAlpha:alpha];
    UIColor *endColor = [self randomColorWithAlpha:alpha];
    
    return [self randomGradientColorsFromColor:startColor toColor:endColor withSize:size alpha:alpha];
}

//获取反差色
+ (UIColor *)getContrastColorForBackground:(UIColor *)backgroundColor {
    CGFloat r, g, b, a;
    [backgroundColor getRed:&r green:&g blue:&b alpha:&a];

    // 计算颜色的亮度
    CGFloat brightness = (r * 299 + g * 587 + b * 114) / 1000;

    // 根据背景颜色的亮度确定文字颜色
    UIColor *textColor = (brightness > 0.5) ? [UIColor blackColor] : [UIColor whiteColor];

    return textColor;
}


//设置竖方向渐变
+ (void)setColor:(NSUInteger)arrSize desiredAlpha:(CGFloat)alpha uiview:(UIView *)uiview ColorType:(ColorType)type {
    // 先移除之前添加的渐变图层（如果存在）
    [self removePreviousGradientLayerFromView:uiview];
    
    NSUInteger gradientSize = arrSize; // 渐变色数组的大小
    CGFloat desiredAlpha = alpha; // 设置透明度，范围为0到1之间
    
    // 根据色调类型初始化颜色数组
    NSArray<UIColor *> *colors;
    switch (type) {
        case PinkColor:
            colors = [UIColor randomPinkGradientColorsWithSize:gradientSize alpha:desiredAlpha];
            break;
        case WarmColor:
            colors = [UIColor randomWarmGradientColorsWithSize:gradientSize alpha:desiredAlpha];
            break;
        case BrightColor:
            colors = [UIColor randomBrightGradientColorsWithSize:gradientSize alpha:desiredAlpha];
            break;
        case DarkColor:
            colors = [UIColor randomDarkGradientColorsWithSize:gradientSize alpha:desiredAlpha];
            break;
        case SystemBackageColor:
            colors = [UIColor randomSystemBackageColorsWithSize:gradientSize alpha:desiredAlpha];
            break;
        case randomColor:
            colors = [UIColor randomColorsWithSize:gradientSize alpha:desiredAlpha];
            break;
        default:
            colors = [NSArray arrayWithObject:[UIColor whiteColor]]; // 默认颜色为白色
            break;
    }
    
    // 创建渐变图层
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = uiview.layer.bounds;
    
    // 将颜色数组转换为CGColor数组
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    
    gradientLayer.colors = cgColors;
    gradientLayer.startPoint = CGPointMake(0, 0.5);
    gradientLayer.endPoint = CGPointMake(1, 0.5);
    
    // 创建遮罩图层
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:uiview.bounds cornerRadius:uiview.layer.cornerRadius].CGPath;
    gradientLayer.mask = maskLayer;
    
    // 将渐变图层添加到父视图的图层上
    [uiview.layer insertSublayer:gradientLayer atIndex:0];
}

+ (void)removePreviousGradientLayerFromView:(UIView *)uiview {
    // 遍历视图的所有子图层
    NSArray<CALayer *> *sublayers = uiview.layer.sublayers;
    for (CALayer *subLayer in sublayers) {
        if ([subLayer isKindOfClass:[CAGradientLayer class]]) {
            // 如果是渐变图层，就从父视图图层中移除它
            [subLayer removeFromSuperlayer];
            break; // 通常一个视图只添加一个这样的渐变图层，找到并移除后可直接退出循环，可根据实际情况调整
        }
    }
}

//获取随机渐变色 随机方向
+ (void)setRandomGradientWithColorCount:(NSUInteger)colorCount desiredAlpha:(CGFloat)alpha forView:(UIView *)view  ColorType:(ColorType)type {
    // 创建渐变图层
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = view.layer.bounds;
    
    // 根据色调类型初始化颜色数组
    NSArray<UIColor *> *colors;
    switch (type) {
        case PinkColor:
            colors = [UIColor randomPinkGradientColorsWithSize:colorCount alpha:alpha];
            break;
        case WarmColor:
            colors = [UIColor randomWarmGradientColorsWithSize:colorCount alpha:alpha];
            break;
        case BrightColor:
            colors = [UIColor randomBrightGradientColorsWithSize:colorCount alpha:alpha];
            break;
        case DarkColor:
            colors = [UIColor randomDarkGradientColorsWithSize:colorCount alpha:alpha];
            break;
        default:
            colors = [NSArray arrayWithObject:[UIColor whiteColor]];// 默认颜色为白色
            break;
    }
    
    // 将颜色数组转换为CGColor数组
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    
    gradientLayer.colors = cgColors;
    
    // 随机生成起始点和结束点
    CGFloat startX = (CGFloat)arc4random_uniform(101) / 100.0; // 0.0 - 1.0 之间的随机数
    CGFloat startY = (CGFloat)arc4random_uniform(101) / 100.0;
    CGFloat endX = (CGFloat)arc4random_uniform(101) / 100.0;
    CGFloat endY = (CGFloat)arc4random_uniform(101) / 100.0;
    
    gradientLayer.startPoint = CGPointMake(startX, startY);
    gradientLayer.endPoint = CGPointMake(endX, endY);
    
    // 将渐变图层添加到自定义视图的图层上
    [view.layer insertSublayer:gradientLayer atIndex:0];
}

//获取动态球毛玻璃视图
+ (void)addColorBallsWithCount1:(NSUInteger)count radius:(CGFloat)radius toView:(UIView *)view minDuration:(CGFloat)minDuration maxDuration:(CGFloat)maxDuration alpha:(CGFloat)alpha{
    //获取视图宽度
    CGSize screenSize = view.bounds.size;
    //循环生成小球数量
    for (NSUInteger i = 0; i < count; i++) {
        //初始化小球视图
        UIView *ball = [[UIView alloc] initWithFrame:CGRectMake(0, 0, radius, radius)];
        //设置圆角宽度的一般 圆形
        ball.layer.cornerRadius = radius / 2;
        ball.layer.masksToBounds = NO;
        //设置小球初始位置 随机
        CGFloat randomX = arc4random_uniform(screenSize.width);
        CGFloat randomY = arc4random_uniform(screenSize.height);
        ball.center = CGPointMake(randomX, randomY);
        //随机颜色
        CGFloat red = (CGFloat)arc4random_uniform(256) / 255.0;
        CGFloat green = (CGFloat)arc4random_uniform(256) / 255.0;
        CGFloat blue = (CGFloat)arc4random_uniform(256) / 255.0;
        //随机背景设
        ball.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        //随机投影色
        ball.layer.shadowColor = [UIColor colorWithRed:red green:green blue:blue alpha:1].CGColor;
        ball.layer.shadowOffset = CGSizeZero;
        ball.layer.shadowOpacity = 1.0;
        ball.layer.shadowRadius = radius / 2;
        //添加到视图
        [view addSubview:ball];
        //每个小球获取不同动画时间
        CGFloat randomDuration = [self randomFloatBetween:minDuration and:maxDuration];
        //执行动画
        [self animateBall:ball inBounds:view.bounds withDuration:randomDuration];
    }
    //给全局视图增加毛玻璃效果
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
    //尺寸和视图同宽高
    blurView.frame = view.bounds;
    // 调整透明度，数值范围为0.0到1.0之间
    blurView.alpha = alpha;
    //添加到视图
    [view addSubview:blurView];
}

+ (void)animateBall:(UIView *)ball inBounds:(CGRect)bounds withDuration:(CGFloat)duration {
    
    //动画起始坐标点
    CGFloat randomX = arc4random_uniform(bounds.size.width);
    CGFloat randomY = arc4random_uniform(bounds.size.height);
    CGPoint destination = CGPointMake(randomX, randomY);
    //执行动画
    [UIView animateWithDuration:duration animations:^{
        //运动到目的地坐标点
        ball.center = destination;
        //动画结束透明度降低为0 以便无感切换颜色
        ball.alpha = 0;
    } completion:^(BOOL finished) {
        //运动到目的地后 获取随机颜色
        CGFloat red = (CGFloat)arc4random_uniform(256) / 255.0;
        CGFloat green = (CGFloat)arc4random_uniform(256) / 255.0;
        CGFloat blue = (CGFloat)arc4random_uniform(256) / 255.0;
        
        [UIView animateWithDuration:duration animations:^{
            // 将小球移回屏幕内并切换颜色
            ball.center = CGPointMake(randomX, randomY);
            ball.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:0.5];
            ball.layer.shadowColor = [UIColor colorWithRed:red green:green blue:blue alpha:0.5].CGColor;
            //更换颜色后 变运动变切换回正常不透明色
            ball.alpha = 1;
        } completion:^(BOOL finished) {
            // 递归调用，继续随机移动
            [self animateBall:ball inBounds:bounds withDuration:duration];
        }];
    }];
}

+ (CGFloat)randomFloatBetween:(CGFloat)minValue and:(CGFloat)maxValue {
    CGFloat randomFloat = (CGFloat)arc4random() / UINT32_MAX; // 生成0到1之间的随机浮点数
    CGFloat scaledFloat = randomFloat * (maxValue - minValue) + minValue; // 将范围缩放到最小值和最大值之间
    return scaledFloat;
}

+ (void)addColorBallsWithCount:(NSUInteger)count ballradius:(CGFloat)radius toView:(UIView *)view minDuration:(CGFloat)minDuration maxDuration:(CGFloat)maxDuration UIBlurEffect:(CGFloat)alpha ballalpha:(CGFloat)ballalpha{
    
    
    UIVisualEffectView *OldexistingBlurEffectView = [view viewWithTag:999];
    if(OldexistingBlurEffectView){
        [OldexistingBlurEffectView removeFromSuperview];
    }
    
    // 创建一个毛玻璃效果对象，使用系统主题自动切换的样式
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    // 创建一个视图，用于展示毛玻璃效果
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.tag = 999;
    visualEffectView.frame = view.bounds;
    visualEffectView.alpha = alpha;
    //添加到视图
    [view addSubview:visualEffectView];
    //移动到底层
    [view sendSubviewToBack:visualEffectView];
    
    view.layer.masksToBounds = YES;
    // Create a parent layer to contain all ball layers
    CALayer *containerLayer = [CALayer layer];
    containerLayer.frame = view.bounds;
    containerLayer.zPosition = -1;
    [visualEffectView.layer addSublayer:containerLayer];
    
    // Create an array to reuse ball layers
    NSMutableArray<CAShapeLayer *> *ballLayersPool = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < count; i++) {
        // Get a reusable ball layer from the array or create a new one
        CAShapeLayer *ballLayer = nil;
        if (i < ballLayersPool.count) {
            ballLayer = ballLayersPool[i];
        } else {
            ballLayer = [CAShapeLayer layer];
            ballLayer.fillColor = [UIColor clearColor].CGColor;
            [containerLayer addSublayer:ballLayer];
            [ballLayersPool addObject:ballLayer];
            // 将小球的zPosition设置为一个较小的值，使其处于背景层级
            

        }
        
        // 随机生成球的初始位置和颜色
        CGFloat startX = arc4random_uniform((uint32_t)(view.bounds.size.width + 2 * radius)) - radius;
        CGFloat startY = arc4random_uniform((uint32_t)(view.bounds.size.height + 2 * radius)) - radius;
        CGFloat startRed = arc4random_uniform(256) / 255.0;
        CGFloat startGreen = arc4random_uniform(256) / 255.0;
        CGFloat startBlue = arc4random_uniform(256) / 255.0;
        
        // 设置球层的初始位置、大小和颜色
        ballLayer.position = CGPointMake(startX, startY);
        ballLayer.bounds = CGRectMake(0, 0, radius, radius);
        ballLayer.path = [UIBezierPath bezierPathWithOvalInRect:ballLayer.bounds].CGPath;
        ballLayer.fillColor = [UIColor colorWithRed:startRed green:startGreen blue:startBlue alpha:ballalpha].CGColor;
        
        
        
        // 随机生成球的目标位置和颜色
        CGFloat endX = arc4random_uniform(view.bounds.size.width)-radius;
        CGFloat endY = arc4random_uniform(view.bounds.size.height)-radius;
        CGFloat endRed = arc4random_uniform(256) / 255.0;
        CGFloat endGreen = arc4random_uniform(256) / 255.0;
        CGFloat endBlue = arc4random_uniform(256) / 255.0;
        
        // 为随机路径创建中间点
        CGFloat controlPoint1X = arc4random_uniform(view.bounds.size.width)+radius;
        CGFloat controlPoint1Y = arc4random_uniform(view.bounds.size.height)+radius;
        CGFloat controlPoint2X = arc4random_uniform(view.bounds.size.width)+radius;
        CGFloat controlPoint2Y = arc4random_uniform(view.bounds.size.height)+radius;
        
        // 为球层创建关键帧动画
        CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        positionAnimation.values = @[[NSValue valueWithCGPoint:CGPointMake(startX, startY)],
                                     [NSValue valueWithCGPoint:CGPointMake(controlPoint1X, controlPoint1Y)],
                                     [NSValue valueWithCGPoint:CGPointMake(controlPoint2X, controlPoint2Y)],
                                     [NSValue valueWithCGPoint:CGPointMake(endX, endY)],
                                     [NSValue valueWithCGPoint:CGPointMake(startX, startY)]];
        
        positionAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                              [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                              [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                              [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        
        positionAnimation.duration = (CGFloat)arc4random_uniform((uint32_t)(maxDuration - minDuration)) + minDuration;
        positionAnimation.repeatCount = HUGE_VALF;
        
        // 为球层创建颜色更改动画
        CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
        colorAnimation.fromValue = (__bridge id)[UIColor colorWithRed:startRed green:startGreen blue:startBlue alpha:ballalpha].CGColor;
        colorAnimation.toValue = (__bridge id)[UIColor colorWithRed:endRed green:endGreen blue:endBlue alpha:ballalpha].CGColor;
        colorAnimation.duration = positionAnimation.duration;
        colorAnimation.repeatCount = HUGE_VALF;
        
        //为球层创建动画组
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.animations = @[positionAnimation, colorAnimation];
        animationGroup.duration = positionAnimation.duration;
        animationGroup.repeatCount = HUGE_VALF;
        
        // 将动画组添加到球层
        [ballLayer addAnimation:animationGroup forKey:@"positionColorAnimation"];
    }
    
}

/// 渐变色
- (void)colorGradientFrom:(UIColor*)color0 toColor:(UIColor*)color1 startP:(CGPoint)point0 EndP:(CGPoint)point1 SubView:(UIView*)subView
{
    //渐变设置
    CAGradientLayer *gradient = [CAGradientLayer layer];
    NSArray *colors = [NSArray arrayWithObjects:(id)color0.CGColor, (id)color1.CGColor, nil];
    //设置开始和结束位置(通过开始和结束位置来控制渐变的方向)
    gradient.startPoint = point0;
    gradient.endPoint = point1;
    gradient.colors = colors;
    gradient.locations = @[@(0.0),@(1.0f)];
    gradient.frame = CGRectMake(0, 0, subView.bounds.size.width, subView.bounds.size.height);
    [subView.layer insertSublayer:gradient atIndex:0];
}

//双主题颜色
+ (UIColor *)colorWithLightColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor {
    if (@available(iOS 13.0, *)) {
        // iOS 13 及以上版本，支持黑暗模式
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return darkColor; // 黑暗模式
            } else {
                return lightColor; // 亮色模式
            }
        }];
    } else {
        // iOS 13 以下版本，不支持黑暗模式，默认返回亮色模式颜色
        return lightColor;
    }
}

// 在配置cell时调用，将字符串转换为UIColor
+ (UIColor *)colorWithHexString:(NSString *)hexString {
    // 处理前缀（#或0x）
    NSString *cleanString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"#0x"]];
    
    // 容错：默认返回灰色
    if (cleanString.length != 6 && cleanString.length != 8) {
        return [UIColor lightGrayColor];
    }
    
    // 解析十六进制值
    unsigned long long hexNumber;
    NSScanner *scanner = [NSScanner scannerWithString:cleanString];
    if (![scanner scanHexLongLong:&hexNumber]) {
        return [UIColor lightGrayColor];
    }
    
    // 提取RGB和透明度（支持带alpha的8位格式，如FF000080）
    CGFloat red, green, blue, alpha = 1.0;
    if (cleanString.length == 6) {
        red = ((hexNumber >> 16) & 0xFF) / 255.0;
        green = ((hexNumber >> 8) & 0xFF) / 255.0;
        blue = (hexNumber & 0xFF) / 255.0;
    } else {
        red = ((hexNumber >> 24) & 0xFF) / 255.0;
        green = ((hexNumber >> 16) & 0xFF) / 255.0;
        blue = ((hexNumber >> 8) & 0xFF) / 255.0;
        alpha = (hexNumber & 0xFF) / 255.0;
    }
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
