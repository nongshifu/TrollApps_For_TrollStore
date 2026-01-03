//
//  AppInfoCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/1.
//

#import "AppInfoCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/AFNetworking.h>
#import "MiniButtonView.h"
#import "NewProfileViewController.h"
#import "MyCollectionViewController.h"
#import "NewAppFileModel.h"
#import "FileInstallManager.h"
#import "config.h"
#import "ShowOneAppViewController.h"
#import "DownloadManagerViewController.h"
#import "ContactHelper.h"
#import "HXPhotoURLConverter.h"
#import "QRCodeGeneratorViewController.h"
#import "ToolMessage.h"
#import "ChatListViewController.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED NO // .M当前文件单独启用

@interface AppInfoCell ()<MiniButtonViewDelegate,HXPhotoViewDelegate>

@property (nonatomic, strong) UIImageView *appIconImageView;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, strong) UIButton *appTypeButton;
@property (nonatomic, strong) UIButton *appVersionButton;
@property (nonatomic, strong) UIButton *appUpdateTimeButton;
@property (nonatomic, strong) UILabel *downloadLabel;
// 替换为UITextView（支持选中）
@property (nonatomic, strong) UITextView *appDescriptionTextView;
// 替换为UITextView（支持选中）
@property (nonatomic, strong) UITextView *releaseNotesTextView;
@property (nonatomic, strong) MiniButtonView *statsMiniButtonView; // 统计按钮容器
@property (nonatomic, strong) MiniButtonView *tagMiniButtonView; // 标签容器
@property (nonatomic, strong) UIButton *downloadButton;


//图片选择器
@property (nonatomic, strong) UIView *imageStackView;
@property (nonatomic, strong) HXPhotoView *photoView;
@property (nonatomic, strong) HXPhotoManager *manager;

@property (nonatomic, strong) AppInfoModel *appInfoModel;

// 缓存文本高度（避免重复计算）
@property (nonatomic, assign) CGFloat descriptionTextHeight;
@property (nonatomic, assign) CGFloat releaseNotesTextHeight;

@end

@implementation AppInfoCell

#pragma mark - 初始化方法

- (void)setupUI {
    
    // 设置背景色
    self.backgroundColor = [UIColor clearColor];
    
    self.contentView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.75]
                                                          darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.4]
    ];
    self.contentView.layer.cornerRadius = 15;
    
    
    
    // 应用图标
    self.appIconImageView = [[UIImageView alloc] init];
    self.appIconImageView.layer.cornerRadius = 15.0;
    self.appIconImageView.layer.masksToBounds = YES;
    self.appIconImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    // 下载按钮
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    self.downloadButton.backgroundColor = [UIColor systemBlueColor];
    self.downloadButton.layer.cornerRadius = 10.0;
    self.downloadButton.layer.masksToBounds = YES;
    [self.downloadButton addTarget:self action:@selector(downloadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    //下载统计
    self.downloadLabel = [UILabel new];
    self.downloadLabel.font = [UIFont systemFontOfSize:10];
    self.downloadLabel.textColor = [UIColor secondaryLabelColor];
    
    // 应用名称
    self.appNameLabel = [[UILabel alloc] init];
    self.appNameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    self.appNameLabel.textColor = [UIColor labelColor];
    self.appNameLabel.numberOfLines = 2;
    
    UIEdgeInsets edge = UIEdgeInsetsMake(2, 4, 2, 4);
    // 应用类型
    self.appTypeButton = [[UIButton alloc] init];
    self.appTypeButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
    [self.appTypeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appTypeButton.contentEdgeInsets = edge;
    self.appTypeButton.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.6];
    self.appTypeButton.layer.cornerRadius = 3;
    self.appTypeButton.tag = 100;
    [self.appTypeButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //版本
    self.appVersionButton = [[UIButton alloc] init];
    self.appVersionButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
    [self.appVersionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appVersionButton.contentEdgeInsets = edge;
    self.appVersionButton.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.6];
    self.appVersionButton.layer.cornerRadius = 3;
    self.appVersionButton.tag = 101;
    [self.appVersionButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    //版本更新时间
    self.appUpdateTimeButton = [[UIButton alloc] init];
    self.appUpdateTimeButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
    [self.appUpdateTimeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appUpdateTimeButton.contentEdgeInsets = edge;
    self.appUpdateTimeButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.6];
    self.appUpdateTimeButton.layer.cornerRadius = 3;
    self.appUpdateTimeButton.tag = 102;
    [self.appUpdateTimeButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    // 标签堆栈视图
    self.tagMiniButtonView = [[MiniButtonView alloc] initWithFrame:CGRectMake(0, 0, kWidth - 130, 20)];
    self.tagMiniButtonView.tag = 0;
    self.tagMiniButtonView.userInteractionEnabled = NO;
    self.tagMiniButtonView.buttonDelegate = self;
    self.tagMiniButtonView.buttonSpace = 5;
    self.tagMiniButtonView.buttonBcornerRadius = 5;
    self.tagMiniButtonView.autoLineBreak = YES;
    self.tagMiniButtonView.fontSize = 10;
    self.tagMiniButtonView.tintIconColor = [UIColor whiteColor];
    self.tagMiniButtonView.buttonBackageColor = [[UIColor orangeColor] colorWithAlphaComponent:0.5];
    
    
    // 应用描述（替换为UITextView）
    self.appDescriptionTextView = [[UITextView alloc] init];
    self.appDescriptionTextView.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    self.appDescriptionTextView.textColor = [UIColor secondaryLabelColor];
    self.appDescriptionTextView.editable = NO; // 禁止编辑
    self.appDescriptionTextView.selectable = NO; // 默认不用允许选中 展开才选择
    self.appDescriptionTextView.scrollEnabled = NO; // 禁用滚动（高度自适应）
    self.appDescriptionTextView.backgroundColor = [UIColor clearColor]; // 透明背景
    self.appDescriptionTextView.textContainerInset = UIEdgeInsetsZero; // 清除内边距
    self.appDescriptionTextView.textContainer.lineFragmentPadding = 0; // 清除文本内边距
    self.appDescriptionTextView.showsVerticalScrollIndicator = NO; // 隐藏滚动条
    self.appDescriptionTextView.showsHorizontalScrollIndicator = NO;
    
    // 更新说明（替换为UITextView）
    self.releaseNotesTextView = [[UITextView alloc] init];
    self.releaseNotesTextView.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    self.releaseNotesTextView.textColor = [UIColor colorWithLightColor:[UIColor blueColor] darkColor:[UIColor yellowColor]];
    self.releaseNotesTextView.editable = NO;
    self.releaseNotesTextView.selectable = YES;
    self.releaseNotesTextView.scrollEnabled = NO;
    self.releaseNotesTextView.backgroundColor = [UIColor clearColor];
    self.releaseNotesTextView.textContainerInset = UIEdgeInsetsZero;
    self.releaseNotesTextView.textContainer.lineFragmentPadding = 0;
    self.releaseNotesTextView.showsVerticalScrollIndicator = NO;
    self.releaseNotesTextView.showsHorizontalScrollIndicator = NO;
    
    // 统计信息按钮堆栈视图
    self.statsMiniButtonView = [[MiniButtonView alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
    self.statsMiniButtonView.buttonDelegate = self;
    self.statsMiniButtonView.buttonSpace = 10;
    self.statsMiniButtonView.buttonBcornerRadius = 5;
    self.statsMiniButtonView.fontSize = 13;
    self.statsMiniButtonView.buttonBackageColorArray = @[
        [[UIColor systemBlueColor] colorWithAlphaComponent:0.5],
        [[UIColor systemPinkColor] colorWithAlphaComponent:0.5],
        [[UIColor systemYellowColor] colorWithAlphaComponent:0.5],
        [[UIColor systemGreenColor] colorWithAlphaComponent:0.5],
        [[UIColor systemTealColor] colorWithAlphaComponent:0.5],
    ];
    self.statsMiniButtonView.tintIconColor = [UIColor whiteColor];
    
    //照片容器
    self.imageStackView = [[UIView alloc] init];
    
    // 头像
    [self.contentView addSubview:self.appIconImageView];
    //下载按钮
    [self.contentView addSubview:self.downloadButton];
    //下载统计
    [self.contentView addSubview:self.downloadLabel];
    
    //名字
    [self.contentView addSubview:self.appNameLabel];
    //类型
    [self.contentView addSubview:self.appTypeButton];
    //版本
    [self.contentView addSubview:self.appVersionButton];
    //时间
    [self.contentView addSubview:self.appUpdateTimeButton];
    //标签
    [self.contentView addSubview:self.tagMiniButtonView];
    //描述（替换为TextView）
    [self.contentView addSubview:self.appDescriptionTextView];
    //更新说明（替换为TextView）
    [self.contentView addSubview:self.releaseNotesTextView];
    //统计按钮
    [self.contentView addSubview:self.statsMiniButtonView];
    //底部图片视图
    [self.contentView addSubview:self.imageStackView];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    // 应用图标约束
    
    // 应用图标约束
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self); // 仅约束边缘，高度由内容决定
        make.width.equalTo(@(kWidth-20));
    }];
    
    // 应用图标约束
    [self.appIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.contentView).offset(16);
        make.width.height.equalTo(@60);
    }];
    
    // 下载按钮约束
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.width.equalTo(@72);
        make.height.equalTo(@22);
    }];
    // 下载量
    [self.downloadLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.downloadButton.mas_bottom).offset(5);
        make.centerX.equalTo(self.downloadButton);
    }];
    
    // 应用名称约束
    [self.appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.left.equalTo(self.appIconImageView.mas_right).offset(12);
        make.width.equalTo(@200);
    }];
    
    // 应用类型约束
    [self.appTypeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameLabel.mas_bottom).offset(10);
        make.left.equalTo(self.appIconImageView.mas_right).offset(12);
        make.height.equalTo(@15);
    }];
    
    // 应用版本
    [self.appVersionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.appTypeButton.mas_right).offset(6);
        make.centerY.equalTo(self.appTypeButton);
        make.height.equalTo(self.appTypeButton);
    }];
    
    // 应用更新时间
    [self.appUpdateTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.appVersionButton.mas_right).offset(6);
        make.centerY.equalTo(self.appTypeButton);
        make.height.equalTo(self.appTypeButton);
    }];
    
    //标签堆栈视图约束
    [self.tagMiniButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appTypeButton.mas_bottom).offset(8);
        make.left.equalTo(self.appIconImageView.mas_right).offset(12);
        make.right.equalTo(self.contentView.mas_right).offset(-12);
    }];
    
    // 应用描述约束（TextView）
    [self.appDescriptionTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagMiniButtonView.mas_bottom).offset(10);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView.mas_right).offset(-16);
        // 初始高度占位（后续动态更新）
        make.height.greaterThanOrEqualTo(@40);
    }];
    
    // 更新说明约束（TextView）
    [self.releaseNotesTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appDescriptionTextView.mas_bottom).offset(10);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView.mas_right).offset(-16);
        // 初始高度占位
        make.height.greaterThanOrEqualTo(@0);
    }];
    
    // 统计信息按钮约束
    [self.statsMiniButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.releaseNotesTextView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView);
        make.height.equalTo(@25);
    }];
    
    // 图片容器约束
    [self.imageStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsMiniButtonView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView);
        make.bottom.lessThanOrEqualTo(self.contentView).offset(-16);
    }];
    
}

- (void)updateConstraints{
    [super updateConstraints];
    
}

#pragma mark - 数据绑定

- (void)bindViewModel:(id)viewModel {
    if ([viewModel isKindOfClass:[AppInfoModel class]]) {
        AppInfoModel *appInfo = (AppInfoModel *)viewModel;
        self.model = appInfo;
        self.appInfoModel = appInfo;
        
        // 设置应用图标
        NSLog(@"iconURL:%@",appInfo.icon_url);
        
        [self.appIconImageView sd_setImageWithURL:[NSURL URLWithString:appInfo.icon_url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if(image){
                self.appIconImageView.image = image;
            }
        }];
        NSLog(@"附件列表:%@",self.appInfoModel.fileNames);
        // 根据应用状态调整下载按钮
        [self updateDownloadButtonForAppStatus:appInfo.app_status];
        
        // 设置应用名称
        self.appNameLabel.text = appInfo.app_name;
        
        // 设置应用类型
        NSString *appTypeTitle = [NewAppFileModel chineseDescriptionForFileType:appInfo.app_type];
        [self.appTypeButton setTitle:[NSString stringWithFormat:@"类型:%@",appTypeTitle] forState:UIControlStateNormal];
        
        //版本
        NSString *appVersionTitle = [NSString stringWithFormat:@"v%@",appInfo.version_name];
        [self.appVersionButton setTitle:appVersionTitle forState:UIControlStateNormal];
        
        //时间
        NSString *appUpdateTimeTitle = [NSString stringWithFormat:@"更新: %@",[TimeTool getTimeDiyWithString:appInfo.update_date]];
        [self.appUpdateTimeButton setTitle:appUpdateTimeTitle forState:UIControlStateNormal];
        
        // 配置标签
        [self configureTagsWithArray:appInfo.tags];
        
        //设置描述（TextView版本）
        [self configureDescriptionTextViewWith:appInfo.app_description];
        
        //更新说明（TextView版本）
        [self configureReleaseNotesTextViewWith:appInfo.release_notes];
        
        // 配置统计按钮
        [self configureStatsButtonsWithAppInfo:appInfo];
        
        //视频图片
        [self configureFilesWithAppInfo:appInfo];
        
    }
}

// 根据应用状态调整下载按钮
- (void)updateDownloadButtonForAppStatus:(NSInteger)status {
    //软件状态：状态（0正常，1失效 2更新中 3锁定 4上传中 5隐藏）
    switch (status) {
        case 0: // 正常
            [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemBlueColor];
            if(self.appInfoModel.download_count > 100){
                [self.downloadButton setTitle:@"🔥 下载" forState:UIControlStateNormal];
            }
            break;
        case 1: // 失效
            [self.downloadButton setTitle:@"失效" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
            break;
        case 2: // 更新中
            [self.downloadButton setTitle:@"更新中" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemOrangeColor];
            break;
        case 3: // 锁定禁止下载
            [self.downloadButton setTitle:@"禁止下载" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemRedColor];
            break;
        case 4: // 正常
            [self.downloadButton setTitle:@"上传中" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor purpleColor];
            break;
        case 5: // 隐藏
            [self.downloadButton setTitle:@"作者隐藏" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor blackColor];
            break;
        default:
            [self.downloadButton setTitle:@"其他" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemGrayColor];
            break;
    }
    // 下载量
    if (self.appInfoModel.download_count > 0) {
        self.downloadLabel.text = [NSString stringWithFormat:@"↓ %@", [self formatCount:self.appInfoModel.download_count]];
    }
}

// 配置标签
- (void)configureTagsWithArray:(NSArray<NSString *> *)tags {
    // 清除现有标签
    [self.tagMiniButtonView updateButtonsWithStrings:tags icons:nil];
    [self.tagMiniButtonView refreshHeight];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self.tagMiniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(self.tagMiniButtonView.refreshHeight));
    }];
}

#pragma mark - UITextView 配置（核心修改）
// 设置应用描述（TextView版本，支持选中+高度自适应）
- (void)configureDescriptionTextViewWith:(NSString *)description {
    NSString *text = description ?: @"暂无介绍";
    self.appDescriptionTextView.text = text;
    
    // 计算文本宽度（和TextView约束宽度一致）
    CGFloat textWidth = CGRectGetWidth(self.contentView.frame) - 32; // left+right=16+16=32
    UIFont *font = self.appDescriptionTextView.font;
    
    if (self.appInfoModel.isShowAll) {
        // 展开状态：自适应全部内容高度
        self.descriptionTextHeight = [self calculateTextHeight:text width:textWidth font:font lineLimit:0];
        self.appDescriptionTextView.selectable = YES; // 默认不用允许选中 展开才选择
    } else {
        // 折叠状态：限制3行高度
        self.descriptionTextHeight = [self calculateTextHeight:text width:textWidth font:font lineLimit:3];
        self.appDescriptionTextView.selectable = NO; // 默认不用允许选中 展开才选择
    }
    
    // 动态更新TextView高度约束
    [self.appDescriptionTextView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(self.descriptionTextHeight));
    }];
    
    // 强制刷新布局
    [self.appDescriptionTextView layoutIfNeeded];
}

// 设置应用更新说明（TextView版本，支持选中+高度自适应）
- (void)configureReleaseNotesTextViewWith:(NSString *)releaseNotes {
    NSString *text = releaseNotes ?: @"";
    self.releaseNotesTextView.text = text;
    
    if (self.appInfoModel.isShowAll) {
        // 展开状态：自适应全部内容高度
        CGFloat textWidth = CGRectGetWidth(self.contentView.frame) - 32;
        self.releaseNotesTextHeight = [self calculateTextHeight:text width:textWidth font:self.releaseNotesTextView.font lineLimit:0];
        
        [self.releaseNotesTextView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(self.releaseNotesTextHeight));
        }];
    } else {
        // 折叠状态：高度设为0（隐藏）
        [self.releaseNotesTextView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
    }
    
    [self.releaseNotesTextView layoutIfNeeded];
}

// 计算文本高度（核心工具方法）
- (CGFloat)calculateTextHeight:(NSString *)text width:(CGFloat)width font:(UIFont *)font lineLimit:(NSInteger)lineLimit {
    if (text.length == 0) return 0;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    // 计算无限制行数时的高度
    CGSize unlimitedSize = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:font,
                                                        NSParagraphStyleAttributeName:paragraphStyle}
                                              context:nil].size;
    
    if (lineLimit <= 0) {
        // 无行数限制：返回实际高度
        return ceil(unlimitedSize.height);
    } else {
        // 有行数限制：计算单行高度，乘以行数
        CGFloat singleLineHeight = [@"测试" boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:font}
                                                       context:nil].size.height;
        CGFloat limitHeight = singleLineHeight * lineLimit;
        
        // 返回「实际高度」和「限制高度」的最小值
        return MIN(ceil(unlimitedSize.height), ceil(limitHeight));
    }
}

// 配置统计按钮
- (void)configureStatsButtonsWithAppInfo:(AppInfoModel *)appInfo {
    // 创建统计按钮
    NSArray *statsTitles = @[
        appInfo.collect_count > 0 ? [self formatCount:appInfo.collect_count] : @"收藏",
        appInfo.like_count > 0 ? [self formatCount:appInfo.like_count] : @"点赞",
        appInfo.dislike_count > 0 ? [self formatCount:appInfo.dislike_count] : @"踩",
        appInfo.comment_count > 0 ? [self formatCount:appInfo.comment_count] : @"评论",
        appInfo.share_count > 0 ? [self formatCount:appInfo.share_count] : @"分享"
    ];
    NSLog(@"点赞等状态isCollect：%d isLike:%d isDislike:%d",appInfo.isCollect,appInfo.isLike,appInfo.isDislike);
    NSArray *imageNames = @[
        appInfo.isCollect ? @"star.fill" : @"star",
        appInfo.isLike ? @"heart.fill" : @"heart",
        appInfo.isDislike ? @"hand.thumbsdown.fill" : @"hand.thumbsdown",
        @"bubble.right",
        @"square.and.arrow.up"
    ];
    
    [self.statsMiniButtonView updateButtonsWithStrings:statsTitles icons:imageNames];
    [self.statsMiniButtonView refreshLayout];
    
    [self.statsMiniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(25));
        if(!self.appInfoModel.isShowAll){
            make.top.equalTo(self.appDescriptionTextView.mas_bottom).offset(5);
        }
    }];
}

// 文件图片视频
- (void)configureFilesWithAppInfo:(AppInfoModel *)appInfo{
    //图片视频
    NSLog(@"AppInfoModel.fileNames:%@",self.appInfoModel.fileNames);
    if(self.appInfoModel.fileNames.count>1 && self.appInfoModel.isShowAll){
        [self addAssModelToManagerWith:self.appInfoModel.fileNames];
        [self.imageStackView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.statsMiniButtonView.mas_bottom).offset(8);
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView);
            make.bottom.lessThanOrEqualTo(self.contentView).offset(-16);
        }];
    }else{
        [self.imageStackView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.statsMiniButtonView.mas_bottom).offset(0);
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView);
            make.height.equalTo(@0);
            make.bottom.lessThanOrEqualTo(self.contentView).offset(-16);
        }];
        [self.photoView removeFromSuperview];
        self.photoView = nil;
    }
}

#pragma mark - 内存管理

- (void)prepareForReuse {
    [super prepareForReuse];
    // 清除TextView内容，避免复用冲突
    self.appDescriptionTextView.text = @"";
    self.releaseNotesTextView.text = @"";
    self.descriptionTextHeight = 0;
    self.releaseNotesTextHeight = 0;
}

#pragma mark - 辅助函数

//重命名数量
- (NSString *)formatCount:(NSInteger)count {
    if (count < 1000) {
        return [NSString stringWithFormat:@"%ld", count];
    } else if (count < 10000) {
        return [NSString stringWithFormat:@"%.2fK", count / 1000.0];
    } else {
        return [NSString stringWithFormat:@"%.2fW", count / 10000.0];
    }
}

#pragma mark - 底部点击代理

- (void)buttonTappedWithTag:(NSInteger)tag title:(nonnull NSString *)title button:(nonnull UIButton *)button {
    NSString *action = nil;
    NSString *successMsg = nil;
    button.tag = tag;
    // 根据按钮tag确定操作类型
    switch (tag) {
        case 0: // 收藏
            action = @"toggle_collect";
            successMsg = @"收藏";
            [self collectButtonTapped:action successMessage:successMsg button:button];
            return;;
        case 1: // 点赞
            action = @"toggle_like";
            successMsg = @"点赞";
            break;
        case 2: // 踩一踩
            action = @"toggle_dislike";
            successMsg = @"踩一踩";
            break;
        case 3: // 评论
            action = @"comment";
            successMsg = @"发布评论";
            [self handleCommentAction];
            return;
        case 4: // 分享
            action = @"share";
            successMsg = @"分享";
            [self handleShareAction];
            return;;
        default:
            return;
    }
    [self performAction:action successMessage:successMsg button:button];
}

#pragma mark - 交互处理

- (void)downloadButtonTapped:(UIButton*)button {
    NSLog(@"点击了下载userModel:%@",self.appInfoModel.userModel.phone);
    NSLog(@"点击了下载userModel:%@",self.appInfoModel.userModel.qq);
    NSLog(@"点击了下载userModel:%@",self.appInfoModel.userModel.wechat);
    if([NewProfileViewController sharedInstance].userInfo.user_id == 0){
        [self showAlertWithConfirmationFromViewController:[self getTopViewController] title:@"请先登录哦" message:@"点击底部导航-我-登录绑定UDID" confirmTitle:@"登录" cancelTitle:@"取消" onConfirmed:^{
            
        } onCancelled:^{
            
        }];
        return;
    }
    // 查看详情可以催更
    if(self.appInfoModel.app_status != 0 && self.appInfoModel.isShowAll) {
        [[ContactHelper shared] showContactActionSheetWithUserInfo:self.appInfoModel.userModel title:@"联系作者催更"];
        return;
    }
    //列表模式 跳过 不显示
    if(self.appInfoModel.app_status != 0) {
        [self showAlertWithConfirmationFromViewController:[self getTopViewController] title:button.titleLabel.text message:@"可查看详情\n点击电话图标催更" confirmTitle:@"查看" cancelTitle:@"关闭" onConfirmed:^{
            ShowOneAppViewController *vc = [ShowOneAppViewController new];
            vc.appInfo = self.appInfoModel;
            vc.app_id = self.appInfoModel.app_id;
            [[self getTopViewController] presentPanModal:vc];
        } onCancelled:^{
            
        }];
        return;
    }
    [SVProgressHUD showWithStatus:@"请求下载地址中"];
    [AppInfoModel getDownloadLinkWithAppId:self.appInfoModel.app_id
                                   success:^(NSURL * _Nonnull downloadURL, NSDictionary *json) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if(!downloadURL){
                [SVProgressHUD showErrorWithStatus:@"读取下载链接失败"];
                [SVProgressHUD dismissWithDelay:2];
                return;
            }
            
            NSString * mainURL = [NSString stringWithFormat:@"%@",downloadURL];
            NSString * title = json[@"app_name"]?:@"下载提示";
            NSString * message =  self.appInfoModel.is_cloud ? @"当前为云端网盘\n自行拷贝连接下载\n" :@"可在下载管理中管理历史下载文件\n";
            NSString * version_name = json[@"version_name"];
            NSString * file_size = json[@"file_size"];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:[NSString stringWithFormat:@"%@ 版本:%@ 大小:%@",message,version_name,file_size]
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            if(self.appInfoModel.is_cloud){
                
                // 1. 拷贝链接按钮
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拷贝链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    // 将链接拷贝到剪贴板
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    pasteboard.string = [NSString stringWithFormat:@"%@",downloadURL]; // 直接拷贝字符串（确保链接完整）
                    
                    // 显示拷贝成功提示
                    UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"成功" message:@"链接已拷贝到剪贴板" preferredStyle:UIAlertControllerStyleAlert];
                    [successAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                    [[self getTopViewController] presentViewController:successAlert animated:YES completion:nil];
                }];
                [alert addAction:cancelAction];
                
                // 2. 在Safari中打开按钮
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Safari中打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    // 检查URL是否有效
                    if ([mainURL containsString:@"http://"] || [mainURL containsString:@"https://"]) {
                        [AppInfoModel getDownloadLinkAndRecordHistoryWithAppId:self.appInfoModel.app_id success:^(DownloadRecordModel * _Nonnull recordModel, NSDictionary * _Nonnull json) {
                            
                        } failure:^(NSError * _Nonnull error) {
                            
                        }];
                        // 用Safari打开链接
                        [[UIApplication sharedApplication] openURL:downloadURL options:@{} completionHandler:^(BOOL success) {
                            if (!success) {
                                // 打开失败提示
                                UIAlertController *failAlert = [UIAlertController alertControllerWithTitle:@"失败" message:@"无法打开链接，请检查URL是否有效" preferredStyle:UIAlertControllerStyleAlert];
                                [failAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                                [[self getTopViewController] presentViewController:failAlert animated:YES completion:nil];
                            }
                        }];
                    } else {
                        // URL无效提示
                        UIAlertController *invalidAlert = [UIAlertController alertControllerWithTitle:@"无效链接" message:@"链接格式不正确，请检查" preferredStyle:UIAlertControllerStyleAlert];
                        [invalidAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                        [[self getTopViewController] presentViewController:invalidAlert animated:YES completion:nil];
                    }
                }];
                [alert addAction:confirmAction];
            }else{
                // 添加取消按钮
                UIAlertAction*cancelAction = [UIAlertAction actionWithTitle:@"仅下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [AppInfoModel getDownloadLinkAndRecordHistoryWithAppId:self.appInfoModel.app_id success:^(DownloadRecordModel * _Nonnull recordModel, NSDictionary * _Nonnull json) {
                        
                    } failure:^(NSError * _Nonnull error) {
                        
                    }];
                    [[FileInstallManager sharedManager] downloadFileWithURLString:mainURL completion:^(NSURL * _Nullable fileLocalURL, NSError * _Nullable error) {
                        if (error) {
                            // 判断错误类型并显示友好提示
                            switch (error.code) {
                                case NSURLErrorCancelled: // -999
                                    NSLog(@"下载已取消（用户主动操作）");
                                    break;
                                case NSURLErrorTimedOut: // -1001
                                    [self showAlertFromViewController:[self getTopViewController]
                                                                title:@"下载超时"
                                                              message:@"连接超时，请检查网络连接后重试"];
                                    break;
                                case NSURLErrorCannotFindHost: // -1003
                                case NSURLErrorCannotConnectToHost: // -1004
                                    [self showAlertFromViewController:[self getTopViewController]
                                                                title:@"连接失败"
                                                              message:@"无法连接到服务器，请检查URL或网络连接"];
                                    break;
                                case NSURLErrorNetworkConnectionLost: // -1005
                                    [self showAlertFromViewController:[self getTopViewController]
                                                                title:@"网络中断"
                                                              message:@"下载过程中网络连接丢失，请重试"];
                                    break;
                                case NSURLErrorFileDoesNotExist: // -1100
                                    [self showAlertFromViewController:[self getTopViewController]
                                                                title:@"文件不存在"
                                                              message:@"请求的文件不存在或已被删除"];
                                    break;
                                default:
                                    [self showAlertFromViewController:[self getTopViewController]
                                                                title:@"下载失败"
                                                              message:[NSString stringWithFormat:@"错误代码: %ld\n%@", (long)error.code, error.localizedDescription]];
                                    break;
                            }
                            return;
                        }
                        // 获取当前顶层视图控制器
                        UIViewController *topVC = [self getTopViewController];
                        
                        // 如果顶层是UIAlertController，先dismiss它
                        if ([topVC isKindOfClass:[UIAlertController class]]) {
                            [topVC dismissViewControllerAnimated:YES completion:^{
                                // 在dismiss完成后，重新获取顶层控制器
                                UIViewController *newTopVC = [self getTopViewController];
                                
                                // 检查新的顶层控制器是否是DownloadManagerViewController
                                if (![newTopVC isKindOfClass:[DownloadManagerViewController class]]) {
                                    // 如果不是，创建并present DownloadManagerViewController
                                    DownloadManagerViewController *vc = [DownloadManagerViewController sharedInstance];
                                    [newTopVC presentPanModal:vc];
                                } else {
                                    // 如果是，调用更新方法
                                    DownloadManagerViewController *vc = (DownloadManagerViewController *)newTopVC;
                                    [vc handleTaskStatusChanged];
                                }
                            }];
                        } else {
                            // 如果顶层不是UIAlertController，直接处理
                            if (![topVC isKindOfClass:[DownloadManagerViewController class]]) {
                                DownloadManagerViewController *vc = [DownloadManagerViewController sharedInstance];
                                [topVC presentPanModal:vc];
                            } else {
                                DownloadManagerViewController *vc = (DownloadManagerViewController *)topVC;
                                [vc handleTaskStatusChanged];
                            }
                        }
                    }];
                }];
                [alert addAction:cancelAction];
                
                UIAlertAction*confirmAction = [UIAlertAction actionWithTitle:@"下载并安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [AppInfoModel getDownloadLinkAndRecordHistoryWithAppId:self.appInfoModel.app_id success:^(DownloadRecordModel * _Nonnull recordModel, NSDictionary * _Nonnull json) {
                        
                    } failure:^(NSError * _Nonnull error) {
                        
                    }];
                    [[FileInstallManager sharedManager] installFileWithURLString:mainURL completion:^(BOOL success, NSError * _Nullable error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(error){
                                NSLog(@"安装失败：%@",error);
                                [self showAlertFromViewController:[self getviewController] title:@"安装失败" message:[NSString stringWithFormat:@"%@",error]];
                                return;
                            }
                        });
                    }];
                }];
                [alert addAction:confirmAction];
                
                UIAlertAction*edit = [UIAlertAction actionWithTitle:@"管理历史下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    DownloadManagerViewController *vc = [DownloadManagerViewController sharedInstance];
                    [[self getTopViewController] presentPanModal:vc];
                }];
                [alert addAction:edit];
            }
            
            UIAlertAction*noAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alert addAction:noAction];
            [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
        });
        
        
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"读取下载链接失败\n%@",error]];
        [SVProgressHUD dismissWithDelay:2];
    }];
    
    
}

- (void)collectButtonTapped:(NSString *)action successMessage:(NSString *)message button:(UIButton *)button {
    NSLog(@"点击了收藏按钮");
    NSString *actionStr = action;
    //底部弹出选择 查看收藏表 收藏此App
    // 1. 获取当前App的ID（假设从当前页面数据中获取，需根据实际情况修改）
    NSInteger currentAppId = self.appInfoModel.app_id; // 示例：当前App的ID
    if (!currentAppId || currentAppId == 0) {
        [SVProgressHUD showErrorWithStatus:@"未获取到应用信息"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    // 2. 创建底部弹出菜单（UIAlertController 模拟 ActionSheet）
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 3. 添加“收藏此App”选项
    NSString *collectActionTitle = self.appInfoModel.isCollect ? @"取消收藏" : @"收藏此应用";
    UIAlertActionStyle style = self.appInfoModel.isCollect ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
    UIAlertAction *collectAction = [UIAlertAction actionWithTitle:collectActionTitle
                                                            style:style
                                                          handler:^(UIAlertAction * _Nonnull action) {
        // 执行收藏操作（调用API）
        [self performAction:actionStr successMessage:message button:button];
    }];
    [actionSheet addAction:collectAction];
    
    // 4. 添加“查看收藏列表”选项
    UIAlertAction *viewFavoritesAction = [UIAlertAction actionWithTitle:@"查看我的收藏"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
        // 跳转到收藏列表页面
        MyCollectionViewController *vc = [MyCollectionViewController new];
        vc.target_udid = self.appInfoModel.udid;
        [[self getviewController] presentPanModal:vc];
    }];
    [actionSheet addAction:viewFavoritesAction];
    
    // 5. 添加取消选项
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [actionSheet addAction:cancelAction];
    
    // 6. 适配iPad（避免崩溃）
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        actionSheet.popoverPresentationController.sourceView = button;
        actionSheet.popoverPresentationController.sourceRect = button.bounds;
    }
    
    // 7. 显示菜单
    [[self getviewController] presentViewController:actionSheet animated:YES completion:nil];
}

- (void)handleCommentAction {
    UIViewController *vc = [self getTopViewController];
    if([vc isKindOfClass:[ShowOneAppViewController class]])return;
    // 处理评论操作
    NSLog(@"处理评论操作");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"发布评论" message:@"请输入评论内容" preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"请输入评论内容";
    }];
    
    // 添加取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // 取消操作的处理
    }];
    
    // 添加确定按钮
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        // 确定操作的处理，这里可以获取输入框的内容
        NSLog(@"输入的内容：%@", textField.text);
        NSString *udid =[NewProfileViewController sharedInstance].userInfo.udid ?: @"";
        if(textField.text.length==0){
            [SVProgressHUD showErrorWithStatus:@"请输入评论内容"];
            [SVProgressHUD dismissWithDelay:2];
            return;
        }
        if(udid.length==0){
            [SVProgressHUD showErrorWithStatus:@"请先登录绑定哦"];
            [SVProgressHUD dismissWithDelay:2];
            return;
        }
        
        Action_type comment_type = Comment_type_AppComment;
        // 构建请求参数（根据实际接口调整）
        NSDictionary *params = @{
            @"action": @"comment",
            @"action_type": @(comment_type),
            @"to_id": @(self.appInfoModel.app_id),
            @"content": textField.text,
            @"udid": udid
        };
        
        [SVProgressHUD showWithStatus:@"发送中..."];
        [DemoBaseViewController triggerVibration];
        
        [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                  urlString:[NSString stringWithFormat:@"%@/app/app_action.php",localURL]
                                                 parameters:params
                                                       udid:udid
                                                   progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            NSLog(@"发布评论返回:%@",jsonResult);
            NSLog(@"发布评论stringResult返回:%@",stringResult);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!jsonResult || !jsonResult[@"code"]){
                    return;
                }
                NSInteger code = [jsonResult[@"code"] intValue];
                NSString * msg = jsonResult[@"msg"];
                
                if (code == 200) {
                    [SVProgressHUD showSuccessWithStatus:msg];
                    //发送给IM
                    [self sendRcimMessage:3 text:textField.text];
                    
                    self.appInfoModel.isComment = YES;
                    self.appInfoModel.isComment+=1;
                } else {
                    [SVProgressHUD showErrorWithStatus:msg];
                }
                [SVProgressHUD dismissWithDelay:1];
                self.model = self.appInfoModel;
                [self bindViewModel:self.model];
            });
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:@"网络错误，发送失败"];
            [SVProgressHUD dismissWithDelay:2];
        }];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [[self getTopViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)handleShareAction {
    // 处理评论操作
    NSLog(@"处理分享操作");
    // 添加应用URL
    NSString *urlString = [NSString stringWithFormat:@"%@/app/app_detail.php?id=%ld&type=app", localURL, self.appInfoModel.app_id];
    //系统导航遮挡问题
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    
    // 确保应用信息有效
    if (!self.appInfoModel || !self.appInfoModel.app_name) {
        [SVProgressHUD showInfoWithStatus:@"暂无应用信息可分享"];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"分享" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    // 添加取消按钮
    UIAlertAction*cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:cancelAction];
    
    UIAlertAction*confirmAction = [UIAlertAction actionWithTitle:@"生成二维码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self generateQRCodeWithUrlString:urlString];
    }];
    [alert addAction:confirmAction];
    
    UIAlertAction*confirmAction2 = [UIAlertAction actionWithTitle:@"拷贝连接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string =urlString;
        [SVProgressHUD showSuccessWithStatus:@"连接已经拷贝到剪贴板"];
        [SVProgressHUD dismissWithDelay:1];
    }];
    [alert addAction:confirmAction2];
    
    UIAlertAction*confirmAction3 = [UIAlertAction actionWithTitle:@"分享到" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 1. 准备分享内容
        NSMutableArray *shareItems = [NSMutableArray array];
        
        NSURL *appURL = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        if (appURL) {
            [shareItems addObject:appURL];
        }
        
        // 添加应用名称和描述
        NSString *shareText = [NSString stringWithFormat:@"%@\n%@",
                               self.appInfoModel.app_name,
                               self.appInfoModel.app_description ?: @"快来一起看看吧！"];
        [shareItems addObject:shareText];
        
        // 处理应用图标（异步下载网络图片）
        __block UIImage *appIcon = nil;
        NSString *iconURL = self.appInfoModel.icon_url;
        if (iconURL && [iconURL length] > 0 && [iconURL hasPrefix:@"http"]) {
            [[UIImageView new] sd_setHighlightedImageWithURL:[NSURL URLWithString:iconURL] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if(image){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentShareControllerWithItems:shareItems appIcon:image];
                    });
                }
            }];
        } else {
            // 本地图片或无图标，直接显示分享界面
            [self presentShareControllerWithItems:shareItems appIcon:appIcon];
        }
    }];
    [alert addAction:confirmAction3];
    
    UIAlertAction*confirmAction4 = [UIAlertAction actionWithTitle:@"分享给好友" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 修改后：包装导航栏 + 底部模态样式
        ChatListViewController *vc = [ChatListViewController new];
        vc.isShare = YES;
        vc.shareModel = self.appInfoModel;
        vc.messageForType = MessageForTypeApp;
        // 1. 创建导航控制器，将vc作为根控制器（核心：让vc拥有导航栏）
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
        navVC.view.backgroundColor = [UIColor systemBackgroundColor];
        [navVC.view addColorBallsWithCount:10 ballradius:150 minDuration:30 maxDuration:50 UIBlurEffectStyle:UIBlurEffectStyleProminent UIBlurEffectAlpha:0.9 ballalpha:0.7];
        // 2. 设置底部模态弹出样式（iOS 13+ 推荐，底部滑入）
        navVC.modalPresentationStyle = UIModalPresentationFullScreen; // 或 UIModalPresentationPageSheet
        // 3. 弹出导航控制器（而非直接弹出vc）
        [[self getviewController] presentViewController:navVC animated:YES completion:nil];
    }];
    [alert addAction:confirmAction4];
    
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)buttonClicked:(UIButton*)button{
    NSLog(@"点击了按钮tag:%ld",button.tag);
    
    ShowOneAppViewController *vc = [ShowOneAppViewController new];
    vc.app_id = self.appInfoModel.app_id;
    UIViewController *topVc = [self getTopViewController];
    if([topVc isKindOfClass:[ShowOneAppViewController class]])return;
    [topVc presentPanModal:vc];
}

- (void)presentShareControllerWithItems:(NSMutableArray *)shareItems appIcon:(UIImage *)appIcon {
    [SVProgressHUD dismiss]; // 隐藏加载提示
    
    // 添加应用图标（如果有）
    if (appIcon) {
        [shareItems addObject:appIcon];
    }
    
    // 2. 创建分享控制器
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
    
    // 3. 排除不需要的分享选项
    activityVC.excludedActivityTypes = @[
    ];
    
    // 4. 设置分享完成回调
    activityVC.completionWithItemsHandler = ^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        NSLog(@"设置分享完成回调");
        if(activityError){
            NSLog(@"分享activityError: %@", activityError);
        }
        if (completed) {
            [SVProgressHUD showSuccessWithStatus:@"分享成功"];
            [SVProgressHUD dismissWithDelay:1];
            NSLog(@"分享完成，活动类型: %@", activityType);
        } else {
            NSLog(@"分享取消");
        }
        
        if (activityError) {
            NSLog(@"分享错误: %@", activityError.localizedDescription);
        }
    };
    
    // 5. 适配iPad
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(self.bounds.size.width/2, self.bounds.size.height/2, 1, 1);
    }
    
    // 6. 显示分享控制器
    [[self getTopViewController] presentViewController:activityVC animated:YES completion:nil];
}

- (void)performAction:(NSString *)action successMessage:(NSString *)message button:(UIButton *)button {
    if (!self.model || !action) return;
    
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if(udid.length == 0){
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"smiley"] status:@"请先获取UDID登录后操作"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // 显示加载指示器
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"正在%@...", message]];
    
    // API地址 - 根据实际情况修改
    NSString *urlString = [NSString stringWithFormat:@"%@/app/app_action.php",localURL];
    
    // 准备请求参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"action"] = action;
    params[@"to_id"] = @(self.appInfoModel.app_id);
    params[@"action_type"] = @(Comment_type_AppComment);
    // 获取设备标识
    params[@"idfv"] = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSLog(@"共享单例udid：%@",udid);
    params[@"udid"] = udid;
    NSLog(@"请求操作字典：%@",params);
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:urlString
                                             parameters:params
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if(!jsonResult ){
                NSLog(@"请求返回stringResult：%@",stringResult);
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"返回数据错误\n%@",stringResult]];
                [SVProgressHUD dismissWithDelay:1];
                return;
            }
            [DemoBaseViewController triggerVibration];
            NSLog(@"请求返回stringResult：%@",stringResult);
            NSLog(@"请求返回字典：%@",jsonResult);
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *message = jsonResult[@"msg"];
            if (code != 200){
                // 失败
                [SVProgressHUD showErrorWithStatus:message];
                [SVProgressHUD dismissWithDelay:1];
                return;
            }
            NSDictionary *data = jsonResult[@"data"];
            BOOL newStatus = [data[@"newStatus"] boolValue];
            if(newStatus){
                [self sendRcimMessage:button.tag text:@""];
            }
            
            UIImage *image = button.imageView.image;
            [SVProgressHUD showImage:image status:message];
            [SVProgressHUD dismissWithDelay:1];
            // 新增：根据服务器返回的status动态更新计数
            [self updateStatsAfterResponse:jsonResult tag:button.tag];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",error]];
        [SVProgressHUD dismissWithDelay:1];
    }];
}

- (void)sendRcimMessage:(NSInteger)tag text:(NSString *)text{
    NSArray *msgs = @[@"我收藏了你的软件", @"我点赞了你的软件", @"我踩了你的软件", @"我评论了你的软件", @"我分享了你的软件"];
    ToolMessage *message = [[ToolMessage alloc] init];
    message.content = [NSString stringWithFormat:@"%@\n%@",msgs[tag],self.appInfoModel.app_name];
    message.messageForType = MessageForTypeApp;
    message.extra = [self.appInfoModel yy_modelToJSONString];
    [[RCIM sharedRCIM] sendMessage:ConversationType_PRIVATE targetId:self.appInfoModel.udid content:message pushContent:message.content pushData:message.content success:^(long messageId) {
        RCTextMessage *meg = [[RCTextMessage alloc] init];
        meg.content = [NSString stringWithFormat:@"%@\n%@",msgs[tag],text];
        [[RCIM sharedRCIM] sendMessage:ConversationType_PRIVATE targetId:self.appInfoModel.udid content:meg pushContent:meg.content pushData:message.content success:^(long messageId) {
            
        } error:^(RCErrorCode nErrorCode, long messageId) {
            
        }];
    } error:^(RCErrorCode nErrorCode, long messageId) {
        
    }];
}

- (void)updateStatsAfterResponse:(id)response tag:(NSInteger )tag{
    // 获取服务器返回的状态和数量变化
    NSDictionary *data = response[@"data"];
    if(!data) return;
    BOOL newStatus = [data[@"newStatus"] boolValue];
    NSInteger count = [data[@"count"] intValue];
    // 根据按钮tag确定操作类型
    switch (tag) {
        case 0: // 收藏
            self.appInfoModel.isCollect = newStatus;
            self.appInfoModel.collect_count = count;
            break;
        case 1: // 点赞
            self.appInfoModel.isLike = newStatus;
            self.appInfoModel.like_count = count;
            break;
        case 2: // 踩一踩
            self.appInfoModel.isDislike = newStatus;
            self.appInfoModel.dislike_count = count;
            break;
        case 3: // 评论
            self.appInfoModel.isComment = newStatus;
            self.appInfoModel.comment_count = count;
            break;
        case 4: // 分享
            self.appInfoModel.isShare = newStatus;
            self.appInfoModel.share_count = count;
            break;
        default:
            return;
    }
    
    // 更新model并刷新UI
    self.model = self.appInfoModel;
    [self bindViewModel:self.model];
}

- (void)generateQRCodeWithUrlString:(NSString*)urlString {
    // 将用户 ID 转换为字符串mySoulChat://user?id=123456
    QRCodeGeneratorViewController *vc = [[QRCodeGeneratorViewController alloc] initWithURLString:urlString title:self.appInfoModel.app_name];
    [[self getTopViewController] presentPanModal:vc];
}

#pragma mark - 更新后的HXPhotoManager配置

- (void)addAssModelToManagerWith:(NSArray<NSString *> *)appFileModels {
    Demo9Model *models =[[HXPhotoURLConverter alloc] getAssetModels:appFileModels];
    self.manager = [[HXPhotoURLConverter alloc] getManager:models];
    
    NSLog(@"最后:%@",appFileModels);
    // 计算文件媒体数量
    NSInteger count = 0;
    // 5. 校验文件格式
    NSSet *allowedFileTypes = [NSSet setWithObjects:
                               // 图片格式
                               @"jpg", @"jpeg", @"png", @"gif", @"bmp", @"heic", @"heif",
                               // 视频格式
                               //                               @"mp4", @"mov", @"avi", @"m4v", @"mpg", @"mpeg", @"flv", @"wmv",
                               // 其他指定格式
                               //                               @"ipa", @"tipa", @"zip", @"js", @"html", @"json", @"deb", @"sh",
                               nil];
    
    for (NSString *file in appFileModels) {
        //排除头像 缩略图 和主程序文件
        if ([file containsString:@"thumbnail"] || [file containsString:ICON_KEY]  || [file containsString:MAIN_File_KEY]) {
            continue;
        }
        NSURL *url= [NSURL URLWithString:file];
        NSString *fileType = [url pathExtension].lowercaseString;
        //排除非图片视频文件
        if (![allowedFileTypes containsObject:fileType]) {
            continue;
        }
        //最后排除图标和缩略图 得到剩下
        count++;
    }
    
    NSLog(@"排除后的媒体数量:%ld",count);
    if(count ==0) return;
    
    // 最大宽度（左右预留16pt，总32pt）
    CGFloat maxWidth = CGRectGetWidth(self.contentView.frame) - 32;
    
    // 高度
    CGFloat totalHeight = 0;
    
    CGFloat cellWidth =(maxWidth - 2*3)/3;
    if(count<=3) {
        totalHeight = cellWidth;
    }else if(count > 3 && count<=6) {
        totalHeight = cellWidth *2 + 3;
    }else if(count > 6 && count<=9) {
        totalHeight = cellWidth *3 +6;
    }else{
        totalHeight = cellWidth *4 +9;
    }
    
    [self.photoView removeFromSuperview];
    self.photoView = nil;
    
    //照片选择器
    self.photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(0, 0, maxWidth, totalHeight) manager:self.manager];
    self.photoView.delegate = self;
    self.photoView.layer.cornerRadius = 10;
    self.photoView.layer.masksToBounds = YES;
    self.photoView.outerCamera = YES;
    self.photoView.alpha = 1;
    self.photoView.showAddCell = NO;
    self.photoView.hideDeleteButton = YES;
    self.photoView.layer.borderWidth = 0.5;
    self.photoView.layer.borderColor = [UIColor quaternaryLabelColor].CGColor;
    self.photoView.backgroundColor = [UIColor clearColor];
    [self.photoView setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
    
    // 刷新视图
    [self.photoView refreshView];
    
    [self.imageStackView addSubview:self.photoView];
    
    // 图片容器
    [self.imageStackView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(maxWidth));
        make.height.equalTo(@(totalHeight));
    }];
    
    // 更新布局
    [self layoutIfNeeded];
}

#pragma mark - 工具方法（原代码中缺失，补充以避免编译错误）

- (UIViewController *)getTopViewController {
    // 实现获取顶层VC的逻辑（根据项目实际情况调整）
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

- (UIViewController *)getviewController {
    return [self getTopViewController];
}

- (void)showAlertFromViewController:(UIViewController *)vc title:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertWithConfirmationFromViewController:(UIViewController *)vc title:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle cancelTitle:(NSString *)cancelTitle onConfirmed:(void (^)(void))confirmedBlock onCancelled:(void (^)(void))cancelledBlock {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (confirmedBlock) confirmedBlock();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (cancelledBlock) cancelledBlock();
    }]];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end
