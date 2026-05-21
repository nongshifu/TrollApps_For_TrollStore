//
//  UIButton+FAK.m
//  TrollApps
//
//  FontAwesomeKit 扩展 - UIButton便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "UIButton+FAK.h"
#import "UIView+FAK.h"

@implementation UIButton (FAK)

#pragma mark - 设置按钮图标

- (void)fak_setIcon:(FAKIcon *)icon
            forState:(UIControlState)state
              color:(UIColor *)color {
    CGFloat size = self.titleLabel.font.pointSize * 1.5;
    [icon addAttribute:NSForegroundColorAttributeName value:color];
    icon.iconSize = size;
    UIImage *image = [icon imageWithSize:CGSizeMake(size, size)];
    [self setImage:image forState:state];
}

- (void)fak_setIconWithName:(NSString *)iconName
                  forState:(UIControlState)state
                     color:(UIColor *)color {
    FAKIcon *icon = [UIView fak_iconWithName:iconName size:self.titleLabel.font.pointSize * 1.5];
    if (icon) {
        [self fak_setIcon:icon forState:state color:color];
    }
}

- (void)fak_setIcon:(FAKIcon *)icon
               title:(NSString *)title
            forState:(UIControlState)state
              color:(UIColor *)color
            spacing:(CGFloat)spacing {
    [self fak_setIcon:icon forState:state color:color];
    [self setTitle:title forState:state];
    [self setTitleColor:color forState:state];
    
    self.imageEdgeInsets = UIEdgeInsetsMake(0, -spacing, 0, spacing);
    self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, -spacing);
}

- (void)fak_setIconWithName:(NSString *)iconName
                      title:(NSString *)title
                   forState:(UIControlState)state
                      color:(UIColor *)color
                    spacing:(CGFloat)spacing {
    FAKIcon *icon = [UIView fak_iconWithName:iconName size:self.titleLabel.font.pointSize * 1.5];
    if (icon) {
        [self fak_setIcon:icon title:title forState:state color:color spacing:spacing];
    }
}

@end
