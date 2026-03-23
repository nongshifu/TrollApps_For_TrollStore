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

@interface PostCell ()<HXPhotoViewDelegate>
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
@property (nonatomic, strong) UIView *interactBarView;
/// 点赞数标签
@property (nonatomic, strong) UILabel *likeCountLabel;
/// 评论数标签
@property (nonatomic, strong) UILabel *commentCountLabel;
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
    self.interactBarView = [[UIView alloc] init];
    [self.cardView addSubview:self.interactBarView];
    
    // 7.1 点赞数
    self.likeCountLabel = [[UILabel alloc] init];
    self.likeCountLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.likeCountLabel.textColor = [UIColor lightGrayColor];
    [self.interactBarView addSubview:self.likeCountLabel];
    
    // 7.2 评论数
    self.commentCountLabel = [[UILabel alloc] init];
    self.commentCountLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.commentCountLabel.textColor = [UIColor lightGrayColor];
    [self.interactBarView addSubview:self.commentCountLabel];
    
    // 初始化媒体视图数组
    self.mediaViews = [NSMutableArray array];
    self.videoDurationLabels = [NSMutableArray array];
}

#pragma mark - 约束布局
- (void)setupConstraints {
    // 1. 卡片容器约束
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        make.width.equalTo(@(kWidth - 20));
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
        make.left.equalTo(self.cardView).offset(10);
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
        make.left.equalTo(self.cardView).inset(10);
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
        make.left.right.equalTo(self.cardView).inset(10);
    }];
    
    // 7. 互动栏
    [self.interactBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.timeLocationLabel.mas_bottom).offset(kSpacing);
        make.left.right.equalTo(self.cardView).inset(10);
        make.bottom.equalTo(self.cardView).offset(-10);
        make.height.equalTo(@20);
    }];
    
    // 7.1 点赞数
    [self.likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.interactBarView);
        make.centerY.equalTo(self.interactBarView);
    }];
    
    // 7.2 评论数
    [self.commentCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.likeCountLabel.mas_right).offset(15);
        make.centerY.equalTo(self.interactBarView);
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
    self.likeCountLabel.text = [NSString stringWithFormat:@"点赞 %ld", model.post_like_count];
    self.commentCountLabel.text = [NSString stringWithFormat:@"评论 %ld", model.post_comment_count];
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
    self.likeCountLabel.text = @"";
    self.commentCountLabel.text = @"";
    
    
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
    [self.statusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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


@end
