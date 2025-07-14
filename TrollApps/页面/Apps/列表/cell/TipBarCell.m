//  TipBarCell.m
//  NewSoulChat
//
//  Created by 十三哥 on 2025/2/24.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "TipBarCell.h"
#import <Masonry/Masonry.h>
#import "TipBarModel.h"
@interface TipBarCell ()


@property (nonatomic, strong) TipBarModel *tipBarModel;

@end

@implementation TipBarCell

#pragma mark - 子类必须重写的方法
/**
 配置UI元素
 */
- (void)setupUI{
    self.contentView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.95];
    self.contentView.layer.cornerRadius = 3;
    self.contentView.layer.masksToBounds = YES;
    
    // 初始化图标视图
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *iconTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iconImageViewTapped)];
    [self.iconImageView addGestureRecognizer:iconTapGesture];
    [self.contentView addSubview:self.iconImageView];

    // 初始化文本标签
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *textTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textLabelTapped)];
    [self.textLabel addGestureRecognizer:textTapGesture];
    self.textLabel.font = [UIFont systemFontOfSize:13];
    self.textLabel.textColor = [UIColor secondaryLabelColor];
    self.textLabel.numberOfLines = 0;
    [self.contentView addSubview:self.textLabel];

    // 初始化左边按钮
    self.leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.leftButton.backgroundColor = [[UIColor linkColor] colorWithAlphaComponent:0.3];
    self.leftButton.layer.cornerRadius = 12.5;
    self.leftButton.titleLabel.font = [UIFont systemFontOfSize:11];
    self.leftButton.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    [self.leftButton addTarget:self action:@selector(leftButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.leftButton];

    // 初始化右边按钮
    self.rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.rightButton.backgroundColor = [[UIColor linkColor] colorWithAlphaComponent:0.1];
    self.rightButton.layer.cornerRadius = 12.5;
    self.rightButton.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    self.rightButton.titleLabel.font = [UIFont systemFontOfSize:11];
    [self.rightButton addTarget:self action:@selector(rightButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.rightButton];
}

/**
 配置布局约束
 */
- (void)setupConstraints{
    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.iconImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@30);
    }];

    [self.textLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconImageView.mas_right).offset(10);
        make.centerY.equalTo(self.contentView);
        make.right.lessThanOrEqualTo(self.leftButton.mas_left).offset(-10);
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).offset(-10);
    }];

    [self.leftButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.rightButton.mas_left).offset(-10);
        make.centerY.equalTo(self.contentView);
        make.height.equalTo(@25);
        make.width.greaterThanOrEqualTo(@20);
        make.width.lessThanOrEqualTo(@100);
    }];

    [self.rightButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-10);
        make.centerY.equalTo(self.contentView);
        make.height.equalTo(@25);
        make.width.greaterThanOrEqualTo(@20);
        make.width.lessThanOrEqualTo(@100);
    }];
}

/**
 数据绑定方法
 @param model 数据模型
 */
- (void)configureWithModel:(id)model{
    _tipBarModel = (TipBarModel *)model;
    UIImage *icon = nil;
    
    if ([_tipBarModel.iconURL containsString:@"http"]) {
        // 网络图片，使用 SDWebImage 异步加载
        NSURL *imageURL = [NSURL URLWithString:_tipBarModel.iconURL];
        [self.iconImageView sd_setImageWithURL:imageURL placeholderImage:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error) {
                NSLog(@"图片加载失败: %@", error.localizedDescription);
            }
        }];
    } else {
        // 系统图标
        icon = [UIImage systemImageNamed:_tipBarModel.iconURL];
        if(!icon) icon = [UIImage imageNamed:_tipBarModel.iconURL];
        self.iconImageView.image = icon;
    }
    
    self.textLabel.text = _tipBarModel.tipText;
    
    [self.leftButton setTitle:_tipBarModel.leftButtonText forState:UIControlStateNormal];
    [self.rightButton setTitle:_tipBarModel.rightButtonText forState:UIControlStateNormal];

    // 强制更新按钮的布局以自适应文字
    [self.leftButton sizeToFit];
    [self.rightButton sizeToFit];
}

#pragma mark - 点击事件处理
- (void)iconImageViewTapped {
    if ([self.tipBarDelegate respondsToSelector:@selector(tipBarCell:didTapElementWithModel:buttonType:sender:)]) {
        [self.tipBarDelegate tipBarCell:self
              didTapElementWithModel:self.tipBarModel
                         buttonType:0
                           sender:self.iconImageView];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kTipBarCellTappedNotification object:self userInfo:@{@"cell": self.tipBarModel, @"buttonType": @(0)}];
}

- (void)textLabelTapped {
    if ([self.tipBarDelegate respondsToSelector:@selector(tipBarCell:didTapElementWithModel:buttonType:sender:)]) {
        [self.tipBarDelegate tipBarCell:self
              didTapElementWithModel:self.tipBarModel
                         buttonType:1
                           sender:self.textLabel];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kTipBarCellTappedNotification object:self userInfo:@{@"model": self.tipBarModel, @"buttonType": @(1)}];
}

- (void)leftButtonTapped {
    self.leftButton.backgroundColor = [[UIColor linkColor] colorWithAlphaComponent:0.3];
    self.rightButton.backgroundColor = [[UIColor linkColor] colorWithAlphaComponent:0.1];
    
    if ([self.tipBarDelegate respondsToSelector:@selector(tipBarCell:didTapElementWithModel:buttonType:sender:)]) {
        [self.tipBarDelegate tipBarCell:self
              didTapElementWithModel:self.tipBarModel
                         buttonType:2
                           sender:self.leftButton];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kTipBarCellTappedNotification object:self userInfo:@{@"model": self.tipBarModel, @"buttonType": @(2)}];
}

- (void)rightButtonTapped {
    self.leftButton.backgroundColor = [[UIColor linkColor] colorWithAlphaComponent:0.1];
    self.rightButton.backgroundColor = [[UIColor linkColor] colorWithAlphaComponent:0.3];
    
    if ([self.tipBarDelegate respondsToSelector:@selector(tipBarCell:didTapElementWithModel:buttonType:sender:)]) {
        [self.tipBarDelegate tipBarCell:self
              didTapElementWithModel:self.tipBarModel
                         buttonType:3
                           sender:self.rightButton];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kTipBarCellTappedNotification object:self userInfo:@{@"model": self.tipBarModel, @"buttonType": @(3)}];
}


@end
