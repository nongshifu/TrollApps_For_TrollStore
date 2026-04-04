//
//  AppIconCell.m
//  TrollApps
//
//  Created by 十三哥 on 2026/4/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "AppIconCell.h"
#import <Masonry/Masonry.h>

@implementation AppIconCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.2];
    self.selectionStyle = UITableViewCellSelectionStyleGray;

    // 头像
    self.appIconView = [[UIImageView alloc] init];
    self.appIconView.contentMode = UIViewContentModeScaleAspectFill;
    self.appIconView.clipsToBounds = YES;
    self.appIconView.layer.cornerRadius = 10;

    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.titleLabel.textColor = [UIColor labelColor];

    // 副标题
    self.subTitleLabel = [[UILabel alloc] init];
    self.subTitleLabel.font = [UIFont systemFontOfSize:12];
    self.subTitleLabel.textColor = [UIColor secondaryLabelColor];

    [self.contentView addSubview:self.appIconView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subTitleLabel];

    // 固定头像 60x60
    CGFloat iconSize = 60;

    // ========== Masonry 布局 ==========
    [self.appIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(16);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(iconSize));
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.appIconView.mas_right).offset(12);
        make.top.equalTo(self.contentView.mas_top).offset(18);
        make.right.equalTo(self.contentView.mas_right).offset(-16);
    }];

    [self.subTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.appIconView.mas_right).offset(12);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.right.equalTo(self.contentView.mas_right).offset(-16);
    }];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

