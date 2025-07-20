//
//  UIView.m
//  NewSoulChat
//
//  Created by 十三哥 on 2024/12/17.
//  Copyright © 2024 D-James. All rights reserved.
//

#import "UIView.h"

@implementation UIView (GradientBackground)



// 设置随机渐变背景
- (void)setRandomGradientBackgroundWithColorCount:(NSInteger)colorCount alpha:(CGFloat)alpha {
    // 调用原有方法设置渐变背景
    [self setRandomGradientBackgroundWithColorCount:colorCount alpha:alpha horizontal:YES];
}

// 设置随机渐变背景
- (void)setRandomGradientBackgroundWithColorCount:(NSInteger)colorCount alpha:(CGFloat)alpha horizontal:(BOOL)horizontal {
    // 确保颜色数量至少为2
    if (colorCount < 2) {
        return;
    }
    
    // 生成随机颜色数组
    NSMutableArray<UIColor *> *randomColors = [NSMutableArray array];
    for (NSInteger i = 0; i < colorCount; i++) {
        [randomColors addObject:[self randomColor]];
    }
    
    // 调用原有方法设置渐变背景
    [self setGradientBackgroundWithColors:randomColors alpha:alpha horizontal:horizontal];
}

- (void)setRandomGradientBackgroundWithColorCount:(NSInteger)colorCount alpha:(CGFloat)alpha horizontal:(BOOL)horizontal insertSublayer:(int)atIndex{
    // 确保颜色数量至少为2
    if (colorCount < 2) {
        return;
    }
    
    // 生成随机颜色数组
    NSMutableArray<UIColor *> *randomColors = [NSMutableArray array];
    for (NSInteger i = 0; i < colorCount; i++) {
        [randomColors addObject:[self randomColor]];
    }
    [self setGradientBackgroundWithColors:randomColors alpha:alpha horizontal:horizontal insertSublayer:atIndex];
}


// 原有方法：设置渐变背景，新增horizontal参数控制渐变方向
- (void)setGradientBackgroundWithColors:(NSArray<UIColor *> *)colors alpha:(CGFloat)alpha{
    [self setGradientBackgroundWithColors:colors alpha:alpha horizontal:YES];
}

// 原有方法：设置渐变背景，新增horizontal参数控制渐变方向
- (void)setGradientBackgroundWithColors:(NSArray<UIColor *> *)colors alpha:(CGFloat)alpha horizontal:(BOOL)horizontal {
    // 确保颜色数组至少有两个颜色来形成渐变
    
    [self setGradientBackgroundWithColors:colors alpha:alpha horizontal:horizontal insertSublayer:0];
}

// 原有方法：设置渐变背景，新增horizontal参数控制渐变方向 以及插入视图层级
//储存渐变色模型属性
static const void *kCurrentGradientLayerKey = &kCurrentGradientLayerKey;

- (void)setCurrentGradientLayer:(CAGradientLayer *)currentGradientLayer {
    objc_setAssociatedObject(self, kCurrentGradientLayerKey, currentGradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAGradientLayer *)currentGradientLayer {
    return objc_getAssociatedObject(self, kCurrentGradientLayerKey);
}

- (void)setGradientBackgroundWithColors:(NSArray<UIColor *> *)colors alpha:(CGFloat)alpha horizontal:(BOOL)horizontal insertSublayer:(int)atIndex{
    // 确保颜色数组至少有两个颜色来形成渐变
    if (colors.count < 2) {
        return;
    }
    
    // 先获取已存在的渐变图层并移除它
    CAGradientLayer *existingGradientLayer = [self existingGradientLayer];
    if (existingGradientLayer) {
        [existingGradientLayer removeFromSuperlayer];
    }
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.bounds;
    // 保存渐变图层到属性
    self.currentGradientLayer = gradientLayer;
    
    // 设置透明度
    gradientLayer.opacity = alpha;
    
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    
    gradientLayer.colors = cgColors;
    
    // 根据horizontal参数设置渐变方向
    if (horizontal) {
        // 左右渐变
        gradientLayer.startPoint = CGPointMake(0, 0.5);
        gradientLayer.endPoint = CGPointMake(1, 0.5);
    } else {
        // 上下渐变
        gradientLayer.startPoint = CGPointMake(0.5, 0);
        gradientLayer.endPoint = CGPointMake(0.5, 1);
    }
    
    // 适配圆角属性
    [self setupLayerCornerForSubLayer:gradientLayer];
    
    [self.layer insertSublayer:gradientLayer atIndex:atIndex];
}




// 辅助函数：生成随机颜色
- (UIColor *)randomColor {
    CGFloat red = arc4random_uniform(256) / 255.0;
    CGFloat green = arc4random_uniform(256) / 255.0;
    CGFloat blue = arc4random_uniform(256) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

// 辅助函数：获取已存在的渐变图层
- (CAGradientLayer *)existingGradientLayer {
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            return (CAGradientLayer *)layer;
        }
    }
    return nil;
}

// 辅助函数：适配圆角属性
- (void)setupLayerCornerForSubLayer:(CALayer *)layer {
    if (self.layer.cornerRadius > 0) {
        layer.cornerRadius = self.layer.cornerRadius;
        layer.masksToBounds = YES;
    }
}

// 添加毛玻璃效果
- (void)setFrostedGlassBackgroundWithStyle:(UIBlurEffectStyle)style alpha:(CGFloat)alpha {
    // 创建模糊效果对象
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
    // 创建可视化效果视图，将模糊效果应用于其上
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.bounds;
    visualEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // 设置透明度，限制范围在0到1之间
    visualEffectView.alpha = (alpha >= 0 && alpha <= 1)? alpha : 1;
    
    // 适配圆角属性
    [self setupLayerCornerForSubLayer:visualEffectView.layer];
    
    [self addSubview:visualEffectView];
}

//添加小球

//储存小球模型
static const void *kColorBallsContainerLayerKey = &kColorBallsContainerLayerKey;

- (void)setColorBallsContainerLayer:(CALayer *)containerLayer {
    objc_setAssociatedObject(self, kColorBallsContainerLayerKey, containerLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CALayer *)colorBallsContainerLayer {
    return objc_getAssociatedObject(self, kColorBallsContainerLayerKey);
}

- (void)addColorBallsWithCount:(NSUInteger)count ballradius:(CGFloat)radius minDuration:(CGFloat)minDuration maxDuration:(CGFloat)maxDuration UIBlurEffectStyle:(UIBlurEffectStyle)style UIBlurEffectAlpha:(CGFloat)alpha ballalpha:(CGFloat)ballalpha{
    
    UIVisualEffectView *OldexistingBlurEffectView = [self viewWithTag:999];
    if(OldexistingBlurEffectView){
        [OldexistingBlurEffectView removeFromSuperview];
    }
    
    // 创建一个毛玻璃效果对象，使用系统主题自动切换的样式
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
    // 创建一个视图，用于展示毛玻璃效果
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.tag = 999;
    visualEffectView.frame = self.bounds;
    visualEffectView.alpha = alpha;
    //添加到视图
    [self addSubview:visualEffectView];
    //移动到底层
    [self sendSubviewToBack:visualEffectView];
    
    self.layer.masksToBounds = YES;
    // Create a parent layer to contain all ball layers
    CALayer *containerLayer = [CALayer layer];
    containerLayer.frame = self.bounds;
    containerLayer.zPosition = -1;
    [visualEffectView.layer addSublayer:containerLayer];
    
    // 保存容器层引用
    self.colorBallsContainerLayer = containerLayer;
    
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
        CGFloat startX = arc4random_uniform((uint32_t)(self.bounds.size.width + 2 * radius)) - radius;
        CGFloat startY = arc4random_uniform((uint32_t)(self.bounds.size.height + 2 * radius)) - radius;
        CGFloat startRed = arc4random_uniform(256) / 255.0;
        CGFloat startGreen = arc4random_uniform(256) / 255.0;
        CGFloat startBlue = arc4random_uniform(256) / 255.0;
        
        // 设置球层的初始位置、大小和颜色
        ballLayer.position = CGPointMake(startX, startY);
        ballLayer.bounds = CGRectMake(0, 0, radius, radius);
        ballLayer.path = [UIBezierPath bezierPathWithOvalInRect:ballLayer.bounds].CGPath;
        ballLayer.fillColor = [UIColor colorWithRed:startRed green:startGreen blue:startBlue alpha:ballalpha].CGColor;
        
        // 随机生成球的目标位置和颜色
        CGFloat endX = arc4random_uniform(self.bounds.size.width)-radius;
        CGFloat endY = arc4random_uniform(self.bounds.size.height)-radius;
        CGFloat endRed = arc4random_uniform(256) / 255.0;
        CGFloat endGreen = arc4random_uniform(256) / 255.0;
        CGFloat endBlue = arc4random_uniform(256) / 255.0;
        
        // 为随机路径创建中间点
        CGFloat controlPoint1X = arc4random_uniform(self.bounds.size.width)+radius;
        CGFloat controlPoint1Y = arc4random_uniform(self.bounds.size.height)+radius;
        CGFloat controlPoint2X = arc4random_uniform(self.bounds.size.width)+radius;
        CGFloat controlPoint2Y = arc4random_uniform(self.bounds.size.height)+radius;
        
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
        positionAnimation.removedOnCompletion = NO; // 动画完成后不移除
        positionAnimation.fillMode = kCAFillModeForwards; // 保持在最后一帧
        
        // 为球层创建颜色更改动画
        CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
        colorAnimation.fromValue = (__bridge id)[UIColor colorWithRed:startRed green:startGreen blue:startBlue alpha:ballalpha].CGColor;
        colorAnimation.toValue = (__bridge id)[UIColor colorWithRed:endRed green:endGreen blue:endBlue alpha:ballalpha].CGColor;
        colorAnimation.duration = positionAnimation.duration;
        colorAnimation.repeatCount = HUGE_VALF;
        colorAnimation.removedOnCompletion = NO; // 动画完成后不移除
        colorAnimation.fillMode = kCAFillModeForwards; // 保持在最后一帧
        
        // 为球层创建动画组
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.animations = @[positionAnimation, colorAnimation];
        animationGroup.duration = positionAnimation.duration;
        animationGroup.repeatCount = HUGE_VALF;
        animationGroup.removedOnCompletion = NO; // 动画完成后不移除
        animationGroup.fillMode = kCAFillModeForwards; // 保持在最后一帧
        
        // 将动画组添加到球层
        [ballLayer addAnimation:animationGroup forKey:@"positionColorAnimation"];
    }
    
}
// 重新计算并更新所有小球的位置
- (void)updateColorBallsPositions {
    CALayer *containerLayer = self.colorBallsContainerLayer;
    if (!containerLayer || containerLayer.sublayers.count == 0) return;
    
    CGFloat radius = [self getBallRadiusFromContainer:containerLayer];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    // 遍历所有小球，根据新尺寸重新计算位置
    for (NSUInteger i = 0; i < containerLayer.sublayers.count; i++) {
        CAShapeLayer *ballLayer = (CAShapeLayer *)containerLayer.sublayers[i];
        
        // 获取原始动画中的关键点
        CAAnimationGroup *animationGroup = (CAAnimationGroup *)[ballLayer animationForKey:@"positionColorAnimation"];
        if (!animationGroup || animationGroup.animations.count == 0) continue;
        
        CAKeyframeAnimation *positionAnimation = (CAKeyframeAnimation *)animationGroup.animations[0];
        NSArray *originalValues = positionAnimation.values;
        NSMutableArray *newValues = [NSMutableArray array];
        
        // 重新计算每个关键点的位置
        for (NSValue *value in originalValues) {
            CGPoint originalPoint = [value CGPointValue];
            CGFloat newX = (originalPoint.x / (self.bounds.size.width + 2 * radius)) * (width + 2 * radius) - radius;
            CGFloat newY = (originalPoint.y / (self.bounds.size.height + 2 * radius)) * (height + 2 * radius) - radius;
            [newValues addObject:[NSValue valueWithCGPoint:CGPointMake(newX, newY)]];
        }
        
        // 更新动画
        positionAnimation.values = newValues;
        
        // 重置动画以应用新的位置
        [ballLayer removeAnimationForKey:@"positionColorAnimation"];
        [ballLayer addAnimation:animationGroup forKey:@"positionColorAnimation"];
    }
}

// 从容器层获取小球半径（假设所有小球半径相同）
- (CGFloat)getBallRadiusFromContainer:(CALayer *)containerLayer {
    if (containerLayer.sublayers.count == 0) return 0;
    CAShapeLayer *firstBall = (CAShapeLayer *)containerLayer.sublayers[0];
    return CGRectGetWidth(firstBall.bounds);
}

// 获取视图所属的视图控制器的方法
- (UIViewController *)getviewController {
    UIResponder *nextResponder = self;
    while (nextResponder != nil) {
        nextResponder = nextResponder.nextResponder;
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

- (void)addGlowEffectWithColor:(UIColor *)color
                 shadowOffset:(CGSize)shadowOffset
                shadowOpacity:(CGFloat)shadowOpacity
                 shadowRadius:(CGFloat)shadowRadius {
    // 获取当前视图的 layer
    CALayer *layer = self.layer;
    // 设置阴影颜色
    layer.shadowColor = color.CGColor;
    // 设置阴影偏移量
    layer.shadowOffset = shadowOffset;
    // 设置阴影透明度
    layer.shadowOpacity = shadowOpacity;
    // 设置阴影半径
    layer.shadowRadius = shadowRadius;
    // 为了确保阴影不被裁剪，设置 masksToBounds 为 NO
    layer.masksToBounds = NO;
}

- (void)addGlowEffectWithColor:(UIColor *)color
                shadowOpacity:(CGFloat)shadowOpacity
                 shadowRadius:(CGFloat)shadowRadius {
    [self addGlowEffectWithColor:color shadowOffset:CGSizeZero shadowOpacity:shadowOpacity shadowRadius:shadowRadius];
}

//获取顶层视图控制器
- (UIViewController *)getTopViewController {
    UIViewController *topViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

// 移除动态背景
- (void)removeDynamicBackground {
    // 移除毛玻璃效果视图
    UIVisualEffectView *visualEffectView = [self viewWithTag:999];
    if (visualEffectView) {
        [visualEffectView removeFromSuperview];
    }
    
    // 移除小球图层及其动画
    CALayer *containerLayer = nil;
    for (CALayer *layer in self.layer.sublayers) {
        if (layer.zPosition == -1) {
            containerLayer = layer;
            break;
        }
    }
    if (containerLayer) {
        for (CAShapeLayer *ballLayer in containerLayer.sublayers) {
            [ballLayer removeAllAnimations];
            [ballLayer removeFromSuperlayer];
        }
        [containerLayer removeFromSuperlayer];
    }
    // 移除渐变色背景
    CAGradientLayer *gradientLayer = [self existingGradientLayer];
    if (gradientLayer) {
        [gradientLayer removeFromSuperlayer];
    }
}


- (void)setViewRadiusWithTopLeft:(CGFloat)topLeft
                          topRight:(CGFloat)topRight
                        bottomLeft:(CGFloat)bottomLeft
                       bottomRight:(CGFloat)bottomRight {
    
    // 确保圆角不会超过视图尺寸的一半
    CGFloat minDimension = MIN(self.bounds.size.width, self.bounds.size.height) ;
    topLeft = MIN(topLeft, minDimension);
    topRight = MIN(topRight, minDimension);
    bottomLeft = MIN(bottomLeft, minDimension);
    bottomRight = MIN(bottomRight, minDimension);
    
    // 创建贝塞尔路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // 从左上角开始绘制
    [path moveToPoint:CGPointMake(0, topLeft)];
    if (topLeft > 0) {
        [path addArcWithCenter:CGPointMake(topLeft, topLeft)
                        radius:topLeft
                    startAngle:M_PI
                      endAngle:M_PI_2 * 3
                     clockwise:YES];
    }
    
    // 右上角
    [path addLineToPoint:CGPointMake(self.bounds.size.width - topRight, 0)];
    if (topRight > 0) {
        [path addArcWithCenter:CGPointMake(self.bounds.size.width - topRight, topRight)
                        radius:topRight
                    startAngle:M_PI_2 * 3
                      endAngle:0
                     clockwise:YES];
    }
    
    // 右下角
    [path addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height - bottomRight)];
    if (bottomRight > 0) {
        [path addArcWithCenter:CGPointMake(self.bounds.size.width - bottomRight, self.bounds.size.height - bottomRight)
                        radius:bottomRight
                    startAngle:0
                      endAngle:M_PI_2
                     clockwise:YES];
    }
    
    // 左下角
    [path addLineToPoint:CGPointMake(bottomLeft, self.bounds.size.height)];
    if (bottomLeft > 0) {
        [path addArcWithCenter:CGPointMake(bottomLeft, self.bounds.size.height - bottomLeft)
                        radius:bottomLeft
                    startAngle:M_PI_2
                      endAngle:M_PI
                     clockwise:YES];
    }
    
    // 闭合路径
    [path closePath];
    
    // 创建形状图层
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    
    // 应用遮罩
    self.layer.mask = maskLayer;
}

/**
 * 为视图添加四周虚化效果
 * @param radius 虚化半径，控制虚化范围
 */
- (void)addBlurEdgeWithRadius:(CGFloat)radius {
    [self addBlurEdgeWithRadius:radius cornerRadius:0];
}


/**
 * 为视图添加四周虚化效果，并指定内部保留区域的圆角
 * @param radius 虚化半径，控制虚化范围
 * @param cornerRadius 内部保留区域的圆角半径
 */
- (void)addBlurEdgeWithRadius:(CGFloat)radius cornerRadius:(CGFloat)cornerRadius {
    // 创建一个与视图大小相同的遮罩层
    CALayer *maskLayer = [CALayer layer];
    maskLayer.frame = self.bounds;
    
    // 创建径向渐变
    CIFilter *radialGradient = [CIFilter filterWithName:@"CIRadialGradient"];
    [radialGradient setDefaults];
    
    // 计算渐变中心点和半径
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat innerRadius = MIN(self.bounds.size.width, self.bounds.size.height) / 2 - radius;
    CGFloat outerRadius = MIN(self.bounds.size.width, self.bounds.size.height) / 2;
    
    // 设置渐变参数
    [radialGradient setValue:[CIVector vectorWithX:center.x Y:center.y] forKey:@"inputCenter"];
    [radialGradient setValue:@(innerRadius) forKey:@"inputRadius0"];
    [radialGradient setValue:@(outerRadius) forKey:@"inputRadius1"];
    [radialGradient setValue:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forKey:@"inputColor0"];
    [radialGradient setValue:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0] forKey:@"inputColor1"];
    
    // 创建 CIContext 用于渲染滤镜
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [radialGradient outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    // 如果需要圆角，创建一个圆角路径
    if (cornerRadius > 0) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.frame = self.bounds;
        shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:cornerRadius].CGPath;
        
        CALayer *gradientLayer = [CALayer layer];
        gradientLayer.frame = self.bounds;
        gradientLayer.contents = (__bridge id)cgImage;
        gradientLayer.mask = shapeLayer;
        [maskLayer addSublayer:gradientLayer];
       
    } else {
        maskLayer.contents = (__bridge id)cgImage;
    }
    
    // 释放 CGImage
    if (cgImage) {
        CGImageRelease(cgImage);
    }
    
    // 设置遮罩
    self.layer.mask = maskLayer;
}

//获取顶层视图控制器
+ (UIViewController *)getTopViewController {
    UIViewController *topViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

///视图转PNG图片对象
+ (UIImage *)convertViewToPNG:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)showAlertFromViewController:(UIViewController *)viewController
                                  title:(NSString *)title
                                message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertWithConfirmationFromViewController:(UIViewController *)viewController
                                              title:(NSString *)title
                                            message:(NSString *)message
                                       confirmTitle:(NSString *)confirmTitle
                                        cancelTitle:(NSString *)cancelTitle
                                        onConfirmed:(void (^)(void))onConfirm
                                         onCancelled:(void (^)(void))onCancel {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
    if(confirmTitle){
        [alert addAction:[UIAlertAction actionWithTitle:confirmTitle
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            if (onConfirm) {
                onConfirm();
            }
        }]];
    }
    if(cancelTitle){
        [alert addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
            if (onCancel) {
                onCancel();
            }
        }]];
    }
    
    
    
    [viewController presentViewController:alert animated:YES completion:nil];
}



@end


