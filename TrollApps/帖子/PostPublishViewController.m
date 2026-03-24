
//
//  PostPublishViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/31.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//
#import "PostPublishViewController.h"
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "PostAttachmentModel.h"
#import "UserModel.h"
#import "NewProfileViewController.h"
#import "TokenGenerator.h"
#import "SystemViewController.h"


#undef MY_NSLog_ENABLED // 取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // 当前文件单独启用

#pragma mark - 动态颜色定义（适配亮色/暗色主题）

@interface UIColor (PostDynamicColor)
/// 主背景色（亮：白色，暗：深灰）
+ (UIColor *)post_bg_color;
/// 次级背景色（亮：浅灰，暗：更深灰）
+ (UIColor *)post_secondary_bg_color;
/// 文本主色（亮：黑色，暗：白色）
+ (UIColor *)post_text_primary_color;
/// 文本次色（亮：深灰，暗：浅灰）
+ (UIColor *)post_text_secondary_color;
/// 边框色（亮：浅灰，暗：深灰）
+ (UIColor *)post_border_color;
/// 主题色（蓝，适配深浅模式）
+ (UIColor *)post_theme_color;
/// 危险色（删除按钮，亮：红，暗：浅红）
+ (UIColor *)post_danger_color;
@end

@implementation UIColor (PostDynamicColor)
+ (UIColor *)post_bg_color {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ?
            [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.5] : // 暗色背景
            [[UIColor whiteColor] colorWithAlphaComponent:0.3]; // 亮色背景
        }];
    } else {
        return [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    }
}

+ (UIColor *)post_secondary_bg_color {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ?
            [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0] :
            [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        }];
    } else {
        return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    }
}

+ (UIColor *)post_text_primary_color {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ?
            [UIColor whiteColor] :
            [UIColor blackColor];
        }];
    } else {
        return [UIColor blackColor];
    }
}

+ (UIColor *)post_text_secondary_color {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ?
            [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0] :
            [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        }];
    } else {
        return [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    }
}

+ (UIColor *)post_border_color {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ?
            [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] :
            [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
        }];
    } else {
        return [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    }
}

+ (UIColor *)post_theme_color {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ?
            [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0] :
            [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
        }];
    } else {
        return [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    }
}

+ (UIColor *)post_danger_color {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ?
            [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0] :
            [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
        }];
    } else {
        return [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
    }
}
@end

// 补充UIButton分类（支持选中背景色，放在文件顶部或单独分类文件）
@interface UIButton (SelectedBackgroundColor)
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
@end

@implementation UIButton (SelectedBackgroundColor)
- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor {
    objc_setAssociatedObject(self, @selector(selectedBackgroundColor), selectedBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateBackgroundColor];
}

- (UIColor *)selectedBackgroundColor {
    return objc_getAssociatedObject(self, @selector(selectedBackgroundColor));
}

- (void)updateBackgroundColor {
    self.backgroundColor = self.isSelected ? self.selectedBackgroundColor : [UIColor post_secondary_bg_color];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateBackgroundColor];
}


@end

#pragma mark - 发帖控制器实现
@interface PostPublishViewController () <UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate>



/// UI组件
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UIView *contentView;

// 标题输入
@property (nonatomic, strong) UITextField *titleTextField;
// 正文输入
@property (nonatomic, strong) UITextView *contentTextView;
// 图片选择区
@property (nonatomic, strong) UIView *imageSelectView;
@property (nonatomic, strong) UICollectionView *imageCollectionView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;
// 视频选择区
@property (nonatomic, strong) UIView *videoSelectView;
@property (nonatomic, strong) UIImageView *videoThumbImageView;
@property (nonatomic, strong) UILabel *videoDurationLabel;
@property (nonatomic, strong) UIButton *deleteVideoBtn; // 新增：删除视频按钮
@property (nonatomic, strong) NSURL *selectedVideoURL;
// 附件选择区
@property (nonatomic, strong) UIView *attachmentSelectView;
@property (nonatomic, strong) UISegmentedControl *attachmentTypeSegment; // 新增：附件类型（文件/URL）
@property (nonatomic, strong) UIButton *addFileBtn; // 新增：选择文件按钮

@property (nonatomic, strong) UIButton *addURLBtn; // 新增：添加URL按钮
@property (nonatomic, strong) UITableView *attachmentTableView;
@property (nonatomic, strong) NSMutableArray<PostAttachmentModel *> *selectedAttachments;
// 地理位置
@property (nonatomic, strong) UIView *locationView;
@property (nonatomic, strong) UIButton *locationLabel;
@property (nonatomic, strong) NSString * selectedLocationName;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
// 权限设置
@property (nonatomic, strong) UIView *permissionView;
@property (nonatomic, strong) UISegmentedControl *visibilitySegment;
@property (nonatomic, strong) UISwitch *commentForbiddenSwitch;
@property (nonatomic, strong) UISwitch *shareForbiddenSwitch;


//类型属性
@property (nonatomic, strong) SystemViewController *sysVC;

// 帖子主类型 单选
@property (nonatomic, strong) UIView *postMainTypeView;
@property (nonatomic, strong) UILabel *postMainTypeLabel;
@property (nonatomic, strong) UISegmentedControl *postMainTypeSegment;

// 帖子副类型 支持多选
@property (nonatomic, strong) UIView *topic_ids_view;
@property (nonatomic, strong) NSMutableArray <UIButton *>* topic_ids_buttons;//支持多选
@property (nonatomic, strong) NSArray<NSNumber *> *topic_ids;/// 帖子标签ID数组支持多选（如@[@0,@2,@3]，对应上面topic_ids_buttons的tag



#pragma mark - 新增属性
@property (nonatomic, assign) BOOL hasShowDraftPrompt; // 标记是否已弹出过草稿载入提示（避免重复弹窗）
@property (nonatomic, strong) UIBarButtonItem *draftBarButton; // 导航栏草稿按钮
@property (nonatomic, strong) UIBarButtonItem *postButton; // 导航栏发帖按钮

// 新增属性
@property (nonatomic, strong) NSMutableArray<MediaItem *> *mediaItems; // 统一管理所有媒体
@property (nonatomic, assign) BOOL isUpdating; // 是否为更新模式


//@property (nonatomic, strong) HXPhotoView *photoView;
//@property (nonatomic, strong) HXPhotoManager *manager;
//



@end

@implementation PostPublishViewController

#pragma mark - 初始化

- (instancetype)initWithDraftPost:(nullable PostModel *)draftPost {
    self = [super init];
    if (self) {
        // 初始化数据容器
        _selectedImages = [NSMutableArray array];
        _selectedAttachments = [NSMutableArray array];
        // 默认值初始化
        [self setupDefaultPostValues];
        
        if(!draftPost){
            _postModel.isUpdating  = NO;
            _isUpdating = NO;
        }else{
            //转为字典
            NSDictionary *dic = [draftPost yy_modelToJSONObject];
            //赋值属性
            [_postModel yy_modelSetWithDictionary:dic];
            
            _postModel.isUpdating  = YES;
            _isUpdating = (draftPost.post_id > 0);
            
            [self updateUIWithPostModel:draftPost]; // 新增：更新所有UI
            
        }
        
    }
    return self;
}

- (instancetype)init {
    return [self initWithDraftPost:nil];
}

- (void)setupDefaultPostValues {
    // 基础默认值（匹配数据库默认值）
    self.postModel = [[PostModel alloc] init];
    self.postModel.post_uuid = [[NSUUID UUID] UUIDString];
    self.postModel.post_create_time = [[NSDate date] timeIntervalSince1970];
    self.postModel.post_update_time = self.postModel.post_create_time;
    self.postModel.post_status = 0; // 草稿
    self.postModel.post_audit_status = 0; // 未审核
    self.postModel.post_visibility = 0; // 公开
    self.postModel.post_is_comment_forbidden = NO;
    self.postModel.post_is_share_forbidden = NO;
    self.postModel.category_id = 0;
    self.postModel.topic_ids = @[@0,@1,@2,@3];
    
    self.postModel.post_images = @[];
    self.postModel.post_images_thumb = @[];
    self.postModel.post_attachments = @[];
    
    self.postModel.post_extra = @{};
    
    // 模拟用户ID（实际从用户中心获取）
   
    UserModel *userModel = [NewProfileViewController sharedInstance].userInfo;
    self.postModel.user_model = userModel;
    
    self.postModel.user_id = userModel.user_id;
    self.postModel.udid = userModel.udid;
    self.postModel.author_name = userModel.nickname;
    self.postModel.author_avatar = userModel.avatar;
    
}

// 新增：根据模型数据更新所有UI元素
- (void)updateUIWithPostModel:(PostModel *)model {
    if (!model) return;

    NSLog(@"帖子UUDI:%@",model.post_uuid);
    // 1. 基础信息更新
    self.titleTextField.text = model.post_title ?: @"";
    NSLog(@"帖子标题:%@",model.post_title);
    self.contentTextView.text = model.post_content ?: @"";
    NSLog(@"帖子内容:%@",model.post_content);
    // 处理正文占位符
    UILabel *placeholderLabel = [self.contentTextView viewWithTag:1001];
    placeholderLabel.hidden = model.post_content.length > 0;
    
    // 2. 权限设置更新
    self.visibilitySegment.selectedSegmentIndex = model.post_visibility;
    NSLog(@"帖子课件权限设置:%ld",model.post_visibility);
    self.commentForbiddenSwitch.on = model.post_is_comment_forbidden;
    NSLog(@"帖子分享权限设置:%d",model.post_is_share_forbidden);
    self.shareForbiddenSwitch.on = model.post_is_share_forbidden;
    
    // 3. 地理位置更新
    if (model.post_location.length > 0) {
        [self.locationLabel setTitle:model.post_location forState:UIControlStateNormal];
    } else if (model.post_latlng.length > 0) {
        [self.locationLabel setTitle:model.post_latlng forState:UIControlStateNormal];
    }
    NSLog(@"帖子地理位置更新location:%@ latlng:%@",model.post_location,model.post_latlng);
    
    // 4. 主类型更新
    if (model.category_id >= 0 && model.category_id < self.postMainTypeSegment.numberOfSegments) {
        self.postMainTypeSegment.selectedSegmentIndex = model.category_id;
        NSLog(@"帖子主类型category_id:%ld",model.category_id);
    }
    
    // 5. 副类型更新
    for (UIButton *btn in self.topic_ids_buttons) {
        btn.selected = [model.topic_ids containsObject:@(btn.tag)];
        [btn updateBackgroundColor]; // 触发背景色更新
    }
    
    // 6. 视频信息更新（补充完整视频UI刷新逻辑）
    self.mediaItems = [NSMutableArray array];
    // 6.1 处理图片
    for (NSString *imgUrl in self.postModel.post_images) {
        if (imgUrl.length > 0) {
            NSLog(@"帖子处理图片:%@",imgUrl);
            // 1. 将字符串转为 NSURL 对象
            NSURL *url = [NSURL URLWithString:imgUrl];
            
            // 2. 安全校验：确保 URL 有效
            if (!url) {
                NSLog(@"无效的URL: %@", imgUrl);
                continue;
            }
            
            // 3. 获取文件名 (自动处理 ?query 和 #fragment)
            NSString *fileName = url.lastPathComponent;
            
            NSLog(@"原始链接: %@", imgUrl);
            NSLog(@"提取的文件名: %@", fileName);
            
            MediaItem *item = [[MediaItem alloc] init];
            item.type = MediaTypeRemoteImage;
            item.remoteUrl = imgUrl;
            item.isDeleted = NO;
            item.fileName = fileName;
            [self.mediaItems addObject:item];
        }
    }
    
    // 6.2处理视频
    if (self.postModel.post_video_url.length > 0) {
        NSLog(@"帖子处理视频:%@",self.postModel.post_video_url);
        MediaItem *item = [[MediaItem alloc] init];
        item.type = MediaTypeRemoteVideo;
        item.remoteUrl = self.postModel.post_video_url;
        item.duration = self.postModel.post_video_duration;
        item.isDeleted = NO;
        NSURL *url = [NSURL URLWithString:item.remoteUrl];
        if (url) {
            item.fileName = url.lastPathComponent;;
        }
        
        [self.mediaItems addObject:item];
    }
    if (model.post_video_url.length > 0) {
        self.selectedVideoURL = [NSURL URLWithString:model.post_video_url];
        
        // 视频缩略图
        if (model.post_video_thumb_url.length > 0) {
            [self.videoThumbImageView sd_setImageWithURL:[NSURL URLWithString:model.post_video_thumb_url]
                                        placeholderImage:[UIImage imageNamed:@"video_placeholder"]
                                               completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                self.videoThumbImageView.hidden = !image;
            }];
        }
        
        // 视频时长
        self.videoDurationLabel.text = [self formatDuration:model.post_video_duration];
        self.videoDurationLabel.hidden = NO;
        self.deleteVideoBtn.hidden = NO;
    } else {
        self.videoThumbImageView.image = nil;
        self.videoThumbImageView.hidden = YES;
        self.videoDurationLabel.hidden = YES;
        self.deleteVideoBtn.hidden = YES;
        self.selectedVideoURL = nil;
    }
    
    // 7. 附件信息更新
    [self.selectedAttachments removeAllObjects];
    if ([model.post_attachments isKindOfClass:[NSArray class]]) {
        for (id attachmentDict in model.post_attachments) {
            if ([attachmentDict isKindOfClass:[NSDictionary class]]) {
                PostAttachmentModel *attachment = [PostAttachmentModel yy_modelWithJSON:attachmentDict];
                if (attachment) {
                    [self.selectedAttachments addObject:attachment];
                }
            }
        }
    }
    [self.attachmentTableView reloadData];
    
    // 刷新图片列表
    [self.imageCollectionView reloadData];
    
    
    // 8. 强制刷新布局
    [self.view layoutIfNeeded];
}

// 更新视频预览
- (void)updateVideoPreview {
    // 查找视频媒体项
    MediaItem *videoItem = nil;
    for (MediaItem *item in self.mediaItems) {
        if (item.type == MediaTypeRemoteVideo || item.type == MediaTypeLocalVideo) {
            videoItem = item;
            break;
        }
    }
    NSLog(@"显示视频地址:%@",self.postModel.post_video_thumb_url)
    if (videoItem) {
        self.videoThumbImageView.hidden = NO;
        // 显示视频封面
        if (videoItem.type == MediaTypeRemoteVideo) {
            
            NSLog(@"云端视频  显示视频封面:%@",self.postModel.post_video_thumb_url);
            [self.videoThumbImageView sd_setImageWithURL:[NSURL URLWithString:self.postModel.post_video_thumb_url]
                                        placeholderImage:[UIImage imageNamed:@"video_placeholder"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if(image){
                    self.videoThumbImageView.hidden = NO;
                    self.videoThumbImageView.image = image;
                    self.videoThumbImageView.contentMode = UIViewContentModeScaleAspectFit;
                }
            }];
            
        } else {
            // 本地视频封面处理
            NSLog(@"本地视频封面处理");
            self.videoThumbImageView.image = [self getVideoThumbnail:videoItem.localPath];
            
        }
        
        
        // 显示时长
        NSLog(@"显示时长:%@",[self formatDuration:videoItem.duration]);
        self.videoDurationLabel.text = [self formatDuration:videoItem.duration];
        self.videoDurationLabel.hidden = NO;
        self.selectedVideoURL = [NSURL URLWithString:videoItem.localPath];
        self.deleteVideoBtn.hidden = NO;
        
        
    }
}


    
// 辅助方法：格式化时长
- (NSString *)formatDuration:(NSTimeInterval)duration {
    NSInteger seconds = (NSInteger)duration % 60;
    NSInteger minutes = (NSInteger)duration / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

// 辅助方法：获取视频缩略图
- (UIImage *)getVideoThumbnail:(NSString *)videoPath {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoPath] options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef imageRef = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    if (imageRef) {
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        return image;
    }
    return [UIImage imageNamed:@"video_placeholder"];
}

// 辅助方法：保存图片到临时路径
- (NSString *)saveImageToTempPath:(UIImage *)image {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]];
    NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
    
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:filePath atomically:YES];
    
    return filePath;
}



#pragma mark - 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 基础配置
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationItem.title = @"发布帖子";
    //读取系统配置信息
    self.sysVC = [SystemViewController sharedInstance];
    // 主动刷新配置（确保类型数据最新）
    [self.sysVC refreshConfigData];
    
    // 构建UI
    //导航
    [self setupnNavigationView];
    //容器
    [self setupMainScrollView];
    //标题输入框
    [self setupTitleTextField];
    //内容输入框
    [self setupContentTextView];
    //图片输入框
    [self setupImageSelectView];
    //视频内容
    [self setupVideoSelectView];
    //附件列表
    [self setupAttachmentSelectView];
    //定位
    [self setupLocationView];
    //底部统计按钮
    [self setupPermissionView];
    //更新主题
    [self updateUIForTraitCollection];
    // 延迟刷新UI（等待配置加载完成）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //设置帖子主类型UI
        [self setupPostMainTypeView];
        //设置帖子副类型UI
        [self setupPostTopicIdsView];
        //更新主题
        [self updateUIForTraitCollection];
        // 新增：更新所有UI
        [self updateUIWithPostModel:self.postModel];
        // 布局约束
        [self setupConstraints];
        //更新约束
        [self updateViewConstraints];
    });
    
    
    // 布局约束
    [self setupConstraints];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 请求定位权限
    [self requestLocationPermission];
    
    // 自动检测草稿（仅首次显示时提示）
    if (!self.hasShowDraftPrompt && self.postModel.post_id == 0) {
        BOOL hasDraft = [[NSUserDefaults standardUserDefaults] objectForKey:@"SinglePostDraft"] != nil;
        if (hasDraft) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"检测到本地草稿" message:@"是否载入上次未完成的草稿内容？" preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"载入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self loadSingleDraft];
                // 还原UI
                PostModel *draftModel = [self loadSingleDraft];
                if (draftModel) {
                    self.titleTextField.text = draftModel.post_title;
                    self.contentTextView.text = draftModel.post_content;
                    self.visibilitySegment.selectedSegmentIndex = draftModel.post_visibility;
                    self.commentForbiddenSwitch.on = draftModel.post_is_comment_forbidden;
                    self.shareForbiddenSwitch.on = draftModel.post_is_share_forbidden;
                    
                    UILabel *placeholderLabel = [self.contentTextView viewWithTag:1001];
                    placeholderLabel.hidden = draftModel.post_content.length > 0;
                    
                    [self.imageCollectionView reloadData];
                    [self.attachmentTableView reloadData];
                    
                    [self showHUDWithTitle:@"草稿载入成功" duration:1.5];
                }
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"暂不载入" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        self.hasShowDraftPrompt = YES; // 标记已提示，避免重复弹窗
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

#pragma mark - UI构建

#pragma mark - 导航栏草稿按钮
- (void)setupnNavigationView {
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    UIBarButtonItem * leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPublish)];
    // 初始化草稿按钮
    self.draftBarButton = [[UIBarButtonItem alloc] initWithTitle:@"草稿" style:UIBarButtonItemStylePlain target:self action:@selector(draftBarButtonClicked:)];
    self.draftBarButton.tintColor = [UIColor post_theme_color];
    self.postButton =  [[UIBarButtonItem alloc] initWithTitle:_isUpdating?@"提交更新":@"发布" style:UIBarButtonItemStyleDone target:self action:@selector(publishPost)];
    self.navigationItem.leftBarButtonItems = @[leftBarButtonItem, self.draftBarButton]; // 发布按钮 + 草稿按钮
    
    
    self.navigationItem.rightBarButtonItem = self.postButton;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor post_theme_color];
    
    
    
}

// 草稿按钮点击事件
- (void)draftBarButtonClicked:(UIBarButtonItem *)sender {
    // 检查是否有草稿
    BOOL hasDraft = [[NSUserDefaults standardUserDefaults] objectForKey:@"SinglePostDraft"] != nil;
    
    // 弹出草稿操作菜单
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"草稿操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 载入草稿
    [alert addAction:[UIAlertAction actionWithTitle:@"载入草稿" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (!hasDraft) {
            [self showHUDWithTitle:@"暂无草稿可载入" duration:1.5];
            return;
        }
        // 读取并还原草稿到UI
        PostModel *draftModel = [self loadSingleDraft];
        if (draftModel) {
            // 还原基础信息
            self.titleTextField.text = draftModel.post_title;
            self.contentTextView.text = draftModel.post_content;
            self.visibilitySegment.selectedSegmentIndex = draftModel.post_visibility;
            self.commentForbiddenSwitch.on = draftModel.post_is_comment_forbidden;
            self.shareForbiddenSwitch.on = draftModel.post_is_share_forbidden;
            
            // 还原正文占位符
            UILabel *placeholderLabel = [self.contentTextView viewWithTag:1001];
            placeholderLabel.hidden = draftModel.post_content.length > 0;
            
            // 刷新图片/附件列表
            [self.imageCollectionView reloadData];
            [self.attachmentTableView reloadData];
            
            [self showHUDWithTitle:@"草稿载入成功" duration:1.5];
        }
    }]];
    
    // 保存当前内容为草稿
    [alert addAction:[UIAlertAction actionWithTitle:@"保存当前为草稿" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self persistSingleDraft];
    }]];
    
    // 删除草稿（仅当有草稿时显示）
    if (hasDraft) {
        [alert addAction:[UIAlertAction actionWithTitle:@"删除草稿" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self deleteSingleDraft];
        }]];
    }
    
    // 取消
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // iPad适配
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = sender;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setupMainScrollView {
    _mainScrollView = [[UIScrollView alloc] init];
    _mainScrollView.backgroundColor = [UIColor post_bg_color];
    _mainScrollView.alwaysBounceVertical = YES;
    [self.view addSubview:_mainScrollView];
    
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor post_bg_color];
    [_mainScrollView addSubview:_contentView];
}

- (void)setupTitleTextField {
    _titleTextField = [[UITextField alloc] init];
    _titleTextField.placeholder = @"请输入帖子标题";
    _titleTextField.textColor = [UIColor post_text_primary_color];
    // 适配占位符颜色
    if (@available(iOS 13.0, *)) {
        _titleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入帖子标题" attributes:@{NSForegroundColorAttributeName: [UIColor post_text_secondary_color]}];
    } else {
        _titleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入帖子标题" attributes:@{NSForegroundColorAttributeName: [UIColor post_text_secondary_color]}];
    }
    
    _titleTextField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    _titleTextField.backgroundColor = [UIColor post_secondary_bg_color];
    _titleTextField.layer.cornerRadius = 8;
    _titleTextField.layer.masksToBounds = YES;
    _titleTextField.layer.borderColor = [UIColor post_border_color].CGColor;
    _titleTextField.layer.borderWidth = 1;
    _titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _titleTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 0)];
    _titleTextField.leftViewMode = UITextFieldViewModeAlways;
    _titleTextField.delegate = self;
    [_contentView addSubview:_titleTextField];
}

- (void)setupContentTextView {
    _contentTextView = [[UITextView alloc] init];
    _contentTextView.textColor = [UIColor post_text_primary_color];
    _contentTextView.backgroundColor = [UIColor post_secondary_bg_color];
    _contentTextView.font = [UIFont systemFontOfSize:16];
    _contentTextView.layer.cornerRadius = 8;
    _contentTextView.layer.masksToBounds = YES;
    _contentTextView.layer.borderColor = [UIColor post_border_color].CGColor;
    _contentTextView.layer.borderWidth = 1;
    _contentTextView.delegate = self;
    [_contentView addSubview:_contentTextView];
    
    // 占位符实现
    [self setupTextViewPlaceholder];
}

- (void)setupImageSelectView {
    _imageSelectView = [[UIView alloc] init];
    _imageSelectView.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_imageSelectView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"添加图片（最多9张）";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor post_text_primary_color];
    [_imageSelectView addSubview:titleLabel];
    
    // 图片选择CollectionView
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(80, 80);
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _imageCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _imageCollectionView.backgroundColor = [UIColor post_secondary_bg_color];
    _imageCollectionView.layer.cornerRadius = 8;
    _imageCollectionView.layer.masksToBounds = YES;
    _imageCollectionView.delegate = self;
    _imageCollectionView.dataSource = self;
    [_imageCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [_imageCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AddImageCell"];
    [_imageCollectionView registerClass:[ImageSelectCell class] forCellWithReuseIdentifier:@"ImageSelectCell"];

    [_imageSelectView addSubview:_imageCollectionView];
    
    // 约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_imageSelectView).offset(4);
        make.height.equalTo(@20);
    }];
    
    [_imageCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(4);
        make.left.right.equalTo(_imageSelectView).inset(4);
        make.height.equalTo(@90);
        make.bottom.equalTo(_imageSelectView).offset(-4);
    }];
}

- (void)setupVideoSelectView {
    _videoSelectView = [[UIView alloc] init];
    _videoSelectView.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_videoSelectView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"添加视频（仅支持一个）";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor post_text_primary_color];
    [_videoSelectView addSubview:titleLabel];
    
    // 视频预览区
    UIView *previewView = [[UIView alloc] init];
    previewView.backgroundColor = [UIColor post_secondary_bg_color];
    previewView.layer.cornerRadius = 8;
    previewView.layer.masksToBounds = YES;
    [_videoSelectView addSubview:previewView];
    
    // 视频缩略图
    _videoThumbImageView = [[UIImageView alloc] init];
    _videoThumbImageView.contentMode = UIViewContentModeScaleAspectFill;
    _videoThumbImageView.clipsToBounds = YES;
    _videoThumbImageView.backgroundColor = [UIColor post_border_color];
    [previewView addSubview:_videoThumbImageView];
    
    // 时长标签
    _videoDurationLabel = [[UILabel alloc] init];
    _videoDurationLabel.textColor = [UIColor whiteColor];
    _videoDurationLabel.font = [UIFont systemFontOfSize:12];
    _videoDurationLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    _videoDurationLabel.textAlignment = NSTextAlignmentCenter;
    _videoDurationLabel.layer.cornerRadius = 4;
    _videoDurationLabel.layer.masksToBounds = YES;
    _videoDurationLabel.hidden = YES;
    [previewView addSubview:_videoDurationLabel];
    
    // 添加视频按钮
    UIButton *addVideoBtn = [[UIButton alloc] init];
    [addVideoBtn setTitle:@"选择视频" forState:UIControlStateNormal];
    [addVideoBtn setTitleColor:[UIColor post_theme_color] forState:UIControlStateNormal];
    addVideoBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [addVideoBtn addTarget:self action:@selector(selectVideo) forControlEvents:UIControlEventTouchUpInside];
    [previewView addSubview:addVideoBtn];
    
    // 新增：删除视频按钮
    _deleteVideoBtn = [[UIButton alloc] init];
    [_deleteVideoBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    _deleteVideoBtn.tintColor = [UIColor post_danger_color];
    _deleteVideoBtn.hidden = YES;
    [_deleteVideoBtn addTarget:self action:@selector(deleteVideo) forControlEvents:UIControlEventTouchUpInside];
    [previewView addSubview:_deleteVideoBtn];
    
    // 约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_videoSelectView).offset(4);
        make.height.equalTo(@20);
    }];
    
    [previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(4);
        make.left.right.equalTo(_videoSelectView).inset(4);
        make.height.equalTo(@180);
        make.bottom.equalTo(_videoSelectView).offset(-4);
    }];
    
    [_videoThumbImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(previewView);
    }];
    
    [_videoDurationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.right.equalTo(previewView).offset(-8);
        make.width.equalTo(@60);
        make.height.equalTo(@20);
    }];
    
    [addVideoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(previewView);
        make.width.equalTo(@80);
        make.height.equalTo(@30);
    }];
    
    [_deleteVideoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(previewView).offset(-5);
        make.top.equalTo(previewView).offset(5);
        make.width.height.equalTo(@24);
    }];
}

- (void)setupAttachmentSelectView {
    _attachmentSelectView = [[UIView alloc] init];
    _attachmentSelectView.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_attachmentSelectView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"添加附件";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor post_text_primary_color];
    [_attachmentSelectView addSubview:titleLabel];
    
    // 新增：附件类型选择
    _attachmentTypeSegment = [[UISegmentedControl alloc] initWithItems:@[@"本地文件", @"文件URL"]];
    _attachmentTypeSegment.selectedSegmentIndex = 0;
    _attachmentTypeSegment.tintColor = [UIColor post_theme_color];
    [_attachmentTypeSegment addTarget:self action:@selector(attachmentTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [_attachmentSelectView addSubview:_attachmentTypeSegment];
    
    // 选择文件按钮
    _addFileBtn = [[UIButton alloc] init];
    [_addFileBtn setTitle:@"选择本地文件" forState:UIControlStateNormal];
    [_addFileBtn setTitleColor:[UIColor post_theme_color] forState:UIControlStateNormal];
    _addFileBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    _addFileBtn.backgroundColor = [UIColor post_secondary_bg_color];
    _addFileBtn.layer.cornerRadius = 8;
    [_addFileBtn addTarget:self action:@selector(selectLocalFile) forControlEvents:UIControlEventTouchUpInside];
    [_attachmentSelectView addSubview:_addFileBtn];
   
    // 新增：添加URL按钮
    _addURLBtn = [[UIButton alloc] init];
    [_addURLBtn setTitle:@"添加URL附件" forState:UIControlStateNormal];
    [_addURLBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_addURLBtn setBackgroundColor:[UIColor post_theme_color]];
    _addURLBtn.layer.cornerRadius = 8;
    _addURLBtn.hidden = YES; // 默认隐藏
    [_addURLBtn addTarget:self action:@selector(addURLAttachment) forControlEvents:UIControlEventTouchUpInside];
    [_attachmentSelectView addSubview:_addURLBtn];
    
    // 附件列表
    _attachmentTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _attachmentTableView.backgroundColor = [UIColor post_secondary_bg_color];
    _attachmentTableView.layer.cornerRadius = 8;
    _attachmentTableView.layer.masksToBounds = YES;
    _attachmentTableView.delegate = self;
    _attachmentTableView.dataSource = self;
    _attachmentTableView.rowHeight = 50;
    [_attachmentTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AttachmentCell"];
    [_attachmentSelectView addSubview:_attachmentTableView];
    
    // 约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_attachmentSelectView).offset(4);
        make.height.equalTo(@20);
    }];
    
    [_attachmentTypeSegment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(4);
        make.left.equalTo(_attachmentSelectView).offset(4);
        make.width.equalTo(@180);
        make.height.equalTo(@32);
    }];
    
    [_addFileBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_attachmentTypeSegment.mas_top);
        make.left.equalTo(_attachmentTypeSegment.mas_right).offset(8);
        make.right.equalTo(_attachmentSelectView).offset(-8);
        make.height.equalTo(@32);
    }];
    
    
    [_addURLBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_attachmentTypeSegment.mas_top);
        make.left.equalTo(_attachmentTypeSegment.mas_right).offset(8);
        make.right.equalTo(_attachmentSelectView).offset(-8);
        make.height.equalTo(@32);
    }];
    
    [_attachmentTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_addFileBtn.mas_bottom).offset(8);
        make.left.right.equalTo(_attachmentSelectView).inset(4);
        make.height.equalTo(@120);
        make.bottom.equalTo(_attachmentSelectView).offset(-4);
    }];
}

- (void)setupLocationView {
    _locationView = [[UIView alloc] init];
    _locationView.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_locationView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"地理位置";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor post_text_primary_color];
    [_locationView addSubview:titleLabel];
    
    // 位置标签
    _locationLabel = [[UIButton alloc] init];
    [_locationLabel setTitle:@"未选择位置" forState:UIControlStateNormal];
    [_locationLabel setTitleColor:[UIColor post_text_secondary_color] forState:UIControlStateNormal];
    [_locationLabel addTarget:self action:@selector(getCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
    _locationLabel.titleLabel.font = [UIFont systemFontOfSize:14];
    _locationLabel.titleLabel.textColor = [UIColor post_text_secondary_color];
    _locationLabel.backgroundColor = [UIColor post_secondary_bg_color];
    _locationLabel.layer.cornerRadius = 8;
    _locationLabel.layer.masksToBounds = YES;
    _locationLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_locationView addSubview:_locationLabel];
    
    // 约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_locationView).offset(8);
        make.height.equalTo(@20);
    }];
   
    
    [_locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(4);
        make.left.equalTo(_locationView).offset(4);
        make.right.equalTo(_locationView.mas_right).offset(-4);
        make.height.equalTo(@36);
    }];
    
    
    
}

// 帖子主类型（单选）UI构建
- (void)setupPostMainTypeView {
    _postMainTypeView = [[UIView alloc] init];
    _postMainTypeView.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_postMainTypeView];
    
    // 标题
    _postMainTypeLabel = [[UILabel alloc] init];
    _postMainTypeLabel.text = @"帖子主类型（单选）";
    _postMainTypeLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _postMainTypeLabel.textColor = [UIColor post_text_primary_color];
    [_postMainTypeView addSubview:_postMainTypeLabel];
    
    // 从SystemVC单例读取主类型配置
    ConfigItem *item0 = [self.sysVC configItemForKey:@"categories0"];
    ConfigItem *item1 = [self.sysVC configItemForKey:@"categories1"];
    ConfigItem *item2 = [self.sysVC configItemForKey:@"categories2"];
    ConfigItem *item3 = [self.sysVC configItemForKey:@"categories3"];
    
    // 组装主类型数据（兼容配置读取失败的默认值）
    NSArray *categories = @[
        @{@"id": @0, @"name": item0 ? item0.config_value : @"全部类型"},
        @{@"id": @1, @"name": item1 ? item1.config_value : @"社区求助"},
        @{@"id": @2, @"name": item2 ? item2.config_value : @"经验分享"},
        @{@"id": @3, @"name": item3 ? item3.config_value : @"有偿"}
    ];
    
    // 构建SegmentedControl选项
    NSMutableArray *segmentTitles = [NSMutableArray array];
    for (NSDictionary *cate in categories) {
        [segmentTitles addObject:cate[@"name"]];
    }
    
    // 主类型Segment（单选）
    _postMainTypeSegment = [[UISegmentedControl alloc] initWithItems:segmentTitles];
    _postMainTypeSegment.selectedSegmentIndex = 0; // 默认选中第一个
    _postMainTypeSegment.tintColor = [UIColor post_theme_color];
    [_postMainTypeSegment addTarget:self action:@selector(postMainTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [_postMainTypeView addSubview:_postMainTypeSegment];
    
    // 初始化选中的主类型ID
    self.postModel.category_id = 0;
    
    // 约束
    [_postMainTypeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_postMainTypeView).offset(8);
        make.height.equalTo(@20);
    }];
    
    [_postMainTypeSegment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_postMainTypeLabel.mas_bottom).offset(8);
        make.left.right.equalTo(_postMainTypeView).inset(8);
        make.height.equalTo(@40);
        make.bottom.equalTo(_postMainTypeView).offset(-8);
    }];
}

//帖子副类型（多选）UI构建
- (void)setupPostTopicIdsView {
    _topic_ids_view = [[UIView alloc] init];
    _topic_ids_view.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_topic_ids_view];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"帖子副类型（多选）";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor post_text_primary_color];
    [_topic_ids_view addSubview:titleLabel];
    
    // 从SystemVC单例读取副类型配置
    ConfigItem *topic0 = [self.sysVC configItemForKey:@"topics0"];
    ConfigItem *topic1 = [self.sysVC configItemForKey:@"topics1"];
    ConfigItem *topic2 = [self.sysVC configItemForKey:@"topics2"];
    ConfigItem *topic3 = [self.sysVC configItemForKey:@"topics3"];
    
    // 组装副类型数据（兼容配置读取失败的默认值）
    NSArray *topics = @[
        @{@"id": @0, @"name": topic0 ? topic0.config_value : @"全部类型"},
        @{@"id": @1, @"name": topic1 ? topic1.config_value : @"巨魔IPA"},
        @{@"id": @2, @"name": topic2 ? topic2.config_value : @"无根插件"},
        @{@"id": @3, @"name": topic3 ? topic3.config_value : @"有根插件"}
    ];
    
    // 初始化副类型按钮数组
    self.topic_ids_buttons = [NSMutableArray array];
    // 按钮容器（用于流式布局，这里用UIStackView简化）
    UIStackView *buttonStackView = [[UIStackView alloc] init];
    buttonStackView.axis = UILayoutConstraintAxisHorizontal;
    buttonStackView.spacing = 10;
    buttonStackView.alignment = UIStackViewAlignmentCenter;
    buttonStackView.distribution = UIStackViewDistributionFillProportionally;
    buttonStackView.backgroundColor = [UIColor post_secondary_bg_color];
    buttonStackView.layer.cornerRadius = 8;
    [_topic_ids_view addSubview:buttonStackView];
    
    // 构建副类型按钮
    for (NSInteger i = 0; i < topics.count; i++) {
        NSDictionary *topic = topics[i];
        NSNumber *topicId = topic[@"id"];
        NSString *topicName = topic[@"name"];
        
        UIButton *topicBtn = [[UIButton alloc] init];
        [topicBtn setTitle:topicName forState:UIControlStateNormal];
        //设置未选中的文字颜色
        [topicBtn setTitleColor:[UIColor tertiaryLabelColor] forState:UIControlStateNormal];
        //选择的文字颜色
        [topicBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        topicBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        topicBtn.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.05];
        topicBtn.selectedBackgroundColor = [UIColor blueColor]; // 需添加UIButton分类支持选中背景色
        topicBtn.layer.cornerRadius = 16;
        topicBtn.tag = topicId.integerValue; // 用tag存储副类型ID
        [topicBtn addTarget:self action:@selector(topicButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        // ===== 正确的选中状态判断 =====
        // 1. 判断 postModel.topic_ids 中是否包含当前按钮的 topicId
        BOOL isSelected = [self.postModel.topic_ids containsObject:topicId];
        // 2. 赋值给按钮的selected属性
        topicBtn.selected = isSelected;
        [buttonStackView addArrangedSubview:topicBtn];
        
        // 设置按钮最小宽度
        [topicBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@32);
            make.width.greaterThanOrEqualTo(@60);
        }];
        
        [self.topic_ids_buttons addObject:topicBtn];
    }
    
    // 初始化副类型ID数组
    self.postModel.topic_ids = @[];
    
    // 约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_topic_ids_view).offset(8);
        make.height.equalTo(@20);
    }];
    
    [buttonStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(_topic_ids_view).inset(8);
        make.bottom.equalTo(_topic_ids_view).offset(-8);
        make.height.equalTo(@48);
    }];
}

// 副类型按钮点击事件（多选切换）
- (void)topicButtonClicked:(UIButton *)sender {
    sender.selected = !sender.selected;
    NSInteger topicId = sender.tag;
    NSMutableArray *selectedTopicIds = [self.postModel.topic_ids mutableCopy] ?: [NSMutableArray array];
    
    if (sender.selected) {
        // 选中：添加ID
        if (![selectedTopicIds containsObject:@(topicId)]) {
            [selectedTopicIds addObject:@(topicId)];
        }
        sender.selectedBackgroundColor = [UIColor blueColor]; // 需添加UIButton分类支持选中背景色
        //选择的文字颜色
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    } else {
        // 取消选中：移除ID
        [selectedTopicIds removeObject:@(topicId)];
        sender.selectedBackgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.05]; // 需添加UIButton分类支持选中背景色
        //设置未选中的文字颜色
        [sender setTitleColor:[UIColor tertiaryLabelColor] forState:UIControlStateNormal];
       
    }
    
    // 更新postModel中的副类型ID数组
    self.postModel.topic_ids = selectedTopicIds.copy;
    NSLog(@"选中的副类型ID数组：%@", self.postModel.topic_ids);
}


// 主类型切换事件
- (void)postMainTypeChanged:(UISegmentedControl *)sender {
    NSInteger selectedIndex = sender.selectedSegmentIndex;
    // 映射Segment索引到主类型ID（索引和ID一致）
    self.postModel.category_id = selectedIndex;
    NSLog(@"选中主类型ID：%ld", (long)self.postModel.category_id);
}

- (void)setupPermissionView {
    _permissionView = [[UIView alloc] init];
    _permissionView.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_permissionView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"权限设置";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor post_text_primary_color];
    [_permissionView addSubview:titleLabel];
    
    // 可见范围
    UIView *visibilityView = [[UIView alloc] init];
    visibilityView.backgroundColor = [UIColor post_secondary_bg_color];
    visibilityView.layer.cornerRadius = 8;
    [_permissionView addSubview:visibilityView];
    
    UILabel *visibilityLabel = [[UILabel alloc] init];
    visibilityLabel.text = @"可见范围：";
    visibilityLabel.font = [UIFont systemFontOfSize:14];
    visibilityLabel.textColor = [UIColor post_text_primary_color];
    [visibilityView addSubview:visibilityLabel];
    
    _visibilitySegment = [[UISegmentedControl alloc] initWithItems:@[@"公开", @"仅粉丝", @"仅自己"]];
    _visibilitySegment.selectedSegmentIndex = 0;
    _visibilitySegment.tintColor = [UIColor post_theme_color];
    [_visibilitySegment addTarget:self action:@selector(visibilityChanged:) forControlEvents:UIControlEventValueChanged];
    [visibilityView addSubview:_visibilitySegment];
    
    // 禁止评论
    UIView *commentView = [[UIView alloc] init];
    commentView.backgroundColor = [UIColor post_secondary_bg_color];
    commentView.layer.cornerRadius = 8;
    [_permissionView addSubview:commentView];
    
    UILabel *commentLabel = [[UILabel alloc] init];
    commentLabel.text = @"禁止评论：";
    commentLabel.font = [UIFont systemFontOfSize:14];
    commentLabel.textColor = [UIColor post_text_primary_color];
    [commentView addSubview:commentLabel];
    
    _commentForbiddenSwitch = [[UISwitch alloc] init];
    _commentForbiddenSwitch.onTintColor = [UIColor post_theme_color];
    [_commentForbiddenSwitch addTarget:self action:@selector(commentForbiddenChanged:) forControlEvents:UIControlEventValueChanged];
    [commentView addSubview:_commentForbiddenSwitch];
    
    // 禁止分享
    UIView *shareView = [[UIView alloc] init];
    shareView.backgroundColor = [UIColor post_secondary_bg_color];
    shareView.layer.cornerRadius = 8;
    [_permissionView addSubview:shareView];
    
    UILabel *shareLabel = [[UILabel alloc] init];
    shareLabel.text = @"禁止分享：";
    shareLabel.font = [UIFont systemFontOfSize:14];
    shareLabel.textColor = [UIColor post_text_primary_color];
    [shareView addSubview:shareLabel];
    
    _shareForbiddenSwitch = [[UISwitch alloc] init];
    _shareForbiddenSwitch.onTintColor = [UIColor post_theme_color];
    [_shareForbiddenSwitch addTarget:self action:@selector(shareForbiddenChanged:) forControlEvents:UIControlEventValueChanged];
    [shareView addSubview:_shareForbiddenSwitch];
    
    // 约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_permissionView).offset(8);
        make.height.equalTo(@20);
    }];
    
    [visibilityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(_permissionView).inset(8);
        make.height.equalTo(@44);
    }];
    
    [visibilityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(visibilityView).offset(16);
        make.centerY.equalTo(visibilityView);
    }];
    
    [_visibilitySegment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(visibilityLabel.mas_right).offset(16);
        make.right.equalTo(visibilityView).offset(-16);
        make.centerY.equalTo(visibilityView);
    }];
    
    [commentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(visibilityView.mas_bottom).offset(8);
        make.left.right.equalTo(_permissionView).inset(8);
        make.height.equalTo(@44);
    }];
    
    [commentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(commentView).offset(16);
        make.centerY.equalTo(commentView);
    }];
    
    [_commentForbiddenSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(commentView).offset(-16);
        make.centerY.equalTo(commentView);
    }];
    
    [shareView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(commentView.mas_bottom).offset(8);
        make.left.right.equalTo(_permissionView).inset(8);
        make.height.equalTo(@44);
        make.bottom.equalTo(_permissionView).offset(-8);
    }];
    
    [shareLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(shareView).offset(16);
        make.centerY.equalTo(shareView);
    }];
    
    [_shareForbiddenSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(shareView).offset(-16);
        make.centerY.equalTo(shareView);
    }];
}

- (void)setupPostsTags {
    _permissionView = [[UIView alloc] init];
    _permissionView.backgroundColor = [UIColor post_bg_color];
    [_contentView addSubview:_permissionView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"权限设置";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor post_text_primary_color];
    [_permissionView addSubview:titleLabel];
    
    // 可见范围
    UIView *visibilityView = [[UIView alloc] init];
    visibilityView.backgroundColor = [UIColor post_secondary_bg_color];
    visibilityView.layer.cornerRadius = 8;
    [_permissionView addSubview:visibilityView];
    
    UILabel *visibilityLabel = [[UILabel alloc] init];
    visibilityLabel.text = @"可见范围：";
    visibilityLabel.font = [UIFont systemFontOfSize:14];
    visibilityLabel.textColor = [UIColor post_text_primary_color];
    [visibilityView addSubview:visibilityLabel];
    
    _visibilitySegment = [[UISegmentedControl alloc] initWithItems:@[@"公开", @"仅粉丝", @"仅自己"]];
    _visibilitySegment.selectedSegmentIndex = 0;
    _visibilitySegment.tintColor = [UIColor post_theme_color];
    [_visibilitySegment addTarget:self action:@selector(visibilityChanged:) forControlEvents:UIControlEventValueChanged];
    [visibilityView addSubview:_visibilitySegment];
    
    // 禁止评论
    UIView *commentView = [[UIView alloc] init];
    commentView.backgroundColor = [UIColor post_secondary_bg_color];
    commentView.layer.cornerRadius = 8;
    [_permissionView addSubview:commentView];
    
    UILabel *commentLabel = [[UILabel alloc] init];
    commentLabel.text = @"禁止评论：";
    commentLabel.font = [UIFont systemFontOfSize:14];
    commentLabel.textColor = [UIColor post_text_primary_color];
    [commentView addSubview:commentLabel];
    
    _commentForbiddenSwitch = [[UISwitch alloc] init];
    _commentForbiddenSwitch.onTintColor = [UIColor post_theme_color];
    [_commentForbiddenSwitch addTarget:self action:@selector(commentForbiddenChanged:) forControlEvents:UIControlEventValueChanged];
    [commentView addSubview:_commentForbiddenSwitch];
    
    // 禁止分享
    UIView *shareView = [[UIView alloc] init];
    shareView.backgroundColor = [UIColor post_secondary_bg_color];
    shareView.layer.cornerRadius = 8;
    [_permissionView addSubview:shareView];
    
    UILabel *shareLabel = [[UILabel alloc] init];
    shareLabel.text = @"禁止分享：";
    shareLabel.font = [UIFont systemFontOfSize:14];
    shareLabel.textColor = [UIColor post_text_primary_color];
    [shareView addSubview:shareLabel];
    
    _shareForbiddenSwitch = [[UISwitch alloc] init];
    _shareForbiddenSwitch.onTintColor = [UIColor post_theme_color];
    [_shareForbiddenSwitch addTarget:self action:@selector(shareForbiddenChanged:) forControlEvents:UIControlEventValueChanged];
    [shareView addSubview:_shareForbiddenSwitch];
    
    // 约束
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_permissionView).offset(8);
        make.height.equalTo(@20);
    }];
    
    [visibilityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(_permissionView).inset(8);
        make.height.equalTo(@44);
    }];
    
    [visibilityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(visibilityView).offset(16);
        make.centerY.equalTo(visibilityView);
    }];
    
    [_visibilitySegment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(visibilityLabel.mas_right).offset(16);
        make.right.equalTo(visibilityView).offset(-16);
        make.centerY.equalTo(visibilityView);
    }];
    
    [commentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(visibilityView.mas_bottom).offset(8);
        make.left.right.equalTo(_permissionView).inset(8);
        make.height.equalTo(@44);
    }];
    
    [commentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(commentView).offset(16);
        make.centerY.equalTo(commentView);
    }];
    
    [_commentForbiddenSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(commentView).offset(-16);
        make.centerY.equalTo(commentView);
    }];
    
    [shareView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(commentView.mas_bottom).offset(8);
        make.left.right.equalTo(_permissionView).inset(8);
        make.height.equalTo(@44);
        make.bottom.equalTo(_permissionView).offset(-8);
    }];
    
    [shareLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(shareView).offset(16);
        make.centerY.equalTo(shareView);
    }];
    
    [_shareForbiddenSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(shareView).offset(-16);
        make.centerY.equalTo(shareView);
    }];
}

#pragma mark - 约束布局
- (void)setupConstraints {
    // 滚动视图约束
    [_mainScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_mainScrollView);
        make.width.equalTo(_mainScrollView);
    }];
    
    // 标题输入框
    [_titleTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentView).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@44);
    }];
    
    // 正文输入框
    [_contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleTextField.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@120);
    }];
    
    // 图片选择区
    [_imageSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentTextView.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@110);
    }];
    
    // 视频选择区
    [_videoSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imageSelectView.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@200);
    }];
    
    // 附件选择区
    [_attachmentSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_videoSelectView.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@220); // 调整高度适配新增组件
    }];
    
    
    
    // 地理位置
    [_locationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_attachmentSelectView.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@60);
    }];
    
    
    // 权限设置
    [_permissionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_locationView.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@200);
        
    }];
    
    // ===== 新增：类型选择UI约束 =====
    // 主类型
    [_postMainTypeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_permissionView.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.equalTo(@80);
    }];
    
    // 副类型
    [_topic_ids_view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_postMainTypeView.mas_bottom).offset(16);
        make.left.right.equalTo(_contentView).inset(16);
        make.height.greaterThanOrEqualTo(@100); // 自适应高度
        make.bottom.equalTo(_contentView).offset(-40);
    }];
    
    
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    // 主类型
    [self.postMainTypeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_permissionView.mas_bottom).offset(16);
        make.left.right.equalTo(self.contentView).inset(16);
        make.height.equalTo(@80);
    }];
    
    // 副类型
    [self.topic_ids_view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.postMainTypeView.mas_bottom).offset(16);
        make.left.right.equalTo(self.contentView).inset(16);
        make.height.greaterThanOrEqualTo(@100); // 自适应高度
        make.bottom.equalTo(_contentView).offset(-40);
    }];
}

#pragma mark - 主题适配
- (void)updateUIForTraitCollection {
    // 更新背景色
    self.view.backgroundColor = [UIColor post_bg_color];
    _mainScrollView.backgroundColor = [UIColor post_bg_color];
    _contentView.backgroundColor = [UIColor post_bg_color];
    
    // 更新文本色
    _titleTextField.textColor = [UIColor post_text_primary_color];
    _contentTextView.textColor = [UIColor post_text_primary_color];
    
    // 更新背景色
    _titleTextField.backgroundColor = [UIColor post_secondary_bg_color];
    _contentTextView.backgroundColor = [UIColor post_secondary_bg_color];
    _imageCollectionView.backgroundColor = [UIColor post_secondary_bg_color];
    _attachmentTableView.backgroundColor = [UIColor post_secondary_bg_color];
    _locationLabel.backgroundColor = [UIColor post_secondary_bg_color];
    _addFileBtn.backgroundColor = [UIColor post_secondary_bg_color];
    
    // 更新边框色
    _titleTextField.layer.borderColor = [UIColor post_border_color].CGColor;
    _contentTextView.layer.borderColor = [UIColor post_border_color].CGColor;
    
    // 更新主题色
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor post_theme_color];
    _visibilitySegment.tintColor = [UIColor post_theme_color];
    _commentForbiddenSwitch.onTintColor = [UIColor post_theme_color];
    _shareForbiddenSwitch.onTintColor = [UIColor post_theme_color];
    _attachmentTypeSegment.tintColor = [UIColor post_theme_color];
    _addURLBtn.backgroundColor = [UIColor post_theme_color];
    _deleteVideoBtn.tintColor = [UIColor post_danger_color];
    
    // 刷新列表/集合视图
    [_imageCollectionView reloadData];
    [_attachmentTableView reloadData];
    // 新增：类型UI主题适配
    _postMainTypeLabel.textColor = [UIColor post_text_primary_color];
    _postMainTypeSegment.tintColor = [UIColor post_theme_color];
    
    // 副类型标题和按钮适配
    for (UIView *subview in _topic_ids_view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            ((UILabel *)subview).textColor = [UIColor post_text_primary_color];
        } else if ([subview isKindOfClass:[UIStackView class]]) {
            UIStackView *stackView = (UIStackView *)subview;
            stackView.backgroundColor = [UIColor post_secondary_bg_color];
            for (UIButton *btn in stackView.arrangedSubviews) {
                [btn setTitleColor:[UIColor post_text_primary_color] forState:UIControlStateNormal];
                btn.backgroundColor = btn.isSelected ? [UIColor post_theme_color] : [UIColor post_secondary_bg_color];
            }
        }
    }
}



#pragma mark - 交互事件

// 取消发布（单草稿保存）
- (void)cancelPublish {
    // 1. 判断是否有可保存内容
    BOOL hasContent = (self.titleTextField.text.length > 0 ||
                       self.contentTextView.text.length > 0 ||
                       self.selectedImages.count > 0 ||
                       self.selectedVideoURL != nil ||
                       self.selectedAttachments.count > 0 ||
                       self.currentLocation != nil);
    
    if (!hasContent) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // 2. 弹出保存确认弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"取消发布"
                                                                   message:@"是否保存当前内容为草稿？（仅保留最新一份草稿）"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // 仅取消
    [alert addAction:[UIAlertAction actionWithTitle:@"仅取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    // 保存草稿并取消
    [alert addAction:[UIAlertAction actionWithTitle:@"保存草稿并取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self persistSingleDraft]; // 保存单个草稿
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 保存草稿核心方法
- (void)saveDraft {
    // 1. 组装草稿数据（更新postModel的所有字段）
    self.postModel.post_title = self.titleTextField.text ?: @"";
    self.postModel.post_content = self.contentTextView.text ?: @"";
    self.postModel.post_visibility = self.visibilitySegment.selectedSegmentIndex;
    self.postModel.post_is_comment_forbidden = self.commentForbiddenSwitch.isOn;
    self.postModel.post_is_share_forbidden = self.shareForbiddenSwitch.isOn;
    self.postModel.post_update_time = [[NSDate date] timeIntervalSince1970]; // 更新草稿时间
    self.postModel.post_status = 1; // 标记为草稿（0=未发布，1=草稿，2=已发布）
    
    // 2. 处理图片（保存本地路径/Base64，示例用Base64简化，实际建议存本地沙盒路径）
    NSMutableArray *imageBase64Array = [NSMutableArray array];
    for (UIImage *image in self.selectedImages) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5); // 压缩为JPG
        [imageBase64Array addObject:[imageData base64EncodedStringWithOptions:0]];
    }
    self.postModel.post_images = imageBase64Array;
    
    // 3. 处理视频（保存本地URL字符串）
    if (self.selectedVideoURL) {
        self.postModel.post_video_url = self.selectedVideoURL.absoluteString;
        // 保存视频时长（可选）
        AVURLAsset *asset = [AVURLAsset assetWithURL:self.selectedVideoURL];
        self.postModel.post_video_duration = CMTimeGetSeconds(asset.duration);
    }
    
    // 4. 处理附件（直接保存模型数组）
    self.postModel.post_attachments = self.selectedAttachments;
    
    // 5. 处理地理位置
    if (self.currentLocation) {
        self.postModel.post_latlng = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
        // 逆地理编码保存地址（可选）
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        __weak typeof(self) weakSelf = self;
        [geocoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (!error && placemarks.count > 0) {
                CLPlacemark *placemark = placemarks.firstObject;
                weakSelf.postModel.post_location = [NSString stringWithFormat:@"%@%@%@", placemark.administrativeArea ?: @"", placemark.locality ?: @"", placemark.thoroughfare ?: @""];
            }
            // 6. 持久化保存草稿
            [weakSelf persistDraft];
        }];
    } else {
        // 无位置信息，直接保存
        [self persistDraft];
    }
}

// 草稿持久化（示例：UserDefaults，复杂场景替换为CoreData/Realm/服务器）
- (void)persistDraft {
    // 1. 将PostModel转为可序列化的字典
    NSDictionary *draftDict = [self.postModel yy_modelToJSONObject];
    
    // 2. 获取已有草稿列表
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *draftList = [NSMutableArray arrayWithArray:[defaults objectForKey:@"PostDrafts"] ?: @[]];
    
    // 3. 去重（同一草稿更新，避免重复）
    NSMutableArray *newDraftList = [NSMutableArray array];
    for (NSDictionary *oldDraft in draftList) {
        if (![oldDraft[@"post_uuid"] isEqualToString:self.postModel.post_uuid]) {
            [newDraftList addObject:oldDraft];
        }
    }
    [newDraftList addObject:draftDict];
    
    // 4. 保存草稿列表
    [defaults setObject:newDraftList forKey:@"PostDrafts"];
    [defaults synchronize];
    
    // 5. 提示保存成功并关闭页面
    [self showHUDWithTitle:@"草稿保存成功" duration:1.5];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - 单草稿核心操作方法
// 保存单个草稿（覆盖式，仅保留最新一个）
- (void)persistSingleDraft {
    // 1. 组装草稿数据
    self.postModel.post_title = self.titleTextField.text ?: @"";
    self.postModel.post_content = self.contentTextView.text ?: @"";
    self.postModel.post_visibility = self.visibilitySegment.selectedSegmentIndex;
    self.postModel.post_is_comment_forbidden = self.commentForbiddenSwitch.isOn;
    self.postModel.post_is_share_forbidden = self.shareForbiddenSwitch.isOn;
    self.postModel.post_update_time = [[NSDate date] timeIntervalSince1970];
    // 新增：保存主类型和副类型
    self.postModel.category_id = self.postMainTypeSegment.selectedSegmentIndex;
    self.postModel.topic_ids = self.postModel.topic_ids ?: @[];
    self.postModel.post_status = 1; // 草稿标记
    
    // 2. 处理图片（Base64，生产环境建议存沙盒路径）
    NSMutableArray *imageBase64Array = [NSMutableArray array];
    for (UIImage *image in self.selectedImages) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [imageBase64Array addObject:[imageData base64EncodedStringWithOptions:0]];
    }
    self.postModel.post_images = imageBase64Array;
    
    // 3. 处理视频
    if (self.selectedVideoURL) {
        self.postModel.post_video_url = self.selectedVideoURL.absoluteString;
        AVURLAsset *asset = [AVURLAsset assetWithURL:self.selectedVideoURL];
        self.postModel.post_video_duration = CMTimeGetSeconds(asset.duration);
    }
    
    // 4. 处理附件
    NSMutableArray *attachmentDicts = [NSMutableArray array];
    
    self.postModel.post_attachments = attachmentDicts;
    
    // 5. 处理地理位置
    if (self.currentLocation) {
        self.postModel.post_latlng = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        __weak typeof(self) weakSelf = self;
        [geocoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (!error && placemarks.count > 0) {
                CLPlacemark *placemark = placemarks.firstObject;
                weakSelf.postModel.post_location = [NSString stringWithFormat:@"%@%@%@", placemark.administrativeArea ?: @"", placemark.locality ?: @"", placemark.thoroughfare ?: @""];
            }
            // 6. 持久化单个草稿（覆盖式）
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[weakSelf.postModel yy_modelToJSONObject] forKey:@"SinglePostDraft"];
            [defaults synchronize];
            
            [weakSelf showHUDWithTitle:@"草稿保存成功" duration:1.5];
        }];
    } else {
        // 无位置信息直接保存
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[self.postModel yy_modelToJSONObject] forKey:@"SinglePostDraft"];
        [defaults synchronize];
        
        [self showHUDWithTitle:@"草稿保存成功" duration:1.5];
    }
}

// 读取单个草稿
- (nullable PostModel *)loadSingleDraft {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *draftDict = [defaults objectForKey:@"SinglePostDraft"];
    if (!draftDict) return nil;
    
    // 字典转模型（YYModel）
    PostModel *draftModel = [PostModel yy_modelWithJSON:draftDict];
    
    // 还原图片（Base64转UIImage）
    NSMutableArray *images = [NSMutableArray array];
    for (NSString *base64Str in draftModel.post_images ?: @[]) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Str options:0];
        if (imageData) {
            [images addObject:[UIImage imageWithData:imageData]];
        }
    }
    self.selectedImages = images;
    
    // 还原视频
    if (draftModel.post_video_url.length > 0) {
        NSURL *videoURL = [NSURL URLWithString:draftModel.post_video_url];
        if ([[NSFileManager defaultManager] fileExistsAtPath:videoURL.path]) {
            self.selectedVideoURL = videoURL;
            
            // 还原视频缩略图和时长
            AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            generator.appliesPreferredTrackTransform = YES;
            CMTime time = CMTimeMakeWithSeconds(0, 600);
            CGImageRef imageRef = [generator copyCGImageAtTime:time actualTime:NULL error:NULL];
            self.videoThumbImageView.image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            
            NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
            self.videoDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)duration/60, (int)duration%60];
            self.videoDurationLabel.hidden = NO;
            self.deleteVideoBtn.hidden = NO;
        }
    }
    
    // 还原附件
    NSMutableArray *attachments = [NSMutableArray array];
    for (NSDictionary *attachmentDict in draftModel.post_attachments ?: @[]) {
        PostAttachmentModel *attachment = [PostAttachmentModel yy_modelWithJSON:attachmentDict];
        [attachments addObject:attachment];
    }
    self.selectedAttachments = attachments;
    
    // 还原地理位置
    if (draftModel.post_latlng.length > 0) {
        self.locationLabel.titleLabel.text = draftModel.post_location ?: draftModel.post_latlng;
        NSArray *latLngArr = [draftModel.post_latlng componentsSeparatedByString:@","];
        if (latLngArr.count == 2) {
            CLLocationDegrees latitude = [latLngArr[0] doubleValue];
            CLLocationDegrees longitude = [latLngArr[1] doubleValue];
            self.currentLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        }
    }
    // 新增：还原主类型选择
    if (draftModel.category_id >= 0 && draftModel.category_id < self.postMainTypeSegment.numberOfSegments) {
        self.postMainTypeSegment.selectedSegmentIndex = draftModel.category_id;
        self.postModel.category_id = draftModel.category_id;
    }
    
    // 新增：还原副类型选择
    NSArray<NSNumber *> *savedTopicIds = draftModel.topic_ids ?: @[];
    for (UIButton *topicBtn in self.topic_ids_buttons) {
        NSInteger btnTag = topicBtn.tag;
        topicBtn.selected = [savedTopicIds containsObject:@(btnTag)];
    }
    self.postModel.topic_ids = savedTopicIds;
    
    return draftModel;
}

// 删除单个草稿
- (void)deleteSingleDraft {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"SinglePostDraft"];
    [defaults synchronize];
    [self showHUDWithTitle:@"草稿已删除" duration:1.5];
}

// 清除草稿（发布成功后调用）
- (void)clearDraftAfterPublish {
    [self deleteSingleDraft];
    self.hasShowDraftPrompt = NO; // 重置提示标记
}

#pragma mark - 发布帖子核心操作方法 = =======

- (void)publishPost {
    // 1. 验证输入
    if (![self validateInput]) {
        [SVProgressHUD showInfoWithStatus:@"请完善帖子信息"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    
    // 2. 构建PostModel
    self.postModel = [self buildPostModel];
    NSLog(@"构建PostModel:%ld",self.postModel.post_images.count);
    
    if (!self.postModel) {
        
        [SVProgressHUD showInfoWithStatus:@"构建帖子数据失败"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // 3. 显示加载框
    [SVProgressHUD showWithStatus:@"发布中..."];
    
    
    // 4. 调用发布工具类
    [[PostPublisher sharedInstance] publishPost:self.postModel progress:^(CGFloat progress) {
        // 更新进度（可选）
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showProgress:progress];
        });
        
    } completion:^(BOOL success, NSString *message, PostModel *postModel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.postModel = postModel;
            [self hideHUD];
            [SVProgressHUD showSuccessWithStatus:message];
            [SVProgressHUD dismissWithDelay:1];
            
            if (success) {
                // 发布成功，返回上一页
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                // 失败处理，可选择重试
            }
        });
        
    }];
}

#pragma mark - 辅助方法
- (BOOL)validateInput {
    // 简单验证：标题和内容至少有一个
    return (self.titleTextField.text.length > 0 && self.contentTextView.text.length > 0);
}

// 获取最新数据
- (PostModel *)buildPostModel {
    // 确保postModel已存在（外部传入/初始化/草稿载入），不在这里创建新实例
    NSAssert(self.postModel, @"postModel未初始化，请先传入或载入草稿");
    if (!self.postModel) {
        return nil; // 或根据业务需求处理未初始化的情况
    }
    
    // ===================== 基础信息（从UI读取） =====================
    self.postModel.post_title = self.titleTextField.text ?: @""; // 帖子标题（兜底空字符串）
    self.postModel.post_content = self.contentTextView.text ?: @""; // 帖子正文
    self.postModel.category_id = self.postMainTypeSegment.selectedSegmentIndex; // 主类型ID
    self.postModel.topic_ids = self.postModel.topic_ids ?: @[@0,@1,@2,@3]; // 副类型ID数组（已通过按钮点击更新）

    // ===================== 视频信息（优先遍历，仅保留1个有效视频） =====================
    BOOL videoExists = NO;
    // 遍历mediaItems，找未删除的视频（本地/远程，且仅保留最后一个有效视频）
    for (MediaItem *item in self.mediaItems) {
        NSLog(@"遍历上传附件:%@",item.fileName);
        if (!item.isDeleted && (item.type == MediaTypeLocalVideo || item.type == MediaTypeRemoteVideo)) {
            videoExists = YES;
            break; // 确保仅一个视频（业务规则）
        }
    }
    
    // ===================== 图片信息（视频处理后遍历，限制数量） =====================
    NSMutableArray<NSString *> *validImageURLs = [NSMutableArray array]; // 有效图片URL/base64数组
    NSMutableArray<NSString *> *validImageThumbURLs = [NSMutableArray array]; // 缩略图数组
    
    // 图片最大数量：有视频则8张，无视频则9张
    NSInteger maxImageCount = videoExists ? 8 : 9;
    
    // 遍历mediaItems，过滤未删除的图片（本地/远程）
    for (MediaItem *item in self.mediaItems) {
        NSLog(@"遍历mediaItems，过滤未删除的图片（本地/远程）:%@",item.fileName);
        // 未删除、并且云端图片
        if (!item.isDeleted && item.type == MediaTypeRemoteImage && item.fileName) {
            [validImageURLs addObject:item.fileName];
        }
        
        // 达到最大数量则停止
        if (validImageURLs.count >= maxImageCount) {
            break;
        }
    }
    // 赋值给postModel（转为不可变数组）
    self.postModel.post_images = [validImageURLs copy]; // 原图URL/base64数组
    self.postModel.post_images_thumb = [validImageThumbURLs copy]; // 缩略图数组
    self.postModel.mediaItems = self.mediaItems;//媒体附件

    // ===================== 音频信息（示例：当前代码未处理音频，可参考图片/视频逻辑） =====================
    self.postModel.post_audio_urls = @[]; // 暂无音频，兜底空数组
    self.postModel.post_audio_durations = @[];
    self.postModel.post_audio_sizes = @[];

    // ===================== 地理位置（从定位逻辑读取） =====================
    self.postModel.post_location = self.locationLabel.currentTitle ?: @""; // 位置名称（从按钮标题读取）
    if (self.currentLocation) {
        // 经纬度格式："纬度,经度"
        self.postModel.post_latlng = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
    } else {
        self.postModel.post_latlng = @"";
    }

    // ===================== 权限/状态信息 =====================
    self.postModel.post_visibility = self.visibilitySegment.selectedSegmentIndex; // 可见范围（0-公开 1-仅粉丝 2-仅自己）
    self.postModel.post_is_comment_forbidden = self.commentForbiddenSwitch.isOn; // 禁止评论
    self.postModel.post_is_share_forbidden = self.shareForbiddenSwitch.isOn; // 禁止分享
    self.postModel.post_update_time = [[NSDate date] timeIntervalSince1970]; // 更新时间戳
    
    // ===================== 附件信息（文件/URL） =====================
    NSMutableArray *validAttachments = [NSMutableArray array];
    for (PostAttachmentModel *attach in self.selectedAttachments) {
        // 转为字典存入postModel（适配接口传输）
        [validAttachments addObject:[attach yy_modelToJSONObject]];
    }
    self.postModel.post_attachments = [validAttachments copy];

    // ===================== 发布状态（新增/更新区分） =====================
    if (self.postModel.post_id == 0) {
        self.postModel.post_status = 1; // 新增：待上传附件
        self.postModel.post_create_time = self.postModel.post_update_time; // 创建时间=更新时间
    } else {
        self.postModel.post_status = 1; // 更新：暂存待提交
    }

    return self.postModel;
}


#pragma mark - 其他Action操作
// 选择图片
- (void)selectImage {
    if (!([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized)) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentImagePicker];
                });
            } else {
                [self showHUDWithTitle:@"请授予相册访问权限" duration:2.0];
            }
        }];
        return;
    }
    [self presentImagePicker];
}

- (void)presentImagePicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

// 新增：删除图片
- (void)deleteImageAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.selectedImages.count) {
        [self.selectedImages removeObjectAtIndex:index];
        [self.imageCollectionView reloadData];
    }
}

// 选择视频
- (void)selectVideo {
    if (!([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized)) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentVideoPicker];
                });
            } else {
                [self showHUDWithTitle:@"请授予相册访问权限" duration:2.0];
            }
        }];
        return;
    }
    [self presentVideoPicker];
}

// 弹出照片选择器
- (void)presentVideoPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

// 新增：附件类型切换
- (void)attachmentTypeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) { // 本地文件
        self.addFileBtn.hidden = NO;
        
        self.addURLBtn.hidden = YES;
    } else { // URL
        self.addFileBtn.hidden = YES;
        
        self.addURLBtn.hidden = NO;
    }
}

// 新增：选择本地文件
- (void)selectLocalFile {
    if (@available(iOS 14.0, *)) {
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypeItem] inMode:UIDocumentPickerModeImport];
        picker.delegate = self;
        picker.allowsMultipleSelection = YES; // 支持多选
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypeItem] inMode:UIDocumentPickerModeImport];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

// 新增：添加URL附件
- (void)addURLAttachment {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"输入URL地址" message:@"http或者https地址" preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"输入http附件地址";
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
        NSString *urlStr = textField.text;
        if (urlStr.length == 0) {
            [self showHUDWithTitle:@"请输入有效的文件URL" duration:2.0];
            return;
        }
        
        // 验证URL格式
        NSURL *url = [NSURL URLWithString:urlStr];
        if (!url || !url.scheme || !url.host) {
            [self showHUDWithTitle:@"URL格式不正确" duration:2.0];
            return;
        }
        
        // 创建附件模型
        PostAttachmentModel *attachment = [[PostAttachmentModel alloc] init];
        attachment.attachment_id = arc4random()%10000;
        attachment.attachment_name = [urlStr lastPathComponent];
        attachment.attachment_url = urlStr;
        attachment.attachment_type = [self getFileTypeFromURL:urlStr];
        attachment.attachment_size = 0; // URL附件无本地大小
        attachment.attachment_source_type = 1; // 1:URL 0:本地文件
        attachment.upload_status = 1; // URL无需上传
        
        [self.selectedAttachments addObject:attachment];
        [self.attachmentTableView reloadData];
        
        [self showHUDWithTitle:@"添加成功" duration:1.0];
        
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [[self.view getTopViewController] presentViewController:alertController animated:YES completion:nil];
    
}

// 新增：获取文件类型
- (NSString *)getFileTypeFromURL:(NSString *)urlStr {
    NSString *ext = [urlStr pathExtension].lowercaseString;
    if (ext.length == 0) return @"unknown";
    return ext;
}

// 新增：删除附件
- (void)deleteAttachmentAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.selectedAttachments.count) {
        [self.selectedAttachments removeObjectAtIndex:index];
        [self.attachmentTableView reloadData];
    }
}

// 获取当前位置（带完整提示逻辑）
- (void)getCurrentLocation {
    // 1. 先判断定位权限状态，分场景处理
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // 场景1：权限未授权/已拒绝
    if (status == kCLAuthorizationStatusNotDetermined) {
        // 先弹业务提示，说明定位用途（提升用户授权意愿）
        [self showHUDWithTitle:@"需要获取位置权限来标记帖子位置" duration:2.0];
        // 请求权限（系统会自动弹权限弹窗）
        [self.locationManager requestWhenInUseAuthorization];
        return;
    } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        // 权限被拒绝/受限，提示用户去设置开启
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"位置权限已关闭"
                                                                       message:@"需要开启位置权限才能获取当前位置，是否前往设置？"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 跳转到App设置页
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
                [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
            }
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 场景2：权限已授权，开始定位（增强过程提示）
    [self showHUDWithTitle:@"正在获取位置..." duration:0]; // 显示加载HUD（直到定位完成/失败）
    [self.locationLabel setTitle:@"正在获取位置..." forState:UIControlStateNormal];
    // 设置定位超时（避免无限等待）
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationTimeOut) object:nil];
    [self performSelector:@selector(locationTimeOut) withObject:nil afterDelay:10.0]; // 10秒超时
    // 开始定位
    [self.locationManager startUpdatingLocation];
}

// 新增：定位超时处理
- (void)locationTimeOut {
    [self.locationManager stopUpdatingLocation];
    [self hideHUD];
    [self showHUDWithTitle:@"定位超时，请稍后重试" duration:2.0];
    
    [self.locationLabel setTitle:@"定位超时-点击重新获取" forState:UIControlStateNormal];
}


// 权限变化
- (void)visibilityChanged:(UISegmentedControl *)sender {
    self.postModel.post_visibility = sender.selectedSegmentIndex;
}

- (void)commentForbiddenChanged:(UISwitch *)sender {
    self.postModel.post_is_comment_forbidden = sender.isOn;
}

- (void)shareForbiddenChanged:(UISwitch *)sender {
    self.postModel.post_is_share_forbidden = sender.isOn;
}

#pragma mark - 定位相关
- (void)requestLocationPermission {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

// 重写定位成功/失败的回调，补充提示
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationTimeOut) object:nil]; // 取消超时
    [self hideHUD]; // 隐藏加载HUD
    
    self.currentLocation = locations.lastObject;
    [manager stopUpdatingLocation];
    
    // 逆地理编码
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (!error && placemarks.count > 0) {
            CLPlacemark *placemark = placemarks.firstObject;
            NSString *locationStr = [NSString stringWithFormat:@"%@%@", placemark.locality ?: @"", placemark.thoroughfare ?: @""];
            self.locationLabel.titleLabel.text = locationStr;
            [self.locationLabel setTitle:locationStr forState:UIControlStateNormal];
            [self showHUDWithTitle:[NSString stringWithFormat:@"定位成功：%@", locationStr] duration:1.5]; // 成功提示
        } else {
            NSString *locationStr = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
            self.locationLabel.titleLabel.text = locationStr;
            self.selectedLocationName = locationStr;
            [self.locationLabel setTitle:locationStr forState:UIControlStateNormal];
            [self showHUDWithTitle:[NSString stringWithFormat:@"定位成功（仅坐标）：%@", locationStr] duration:1.5];
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationTimeOut) object:nil]; // 取消超时
    [self hideHUD]; // 隐藏加载HUD
    
    NSString *errorMsg = @"获取位置失败";
    if (error.code == kCLErrorDenied) {
        errorMsg = @"位置权限被拒绝";
    } else if (error.code == kCLErrorLocationUnknown) {
        errorMsg = @"暂时无法获取位置，请稍后重试";
    }
    
    [self.locationLabel setTitle:errorMsg forState:UIControlStateNormal];
    [self showHUDWithTitle:errorMsg duration:2.0]; // 失败提示
    NSLog(@"定位失败：%@", error);
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    
    // 1. 获取媒体类型（区分图片/视频）
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    // 2. 提取 PHAsset（iOS 11+ 支持，仅相册选择的资源有值，相机拍摄的为 nil）
    PHAsset *asset = info[UIImagePickerControllerPHAsset];
    
    // ========== 处理图片 ==========
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        // 获取原始图片（避免压缩）
        UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
        if (!originalImage) return;
        
        // 调用改造后的方法，传入图片 + PHAsset（相机拍摄则asset为nil）
        [self addNewImage:originalImage asset:asset];
        
    // ========== 处理视频 ==========
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        // 获取视频本地URL（仅临时路径，相机拍摄的视频保存在沙盒，相册选择的视频为系统路径）
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        if (!videoURL) return;
        
        // 调用改造后的方法，传入视频URL + PHAsset（相机拍摄则asset为nil）
        [self addNewVideo:videoURL asset:asset];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        // 获取文件信息
        NSError *error;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
        long long fileSize = attrs.fileSize;
        NSString *fileName = url.lastPathComponent;
        NSString *fileType = [fileName pathExtension].lowercaseString;
        
        // 创建附件模型
        PostAttachmentModel *attachment = [[PostAttachmentModel alloc] init];
        attachment.attachment_id = arc4random()%10000;
        attachment.attachment_name = fileName;
        attachment.attachment_url = url.path; // 本地路径
        attachment.attachment_size = fileSize;
        attachment.attachment_type = fileType.length > 0 ? fileType : @"unknown";
        attachment.attachment_source_type = 0; // 0:本地文件 1:URL
        attachment.upload_status = 0; // 待上传
        
        [self.selectedAttachments addObject:attachment];
    }
    
    [self.attachmentTableView reloadData];
    [self showHUDWithTitle:[NSString stringWithFormat:@"成功添加%lu个文件", (unsigned long)urls.count] duration:1.0];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSLog(@"文件选择已取消");
}

#pragma mark - UITextView占位符扩展
- (void)setupTextViewPlaceholder {
    // 给UITextView添加占位符
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.text = @"分享你的想法...";
    placeholderLabel.font = _contentTextView.font;
    placeholderLabel.textColor = [UIColor post_text_secondary_color];
    placeholderLabel.numberOfLines = 0;
    placeholderLabel.tag = 1001;
    [_contentTextView addSubview:placeholderLabel];
    
    [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentTextView).offset(8);
        make.left.equalTo(_contentTextView).offset(8);
        make.right.equalTo(_contentTextView).offset(-8);
    }];
    
    // 监听文本变化
    [_contentTextView addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"text"] && object == _contentTextView) {
        UILabel *placeholderLabel = [_contentTextView viewWithTag:1001];
        placeholderLabel.hidden = _contentTextView.text.length > 0;
    }
}
- (void)textViewDidChange:(UITextView *)textView {
    UILabel *placeholderLabel = [_contentTextView viewWithTag:1001];
    placeholderLabel.hidden = textView.text.length > 0;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    UILabel *placeholderLabel = [_contentTextView viewWithTag:1001];
    placeholderLabel.hidden = textView.text.length > 0;
    return YES;
}

#pragma mark - 工具方法（HUD）
- (void)showHUDWithTitle:(NSString *)title {
    [self showHUDWithTitle:title duration:0];
}

- (void)showHUDWithTitle:(NSString *)title duration:(NSTimeInterval)duration {
    UIView *hudView = [[UIView alloc] init];
    hudView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    hudView.layer.cornerRadius = 8;
    hudView.tag = 9999;
    [self.view addSubview:hudView];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14];
    [hudView addSubview:label];
    
    [hudView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.greaterThanOrEqualTo(@80);
        make.height.greaterThanOrEqualTo(@40);
    }];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(hudView);
        make.left.right.equalTo(hudView).inset(16);
        make.top.bottom.equalTo(hudView).inset(8);
    }];
    
    if (duration > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideHUD];
        });
    }
}

- (void)hideHUD {
    UIView *hudView = [self.view viewWithTag:9999];
    [hudView removeFromSuperview];
}

#pragma mark - 内存管理
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_contentTextView removeObserver:self forKeyPath:@"text"];
}

#pragma mark - UICollectionViewDataSource/Delegate（图片选择）
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // 统计未删除的图片数量 + 1个添加按钮
    NSInteger validImageCount = 0;
    for (MediaItem *item in self.mediaItems) {
        if (!item.isDeleted && (item.type == MediaTypeLocalImage || item.type == MediaTypeRemoteImage)) {
            validImageCount++;
        }
    }
    return MIN(validImageCount + 1, 9); // 最多9张图
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageSelectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageSelectCell" forIndexPath:indexPath];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.imageView.clipsToBounds = YES;
    
    // 查找当前索引对应的未删除图片
    NSInteger mediaCount = 0;
    MediaItem *targetItem = nil;
    for (MediaItem *item in self.mediaItems) {
        if (!item.isDeleted && (item.type == MediaTypeLocalImage || item.type == MediaTypeRemoteImage)) {
            if (mediaCount == indexPath.item) {
                targetItem = item;
                break;
            }
            mediaCount++;
        }
    }
    
    if (targetItem) {
        // 显示图片和删除按钮
        cell.deleteButton.hidden = NO;
        cell.deleteButton.tag = indexPath.item;
        [cell.deleteButton addTarget:self action:@selector(deleteImage:) forControlEvents:UIControlEventTouchUpInside];
        
        if (targetItem.type == MediaTypeRemoteImage) {
            // 远程图片用SDWebImage加载
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:targetItem.remoteUrl]
                                  placeholderImage:[UIImage imageNamed:@"image_placeholder"]];
        } else {
            // 本地图片直接加载
            cell.imageView.image = [UIImage imageWithContentsOfFile:targetItem.localPath];
        }
    } else {
        // 添加按钮
        cell.imageView.image = [UIImage systemImageNamed:@"plus.app"];
        cell.deleteButton.hidden = YES;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 点击添加按钮时打开相册
    NSInteger validImageCount = 0;
    for (MediaItem *item in self.mediaItems) {
        if (!item.isDeleted && (item.type == MediaTypeLocalImage || item.type == MediaTypeRemoteImage)) {
            validImageCount++;
        }
    }
    if (indexPath.item == validImageCount) { // 最后一个是添加按钮
        [self selectImage];
    }
}

// 添加新图片处理（新增 PHAsset 参数，nullable 兼容无相册资源的场景，如拍照）
- (void)addNewImage:(UIImage *)image asset:(PHAsset * _Nullable)asset {
    // 保存图片到临时路径
    NSString *tempPath = [self saveImageToTempPath:image];
    if (!tempPath) return;
    // 步骤1：取完整文件名
    NSString *fileNameWithExt = [tempPath lastPathComponent];
   
    
    // 创建本地图片媒体项
    MediaItem *item = [[MediaItem alloc] init];
    item.type = MediaTypeLocalImage;
    item.localPath = tempPath;
    item.isDeleted = NO;
    item.fileData = [NSData dataWithContentsOfFile:tempPath];
    // 核心：赋值 PHAsset（相册选的图片传asset，拍照/本地生成传nil）
    item.asset = asset;
    item.fileName = fileNameWithExt;
    item.fileType = [self mimeTypeForFileAtPath:tempPath];
    [self.mediaItems addObject:item];
    NSLog(@"添加图片后 当前附件数量：%ld",self.mediaItems.count);
    // 刷新UI
    [self.imageCollectionView reloadData];
}

// 添加新视频（仅操作mediaItems，新增 PHAsset 参数）
- (void)addNewVideo:(NSURL *)videoUrl asset:(PHAsset * _Nullable)asset {
    // 先标记现有视频为删除（确保只能有一个视频）
    for (MediaItem *item in self.mediaItems) {
        if (item.type == MediaTypeLocalVideo || item.type == MediaTypeRemoteVideo) {
            item.isDeleted = YES;
        }
    }
    
    // 获取视频信息
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:videoUrl];
    NSTimeInterval duration = CMTimeGetSeconds(urlAsset.duration);
    
    // 步骤1：取完整文件名
    NSString *fileNameWithExt = [videoUrl.path lastPathComponent];
   
    // 创建本地视频媒体项
    MediaItem *item = [[MediaItem alloc] init];
    item.type = MediaTypeLocalVideo;
    item.localPath = videoUrl.path;
    item.duration = duration;
    item.isDeleted = NO;
    item.fileData = [NSData dataWithContentsOfFile:videoUrl.path];
    // 核心：赋值 PHAsset（相册选的视频传asset，录制/本地视频传nil）
    item.asset = asset;
    item.fileName = fileNameWithExt;
    item.fileType = [self mimeTypeForFileAtPath:videoUrl.path];
    [self.mediaItems addObject:item];
    NSLog(@"添加视频后 当前附件数量：%ld",self.mediaItems.count);
    // 刷新视频UI
    [self updateVideoPreview];
    
    //数据模型属性
    self.postModel.post_video_thumb_url = @"";
    self.postModel.post_video_duration = duration;
    NSError *error;
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:item.localPath error:&error];
    self.postModel.post_video_size = error ? 0 : [fileAttrs[NSFileSize] longLongValue];
    
    
    if (item.type == MediaTypeLocalVideo && item.localPath.length > 0) {

        self.postModel.post_video_url = item.localPath;
    } else {
        // 远程视频保留URL
        self.postModel.post_video_url = item.remoteUrl;
    }
}

// 删除图片（仅标记isDeleted，不实际移除）
- (void)deleteImage:(UIButton *)sender {
    NSInteger index = sender.tag;
    NSInteger mediaCount = 0;
    MediaItem *targetItem = nil;
    
    // 找到对应索引的未删除图片
    for (MediaItem *item in self.mediaItems) {
        if (!item.isDeleted && (item.type == MediaTypeLocalImage || item.type == MediaTypeRemoteImage)) {
            if (mediaCount == index) {
                targetItem = item;
                break;
            }
            mediaCount++;
        }
    }
    
    if (targetItem) {
        targetItem.isDeleted = YES; // 仅标记删除
        [self.imageCollectionView reloadData]; // 刷新UI
    }
}


// 删除视频（仅标记isDeleted）
- (void)deleteVideo {
    for (MediaItem *item in self.mediaItems) {
        if (item.type == MediaTypeLocalVideo || item.type == MediaTypeRemoteVideo) {
            item.isDeleted = YES;
            break;
        }
    }
    //删除页面属性
    self.selectedVideoURL = nil;
    self.videoThumbImageView.image = nil;
    self.videoDurationLabel.hidden = YES;
    self.deleteVideoBtn.hidden = YES;
    [self updateVideoPreview]; // 刷新UI
    
    
    //删除数据模型属性
    self.postModel.post_video_url = @"";
    self.postModel.post_video_thumb_url = @"";
    self.postModel.post_video_duration = 0;
    self.postModel.post_video_size = 0;
}

// 新增：图片删除按钮点击
- (void)deleteImageBtnClicked:(UIButton *)sender {
    NSInteger index = sender.tag - 300;
    [self deleteImageAtIndex:index];
}

// 补充：MIME类型判断
- (NSString *)mimeTypeForFileAtPath:(NSString *)path {
    NSString *extension = [path pathExtension].lowercaseString;
    if ([extension isEqualToString:@"png"]) return @"image/png";
    if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) return @"image/jpeg";
    if ([extension isEqualToString:@"mov"]) return @"video/mov";
    if ([extension isEqualToString:@"mp4"]) return @"video/mp4";
    return @"application/octet-stream";
}


#pragma mark - UITableViewDataSource/Delegate（附件列表）
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.selectedAttachments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor post_secondary_bg_color];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 移除旧视图
    for (UIView *subview in cell.contentView.subviews) {
        if (subview.tag >= 400) {
            [subview removeFromSuperview];
        }
    }
    
    PostAttachmentModel *attachment = self.selectedAttachments[indexPath.item];
    cell.textLabel.text = attachment.attachment_name;
    cell.textLabel.textColor = [UIColor post_text_primary_color];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    
    // 附件信息
    NSString *subTitle = @"";
    if (attachment.attachment_source_type == 0) { // 本地文件
        NSString *sizeStr = [self formatFileSize:attachment.attachment_size];
        subTitle = [NSString stringWithFormat:@"%@ | %ld | 本地文件", sizeStr, attachment.attachment_type];
    } else { // URL
        subTitle = [NSString stringWithFormat:@"%ld | 网络文件", attachment.attachment_type];
    }
    cell.detailTextLabel.text = subTitle;
    cell.detailTextLabel.textColor = [UIColor post_text_secondary_color];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    
    // 新增：删除按钮
    UIButton *deleteBtn = [[UIButton alloc] init];
    [deleteBtn setImage:[UIImage systemImageNamed:@"trash.fill"] forState:UIControlStateNormal];
    deleteBtn.tintColor = [UIColor post_danger_color];
    deleteBtn.tag = 400 + indexPath.item;
    [deleteBtn addTarget:self action:@selector(deleteAttachmentBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:deleteBtn];
    
    [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cell.contentView);
        make.right.equalTo(cell.contentView).offset(-16);
        make.width.height.equalTo(@24);
    }];
    
    return cell;
}

// 新增：附件删除按钮点击
- (void)deleteAttachmentBtnClicked:(UIButton *)sender {
    NSInteger index = sender.tag - 400;
    [self deleteAttachmentAtIndex:index];
}

- (NSString *)formatFileSize:(long long)size {
    if (size < 1024) {
        return [NSString stringWithFormat:@"%lld B", size];
    } else if (size < 1024*1024) {
        return [NSString stringWithFormat:@"%.1f KB", size/1024.0];
    } else if (size < 1024*1024*1024) {
        return [NSString stringWithFormat:@"%.1f MB", size/(1024.0*1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.1f GB", size/(1024.0*1024.0*1024.0)];
    }
}

@end
