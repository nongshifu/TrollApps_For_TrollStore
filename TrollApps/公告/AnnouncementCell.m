// AnnouncementCell.m
#import "AnnouncementCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface AnnouncementCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *priorityLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *iconImageView;

@end

@implementation AnnouncementCell

#pragma mark - 子类必须重写的方法

- (void)setupUI {
    // 卡片视图
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor systemBackgroundColor];
    self.cardView.layer.cornerRadius = 12;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardView.layer.shadowRadius = 4;
    self.cardView.layer.shadowOpacity = 0.1;
    [self.contentView addSubview:self.cardView];

    // 图标
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.layer.cornerRadius = 20;
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.backgroundColor = [UIColor systemGray6Color];
    [self.cardView addSubview:self.iconImageView];

    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.numberOfLines = 2;
    [self.cardView addSubview:self.titleLabel];

    // 摘要
    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.font = [UIFont systemFontOfSize:13];
    self.summaryLabel.textColor = [UIColor secondaryLabelColor];
    self.summaryLabel.numberOfLines = 4;
    [self.cardView addSubview:self.summaryLabel];

    // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.layer.cornerRadius = 4;
    self.statusLabel.clipsToBounds = YES;
    [self.cardView addSubview:self.statusLabel];

    // 类型标签
    self.typeLabel = [[UILabel alloc] init];
    self.typeLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    self.typeLabel.textAlignment = NSTextAlignmentCenter;
    self.typeLabel.backgroundColor = [UIColor systemBlueColor];
    self.typeLabel.textColor = [UIColor whiteColor];
    self.typeLabel.layer.cornerRadius = 4;
    self.typeLabel.clipsToBounds = YES;
    [self.cardView addSubview:self.typeLabel];

    // 优先级标签
    self.priorityLabel = [[UILabel alloc] init];
    self.priorityLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    self.priorityLabel.textAlignment = NSTextAlignmentCenter;
    self.priorityLabel.layer.cornerRadius = 4;
    self.priorityLabel.clipsToBounds = YES;
    [self.cardView addSubview:self.priorityLabel];

    // 时间标签
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    self.timeLabel.textColor = [UIColor tertiaryLabelColor];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.cardView addSubview:self.timeLabel];
}

- (void)setupConstraints {
    // 卡片 - 四边固定约束，父类contentView高度由内容撑开
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(4);
        make.left.equalTo(self.contentView);
        make.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-4);
    }];
    
    // 图标
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(12);
        make.centerY.equalTo(self.cardView);
        make.width.height.equalTo(@40);
    }];

    // 标题
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(12);
        make.left.equalTo(self.iconImageView.mas_right).offset(12);
        make.right.equalTo(self.cardView).offset(-80);
    }];

    // 摘要
    [self.summaryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.cardView).offset(-12);
    }];

    // 状态标签
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconImageView.mas_right).offset(12);
        make.top.equalTo(self.summaryLabel.mas_bottom).offset(12);
        make.bottom.equalTo(self.cardView).offset(-12);
        make.height.equalTo(@18);
        make.width.greaterThanOrEqualTo(@40);
    }];

    // 类型标签
    [self.typeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.statusLabel.mas_right).offset(8);
        make.centerY.equalTo(self.statusLabel);
        make.height.equalTo(@18);
        make.width.greaterThanOrEqualTo(@50);
    }];

    // 优先级标签
    [self.priorityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeLabel.mas_right).offset(8);
        make.centerY.equalTo(self.statusLabel);
        make.height.equalTo(@18);
        make.width.greaterThanOrEqualTo(@40);
    }];

    // 时间 - 位于底部右侧
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.cardView).offset(-12);
        make.bottom.equalTo(self.cardView).offset(-12);
    }];
}

- (void)configureWithModel:(id)model {
    if (![model isKindOfClass:[AnnouncementModel class]]) {
        return;
    }
    
    AnnouncementModel *announcement = (AnnouncementModel *)model;
    
    // 标题
    self.titleLabel.text = announcement.announcement_title;
    
    // 摘要
    self.summaryLabel.text = announcement.announcement_summary.length > 0 ? announcement.announcement_summary : @"暂无摘要";
    
    // 图标
    if (announcement.announcement_icon.length > 0) {
        self.iconImageView.image = [UIImage fak_imageWithIconName:announcement.announcement_icon size:30 color:[UIColor randomColorWithAlpha:1]];
        self.iconImageView.tintColor = [UIColor systemBlueColor];
    } else {
        self.iconImageView.image = [UIImage systemImageNamed:@"megaphone.fill"];
        self.iconImageView.tintColor = [UIColor systemBlueColor];
    }
    // 背景
    if(announcement.announcement_color.length > 0){
        UIColor *color = [self colorWithHexString:announcement.announcement_color];
        self.cardView.backgroundColor = [color colorWithAlphaComponent:0.05];
    }
    
    // 状态
    [self configureStatusLabel:announcement.announcement_status];
    
    // 类型
    [self configureTypeLabel:announcement.announcement_type];
    
    // 优先级
    [self configurePriorityLabel:announcement.announcement_priority];
    
    // 时间
    self.timeLabel.text = [announcement formattedCreateTime];
    
}

#pragma mark - Helper Methods

- (void)configureStatusLabel:(AnnouncementStatus)status {
    NSString *title;
    UIColor *bgColor;
    UIColor *textColor;

    switch (status) {
        case AnnouncementStatusDraft:
            title = @"草稿";
            bgColor = [UIColor systemGray5Color];
            textColor = [UIColor systemGrayColor];
            break;
        case AnnouncementStatusPublished:
            title = @"已发布";
            bgColor = [UIColor systemGreenColor];
            textColor = [UIColor whiteColor];
            break;
        case AnnouncementStatusOffline:
            title = @"已下架";
            bgColor = [UIColor systemOrangeColor];
            textColor = [UIColor whiteColor];
            break;
        case AnnouncementStatusDeleted:
            title = @"已删除";
            bgColor = [UIColor systemRedColor];
            textColor = [UIColor whiteColor];
            break;
        default:
            title = @"未知";
            bgColor = [UIColor systemGray5Color];
            textColor = [UIColor systemGrayColor];
            break;
    }

    self.statusLabel.text = [NSString stringWithFormat:@" %@ ", title];
    self.statusLabel.backgroundColor = bgColor;
    self.statusLabel.textColor = textColor;
}

- (void)configureTypeLabel:(AnnouncementType)type {
    NSString *title;

    switch (type) {
        case AnnouncementTypeNormal:
            title = @"普通";
            break;
        case AnnouncementTypeSystem:
            title = @"系统";
            break;
        case AnnouncementTypeActivity:
            title = @"活动";
            break;
        case AnnouncementTypeMaintenance:
            title = @"维护";
            break;
        default:
            title = @"未知";
            break;
    }

    self.typeLabel.text = [NSString stringWithFormat:@" %@ ", title];
}

- (void)configurePriorityLabel:(AnnouncementPriority)priority {
    NSString *title;
    UIColor *bgColor;

    switch (priority) {
        case AnnouncementPriorityNormal:
            title = @"普通";
            bgColor = [UIColor systemGray5Color];
            break;
        case AnnouncementPriorityImportant:
            title = @"重要";
            bgColor = [UIColor systemOrangeColor];
            break;
        case AnnouncementPriorityUrgent:
            title = @"紧急";
            bgColor = [UIColor systemRedColor];
            break;
        default:
            title = @"未知";
            bgColor = [UIColor systemGray5Color];
            break;
    }

    self.priorityLabel.text = [NSString stringWithFormat:@" %@ ", title];
    self.priorityLabel.backgroundColor = bgColor;
    self.priorityLabel.textColor = [UIColor whiteColor];
}

#pragma mark - Helper Methods

- (UIColor *)colorWithHexString:(NSString *)hexString {
    if (!hexString || hexString.length == 0) {
        return [UIColor systemBackgroundColor];
    }
    
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (cleanString.length != 6) {
        return [UIColor systemBackgroundColor];
    }
    
    unsigned int red, green, blue;
    [[NSScanner scannerWithString:[cleanString substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&red];
    [[NSScanner scannerWithString:[cleanString substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&green];
    [[NSScanner scannerWithString:[cleanString substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&blue];
    
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}
@end
