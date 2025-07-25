//
//  AppVersionHistoryCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "AppVersionHistoryCell.h"
#import "AppVersionHistoryModel.h"
#import <Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface AppVersionHistoryCell ()
@property (nonatomic, strong) AppVersionHistoryModel *appVersionHistoryModel;

@end

@implementation AppVersionHistoryCell
#pragma mark - 子类必须重写的方法
/**
 配置UI元素（必须由子类实现）
 */
- (void)setupUI {
    _downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    _downloadButton.layer.cornerRadius = 5;
    _downloadButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.7];
    [_downloadButton addTarget:self action:@selector(downloadTap:) forControlEvents:UIControlEventTouchUpInside];
    _downloadButton.contentEdgeInsets = UIEdgeInsetsMake(3, 10, 3, 10);
    [self.contentView addSubview:_downloadButton];
    
    // 版本名称标签
    _versionNameLabel = [[UILabel alloc] init];
    _versionNameLabel.font = [UIFont boldSystemFontOfSize:16];
    _versionNameLabel.textColor = [UIColor labelColor];
    [self.contentView addSubview:_versionNameLabel];
    
    // 发布日期标签
    _releaseDateLabel = [[UILabel alloc] init];
    _releaseDateLabel.font = [UIFont systemFontOfSize:12];
    _releaseDateLabel.textColor = [UIColor orangeColor];
    [self.contentView addSubview:_releaseDateLabel];
    
    // 安装包大小标签
    _sizeLabel = [[UILabel alloc] init];
    _sizeLabel.font = [UIFont systemFontOfSize:12];
    _sizeLabel.textColor = [UIColor grayColor];
    _sizeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_sizeLabel];
    
    // 强制更新标签
    _mandatoryLabel = [[UILabel alloc] init];
    _mandatoryLabel.font = [UIFont boldSystemFontOfSize:10];
    _mandatoryLabel.textColor = [UIColor whiteColor];
    _mandatoryLabel.backgroundColor = [UIColor redColor];
    _mandatoryLabel.textAlignment = NSTextAlignmentCenter;
    _mandatoryLabel.layer.cornerRadius = 4;
    _mandatoryLabel.layer.masksToBounds = YES;
    _mandatoryLabel.hidden = YES; // 默认隐藏
    [self.contentView addSubview:_mandatoryLabel];
    
    // 更新说明标签
    _releaseNotesLabel = [[UILabel alloc] init];
    _releaseNotesLabel.font = [UIFont systemFontOfSize:14];
    _releaseNotesLabel.textColor = [UIColor secondaryLabelColor];
    _releaseNotesLabel.numberOfLines = 0; // 多行显示
    [self.contentView addSubview:_releaseNotesLabel];
    
    // 分隔线
    _separatorView = [[UIView alloc] init];
    _separatorView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    [self.contentView addSubview:_separatorView];
}

/**
 配置布局Masonry约束（必须由子类实现）
 */
- (void)setupConstraints {
    CGFloat padding = 5;
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
        make.width.equalTo(@(kWidth - 40));
    }];
    // 下载按钮
    [_downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(padding);
        make.right.equalTo(self.contentView.mas_right).offset(-padding);
    }];
    // 安装包大小
    [_sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_downloadButton.mas_bottom).offset(padding);
        make.right.equalTo(self.contentView).offset(-padding);
    }];
    // 版本名称
    [_versionNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(padding);
        make.left.equalTo(self.contentView).offset(padding);
    }];
    
    // 强制更新标签
    [_mandatoryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_versionNameLabel.mas_right).offset(8);
        make.centerY.equalTo(_versionNameLabel);
        make.height.equalTo(@18);
        make.width.greaterThanOrEqualTo(@30);
    }];
    
    // 发布日期
    [_releaseDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_versionNameLabel.mas_bottom).offset(4);
        make.left.equalTo(self.contentView).offset(padding);
    }];
    
    
    
    // 更新说明
    [_releaseNotesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_releaseDateLabel.mas_bottom).offset(12);
        make.left.equalTo(self.contentView).offset(padding);
        make.right.equalTo(self.contentView).offset(-padding);
        make.bottom.equalTo(self.contentView).offset(-padding);
    }];
    
    // 分隔线
    [_separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(padding);
        make.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView);
        make.height.equalTo(@0.5);
    }];
}

/**
 数据绑定方法（必须由子类实现）
 @param model 数据模型
 */
- (void)configureWithModel:(id)model {
    if (![model isKindOfClass:[AppVersionHistoryModel class]]) {
        return;
    }
    
    self.appVersionHistoryModel = (AppVersionHistoryModel *)model;
    AppVersionHistoryModel *version = self.appVersionHistoryModel;
    
    // 设置版本名称
    if (version.version_name && version.version_code > 0) {
        self.versionNameLabel.text = [NSString stringWithFormat:@"%@ (%ld)",
                                      version.version_name,
                                      (long)version.version_code];
    } else {
        self.versionNameLabel.text = @"未知版本";
    }
    
    // 设置发布日期（更健壮的日期格式化）
    if (version.release_date && version.release_date.length > 0) {
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date = [inputFormatter dateFromString:version.release_date];
        
        if (date) {
            NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
            [outputFormatter setDateFormat:@"yyyy-MM-dd"];
            self.releaseDateLabel.text = [outputFormatter stringFromDate:date];
        } else {
            // 日期格式不匹配，使用原始字符串
            self.releaseDateLabel.text = version.release_date;
        }
    } else {
        self.releaseDateLabel.text = @"未知日期";
    }
    
    // 设置安装包大小
    if (version.file_size > 0) {
        CGFloat sizeInMB = version.file_size / (1024.0 * 1024.0);
        self.sizeLabel.text = [NSString stringWithFormat:@"%.2f MB", sizeInMB];
    } else {
        self.sizeLabel.text = @"未知大小";
    }
    
    // 设置更新说明
    self.releaseNotesLabel.text = version.release_notes.length > 0 ?
                                 version.release_notes : @"无更新说明";
    
    // 设置强制更新标签
    self.mandatoryLabel.hidden = !version.is_mandatory;
    if (version.is_mandatory) {
        self.mandatoryLabel.text = @"强制更新";
    }
    
    // 确保布局更新（如果需要）
    [self setNeedsLayout];
}

#pragma mark - Size Calculation

+ (CGFloat)cellHeightForModel:(AppVersionHistoryModel *)model withWidth:(CGFloat)width {
    if (!model) {
        return 0;
    }
    
    CGFloat padding = 16;
    CGFloat contentWidth = width - padding * 2;
    
    // 计算更新说明的高度
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14]};
    CGRect rect = [model.release_notes boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:attributes
                                                      context:nil];
    CGFloat notesHeight = rect.size.height;
    
    // 其他元素的固定高度
    CGFloat fixedHeight = padding * 2 + 16 + 4 + 12 + 12; // 上下间距 + 版本名称 + 间距 + 发布日期 + 间距 + 底部间距
    
    return fixedHeight + notesHeight;
}

#pragma mark -- action

- (void)downloadTap:(UIButton*)button{
    NSURL * URL = [NSURL URLWithString:self.appVersionHistoryModel.download_url];
    if(!URL){
        [SVProgressHUD showErrorWithStatus:@"连接不合法"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:^(BOOL success) {
        if(success){
            
        }
    }];
}

@end
