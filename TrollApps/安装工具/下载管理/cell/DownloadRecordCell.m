//
//  DownloadRecordCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/10.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DownloadRecordCell.h"
#import "DownloadRecordModel.h"
#import "FileInstallManager.h"
#import "AppInfoModel.h"
#import <Masonry/Masonry.h>


#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@interface DownloadRecordCell ()

@property (nonatomic, strong) DownloadRecordModel *downloadRecordModel;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UILabel *downloadTimeLabel;
@property (nonatomic, strong) UILabel *pointsLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIView *dividerView;

@end

@implementation DownloadRecordCell

#pragma mark - 初始化



#pragma mark - 子类必须重写的方法

/**
 配置UI元素
 */
- (void)setupUI {
    // 卡片容器视图
    self.cardView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kWidth)];
    self.cardView.backgroundColor = [self dynamicSecondaryBackgroundColor];
    self.cardView.layer.cornerRadius = 16;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.1;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardView.layer.shadowRadius = 8;
    self.cardView.layer.masksToBounds = NO;
    [self.contentView addSubview:self.cardView];
    
    
    // 应用名称标签
    self.appNameLabel = [[UILabel alloc] init];
    self.appNameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.appNameLabel.textColor = [self dynamicLabelColor];
    self.appNameLabel.numberOfLines = 2;
    [self.cardView addSubview:self.appNameLabel];
    
    // 分隔线
    self.dividerView = [[UIView alloc] init];
    self.dividerView.backgroundColor = [self dynamicSeparatorColor];
    [self.cardView addSubview:self.dividerView];
    
    // 版本号标签
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.font = [UIFont systemFontOfSize:14];
    self.versionLabel.textColor = [self dynamicSecondaryLabelColor];
    [self.cardView addSubview:self.versionLabel];
    
    // 下载时间标签
    self.downloadTimeLabel = [[UILabel alloc] init];
    self.downloadTimeLabel.font = [UIFont systemFontOfSize:14];
    self.downloadTimeLabel.textColor = [self dynamicSecondaryLabelColor];
    [self.cardView addSubview:self.downloadTimeLabel];
    
    // 扣除点数标签
    self.pointsLabel = [[UILabel alloc] init];
    self.pointsLabel.font = [UIFont systemFontOfSize:14];
    self.pointsLabel.textColor = [self dynamicSecondaryLabelColor];
    [self.cardView addSubview:self.pointsLabel];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentRight;
    [self.cardView addSubview:self.statusLabel];
    
    // 下载按钮
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.downloadButton setTitle:@"重新下载" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.downloadButton.backgroundColor = [self dynamicTintColor];
    self.downloadButton.layer.cornerRadius = 10;
    self.downloadButton.layer.shadowColor = [self dynamicTintColor].CGColor;
    self.downloadButton.layer.shadowOpacity = 0.2;
    self.downloadButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.downloadButton.layer.shadowRadius = 4;
    [self.downloadButton addTarget:self action:@selector(downloadButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.downloadButton];
    // 约束卡片视图
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(kWidth));
    }];
    
    // 约束卡片视图
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 16, 8, 16));
    }];
}

/**
 配置布局约束
 */
- (void)setupConstraints {
    // 应用名称标签约束
    [self.appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.cardView).offset(20);
        make.right.equalTo(self.cardView).offset(-20);
        make.height.greaterThanOrEqualTo(@24);
    }];
    
    // 分隔线约束
    [self.dividerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameLabel.mas_bottom).offset(16);
        make.left.equalTo(self.cardView).offset(20);
        make.right.equalTo(self.cardView).offset(-20);
        make.height.mas_equalTo(1);
    }];
    
    // 版本号标签约束
    [self.versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dividerView.mas_bottom).offset(16);
        make.left.equalTo(self.cardView).offset(20);
        make.height.mas_equalTo(20);
    }];
    
    // 下载时间标签约束
    [self.downloadTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.versionLabel.mas_bottom).offset(12);
        make.left.equalTo(self.cardView).offset(20);
        make.height.mas_equalTo(20);
    }];
    
    // 扣除点数标签约束
    [self.pointsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.downloadTimeLabel.mas_bottom).offset(12);
        make.left.equalTo(self.cardView).offset(20);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.cardView).offset(-20);
    }];
    
    // 状态标签约束
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dividerView.mas_bottom).offset(16);
        make.right.equalTo(self.cardView).offset(-20);
        make.height.mas_equalTo(20);
    }];
    
    // 下载按钮约束
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {

        make.right.equalTo(self.cardView).offset(-20);
        make.bottom.equalTo(self.pointsLabel);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(30);
    }];
    [self.cardView addColorBallsWithCount:10 ballradius:150 minDuration:30 maxDuration:100 UIBlurEffectStyle:UIBlurEffectStyleProminent UIBlurEffectAlpha:0.9 ballalpha:0.9];
}

#pragma mark - 数据绑定
- (void)configureWithModel:(id)model {
    if (![model isKindOfClass:[DownloadRecordModel class]]) return;
    
    self.downloadRecordModel = (DownloadRecordModel *)model;
    
    // 设置应用名称
    self.appNameLabel.text = self.downloadRecordModel.appName;
    
    // 设置版本号
    self.versionLabel.text = [NSString stringWithFormat:@"版本号: %@", self.downloadRecordModel.versionName ?: @"未知"];
    
    // 设置下载时间
    self.downloadTimeLabel.text = [NSString stringWithFormat:@"下载时间: %@", [self formatDateTime:self.downloadRecordModel.downloadTime]];
    
    // 设置扣除点数
    self.pointsLabel.text = [NSString stringWithFormat:@"扣除点数: %ld", (long)self.downloadRecordModel.downloadPoints];
    
    // 设置状态
    [self setupStatusLabel];
}

#pragma mark - 辅助方法

/**
 格式化日期时间
 @param dateString 原始日期字符串
 @return 格式化后的日期字符串
 */
- (NSString *)formatDateTime:(NSString *)dateString {
    if (!dateString || dateString.length == 0) {
        return @"未知";
    }
    
    // 假设原始日期格式为 "yyyy-MM-dd HH:mm:ss"
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    inputFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [inputFormatter dateFromString:dateString];
    
    if (!date) {
        return dateString;
    }
    
    // 输出格式为 "MM-dd HH:mm"
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    outputFormatter.dateFormat = @"MM-dd HH:mm";
    return [outputFormatter stringFromDate:date];
}

/**
 设置状态标签
 */
- (void)setupStatusLabel {
    switch (self.downloadRecordModel.status) {
        case 0:
            self.statusLabel.text = @"下载成功";
            self.statusLabel.textColor = [UIColor systemGreenColor];
            break;
        case 1:
            self.statusLabel.text = @"下载失败";
            self.statusLabel.textColor = [UIColor systemRedColor];
            break;
        case 2:
            self.statusLabel.text = @"已取消";
            self.statusLabel.textColor = [UIColor systemOrangeColor];
            break;
        default:
            self.statusLabel.text = @"未知状态";
            self.statusLabel.textColor = [self dynamicSecondaryLabelColor];
            break;
    }
}

/**
 获取动态背景色
 @return 适配黑暗/亮色主题的背景色
 */
- (UIColor *)dynamicSecondaryBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemBackgroundColor];
    } else {
        return [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    }
}

/**
 获取动态标签色
 @return 适配黑暗/亮色主题的标签色
 */
- (UIColor *)dynamicLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    } else {
        return [UIColor blackColor];
    }
}

/**
 获取动态次要标签色
 @return 适配黑暗/亮色主题的次要标签色
 */
- (UIColor *)dynamicSecondaryLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    } else {
        return [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    }
}

/**
 获取动态分隔线色
 @return 适配黑暗/亮色主题的分隔线色
 */
- (UIColor *)dynamicSeparatorColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor separatorColor];
    } else {
        return [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    }
}

/**
 获取动态主色调
 @return 适配黑暗/亮色主题的主色调
 */
- (UIColor *)dynamicTintColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemBlueColor];
    } else {
        return [UIColor blueColor];
    }
}



#pragma mark - 按钮点击事件

/**
 下载按钮点击事件
 */
- (void)downloadButtonClicked {
    // 这里可以添加下载逻辑，例如调用DownloadManagerViewController进行下载
    NSLog(@"重新下载应用downloadUrl: %@", self.downloadRecordModel.downloadUrl);
    [AppInfoModel getDownloadLinkWithAppId:self.downloadRecordModel.appId success:^(NSURL * _Nonnull downloadURL, NSDictionary * _Nonnull json) {
        [SVProgressHUD showSuccessWithStatus:@"开始下载"];
        [SVProgressHUD dismissWithDelay:1];
        [[FileInstallManager sharedManager] installFileWithURL:downloadURL completion:^(BOOL success, NSError * _Nullable error) {
            [SVProgressHUD dismiss];
        }];
        
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:@"连接不合法"];
        [SVProgressHUD dismissWithDelay:1];
    }];
   
    
}

#pragma mark - 主题变化处理

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 更新主题相关的UI元素
    UIView *cardView = self.contentView.subviews.firstObject;
    cardView.backgroundColor = [self dynamicSecondaryBackgroundColor];
    
    self.appNameLabel.textColor = [self dynamicLabelColor];
    self.versionLabel.textColor = [self dynamicSecondaryLabelColor];
    self.downloadTimeLabel.textColor = [self dynamicSecondaryLabelColor];
    self.pointsLabel.textColor = [self dynamicSecondaryLabelColor];
    self.dividerView.backgroundColor = [self dynamicSeparatorColor];
    self.downloadButton.backgroundColor = [self dynamicTintColor];
    self.downloadButton.layer.shadowColor = [self dynamicTintColor].CGColor;
}

@end
