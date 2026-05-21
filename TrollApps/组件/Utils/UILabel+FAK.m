//
//  UILabel+FAK.m
//  TrollApps
//
//  FontAwesomeKit 扩展 - UILabel便捷操作
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "UILabel+FAK.h"
#import "UIView+FAK.h"

@implementation UILabel (FAK)

#pragma mark - 直接设置FAK图标文本

- (void)fak_setIcon:(FAKIcon *)icon
              color:(UIColor *)color {
    [icon addAttribute:NSForegroundColorAttributeName value:color];
    icon.iconSize = self.font.pointSize;
    self.attributedText = icon.attributedString;
}

- (void)fak_setIconWithName:(NSString *)iconName
                      color:(UIColor *)color {
    FAKIcon *icon = [UIView fak_iconWithName:iconName size:self.font.pointSize];
    if (icon) {
        [self fak_setIcon:icon color:color];
    }
}

- (void)fak_setIcon:(FAKIcon *)icon
               text:(NSString *)text
              color:(UIColor *)color
            spacing:(CGFloat)spacing {
    if (!text || text.length == 0) {
        [self fak_setIcon:icon color:color];
        return;
    }
    
    [icon addAttribute:NSForegroundColorAttributeName value:color];
    icon.iconSize = self.font.pointSize;
    
    NSMutableAttributedString *mutableAttr = [[NSMutableAttributedString alloc] init];
    [mutableAttr appendAttributedString:icon.attributedString];
    
    NSString *spacingStr = [@"" stringByPaddingToLength:MAX(1, spacing) withString:@" " startingAtIndex:0];
    [mutableAttr appendAttributedString:[[NSAttributedString alloc] initWithString:spacingStr]];
    
    NSAttributedString *textAttr = [[NSAttributedString alloc] initWithString:text
                                                                   attributes:@{NSForegroundColorAttributeName: color}];
    [mutableAttr appendAttributedString:textAttr];
    
    self.attributedText = mutableAttr;
}

- (void)fak_setIconWithName:(NSString *)iconName
                       text:(NSString *)text
                      color:(UIColor *)color
                    spacing:(CGFloat)spacing {
    FAKIcon *icon = [UIView fak_iconWithName:iconName size:self.font.pointSize];
    if (icon) {
        [self fak_setIcon:icon text:text color:color spacing:spacing];
    }
}

@end
