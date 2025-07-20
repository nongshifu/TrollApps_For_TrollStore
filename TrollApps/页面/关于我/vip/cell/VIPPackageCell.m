//
//  VIPPackageCell.m
//  TrollApps
//

#import "VIPPackageCell.h"


@implementation VIPPackageCell


#pragma mark - 布局方法


- (void)setupConstraints {
    // 约束设置
    
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.top.equalTo(self.contentView).offset(0);
        make.right.equalTo(self.contentView).offset(0);
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).offset(0);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.cardView).inset(12);
    }];
    
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.cardView).offset(12);
        
        make.width.mas_equalTo(kWidth - 100);
    }];
    
    [self.priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descLabel.mas_bottom).offset(8);
        make.left.equalTo(self.cardView).inset(12);
        
        make.bottom.equalTo(self.cardView).inset(12);
    }];
    
    [self.recommendedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).inset(8);
        make.right.equalTo(self.cardView.mas_right).offset(-8);
        
        make.height.greaterThanOrEqualTo(@20);
    }];
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    // 卡片背景
    self.cardView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWidth, 150)];
    self.cardView.layer.cornerRadius = 10;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.1;
    self.cardView.layer.shadowRadius = 4;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    [self.contentView addSubview:self.cardView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.cardView addSubview:self.titleLabel];
    
    // 描述
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.textColor = [UIColor whiteColor];
    self.descLabel.font = [UIFont systemFontOfSize:12];
    self.descLabel.numberOfLines = 0;
    [self.cardView addSubview:self.descLabel];
    
    // 价格
    self.priceLabel = [[UILabel alloc] init];
    self.priceLabel.textColor = [UIColor whiteColor];
    self.priceLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.cardView addSubview:self.priceLabel];
    
    // 推荐标签（改为UIButton）
    self.recommendedLabel = [UIButton buttonWithType:UIButtonTypeCustom];
    self.recommendedLabel.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    self.recommendedLabel.layer.cornerRadius = 4;
    self.recommendedLabel.clipsToBounds = YES;
    self.recommendedLabel.contentEdgeInsets = UIEdgeInsetsMake(4, 8, 4, 8); // 设置按钮内边距
    self.recommendedLabel.userInteractionEnabled = NO; // 禁用点击事件
    [self.cardView addSubview:self.recommendedLabel];
    
    [self.cardView addColorBallsWithCount:10 ballradius:100 minDuration:50 maxDuration:200 UIBlurEffectStyle:UIBlurEffectStyleProminent UIBlurEffectAlpha:0.2 ballalpha:0.5];
    [self.cardView setRandomGradientBackgroundWithColorCount:2 alpha:0.8];
}

- (void)bindViewModel:(id)viewModel {
    self.vipPackage = (VIPPackage *)viewModel;
    [self configureWithPackage:self.vipPackage];
}

- (void)configureWithPackage:(VIPPackage *)package {
    self.titleLabel.text = package.title;
    self.descLabel.text = package.vipDescription;
    self.priceLabel.text = package.price;
    
    // 设置主题色
    self.cardView.backgroundColor = [UIColor colorWithHexString:package.themeColor] ?: [UIColor randomColorWithAlpha:0.5];
    
    // 显示/隐藏推荐标签
    if (package.isRecommended && package.recommendedTitle.length > 0) {
        self.recommendedLabel.hidden = NO;
        [self.recommendedLabel setTitle:package.recommendedTitle forState:UIControlStateNormal];
        self.recommendedLabel.backgroundColor = [UIColor randomColorWithAlpha:1];
        [self.recommendedLabel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        // 确保按钮根据内容调整大小
        [self.recommendedLabel sizeToFit];
    } else {
        self.recommendedLabel.hidden = YES;
    }
    
    // 标记需要更新布局
    [self setNeedsLayout];
}

// 关键：布局完成后设置渐变色（此时frame已确定）
- (void)layoutSubviews {
    [super layoutSubviews];
    // 约束生效后，cardView的frame已确定，此时添加渐变色
//    NSLog(@"约束生效后，cardView的frame已确定，此时添加渐变色");
//    if (self.cardView.currentGradientLayer) {
//        NSLog(@"约束生效后：%@",self.cardView.currentGradientLayer);
//        self.cardView.currentGradientLayer.frame = self.bounds;
//    }
//    if (self.cardView.colorBallsContainerLayer) {
//        NSLog(@"约束生效后colorBallsContainerLayer：%@",self.cardView.colorBallsContainerLayer);
//        self.cardView.colorBallsContainerLayer.frame = self.bounds;
//        [self updateColorBallsPositions];
//    }
    
}

@end
