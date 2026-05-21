//
//  UIImageView+FAK.m
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIImageView便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "UIImageView+FAK.h"
#import "UIView+FAK.h"

@implementation UIImageView (FAK)

#pragma mark - 直接设置FAK图标

- (void)fak_setIcon:(FAKIcon *)icon
              color:(UIColor *)color {
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    if (size <= 0) {
        size = 30.0;
    }
    [self fak_setIcon:icon size:CGSizeMake(size, size) color:color];
}

- (void)fak_setIcon:(FAKIcon *)icon
               size:(CGSize)size
              color:(UIColor *)color {
    [icon addAttribute:NSForegroundColorAttributeName value:color];
    icon.iconSize = size.width;
    self.image = [icon imageWithSize:size];
}

#pragma mark - 根据图标名称设置

- (void)fak_setIconWithName:(NSString *)iconName
                      color:(UIColor *)color {
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    if (size <= 0) {
        size = 30.0;
    }
    [self fak_setIconWithName:iconName size:CGSizeMake(size, size) color:color];
}

- (void)fak_setIconWithName:(NSString *)iconName
                       size:(CGSize)size
                      color:(UIColor *)color {
    FAKIcon *icon = [UIView fak_iconWithName:iconName size:size.width];
    if (icon) {
        [self fak_setIcon:icon size:size color:color];
    }
}

@end
