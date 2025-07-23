//
//  EmptyView.m
//  NewSoulChat
//
//  Created by 十三哥 on 2025/4/5.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "EmptyView.h"
#import <Masonry/Masonry.h> // 引入 Masonry

@implementation EmptyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.alpha = 0.5;
    [self addSubview:_imageView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:16];
    _titleLabel.textColor = [UIColor grayColor];
    _titleLabel.text = @"";
    _titleLabel.numberOfLines = 0;
    [self addSubview:_titleLabel];
    
    _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_actionButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
    _actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    _actionButton.layer.cornerRadius = 5;
    _actionButton.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    [self addSubview:_actionButton];
    [self updateConstraints];
    
    
}
- (void)updateConstraints{
    [super updateConstraints];
    
    // Masonry 约束
    if(self.superview && self.frame.size.width > 0){
        self.frame = self.superview.bounds;
        // Masonry 约束
        
        [_imageView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self).offset(-100); // 垂直居中并向上偏移50
            make.width.height.mas_equalTo(100);    // 固定宽高
        }];
        
        [_titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_imageView.mas_bottom).offset(20); // 图片下方20pt
            make.leading.equalTo(self).offset(20);  // 左右边距20
            make.trailing.equalTo(self).offset(-20);
        }];
        
        [_actionButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_titleLabel.mas_bottom).offset(20); // 文字下方20pt
            make.centerX.equalTo(self);             // 水平居中
            make.width.mas_equalTo(120);            // 固定宽度
            make.height.mas_equalTo(40);            // 固定高度
        }];
        
    }
    
   
    // 添加动画效果
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
    
    [self layoutIfNeeded];
}

- (void)configureWithImage:(UIImage *)image title:(NSString *)title buttonTitle:(NSString *)buttonTitle {
    _imageView.image = image;
    _titleLabel.text = title;
    [_actionButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self updateConstraints];
}

@end
