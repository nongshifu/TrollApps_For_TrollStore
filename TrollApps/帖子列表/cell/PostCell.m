//
//  PostCell.m
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "PostCell.h"
#import "PostModel.h"
#import "config.h"
#import "HXPhotoURLConverter.h"
#import "UserProfileViewController.h"
#import <YYModel/YYModel.h>
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "PostPublishViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "NewProfileViewController.h"
#import "MiniButtonView.h"
#import "MyCollectionViewController.h"
#import "ShowOnePostViewController.h"
#import "ToolMessage.h"
#import "ChatListViewController.h"
#import "QRCodeGeneratorViewController.h"


#undef MY_NSLog_ENABLED
#define MY_NSLog_ENABLED YES

// 常量定义
#define kCardCornerRadius 8.f      // 卡片圆角
#define kAvatarWidth 40.f          // 头像大小
#define kCardShadowOffset CGSizeMake(0, 2) // 卡片阴影偏移
#define kCardShadowOpacity 0.1f     // 卡片阴影透明度
#define kSpacing 8.f                // 通用间距
#define kSingleImageSize 200.f      // 单张图片/视频尺寸
#define kMaxContentLines 4          // 正文最大行数
#define kMaxMediaCount 9            // 最大媒体数量（图片+视频）

@interface PostCell ()<HXPhotoViewDelegate, MiniButtonViewDelegate>
/// 卡片容器视图
@property (nonatomic, strong) UIView *cardView;
/// 状态按钮
@property (nonatomic, strong) UIButton *statusButton;
/// 用户头像
@property (nonatomic, strong) UIImageView *authorAvatarView;
/// 帖子标题标签
@property (nonatomic, strong) UILabel *titleLabel;
/// 帖子用户名
@property (nonatomic, strong) UILabel *userLabel;
/// 帖子正文标签
@property (nonatomic, strong) UILabel *contentLabel;
/// 媒体容器（九宫格）
@property (nonatomic, strong) UIView *mediaContainerView;
@property (nonatomic, strong) HXPhotoView *photoView;
@property (nonatomic, strong) HXPhotoManager *manager;

/// 互动栏
@property (nonatomic, strong) MiniButtonView *statsMiniButtonView; // 统计按钮容器

/// 帖子驳回
@property (nonatomic, strong) UILabel *post_reject_reason_Label;

/// 时间/位置标签
@property (nonatomic, strong) UILabel *timeLocationLabel;

/// 数据模型
@property (nonatomic, strong) PostModel *postModel;
/// 图片/视频视图数组（九宫格）
@property (nonatomic, strong) NSMutableArray<UIImageView *> *mediaViews;
/// 视频时长标签数组（对应每个视频视图）
@property (nonatomic, strong) NSMutableArray<UILabel *> *videoDurationLabels;

/// 当前播放的视频播放器
@property (nonatomic, strong) AVPlayer *currentPlayer;
/// 当前视频播放控制器
@property (nonatomic, weak) UIViewController *currentVideoVC;
/// 当前图片预览控制器
@property (nonatomic, strong) UIViewController *previewVC;

@end

@implementation PostCell



#pragma mark - UI创建
- (void)setupUI {
    // 1. 卡片容器
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.8]
                                                       darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.4]];
    self.cardView.layer.cornerRadius = kCardCornerRadius;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOffset = kCardShadowOffset;
    self.cardView.layer.shadowOpacity = kCardShadowOpacity;
    self.cardView.layer.shadowRadius = kCardCornerRadius/2;
    self.cardView.clipsToBounds = NO;
    [self.contentView addSubview:self.cardView];
    
    // 2. 状态按钮（替代原来的statusLabel）
    self.statusButton = [[UIButton alloc] init];
    self.statusButton.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    self.statusButton.layer.cornerRadius = 8.f;
    self.statusButton.clipsToBounds = YES;
    [self.statusButton addTarget:self action:@selector(statusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.statusButton];
    
    //用户头像
    self.authorAvatarView = [UIImageView new];
    self.authorAvatarView.layer.cornerRadius = kAvatarWidth/2;
    self.authorAvatarView.layer.masksToBounds = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(authorAvatarViewTap:)];
    tapGesture.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.authorAvatarView.userInteractionEnabled = YES;
    [self.authorAvatarView addGestureRecognizer:tapGesture];

    [self.cardView addSubview:self.authorAvatarView];
    
    // 3. 帖子标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.numberOfLines = 2;
    [self.cardView addSubview:self.titleLabel];
    
    // 4. 帖子用户名
    self.userLabel = [[UILabel alloc] init];
    self.userLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.userLabel.textColor = [UIColor colorWithLightColor:[[UIColor redColor] colorWithAlphaComponent:0.5] darkColor:[[UIColor greenColor] colorWithAlphaComponent:0.5]];
    self.userLabel.numberOfLines = kMaxContentLines;
    [self.cardView addSubview:self.userLabel];
    
    // 4. 帖子正文
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.contentLabel.textColor = [UIColor secondaryLabelColor];
    self.contentLabel.numberOfLines = kMaxContentLines;
    [self.cardView addSubview:self.contentLabel];
    
    // 5. 媒体容器
    self.mediaContainerView = [[UIView alloc] init];
    self.mediaContainerView.clipsToBounds = YES;
    [self.cardView addSubview:self.mediaContainerView];
    
    // 6. 时间/位置标签
    self.timeLocationLabel = [[UILabel alloc] init];
    self.timeLocationLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
    self.timeLocationLabel.textColor = [UIColor lightGrayColor];
    [self.cardView addSubview:self.timeLocationLabel];
    
    // 7. 互动栏
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
    [self.cardView addSubview:self.statsMiniButtonView];
    
    // 8 驳回
    self.post_reject_reason_Label = [[UILabel alloc] init];
    self.post_reject_reason_Label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
    self.post_reject_reason_Label.textColor = [UIColor redColor];
    [self.cardView addSubview:self.post_reject_reason_Label];
    
    // 初始化媒体视图数组
    self.mediaViews = [NSMutableArray array];
    self.videoDurationLabels = [NSMutableArray array];
}

#pragma mark - 约束布局
- (void)setupConstraints {
    
    // 1. 卡片容器约束
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        make.width.equalTo(@(CGRectGetWidth(self.contentView.frame)));
    }];
    
    // 2. 状态按钮约束（与原来的标签约束一致）
    [self.statusButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(10);
        make.right.equalTo(self.cardView).offset(-10);
        make.width.equalTo(@60);
        make.height.equalTo(@25);
    }];
    
    // 3. 头像
    [self.authorAvatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(10);
        make.left.equalTo(self.cardView).offset(15);
        make.width.height.equalTo(@(kAvatarWidth));
    }];
    
    
    // 3. 标题标签
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(10);
        make.left.equalTo(self.authorAvatarView.mas_right).offset(10);
        make.right.equalTo(self.statusButton.mas_left).offset(-10);
    }];
    
    // 4. 用户名
    [self.userLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(kSpacing);
        make.left.equalTo(self.authorAvatarView.mas_right).inset(10);
        make.right.equalTo(self.cardView.mas_right).offset(-10);
    }];
    
    // 4. 正文标签
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userLabel.mas_bottom).offset(kSpacing);
        make.left.equalTo(self.cardView).inset(20);
        make.right.equalTo(self.cardView.mas_right).offset(-10);
    }];
    
    // 5. 媒体容器
    [self.mediaContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(kSpacing);
        make.left.right.equalTo(self.cardView).inset(10);
        make.height.greaterThanOrEqualTo(@0);
    }];
    
    // 6. 时间/位置标签
    [self.timeLocationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mediaContainerView.mas_bottom).offset(kSpacing);
        make.left.right.equalTo(self.cardView).inset(20);
    }];
    
    
    // 7. 统计信息按钮约束
    [self.statsMiniButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.timeLocationLabel.mas_bottom).offset(8);
        make.left.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.cardView);
        make.height.equalTo(@25);
    }];
    
    // 8.驳回原因
    [self.post_reject_reason_Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsMiniButtonView.mas_bottom).offset(8);
        make.left.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.cardView);
        make.bottom.equalTo(self.cardView).offset(-10);
    }];
    
}

#pragma mark - 数据绑定
- (void)configureWithModel:(id)model{
    if([model isKindOfClass:[PostModel class]]){
        [self configureWithPostModel:(PostModel *)model];
    }
}

- (void)configureWithPostModel:(PostModel *)model {
    self.postModel = model;
    
    // 1. 状态按钮（更新为按钮的配置方法）
    [self setupStatusButtonWithModel:model];
    
    // 2. 头像
    [self setupAuthorAvatarViewWithModel:model];
    
    // 3. 标题
    self.titleLabel.text = model.post_title ?: @"无标题";
    
    // 3. 用户名
    self.userLabel.text = [NSString stringWithFormat:@"发布者:%@",model.author_name ?: @"匿名用户"];
    
    // 4. 正文
    self.contentLabel.numberOfLines = self.postModel.showAllData ? 0 :kMaxContentLines;
    self.contentLabel.text = model.post_content ?: @"无内容";
    
    // 5. 合并媒体数据（图片+视频）
    [self mergeMediaDataWithModel:model];
    
    
    // 6. 时间/位置
    [self setupTimeLocationWithModel:model];
    
    // 7. 互动数据
    [self setupInteractDataWithModel:model];
    
    // 8. 驳回数据
    [self setupPostRejectReasonDataWithModel:model];
    
    
    // 强制刷新布局
    [self layoutIfNeeded];
}

#pragma mark - 合并媒体数据（图片+视频）
- (void)mergeMediaDataWithModel:(PostModel *)model {
   
    // 清空原有视图
    [self clearMediaGrid];
    
    NSInteger mediaCount = model.post_images.count;
    NSLog(@"帖子视频地址:%@", model.post_video_url);
    if (model.post_video_url.length>0){
        mediaCount += 1;
    }
    
    if (mediaCount == 0) {
        self.mediaContainerView.hidden = YES;
        [self.mediaContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
        return;
    }
    
    self.mediaContainerView.hidden = NO;
    CGFloat gap = kSpacing;
    CGFloat containerWidth = kWidth - 40; // 卡片左右间距10
    CGFloat itemSize = (containerWidth - 2 * gap) / 3;
    CGFloat containerHeight = 0;
    NSInteger rowCount = 0;
    if(mediaCount>0){
        rowCount = (mediaCount + 2) / 3;
        containerHeight = rowCount * (itemSize + gap) - gap;
    }
    
   
    
    // 更新容器高度
    [self.mediaContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(containerHeight));
    }];
    //初始化拷贝
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:model.post_images];
    
    
    // 创建媒体视图
    [self addAssModelToManagerWith:newArray];
    
    //判断是否有视频
    if(model.post_video_url.length >0 && model.post_video_thumb_url.length >0 ){
        
        // 视频（使用找到的缩略图URL和提取的时长）
        HXCustomAssetModel *assetModel = [HXCustomAssetModel assetWithNetworkVideoURL:[NSURL URLWithString:model.post_video_url]
                                                                            videoCoverURL:[NSURL URLWithString:model.post_video_thumb_url]
                                                                            videoDuration:model.post_video_duration
                                                                                selected:YES];
        
        [self.manager addCustomAssetModel:@[assetModel]];
        self.photoView.manager = self.manager;
        [self.photoView refreshView];
    }
    
    
}

#pragma mark - 清空媒体九宫格
- (void)clearMediaGrid {
    // 移除图片视图
    [self.mediaViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        [view removeFromSuperview];
    }];
    [self.mediaViews removeAllObjects];
    
    // 移除时长标签
    [self.videoDurationLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        [label removeFromSuperview];
    }];
    [self.videoDurationLabels removeAllObjects];
    
    // 重置容器高度
    [self.mediaContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0);
    }];
    
}

#pragma mark - 状态标签配置
- (void)setupStatusLabelWithModel:(PostModel *)model {
    NSString *statusText = @"";
    UIColor *statusBgColor = [UIColor lightGrayColor];
    
    switch (model.post_status) {
        case PostStatusDraft:
            statusText = @"草稿";
            statusBgColor = [UIColor grayColor];
            break;
        case PostStatusPendingAudit:
            statusText = @"待审核";
            statusBgColor = [UIColor orangeColor];
            break;
        case PostStatusPublished:
            if (model.post_audit_status == PostAuditStatusApproved) {
                statusText = @"已发布";
                statusBgColor = [UIColor greenColor];
            } else if (model.post_audit_status == PostAuditStatusRejected) {
                statusText = @"审核驳回";
                statusBgColor = [UIColor redColor];
            }
            break;
        case PostStatusRemoved:
            statusText = @"已下架";
            statusBgColor = [UIColor darkGrayColor];
            break;
        case PostStatusDeleted:
            statusText = @"已删除";
            statusBgColor = [UIColor blackColor];
            break;
        default:
            statusText = @"未知状态";
            break;
    }
    [self.statusButton setTitle:statusText forState:UIControlStateNormal];
    [self.statusButton setBackgroundColor:statusBgColor];
    
}

#pragma mark - 头像配置
- (void)setupAuthorAvatarViewWithModel:(PostModel *)model {
    NSLog(@"用户头像:%@",model.author_avatar);
    if(model.author_avatar){
        [self.authorAvatarView sd_setImageWithURL:[NSURL URLWithString:model.author_avatar]
                                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if(image){
                self.authorAvatarView.image = image;
            }
        }];
        [self.authorAvatarView sd_setImageWithURL:[NSURL URLWithString:model.author_avatar] placeholderImage:[UIImage systemImageNamed:@"person.circle"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if(image){
                self.authorAvatarView.image = image;
                self.authorAvatarView.layer.cornerRadius = kAvatarWidth/2;
                self.authorAvatarView.layer.masksToBounds = YES;
            }
        }];
    }
}

#pragma mark - 时间/位置配置
- (void)setupTimeLocationWithModel:(PostModel *)model {
    NSMutableString *timeLocationText = [NSMutableString string];
    
    // 时间
    NSTimeInterval time = model.post_publish_time > 0 ? model.post_publish_time : model.post_create_time;
    if (time > 0) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
        [timeLocationText appendString:[formatter stringFromDate:date]];
    }
    
    // 位置
    if (model.post_location.length > 0) {
        if (timeLocationText.length > 0) {
            [timeLocationText appendString:@" | "];
        }
        [timeLocationText appendString:model.post_location];
    }
    
    self.timeLocationLabel.text = timeLocationText.length > 0 ? timeLocationText : @"未知时间";
}

#pragma mark - 互动数据配置
- (void)setupInteractDataWithModel:(PostModel *)model {
    // 创建统计按钮
    NSArray *statsTitles = @[
        model.post_collect_count > 0 ? [self formatCount:model.post_collect_count] : @"收藏",
        model.post_like_count > 0 ? [self formatCount:model.post_like_count] : @"点赞",
        model.post_report_count > 0 ? [self formatCount:model.post_report_count] : @"踩",
        model.post_comment_count > 0 ? [self formatCount:model.post_comment_count] : @"评论",
        model.post_share_count > 0 ? [self formatCount:model.post_share_count] : @"分享"
    ];
    NSLog(@"点赞等状态isCollect：%d isLike:%d isDislike:%d",model.post_is_collected,model.post_is_liked,model.post_is_report);
    NSArray *imageNames = @[
        model.post_is_collected ? @"star.fill" : @"star",
        model.post_is_liked ? @"heart.fill" : @"heart",
        model.post_is_report ? @"hand.thumbsdown.fill" : @"hand.thumbsdown",
        @"bubble.right",
        @"square.and.arrow.up"
    ];
    
    [self.statsMiniButtonView updateButtonsWithStrings:statsTitles icons:imageNames];
    [self.statsMiniButtonView refreshLayout];
    
    [self.statsMiniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(25));
        if(!self.postModel.showAllData){
//            make.top.equalTo(self.appDescriptionTextView.mas_bottom).offset(5);
        }
    }];
}

#pragma mark - 驳回数据
- (void)setupPostRejectReasonDataWithModel:(PostModel *)model {
    BOOL isAdmin = [NewProfileViewController sharedInstance].userInfo.role;
    BOOL isMySelf = [NewProfileViewController sharedInstance].userInfo.user_id == model.user_id;
    self.post_reject_reason_Label.text = [NSString stringWithFormat:@"【管理驳回原因】%@",model.post_reject_reason];
    
    [self.post_reject_reason_Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsMiniButtonView.mas_bottom).offset(8);
        make.left.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.cardView);
        make.bottom.equalTo(self.cardView).offset(-10);
        if(!isAdmin && !isMySelf){
            make.height.equalTo(@(0));
        }
    }];
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
#pragma mark - 工具方法
- (BOOL)isValidURL:(NSString *)urlStr {
    if (!urlStr || urlStr.length == 0) return NO;
    NSURL *url = [NSURL URLWithString:urlStr];
    return url && url.scheme && url.host;
}

#pragma mark - 动态高度计算
+ (CGFloat)calculateHeightWithModel:(PostModel *)model {
    // 基础高度（卡片内边距+状态标签+标题+正文+时间+互动栏）
    CGFloat baseHeight = 8*2 + 10*2 + 20 + 8 + 8 + 20 + 8 + 20 + 10;
    
    // 标题高度
    CGFloat titleWidth = kWidth - 20 - 80; // 卡片宽度 - 状态标签宽度
    CGFloat titleHeight = [self calculateTextHeight:model.post_title ?: @"无标题"
                                               font:[UIFont systemFontOfSize:16 weight:UIFontWeightBold]
                                           maxWidth:titleWidth
                                          maxLines:2];
    baseHeight += titleHeight - 20;
    
    // 正文高度
    CGFloat contentWidth = kWidth - 20;
    CGFloat contentHeight = [self calculateTextHeight:model.post_content ?: @"无内容"
                                                 font:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]
                                             maxWidth:contentWidth
                                            maxLines:kMaxContentLines];
    baseHeight += contentHeight - 20;
    
    // 媒体高度
    CGFloat mediaHeight = [self calculateMediaHeightWithModel:model];
    baseHeight += mediaHeight;
    
    return ceil(baseHeight);
}

+ (CGFloat)calculateMediaHeightWithModel:(PostModel *)model {
    // 计算合并后的媒体数量
    NSInteger imageCount = model.post_images.count;
    NSInteger mediaCount = imageCount;
    if (model.post_video_url.length > 0 && mediaCount < kMaxMediaCount) {
        mediaCount++;
    }
    mediaCount = MIN(mediaCount, kMaxMediaCount);
    
    if (mediaCount == 0) return 0;
    
    CGFloat gap = kSpacing;
    if (mediaCount == 1) {
        // 单张：200
        return kSingleImageSize;
    } else {
        // 九宫格
        CGFloat containerWidth = kWidth - 20;
        CGFloat itemSize = (containerWidth - 2 * gap) / 3;
        NSInteger rowCount = (mediaCount + 2) / 3;
        return rowCount * (itemSize + gap) - gap;
    }
}

+ (CGFloat)calculateTextHeight:(NSString *)text font:(UIFont *)font maxWidth:(CGFloat)maxWidth maxLines:(NSInteger)maxLines {
    if (!text || text.length == 0) return 0;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *attrs = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: style};
    CGRect rect = [text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attrs
                                     context:nil];
    
    CGFloat height = rect.size.height;
    if (maxLines > 0) {
        CGFloat singleLineHeight = [@"测试" boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:attrs
                                                         context:nil].size.height;
        height = MIN(height, singleLineHeight * maxLines);
    }
    
    return ceil(height);
}

#pragma mark - 复用回收
- (void)prepareForReuse {
    [super prepareForReuse];
    
    // 清空数据
    self.postModel = nil;
    self.titleLabel.text = @"";
    self.contentLabel.text = @"";
    self.timeLocationLabel.text = @"";
   
    
    if (self.currentPlayer) {
        [self.currentPlayer pause];
        self.currentPlayer = nil;
    }
    self.currentVideoVC = nil;
    
    // 清空媒体
    [self clearMediaGrid];
}

#pragma mark - 媒体视图封装

- (void)addAssModelToManagerWith:(NSArray<NSString *> *)appFileModels {
    Demo9Model *models = [[HXPhotoURLConverter alloc] getAssetModels:appFileModels];
    self.manager = [[HXPhotoURLConverter alloc] getManager:models];
    self.manager.configuration.photoCanEdit = NO;
    self.manager.configuration.videoCanEdit = NO;
    self.manager.configuration.maxNum = 9;
    self.manager.configuration.videoMaxNum = 1;
    NSLog(@"最后:%@",appFileModels);
   
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
        
        NSURL *url= [NSURL URLWithString:file];
        NSString *fileType = [url pathExtension].lowercaseString;
        //排除非图片视频文件
        if (![allowedFileTypes containsObject:fileType]) {
            continue;
        }
        
    }
    
    [self.photoView removeFromSuperview];
    self.photoView = nil;
    
    //照片选择器
    self.photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.mediaContainerView.frame),  CGRectGetHeight(self.mediaContainerView.frame)) manager:self.manager];
    self.photoView.delegate = self;
    self.photoView.layer.cornerRadius = 10;
//    self.photoView.layer.masksToBounds = YES;
    self.photoView.outerCamera = YES;
    self.photoView.alpha = 1;
    self.photoView.showAddCell = NO;
    self.photoView.hideDeleteButton = YES;
//    self.photoView.layer.borderWidth = 0.5;
//    self.photoView.layer.borderColor = [UIColor quaternaryLabelColor].CGColor;
    self.photoView.backgroundColor = [UIColor clearColor];
//    [self.photoView setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
    
    // 刷新视图
    [self.photoView refreshView];
    
    [self.mediaContainerView addSubview:self.photoView];
//    self.mediaContainerView.layer.borderWidth = 0.5;
    self.mediaContainerView.layer.cornerRadius = 10;
    self.mediaContainerView.layer.masksToBounds = YES;
    self.mediaContainerView.layer.borderColor = [UIColor quaternaryLabelColor].CGColor;
    
    
    // 更新布局
    [self layoutIfNeeded];
}

#pragma mark - 头像点击
- (void)authorAvatarViewTap:(UITapGestureRecognizer *)tapGesture{
    NSString *my_udid = [NewProfileViewController sharedInstance].userInfo.udid;
    BOOL  role = [NewProfileViewController sharedInstance].userInfo.role == 1;
    NSLog(@"点击了头像udid:%@",self.postModel.udid);
    UserProfileViewController *vc = [UserProfileViewController new];
    vc.user_udid = self.postModel.udid;
    [[self getTopViewController] presentPanModal:vc];
    
}

#pragma mark - 状态按钮配置
- (void)setupStatusButtonWithModel:(PostModel *)model {
    NSString *statusText = @"";
    UIColor *statusBgColor = [UIColor lightGrayColor];
    
    switch (model.post_status) {
        case PostStatusDraft:
            statusText = @"草稿";
            statusBgColor = [UIColor grayColor];
            break;
        case PostStatusPendingAudit:
            statusText = @"待审核";
            statusBgColor = [UIColor orangeColor];
            break;
        case PostStatusPublished:
            statusText = @"已发布";
            if (model.post_audit_status == PostAuditStatusApproved) {
                statusText = @"已发布";
                statusBgColor = [UIColor greenColor];
            } else if (model.post_audit_status == PostAuditStatusRejected) {
                statusText = @"审核驳回";
                statusBgColor = [UIColor redColor];
            }else if (model.post_audit_status == PostAuditStatusNotAudited) {
                statusText = @"待审核";
                statusBgColor = [UIColor redColor];
            }
            break;
        case PostStatusRemoved:
            statusText = @"已下架";
            statusBgColor = [UIColor darkGrayColor];
            break;
        case PostStatusDeleted:
            statusText = @"已删除";
            statusBgColor = [UIColor blackColor];
            break;
        default:
            statusText = @"未知状态";
            break;
    }
    
    [self.statusButton setTitle:statusText forState:UIControlStateNormal];
    [self.statusButton setBackgroundColor:statusBgColor];
    [self.statusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    BOOL isAdmin = [NewProfileViewController sharedInstance].userInfo.role;
    BOOL isMySelf = [NewProfileViewController sharedInstance].userInfo.user_id == model.user_id;
    
    self.statusButton.hidden = !isAdmin && !isMySelf;
}

#pragma mark - 状态按钮点击事件

- (void)statusButtonTapped:(UIButton *)sender {
    // 获取当前用户信息
    NewProfileViewController *profileVC = [NewProfileViewController sharedInstance];
    NSString *myUdid = profileVC.userInfo.udid;
    NSInteger userRole = profileVC.userInfo.role;
    BOOL isOwner = [myUdid isEqualToString:self.postModel.udid];
    BOOL isAdmin = (userRole == 1);
    
    // 如果既不是作者也不是管理员，不显示操作
    if (!isOwner && !isAdmin) {
        return;
    }
    
    // 创建操作菜单
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"帖子操作"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 作者可执行的操作
    if (isOwner) {
        [self addOwnerActionsToAlert:alert];
    }
    
    // 管理员可执行的操作
    if (isAdmin) {
        [self addAdminActionsToAlert:alert];
    }
    
    // 通用删除操作（作者和管理员都能执行，只显示一次）
    if ((isOwner || isAdmin) && self.postModel.post_status != PostStatusDeleted) {
        [alert addAction:[UIAlertAction actionWithTitle:@"更新帖子内容"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self updatePostData];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"删除帖子"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self deletePost];
        }]];
    }
    
    // 取消按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    // iPad适配
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = sender;
        alert.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    // 显示弹窗
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 作者可执行的操作（更新相关）
- (void)addOwnerActionsToAlert:(UIAlertController *)alert {
    PostModel *model = self.postModel;
    
    // 可见范围设置
    NSString *visibilityTitle;
    switch (model.post_visibility) {
        case PostVisibilityPublic:
            visibilityTitle = @"当前: 公开 (点击修改)";
            break;
        case PostVisibilityOnlyFans:
            visibilityTitle = @"当前: 仅粉丝可见 (点击修改)";
            break;
        case PostVisibilityOnlySelf:
            visibilityTitle = @"当前: 仅自己可见 (点击修改)";
            break;
        default:
            visibilityTitle = @"修改可见范围";
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:visibilityTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self showVisibilityOptions];
    }]];
    
    // 评论设置
    NSString *commentTitle = model.post_is_comment_forbidden ?
        @"当前: 禁止评论 (点击允许)" : @"当前: 允许评论 (点击禁止)";
    [alert addAction:[UIAlertAction actionWithTitle:commentTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self toggleCommentPermission];
    }]];
    
    // 分享设置
    NSString *shareTitle = model.post_is_share_forbidden ?
        @"当前: 禁止分享 (点击允许)" : @"当前: 允许分享 (点击禁止)";
    [alert addAction:[UIAlertAction actionWithTitle:shareTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self toggleSharePermission];
    }]];
}


#pragma mark - 管理员可执行的操作（更新相关）
- (void)addAdminActionsToAlert:(UIAlertController *)alert {
    PostModel *model = self.postModel;
    
    // 帖子状态设置
    [alert addAction:[UIAlertAction actionWithTitle:@"修改帖子状态"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self showStatusOptions];
    }]];
    
    // 审核状态设置
    [alert addAction:[UIAlertAction actionWithTitle:@"修改审核状态"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self showAuditStatusOptions];
    }]];
    
    // 置顶设置
    NSString *topTitle = model.post_is_top ?
        @"当前: 已置顶 (取消置顶)" : @"当前: 未置顶 (设置置顶)";
    [alert addAction:[UIAlertAction actionWithTitle:topTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self toggleTopStatus];
    }]];
    
    // 热门设置
    NSString *hotTitle = model.post_is_hot ?
        @"当前: 已设为热门 (取消)" : @"当前: 未设为热门 (设置)";
    [alert addAction:[UIAlertAction actionWithTitle:hotTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self toggleHotStatus];
    }]];
    
    // 推荐设置
    NSString *recommendTitle = model.post_is_recommend ?
        @"当前: 已推荐 (取消)" : @"当前: 未推荐 (设置)";
    [alert addAction:[UIAlertAction actionWithTitle:recommendTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self toggleRecommendStatus];
    }]];
}

#pragma mark - 各种操作的实现
// 可见范围设置
- (void)showVisibilityOptions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择可见范围"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *titles = @[@"公开", @"仅粉丝可见", @"仅自己可见"];
    for (NSInteger i = 0; i < titles.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:titles[i]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
            self.postModel.post_visibility = i;
            [self updatePostWithCompletion:^(BOOL success) {
                if (success) {
                    // 更新成功后刷新UI
                }
            }];
        }];
        if (i == self.postModel.post_visibility) {
            [action setValue:[UIImage imageNamed:@"selected_check"] forKey:@"image"];
        }
        [alert addAction:action];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

// 切换评论权限
- (void)toggleCommentPermission {
    self.postModel.post_is_comment_forbidden = !self.postModel.post_is_comment_forbidden;
    [self updatePostWithCompletion:^(BOOL success) {
        if (success) {
            // 更新成功后刷新UI
        }
    }];
}

// 切换分享权限
- (void)toggleSharePermission {
    self.postModel.post_is_share_forbidden = !self.postModel.post_is_share_forbidden;
    [self updatePostWithCompletion:^(BOOL success) {
        if (success) {
            // 更新成功后刷新UI
        }
    }];
}

// 帖子状态设置
- (void)showStatusOptions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择帖子状态"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *titles = @[@"草稿", @"待审核", @"已发布", @"已下架", @"已删除"];
    for (NSInteger i = 0; i < titles.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:titles[i]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
            self.postModel.post_status = i;
            [self updatePostWithCompletion:^(BOOL success) {
                if (success) {
                    [self setupStatusButtonWithModel:self.postModel];
                }
            }];
        }];
        if (i == self.postModel.post_status) {
            [action setValue:[UIImage imageNamed:@"selected_check"] forKey:@"image"];
        }
        [alert addAction:action];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

// 审核状态设置
- (void)showAuditStatusOptions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择审核状态"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *titles = @[@"未审核", @"审核通过", @"审核驳回"];
    for (NSInteger i = 0; i < titles.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:titles[i]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
            self.postModel.post_audit_status = i;
            
            // 如果是审核驳回，需要输入驳回原因
            if (i == PostAuditStatusRejected) {
                [self showRejectReasonInput];
            } else {
                [self updatePostWithCompletion:^(BOOL success) {
                    if (success) {
                        [self setupStatusButtonWithModel:self.postModel];
                    }
                }];
            }
        }];
        if (i == self.postModel.post_audit_status) {
            [action setValue:[UIImage imageNamed:@"selected_check"] forKey:@"image"];
        }
        [alert addAction:action];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

// 输入驳回原因
- (void)showRejectReasonInput {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"审核驳回原因"
                                                                   message:@"请输入驳回原因"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入驳回原因";
        textField.text = self.postModel.post_reject_reason;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        self.postModel.post_reject_reason = alert.textFields.firstObject.text;
        self.postModel.post_audit_count += 1;
        [self updatePostWithCompletion:^(BOOL success) {
            if (success) {
                [self setupStatusButtonWithModel:self.postModel];
            }
        }];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

// 切换置顶状态
- (void)toggleTopStatus {
    self.postModel.post_is_top = !self.postModel.post_is_top;
    [self updatePostWithCompletion:^(BOOL success) {
        if (success) {
            // 更新成功后刷新UI
        }
    }];
}

// 切换热门状态
- (void)toggleHotStatus {
    self.postModel.post_is_hot = !self.postModel.post_is_hot;
    [self updatePostWithCompletion:^(BOOL success) {
        if (success) {
            // 更新成功后刷新UI
        }
    }];
}

// 切换推荐状态
- (void)toggleRecommendStatus {
    self.postModel.post_is_recommend = !self.postModel.post_is_recommend;
    [self updatePostWithCompletion:^(BOOL success) {
        if (success) {
            // 更新成功后刷新UI
        }
    }];
}

// 删除帖子
- (void)deletePost {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除"
                                                                   message:@"确定要删除此帖子吗？此操作不可撤销。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        self.postModel.post_status = PostStatusDeleted;
        [self updatePostWithCompletion:^(BOOL success) {
            if (success) {
                [self setupStatusButtonWithModel:self.postModel];
                // 可以通知列表刷新或移除当前cell
                [self.dataSource removeObject:self.model];
                
                
            }
        }];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

// 更新帖子
- (void)updatePostData {
    PostPublishViewController *publishVC = [[PostPublishViewController alloc] initWithDraftPost:self.postModel];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:publishVC];
    [[self getTopViewController] presentViewController:nc animated:YES completion:nil];
    
}

#pragma mark - 辅助方法
// 获取顶层视图控制器
- (UIViewController *)getTopViewController {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}


#pragma mark - 网络请求：更新帖子
- (void)updatePostWithCompletion:(void(^)(BOOL success))completion {
    // 1. 构建请求参数
    // 这里将 model 转换为字典，只发送变化的字段（或者发送全部可写字段）
    NSMutableDictionary *params = [self.postModel yy_modelToJSONObject];
    
    // 基础认证信息
    params[@"action"] = @"update_post_field"; // 【关键】对应新的后端路由
    params[@"udid"] = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    

    // 2. 发送网络请求 (这里需要替换为你项目中真实的网络请求类，如 AFNetworking)
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/post/post_api.php",localURL]
                                             parameters:params progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        
        // 3. 处理响应
        NSInteger code = [jsonResult[@"code"] integerValue];
        NSString *msg = jsonResult[@"msg"] ?: @"更新失败";
        if (code == 200) {
            // 假设 SUCCESS = 200
            // 更新成功，服务器返回了最新的完整帖子数据
            NSDictionary *data = jsonResult[@"data"];
            if (data) {
                // 使用 YYModel 刷新本地 model
                [self.postModel yy_modelSetWithDictionary:data];
                
                // 可选：通知 UI 刷新
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setupStatusButtonWithModel:self.postModel]; // 刷新状态按钮
                    // 如果是在列表里，可以在这里回调 delegate 刷新列表
                    [SVProgressHUD showSuccessWithStatus:msg];
                    [SVProgressHUD dismissWithDelay:1];
                });
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES);
            });
        } else {
            
            NSLog(@"更新失败: %@", msg);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
    } failure:^(NSError *error) {
        if (error) {
            NSLog(@"更新帖子失败: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
            return;
        }
        
    }];
    // 下面是一个通用的示例逻辑
    
}

#pragma mark - 统计按钮点击
- (void)buttonTappedWithTag:(NSInteger)tag title:(nonnull NSString *)title button:(nonnull UIButton *)button view:(nonnull MiniButtonView *)view{
    NSString *action = nil;
    NSString *successMsg = nil;
    button.tag = tag;
    // 根据按钮tag确定操作类型
    NSLog(@"点击了统计按钮的第%ld",tag);
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


- (void)collectButtonTapped:(NSString *)action successMessage:(NSString *)message button:(UIButton *)button {
    NSLog(@"点击了收藏按钮");
    NSString *actionStr = action;
    //底部弹出选择 查看收藏表 收藏此App
    // 1. 获取当前App的ID（假设从当前页面数据中获取，需根据实际情况修改）
    NSInteger currentAppId = self.postModel.post_id; // 示例：当前App的ID
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
    NSString *collectActionTitle = self.postModel.post_is_collected ? @"取消收藏" : @"收藏此应用";
    UIAlertActionStyle style = self.postModel.post_is_collected ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
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
        vc.target_udid = self.postModel.udid;
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
    if([vc isKindOfClass:[ShowOnePostViewController class]])return;
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
        
        Action_type comment_type = Comment_type_Post;
        // 构建请求参数（根据实际接口调整）
        NSDictionary *params = @{
            @"action": @"comment",
            @"action_type": @(comment_type),
            @"to_id": @(self.postModel.post_id),
            @"content": textField.text,
            @"udid": udid
        };
        
        [SVProgressHUD showWithStatus:@"发送中..."];
        [DemoBaseViewController triggerVibration];
        
        [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                  urlString:[NSString stringWithFormat:@"%@/post/post_api.php",localURL]
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
                    
                    
                    self.postModel.post_comment_count+=1;
                } else {
                    [SVProgressHUD showErrorWithStatus:msg];
                }
                [SVProgressHUD dismissWithDelay:1];
                self.model = self.postModel;
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
    NSString *urlString = [NSString stringWithFormat:@"%@/post/post.php?id=%lld&type=app", localURL, self.postModel.post_id];
    //系统导航遮挡问题
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    
    // 确保应用信息有效
    if (!self.postModel || !self.postModel.post_title) {
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
        NSString *shareText = [NSString stringWithFormat:@"%@",
                               self.postModel.post_title ?: @"快来一起看看吧！"];
        [shareItems addObject:shareText];
        
        // 处理应用图标（异步下载网络图片）
        __block UIImage *appIcon = nil;
        NSString *iconURL = self.postModel.user_model.avatar;
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
        vc.shareModel = self.postModel;
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
    NSString *urlString = [NSString stringWithFormat:@"%@/post/post_api.php",localURL];
    
    // 准备请求参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"action"] = action;
    params[@"to_id"] = @(self.postModel.post_id);
    params[@"action_type"] = @(Comment_type_Post);
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",error]];
            [SVProgressHUD dismissWithDelay:1];
        });
        
    }];
}

- (void)sendRcimMessage:(NSInteger)tag text:(NSString *)text{
    NSArray *msgs = @[@"我收藏了你的帖子", @"我点赞了你的帖子", @"我踩了你的帖子", @"我评论了你的帖子", @"我分享了你的帖子"];
    ToolMessage *message = [[ToolMessage alloc] init];
    message.content = [NSString stringWithFormat:@"%@\n%@",msgs[tag],self.postModel.post_title];
    message.messageForType = MessageForTypeApp;
    message.extra = [self.postModel yy_modelToJSONString];
    [[RCIM sharedRCIM] sendMessage:ConversationType_PRIVATE targetId:self.postModel.udid content:message pushContent:message.content pushData:message.content success:^(long messageId) {
        RCTextMessage *meg = [[RCTextMessage alloc] init];
        meg.content = [NSString stringWithFormat:@"%@\n%@",msgs[tag],text];
        [[RCIM sharedRCIM] sendMessage:ConversationType_PRIVATE targetId:self.postModel.udid content:meg pushContent:meg.content pushData:message.content success:^(long messageId) {
            
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
            self.postModel.post_is_collected = newStatus;
            self.postModel.post_is_collected = count;
            break;
        case 1: // 点赞
            self.postModel.post_is_liked = newStatus;
            self.postModel.post_like_count = count;
            break;
        case 2: // 踩一踩
            self.postModel.post_is_report = newStatus;
            self.postModel.post_report_count = count;
            break;
        case 3: // 评论
            
            self.postModel.post_comment_count = count;
            break;
        case 4: // 分享
            
            self.postModel.post_share_count = count;
            break;
        default:
            return;
    }
    
    // 更新model并刷新UI
    self.model = self.postModel;
    [self bindViewModel:self.model];
}

- (void)generateQRCodeWithUrlString:(NSString*)urlString {
    // 将用户 ID 转换为字符串mySoulChat://user?id=123456
    QRCodeGeneratorViewController *vc = [[QRCodeGeneratorViewController alloc] initWithURLString:urlString title:self.postModel.post_title];
    [[self getTopViewController] presentPanModal:vc];
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

@end
