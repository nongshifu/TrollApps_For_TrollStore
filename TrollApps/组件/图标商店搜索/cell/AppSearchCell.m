//
//  AppSearchCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/4.
//

#import "AppSearchCell.h"

@implementation AppSearchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - 初始化子视图
- (void)setupSubviews {
    self.contentView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.6];
    // 图标（带圆角和阴影）
    self.iconView = [[UIImageView alloc] init];
    self.iconView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconView.layer.cornerRadius = 12;
    self.iconView.clipsToBounds = YES;
    self.iconView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.iconView.layer.shadowOpacity = 0.1;
    self.iconView.layer.shadowRadius = 4;
    self.iconView.layer.shadowOffset = CGSizeMake(0, 2);
    [self.contentView addSubview:self.iconView];
    
    // 应用名称
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:16];
    self.nameLabel.textColor = [UIColor labelColor];
    self.nameLabel.numberOfLines = 2;
    [self.contentView addSubview:self.nameLabel];
    
    // 开发者
    self.developerLabel = [[UILabel alloc] init];
    self.developerLabel.font = [UIFont systemFontOfSize:8];
    self.developerLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.developerLabel];
    
    // 评分容器（星星+数字）
    self.ratingContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.ratingContainer];
    
    // 评分标签
    self.ratingLabel = [[UILabel alloc] init];
    self.ratingLabel.font = [UIFont systemFontOfSize:11];
    self.ratingLabel.textColor = [UIColor secondaryLabelColor];
    [self.ratingContainer addSubview:self.ratingLabel];
    
    // 分类标签（带背景色）
    self.categoryLabel = [[UILabel alloc] init];
    self.categoryLabel.font = [UIFont systemFontOfSize:11];
    self.categoryLabel.textColor = [UIColor systemBlueColor];
    self.categoryLabel.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.1];
    self.categoryLabel.layer.cornerRadius = 4;
    self.categoryLabel.clipsToBounds = YES;
    
    [self.contentView addSubview:self.categoryLabel];
    
    // 价格标签
    self.priceLabel = [[UILabel alloc] init];
    self.priceLabel.font = [UIFont boldSystemFontOfSize:13];
    self.priceLabel.textColor = [UIColor systemGreenColor]; // 免费/价格用绿色突出
    [self.contentView addSubview:self.priceLabel];
    
    // 简介（多行）
    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.font = [UIFont systemFontOfSize:13];
    self.summaryLabel.textColor = [UIColor tertiaryLabelColor];
    self.summaryLabel.numberOfLines = 2; // 限制2行，避免过长
    [self.contentView addSubview:self.summaryLabel];
    
    self.installButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.installButton.layer.cornerRadius = 7;
    self.installButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
    [self.installButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.installButton setTitle:@"安装" forState:UIControlStateNormal];
    [self.installButton addTarget:self action:@selector(installAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.installButton];
}

#pragma mark - 布局约束
- (void)setupConstraints {
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.contentView).inset(12);
        make.width.height.equalTo(@60); // 图标大小80x80
    }];
    
    //安装
    [self.installButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.contentView).inset(12);
        make.width.equalTo(@50);
        make.height.equalTo(@20);
    }];
    
    //名字
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconView);
        make.left.equalTo(self.iconView.mas_right).offset(12);
        make.right.equalTo(self.installButton.mas_left).offset(-10);
    }];
    //开发者
    [self.developerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
        make.left.equalTo(self.nameLabel);
        make.right.lessThanOrEqualTo(self.contentView).inset(12);
    }];
    //评分
    [self.ratingContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.developerLabel.mas_bottom).offset(4);
        make.left.equalTo(self.nameLabel);
        make.height.equalTo(@16);
    }];
    //评分
    [self.ratingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.ratingContainer);
    }];
    //类别
    [self.categoryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.ratingContainer.mas_bottom).offset(6);
        make.left.equalTo(self.nameLabel);
        make.height.equalTo(@18);
    }];
    //价格
    [self.priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.categoryLabel);
        make.left.equalTo(self.categoryLabel.mas_right).offset(8);
    }];
    //摘要
    [self.summaryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.categoryLabel.mas_bottom).offset(8);
        make.left.equalTo(self.nameLabel);
        make.right.equalTo(self.contentView).inset(12);
        make.bottom.equalTo(self.contentView).inset(12); // 底部与cell保持12间距
    }];
    
    
}

#pragma mark - 配置数据
- (void)configureWithModel:(ITunesAppModel *)model {
    _model = model;
    // 图标
    [self.iconView sd_setImageWithURL:[NSURL URLWithString:model.artworkUrl512]
                      placeholderImage:[UIImage systemImageNamed:@"app.badge.fill"]];
    
    // 基本信息
    self.nameLabel.text = model.trackName;
    self.developerLabel.text = model.artistName;
    self.summaryLabel.text = model.appDescription;
    
    // 评分（处理null值）
    NSString *ratingText = model.averageUserRating ? [NSString stringWithFormat:@"评分: %.1f", model.averageUserRating] : @"暂无评分";
    self.ratingLabel.text = ratingText;
    
    // 分类（取一级分类）
    self.categoryLabel.text = model.primaryGenreName ?: @"未知分类";
    
    // 价格（免费显示"免费"，付费显示价格）
    if (model.price <= 0) {
        self.priceLabel.text = @"免费";
    } else {
        self.priceLabel.text = [NSString stringWithFormat:@"%@%.2f", model.currency, model.price];
    }
}

#pragma mark - 操作
- (void)installAction:(UIButton*)button {
   
    // 优先使用trackViewUrl，为空则用trackId构建
    NSString *appUrlString = self.model.trackViewUrl;
    if (appUrlString.length == 0 && self.model.trackId.length > 0) {
        // 构建链接格式：https://itunes.apple.com/app/id[trackId]?mt=8（mt=8表示iOS应用）
        appUrlString = [NSString stringWithFormat:@"https://itunes.apple.com/app/id%@?mt=8", self.model.trackId];
    }
    
    if (appUrlString.length == 0) {
        [SVProgressHUD showInfoWithStatus:@"无法获取应用信息"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    NSURL *appStoreURL = [NSURL URLWithString:appUrlString];
    if ([[UIApplication sharedApplication] canOpenURL:appStoreURL]) {
        [[UIApplication sharedApplication] openURL:appStoreURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showInfoWithStatus:@"打开失败，请手动搜索应用"];
                [SVProgressHUD dismissWithDelay:2];
                
            }
        }];
    }
}

@end
