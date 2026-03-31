//
//  MinWebToolViewCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/20.
//

#import "MinWebToolViewCell.h"
#import "WebToolManager.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED NO // .M当前文件单独启用

@interface MinWebToolViewCell ()

// 左侧头像
@property (nonatomic, strong) UIImageView *avatarImgView;

// 右侧内容区
@property (nonatomic, strong) UILabel *toolNameLabel;      // 工具名称（最多2行）
@property (nonatomic, strong) UILabel *updateTimeLabel;    // 更新日期

@property (nonatomic, strong) UILabel *descLabel;          // 简介（最多4行）
@property (nonatomic, strong) UIButton * refreshButton;    // 刷新按钮
@end

@implementation MinWebToolViewCell

#pragma mark - 初始化

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.6]
                                                          darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.4]];
   
    self.contentView.clipsToBounds = YES; // 确保子视图不超出圆角范围
    
    // 1. 左侧头像
    self.avatarImgView = [[UIImageView alloc] init];
    self.avatarImgView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImgView.clipsToBounds = YES;
    self.avatarImgView.layer.cornerRadius = 15; // 圆角15
    self.avatarImgView.backgroundColor = [UIColor lightGrayColor]; // 占位背景
    [self.contentView addSubview:self.avatarImgView];
    
    // 2. 工具名称（最多2行）
    self.toolNameLabel = [[UILabel alloc] init];
    self.toolNameLabel.font = [UIFont boldSystemFontOfSize:14];
    self.toolNameLabel.textColor = [UIColor labelColor];
    self.toolNameLabel.numberOfLines = 1; // 最多2行
    self.toolNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.toolNameLabel];
    
    // 3. 更新日期
    self.updateTimeLabel = [[UILabel alloc] init];
    self.updateTimeLabel.font = [UIFont systemFontOfSize:7];
    self.updateTimeLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.updateTimeLabel];
    
    // 5. 简介（最多4行）
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = [UIFont systemFontOfSize:12];
    self.descLabel.textColor = [UIColor secondaryLabelColor];
    self.descLabel.numberOfLines = 2; // 最多4行
    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.descLabel];
    
    self.refreshButton = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"goforward"] target:self action:@selector(refreshButtonAction:)];
    self.refreshButton.userInteractionEnabled = YES;
    [self.contentView addSubview:self.refreshButton];
    
}

#pragma mark - 约束设置

- (void)setupConstraints {
    
    // 正确约束：contentView 撑满 cell，不限制高度
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self); // 仅约束边缘，高度由内容决定
        make.width.equalTo(@(200));
    }];
    // 左侧头像：固定宽高60，左、上、下有间距
    [self.avatarImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.top.equalTo(self.contentView).offset(10);
        make.width.height.equalTo(@30); // 头像大小60x60（圆角15，视觉上更协调）
    }];
    
    
    // 工具名称：左接头像，右接使用按钮，顶部与头像对齐
    [self.toolNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImgView);
        make.left.equalTo(self.avatarImgView.mas_right).offset(10);
        make.right.equalTo(self.contentView.mas_right).offset(-10);
        
    }];
    
    // 更新日期：在名称下方，左、右与名称对齐
    [self.updateTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImgView.mas_right).offset(10);
        make.right.equalTo(self.contentView.mas_right).offset(-10);
        make.top.equalTo(self.toolNameLabel.mas_bottom).offset(5);
    }];
    
    // 简介：左接contentView左侧，右接contentView右侧（占满宽度），在标签下方
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImgView.mas_bottom).offset(5);
        make.left.equalTo(self.contentView.mas_left).offset(10);
        make.right.equalTo(self.contentView.mas_right).offset(-10);
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).offset(-10);
    }];
    // 右下角刷新按钮
    [self.refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView.mas_right).offset(-10);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-10);
        make.width.height.equalTo(@20); // 头像大小60x60（圆角15，视觉上更协调）
    }];

}

#pragma mark - 数据绑定

- (void)bindViewModel:(id)viewModel {
    self.model = viewModel;
    if (![viewModel isKindOfClass:[WebToolModel class]]) return;
    self.webToolModel = (WebToolModel *)viewModel;
    
    // 绑定数据到UI
    self.toolNameLabel.text = self.webToolModel.tool_name;
    self.updateTimeLabel.text = [NSString stringWithFormat:@"%@", self.webToolModel.update_time];
    self.descLabel.text = self.webToolModel.tool_description;
    
    // 头像占位（实际项目中替换为工具图标URL）
    self.avatarImgView.image = [UIImage systemImageNamed:@"doc.text.fill"]; // 系统占位图
    NSString *iconUrlString = [NSString stringWithFormat:@"%@/%@/icon.png",localURL,self.webToolModel.tool_path];
    [self.avatarImgView sd_setImageWithURL:[NSURL URLWithString:iconUrlString]];
    
    
}

#pragma mark - Action

- (void)refreshButtonAction:(UIButton *)action{
    NSLog(@"点击了右下角刷新按钮: %@  %@ collectionView:%@", self.model,self.dataSource,self.collectionView);
    [[WebToolManager sharedManager] removeWebToolWithId:self.webToolModel.tool_id];
    [SVProgressHUD showWithStatus:@"刷新中"];
    [SVProgressHUD dismissWithDelay:1 completion:^{
        [SVProgressHUD showSuccessWithStatus:@"刷新完成"];
        [SVProgressHUD dismissWithDelay:1 completion:^{
            
        }];
    }];
    

}

@end
