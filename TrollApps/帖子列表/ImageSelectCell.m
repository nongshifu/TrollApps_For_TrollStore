//
//  ImageSelectCell.m
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "ImageSelectCell.h"
#import <Masonry/Masonry.h>
@implementation ImageSelectCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    // 图片视图
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.imageView];
    
    // 删除按钮
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteButton setImage:[UIImage systemImageNamed:@"trash.circle"] forState:UIControlStateNormal]; // 替换为你的删除图标
    self.deleteButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self.deleteButton setTintColor:[UIColor redColor]];
    self.deleteButton.layer.cornerRadius = 12;
    self.deleteButton.clipsToBounds = YES;
    [self.contentView addSubview:self.deleteButton];
    
    // 布局约束
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.contentView).inset(2);
        make.width.height.equalTo(@24);
    }];
}

@end
