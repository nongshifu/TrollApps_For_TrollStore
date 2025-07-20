//
//  UserModelCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "UserModelCell.h"
#import "UserModel.h"
#import "config.h"
#import <Masonry/Masonry.h>

@interface UserModelCell ()
@property (nonatomic, strong) UserModel *userModel;


// 卡片容器
@property (nonatomic, strong) UIView *cardView;

// 头像
@property (nonatomic, strong) UIImageView *avatarImageView;

// 主信息容器
@property (nonatomic, strong) UIView *infoContainer;

// 昵称+VIP标识
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UILabel *vipTagLabel;

// 个人简介
@property (nonatomic, strong) UILabel *bioLabel;

// 辅助信息（下载量+注册时间）
@property (nonatomic, strong) UILabel *statsLabel;

// 分隔线
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation UserModelCell

#pragma mark - 布局方法（空实现，强制子类重写）
- (void)setupUI {
    self.contentView.backgroundColor = [UIColor clearColor];
    // 卡片容器
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = UIColor.whiteColor;
    self.cardView.layer.cornerRadius = 12;
    self.cardView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.cardView.layer.shadowOpacity = 0.05;
    self.cardView.layer.shadowRadius = 4;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    [self.contentView addSubview:self.cardView];
    
    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 30;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.backgroundColor = UIColor.systemGray2Color;
    [self.cardView addSubview:self.avatarImageView];
    
    // 信息容器
    self.infoContainer = [[UIView alloc] init];
    [self.cardView addSubview:self.infoContainer];
    
    // 昵称
    self.nicknameLabel = [[UILabel alloc] init];
    self.nicknameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.nicknameLabel.textColor = UIColor.labelColor;
    [self.infoContainer addSubview:self.nicknameLabel];
    
    // VIP标识
    self.vipTagLabel = [[UILabel alloc] init];
    self.vipTagLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.vipTagLabel.textColor = UIColor.whiteColor;
    self.vipTagLabel.backgroundColor = UIColor.systemOrangeColor;
    self.vipTagLabel.layer.cornerRadius = 10;
    self.vipTagLabel.layer.masksToBounds = YES;
    self.vipTagLabel.textAlignment = NSTextAlignmentCenter;
    [self.infoContainer addSubview:self.vipTagLabel];
    
    // 个人简介
    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.font = [UIFont systemFontOfSize:13];
    self.bioLabel.textColor = UIColor.secondaryLabelColor;
    self.bioLabel.numberOfLines = 2; // 最多两行，超出省略
    [self.infoContainer addSubview:self.bioLabel];
    
    // 统计信息
    self.statsLabel = [[UILabel alloc] init];
    self.statsLabel.font = [UIFont systemFontOfSize:12];
    self.statsLabel.textColor = UIColor.tertiaryLabelColor;
    [self.infoContainer addSubview:self.statsLabel];
    
    // 分隔线
    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = UIColor.systemGray3Color;
    self.separatorView.alpha = 0.2;
    [self.cardView addSubview:self.separatorView];
}

#pragma mark - 布局约束方法（空实现，强制子类重写）
- (void)setupConstraints {
    // 卡片容器
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.contentView).inset(8);
        make.left.right.equalTo(self.contentView).inset(16);
    }];
    
    // 头像
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(16);
        make.left.equalTo(self.cardView).offset(16);
        make.width.height.equalTo(@60);
        make.bottom.lessThanOrEqualTo(self.cardView).offset(-16); // 避免内容过短时头像底部溢出
    }];
    
    // 信息容器
    [self.infoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView);
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.right.equalTo(self.cardView).offset(-16);
        make.bottom.equalTo(self.avatarImageView);
    }];
    
    // 昵称和VIP标签（水平排列）
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.infoContainer);
        make.left.equalTo(self.infoContainer);
    }];
    
    [self.vipTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.nicknameLabel);
        make.left.equalTo(self.nicknameLabel.mas_right).offset(6);
        make.height.equalTo(@20);
        make.width.greaterThanOrEqualTo(@36);
        make.right.lessThanOrEqualTo(self.infoContainer); // 避免标签过宽溢出
    }];
    
    // 个人简介（昵称下方）
    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(6);
        make.left.right.equalTo(self.infoContainer);
    }];
    
    // 统计信息（简介下方）
    [self.statsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioLabel.mas_bottom).offset(8);
        make.left.equalTo(self.infoContainer);
        make.right.lessThanOrEqualTo(self.infoContainer);
    }];
    
    // 分隔线（可选，用于区分不同类型的卡片）
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.cardView);
        make.height.equalTo(@0.5);
        make.bottom.equalTo(self.cardView);
    }];
}

#pragma mark - 数据绑定
- (void)configureWithModel:(id)model {
    self.userModel = (UserModel *)model;
    //更新UI
    [self configureWithUserModel:self.userModel];
}

- (void)configureWithUserModel:(UserModel *)model {
    if (!model) return;
    
    // 头像设置
    if (model.avatarImage) {
        self.avatarImageView.image = model.avatarImage;
    } else if (model.avatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:model.avatar]
                              placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    }
    
    // 昵称
    self.nicknameLabel.text = model.nickname ?: @"未知用户";
    
    // VIP标签
    BOOL isVipExpired = [UserModel isVIPExpiredWithDate:model.vip_expire_date];
    if (model.vip_level > 0 && !isVipExpired) {
        self.vipTagLabel.text = [NSString stringWithFormat:@"VIP %ld", (long)model.vip_level];
        self.vipTagLabel.hidden = NO;
    } else {
        self.vipTagLabel.hidden = YES;
    }
    
    // 个人简介
    self.bioLabel.text = model.bio ?: @"该用户未填写简介";
    
    // 统计信息（下载量+注册时间）
    NSString *downloads = [NSString stringWithFormat:@"下载: %ld次", (long)model.downloads_number];
    NSString *registerDate = [TimeTool getTimeformatDateForDay:model.register_time];
    self.statsLabel.text = [NSString stringWithFormat:@"%@ · 注册于 %@", downloads, registerDate];
    
    // 强制更新布局（确保高度计算准确）
    [self setNeedsLayout];
    [self layoutIfNeeded];
}


@end
