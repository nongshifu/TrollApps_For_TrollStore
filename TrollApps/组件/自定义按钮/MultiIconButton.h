//
//  MultiIconButton.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/4/8.
//  Copyright © 2025 D-James. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>

NS_ASSUME_NONNULL_BEGIN

@interface MultiIconButton : UIButton

// 右侧图标
@property (nonatomic, strong) UIImage *rightImage;
// 顶部图标
@property (nonatomic, strong) UIImage *topImage;
// 底部图标
@property (nonatomic, strong) UIImage *bottomImage;
// 左侧图标
@property (nonatomic, strong) UIImage *leftImage;
// 顶部图标和文字的间隔
@property (nonatomic, assign) CGFloat topImageTextSpacing;
// 底部图标和文字的间隔
@property (nonatomic, assign) CGFloat bottomImageTextSpacing;
// 图标与文字间距属性（可外部设置）
@property (nonatomic, assign) CGFloat imageTextSpacing;

// 按钮高度约束是否包括顶部和底部图标
@property (nonatomic, assign) BOOL heightIncludesTopImages;
// 按钮高度约束是否包括顶部和底部图标
@property (nonatomic, assign) BOOL heightIncludesBottomImages;

@property (nonatomic, strong) UIImageView *rightImageView;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UIImageView *bottomImageView;
@property (nonatomic, strong) UIImageView *leftImageView;

@property (nonatomic, strong) UIView *backgroundColorView;

// 设置不同状态下的文字字体
- (void)setTitleFont:(UIFont *)font forState:(UIControlState)state;
// 设置四个方向的图标
- (void)setLeftImage:(UIImage *)image forState:(UIControlState)state;
- (void)setRightImage:(UIImage *)image forState:(UIControlState)state;
- (void)setTopImage:(UIImage *)image forState:(UIControlState)state;
- (void)setBottomImage:(UIImage *)image forState:(UIControlState)state;

@end    

NS_ASSUME_NONNULL_END
