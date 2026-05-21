//
//  UIView+FAK.m
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIView便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "UIView+FAK.h"

@implementation UIView (FAK)

#pragma mark - 设置FAK图标到视图

- (void)fak_setIcon:(FAKIcon *)icon
               size:(CGSize)size
              color:(UIColor *)color {
    [icon addAttribute:NSForegroundColorAttributeName value:color];
    icon.iconSize = size.width;
    UIImage *image = [icon imageWithSize:size];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self addSubview:imageView];
    
    [NSLayoutConstraint activateConstraints:@[
        [imageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [imageView.widthAnchor constraintEqualToConstant:size.width],
        [imageView.heightAnchor constraintEqualToConstant:size.height]
    ]];
}

- (void)fak_setIcon:(FAKIcon *)icon
              color:(UIColor *)color {
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    [self fak_setIcon:icon size:CGSizeMake(size, size) color:color];
}

#pragma mark - 根据图标名称设置

- (void)fak_setIconWithName:(NSString *)iconName
                       size:(CGSize)size
                      color:(UIColor *)color {
    FAKIcon *icon = [self.class fak_iconWithName:iconName size:size.width];
    if (icon) {
        [self fak_setIcon:icon size:size color:color];
    }
}

- (void)fak_setIconWithName:(NSString *)iconName
                      color:(UIColor *)color {
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    [self fak_setIconWithName:iconName size:CGSizeMake(size, size) color:color];
}

#pragma mark - 获取FAK图标对象

+ (FAKIcon *)fak_iconWithName:(NSString *)iconName
                         size:(CGFloat)size {
    if (!iconName || iconName.length == 0) {
        return nil;
    }
    
    NSString *cleanName = iconName;
    if ([iconName hasPrefix:@"fa-"]) {
        cleanName = [iconName substringFromIndex:3];
    }
    
    // 获取FontAwesome图标映射
    NSDictionary *mapping = [FAKFontAwesome iconFontMapping];
    NSString *key = [NSString stringWithFormat:@"fa%@", [cleanName capitalizedString]];
    NSString *iconCode = mapping[key];
    
    if (!iconCode) {
        return nil;
    }
    
    return [FAKFontAwesome iconWithCode:iconCode size:size];
}

+ (UIImage *)fak_imageWithIconName:(NSString *)iconName
                              size:(CGFloat)size
                             color:(UIColor *)color {
    FAKIcon *icon = [self fak_iconWithName:iconName size:size];
    if (!icon) {
        return nil;
    }
    
    [icon addAttribute:NSForegroundColorAttributeName value:color];
    return [icon imageWithSize:CGSizeMake(size, size)];
}

@end
