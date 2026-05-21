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
    icon.iconFontSize = size.width;
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
    
    // 直接通过常用图标名称映射（最可靠的方式）
    if ([cleanName isEqualToString:@"gift"]) return [FAKFontAwesome giftIconWithSize:size];
    if ([cleanName isEqualToString:@"heart"]) return [FAKFontAwesome heartIconWithSize:size];
    if ([cleanName isEqualToString:@"star"]) return [FAKFontAwesome starIconWithSize:size];
    if ([cleanName isEqualToString:@"check"]) return [FAKFontAwesome checkIconWithSize:size];
    if ([cleanName isEqualToString:@"times"]) return [FAKFontAwesome timesIconWithSize:size];
    if ([cleanName isEqualToString:@"play"]) return [FAKFontAwesome playIconWithSize:size];
    if ([cleanName isEqualToString:@"pause"]) return [FAKFontAwesome pauseIconWithSize:size];
    if ([cleanName isEqualToString:@"home"]) return [FAKFontAwesome homeIconWithSize:size];
    if ([cleanName isEqualToString:@"search"]) return [FAKFontAwesome searchIconWithSize:size];
    if ([cleanName isEqualToString:@"user"]) return [FAKFontAwesome userIconWithSize:size];
    if ([cleanName isEqualToString:@"bell"]) return [FAKFontAwesome bellIconWithSize:size];
    if ([cleanName isEqualToString:@"cog"]) return [FAKFontAwesome cogIconWithSize:size];
    if ([cleanName isEqualToString:@"trash"]) return [FAKFontAwesome trashIconWithSize:size];
    if ([cleanName isEqualToString:@"edit"]) return [FAKFontAwesome editIconWithSize:size];
    if ([cleanName isEqualToString:@"plus"]) return [FAKFontAwesome plusIconWithSize:size];
    if ([cleanName isEqualToString:@"minus"]) return [FAKFontAwesome minusIconWithSize:size];
    if ([cleanName isEqualToString:@"arrow-left"]) return [FAKFontAwesome arrowLeftIconWithSize:size];
    if ([cleanName isEqualToString:@"arrow-right"]) return [FAKFontAwesome arrowRightIconWithSize:size];
    if ([cleanName isEqualToString:@"arrow-up"]) return [FAKFontAwesome arrowUpIconWithSize:size];
    if ([cleanName isEqualToString:@"arrow-down"]) return [FAKFontAwesome arrowDownIconWithSize:size];
    if ([cleanName isEqualToString:@"map-marker"]) return [FAKFontAwesome mapMarkerIconWithSize:size];
    if ([cleanName isEqualToString:@"location-arrow"]) return [FAKFontAwesome locationArrowIconWithSize:size];
    if ([cleanName isEqualToString:@"globe"]) return [FAKFontAwesome globeIconWithSize:size];
    if ([cleanName isEqualToString:@"user-circle"]) return [FAKFontAwesome userCircleIconWithSize:size];
    if ([cleanName isEqualToString:@"user-plus"]) return [FAKFontAwesome userPlusIconWithSize:size];
    if ([cleanName isEqualToString:@"thumbs-up"]) return [FAKFontAwesome thumbsUpIconWithSize:size];
    if ([cleanName isEqualToString:@"comment"]) return [FAKFontAwesome commentIconWithSize:size];
    if ([cleanName isEqualToString:@"share"]) return [FAKFontAwesome shareIconWithSize:size];
    if ([cleanName isEqualToString:@"video"]) return [FAKFontAwesome videoCameraIconWithSize:size];
    if ([cleanName isEqualToString:@"music"]) return [FAKFontAwesome musicIconWithSize:size];
    if ([cleanName isEqualToString:@"camera"]) return [FAKFontAwesome cameraIconWithSize:size];
    if ([cleanName isEqualToString:@"file"]) return [FAKFontAwesome fileIconWithSize:size];
    if ([cleanName isEqualToString:@"folder"]) return [FAKFontAwesome folderIconWithSize:size];
    if ([cleanName isEqualToString:@"copy"]) return [FAKFontAwesome copyIconWithSize:size];
    if ([cleanName isEqualToString:@"download"]) return [FAKFontAwesome downloadIconWithSize:size];
    if ([cleanName isEqualToString:@"upload"]) return [FAKFontAwesome uploadIconWithSize:size];
    if ([cleanName isEqualToString:@"shopping-cart"]) return [FAKFontAwesome shoppingCartIconWithSize:size];
    if ([cleanName isEqualToString:@"credit-card"]) return [FAKFontAwesome creditCardIconWithSize:size];
    if ([cleanName isEqualToString:@"mobile"]) return [FAKFontAwesome mobileIconWithSize:size];
    if ([cleanName isEqualToString:@"wifi"]) return [FAKFontAwesome wifiIconWithSize:size];
    if ([cleanName isEqualToString:@"clock"]) return [FAKFontAwesome clockOIconWithSize:size];
    if ([cleanName isEqualToString:@"calendar"]) return [FAKFontAwesome calendarIconWithSize:size];
    if ([cleanName isEqualToString:@"lock"]) return [FAKFontAwesome lockIconWithSize:size];
    if ([cleanName isEqualToString:@"unlock"]) return [FAKFontAwesome unlockIconWithSize:size];
    if ([cleanName isEqualToString:@"link"]) return [FAKFontAwesome linkIconWithSize:size];
    if ([cleanName isEqualToString:@"sun"]) return [FAKFontAwesome sunOIconWithSize:size];
    if ([cleanName isEqualToString:@"cloud"]) return [FAKFontAwesome cloudIconWithSize:size];
    if ([cleanName isEqualToString:@"umbrella"]) return [FAKFontAwesome umbrellaIconWithSize:size];
    if ([cleanName isEqualToString:@"coffee"]) return [FAKFontAwesome coffeeIconWithSize:size];
    if ([cleanName isEqualToString:@"beer"]) return [FAKFontAwesome beerIconWithSize:size];
    if ([cleanName isEqualToString:@"gamepad"]) return [FAKFontAwesome gamepadIconWithSize:size];
    if ([cleanName isEqualToString:@"trophy"]) return [FAKFontAwesome trophyIconWithSize:size];
    if ([cleanName isEqualToString:@"book"]) return [FAKFontAwesome bookIconWithSize:size];
    if ([cleanName isEqualToString:@"print"]) return [FAKFontAwesome printIconWithSize:size];
    if ([cleanName isEqualToString:@"envelope"]) return [FAKFontAwesome envelopeIconWithSize:size];
    if ([cleanName isEqualToString:@"paper-plane"]) return [FAKFontAwesome paperPlaneIconWithSize:size];
    if ([cleanName isEqualToString:@"lightbulb"]) return [FAKFontAwesome lightbulbOIconWithSize:size];
    if ([cleanName isEqualToString:@"phone"]) return [FAKFontAwesome phoneIconWithSize:size];
    if ([cleanName isEqualToString:@"laptop"]) return [FAKFontAwesome laptopIconWithSize:size];
    if ([cleanName isEqualToString:@"tv"]) return [FAKFontAwesome tvIconWithSize:size];
    if ([cleanName isEqualToString:@"headphones"]) return [FAKFontAwesome headphonesIconWithSize:size];
    if ([cleanName isEqualToString:@"database"]) return [FAKFontAwesome databaseIconWithSize:size];
    if ([cleanName isEqualToString:@"server"]) return [FAKFontAwesome serverIconWithSize:size];
    if ([cleanName isEqualToString:@"code"]) return [FAKFontAwesome codeIconWithSize:size];
    if ([cleanName isEqualToString:@"terminal"]) return [FAKFontAwesome terminalIconWithSize:size];
    if ([cleanName isEqualToString:@"chart-bar"]) return [FAKFontAwesome barChartIconWithSize:size];
    if ([cleanName isEqualToString:@"users"]) return [FAKFontAwesome usersIconWithSize:size];
    if ([cleanName isEqualToString:@"building"]) return [FAKFontAwesome buildingIconWithSize:size];
    if ([cleanName isEqualToString:@"car"]) return [FAKFontAwesome carIconWithSize:size];
    if ([cleanName isEqualToString:@"plane"]) return [FAKFontAwesome planeIconWithSize:size];
    if ([cleanName isEqualToString:@"bicycle"]) return [FAKFontAwesome bicycleIconWithSize:size];
    if ([cleanName isEqualToString:@"leaf"]) return [FAKFontAwesome leafIconWithSize:size];
    if ([cleanName isEqualToString:@"fire"]) return [FAKFontAwesome fireIconWithSize:size];
    if ([cleanName isEqualToString:@"snowflake"]) return [FAKFontAwesome snowflakeOIconWithSize:size];
    if ([cleanName isEqualToString:@"tree"]) return [FAKFontAwesome treeIconWithSize:size];
    if ([cleanName isEqualToString:@"mountain"]) return [FAKFontAwesome sortAmountAscIconWithSize:size];
    
    return nil;
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
