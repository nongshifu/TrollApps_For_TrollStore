//
//  AppPublishEditViewController.m
//  TrollApps
//
//  发布/编辑页面基类 - 同一页面支持发布和编辑两种属性
//

#import "AppPublishEditViewController.h"
#import "NewProfileViewController.h"
#import "config.h"
#import "NetworkClient.h"
#import "MediaManager.h"
#import "AppSearchViewController.h"
#import "ImageGridSearchViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <AVKit/AVKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "TokenGenerator.h"
#import "loadData.h"


#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用
static CGFloat const kSectionHeaderHeight = 44.0;
static CGFloat const kCellHeight = 50.0;
static CGFloat const kMediaCellWidth = 100.0;
static CGFloat const kIconSize = 80.0;
static NSInteger const kMaximumMediaCount = 12;

@interface MediaCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *videoIconView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *durationLabel;
- (void)configureWithMediaItem:(MediaItemModel *)item isEditing:(BOOL)isEditing;
@end

@implementation MediaCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.layer.cornerRadius = 8;
    self.contentView.clipsToBounds = YES;
    self.contentView.backgroundColor = [UIColor systemGray6Color];
    
    _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:_imageView];
    
    _videoIconView = [[UIImageView alloc] init];
    _videoIconView.image = [UIImage systemImageNamed:@"play.circle.fill"];
    _videoIconView.tintColor = [UIColor whiteColor];
    _videoIconView.frame = CGRectMake(0, 0, 30, 30);
    _videoIconView.center = CGPointMake(self.contentView.bounds.size.width / 2, self.contentView.bounds.size.height / 2);
    _videoIconView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _videoIconView.hidden = YES;
    [self.contentView addSubview:_videoIconView];
    
    _durationLabel = [[UILabel alloc] init];
    _durationLabel.font = [UIFont systemFontOfSize:10];
    _durationLabel.textColor = [UIColor whiteColor];
    _durationLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    _durationLabel.textAlignment = NSTextAlignmentCenter;
    _durationLabel.layer.cornerRadius = 4;
    _durationLabel.clipsToBounds = YES;
    _durationLabel.hidden = YES;
    [self.contentView addSubview:_durationLabel];
    
    _deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _deleteButton.frame = CGRectMake(self.contentView.bounds.size.width - 34, 0, 34, 34);
    _deleteButton.backgroundColor = [UIColor redColor];
    _deleteButton.layer.cornerRadius = 17;
    _deleteButton.tintColor = [UIColor whiteColor];
    [_deleteButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    _deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _deleteButton.hidden = YES;
    [self.contentView addSubview:_deleteButton];
    
    _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _loadingIndicator.center = CGPointMake(self.contentView.bounds.size.width / 2, self.contentView.bounds.size.height / 2);
    _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _loadingIndicator.hidesWhenStopped = YES;
    [self.contentView addSubview:_loadingIndicator];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _durationLabel.frame = CGRectMake(self.contentView.bounds.size.width - 50, self.contentView.bounds.size.height - 20, 46, 16);
}

- (void)configureWithMediaItem:(MediaItemModel *)item isEditing:(BOOL)isEditing {
    _deleteButton.hidden = !isEditing;
    _videoIconView.hidden = YES;
    _durationLabel.hidden = YES;
    [_loadingIndicator stopAnimating];
    
    // 处理待删除的视觉效果
    if (item.pendingDelete) {
        self.contentView.alpha = 0.4;
    } else {
        self.contentView.alpha = 1.0;
    }
    
    if (item.source == MediaSourceNew) {
        if (item.mediaType == MediaItemTypeImage) {
            _imageView.image = item.localImage;
        } else if (item.mediaType == MediaItemTypeVideo) {
            _imageView.image = item.thumbnailImage;
            _videoIconView.hidden = NO;
            _durationLabel.hidden = NO;
            NSInteger duration = (NSInteger)item.videoDuration;
            _durationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)(duration / 60), (long)(duration % 60)];
        }
        if (item.isUploading) {
            [_loadingIndicator startAnimating];
            _deleteButton.hidden = YES;
        }
    } else {
        NSString *urlToLoad = item.isVideo ? (item.thumbnailURL ?: item.fileURL) : item.fileURL;
        if (urlToLoad) {
            if ([urlToLoad hasPrefix:@"http"]) {
                [_imageView sd_setImageWithURL:[NSURL URLWithString:urlToLoad] placeholderImage:[UIImage systemImageNamed:@"photo"]];
            } else {
                _imageView.image = [UIImage imageNamed:urlToLoad];
            }
        } else {
            _imageView.image = [UIImage systemImageNamed:@"photo"];
        }
        if (item.isVideo) {
            _videoIconView.hidden = NO;
            _durationLabel.hidden = NO;
        }
    }
}

@end

@interface IconCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIView *addOverlayView;
- (void)configureWithImage:(UIImage *)image isEmpty:(BOOL)isEmpty;
@end

@implementation IconCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.layer.cornerRadius = 16;
    self.contentView.clipsToBounds = YES;
    self.contentView.layer.borderWidth = 2;
    self.contentView.layer.borderColor = [UIColor systemGray4Color].CGColor;
    self.contentView.backgroundColor = [UIColor systemGray6Color];
    
    _iconImageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    _iconImageView.clipsToBounds = YES;
    _iconImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:_iconImageView];
    
    _addOverlayView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    _addOverlayView.backgroundColor = [[UIColor systemGrayColor] colorWithAlphaComponent:0.3];
    _addOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIImageView *plusIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"plus"]];
    plusIcon.tintColor = [UIColor systemGrayColor];
    plusIcon.frame = CGRectMake(0, 0, 30, 30);
    plusIcon.center = CGPointMake(_addOverlayView.bounds.size.width / 2, _addOverlayView.bounds.size.height / 2);
    plusIcon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_addOverlayView addSubview:plusIcon];
    [self.contentView addSubview:_addOverlayView];
}

- (void)configureWithImage:(UIImage *)image isEmpty:(BOOL)isEmpty {
    if (isEmpty || !image) {
        _iconImageView.image = nil;
        _addOverlayView.hidden = NO;
    } else {
        _iconImageView.image = image;
        _addOverlayView.hidden = YES;
    }
}

@end

@interface TagCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *tagLabel;
- (void)configureWithTag:(NSString *)tag isSelected:(BOOL)isSelected;
@end

@implementation TagCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.layer.cornerRadius = 15;
    self.contentView.layer.borderWidth = 1;
    self.contentView.clipsToBounds = YES;
    
    _tagLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
    _tagLabel.font = [UIFont systemFontOfSize:13];
    _tagLabel.textAlignment = NSTextAlignmentCenter;
    _tagLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:_tagLabel];
}

- (void)configureWithTag:(NSString *)tag isSelected:(BOOL)isSelected {
    _tagLabel.text = tag;
    if (isSelected) {
        self.contentView.backgroundColor = [UIColor systemBlueColor];
        self.contentView.layer.borderColor = [UIColor systemBlueColor].CGColor;
        _tagLabel.textColor = [UIColor whiteColor];
    } else {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentView.layer.borderColor = [UIColor systemGray4Color].CGColor;
        _tagLabel.textColor = [UIColor labelColor];
    }
}

@end

@interface SectionHeaderView : UITableViewHeaderFooterView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
@end

@implementation SectionHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _titleLabel.textColor = [UIColor labelColor];
    [self.contentView addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = [UIFont systemFontOfSize:12];
    _subtitleLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:_subtitleLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.frame = CGRectMake(16, 12, self.contentView.bounds.size.width - 32, 20);
    _subtitleLabel.frame = CGRectMake(16, 32, self.contentView.bounds.size.width - 32, 16);
}

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    _titleLabel.text = title;
    if (subtitle && subtitle.length > 0) {
        _subtitleLabel.text = subtitle;
        _subtitleLabel.hidden = NO;
    } else {
        _subtitleLabel.hidden = YES;
    }
}

@end

typedef NS_ENUM(NSInteger, ImageSourceType) {
    ImageSourceTypeIcon = 0,
    ImageSourceTypeMedia = 1,
    ImageSourceTypeMainFile = 2
};

@interface AppPublishEditViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, AppSearchViewControllerDelegate, ImageGridSearchViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextField *appNameField;
@property (nonatomic, strong) UITextField *bundleIdField;
@property (nonatomic, strong) UITextField *trackIdField;
@property (nonatomic, strong) UITextField *versionNameField;
@property (nonatomic, strong) UITextField *appRmbField;
@property (nonatomic, strong) UISegmentedControl *appTypeSegment;
@property (nonatomic, strong) UITextView *descriptionTextView;
@property (nonatomic, strong) UITextView *releaseNotesTextView;
@property (nonatomic, strong) UISwitch *statusSwitch;
@property (nonatomic, strong) UICollectionView *iconCollectionView;
@property (nonatomic, strong) UIImage *selectedIcon;
@property (nonatomic, strong) UICollectionView *mediaCollectionView;
@property (nonatomic, strong) NSMutableArray<MediaItemModel *> *mediaItems;
@property (nonatomic, strong) UICollectionView *tagsCollectionView;
@property (nonatomic, strong) NSArray<NSString *> *availableTags;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedTagsSet;
@property (nonatomic, strong) UISegmentedControl *mainFileModeSegment;
@property (nonatomic, strong) UITextField *mainFileURLField;
@property (nonatomic, strong) UIButton *selectFileButton;
@property (nonatomic, strong) UILabel *existingFileLabel;

@property (nonatomic, assign) ImageSourceType currentImageSourceType;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong, readwrite) AppPublishEditViewModel *viewModel;

@property (nonatomic, assign) UIEdgeInsets originalContentInset;
@property (nonatomic, assign) UIEdgeInsets originalScrollIndicatorInsets;
@property (nonatomic, weak) UIView *currentFirstResponder;
@property (nonatomic, assign) BOOL hasSuccessfullySubmitted;

// 应用类型相关
@property (nonatomic, strong) UICollectionView *appTypeCollectionView;
@property (nonatomic, strong) NSArray<NSDictionary *> *appTypes;

@end

// 应用类型 Cell
@interface AppTypeCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *titleLabel;
- (void)configureWithTitle:(NSString *)title isSelected:(BOOL)isSelected;
@end

@implementation AppTypeCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 8;
        self.contentView.layer.borderWidth = 1;
        self.contentView.clipsToBounds = YES;
        
        _titleLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:_titleLabel];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title isSelected:(BOOL)isSelected {
    _titleLabel.text = title;
    if (isSelected) {
        self.contentView.backgroundColor = [UIColor systemBlueColor];
        self.contentView.layer.borderColor = [UIColor systemBlueColor].CGColor;
        _titleLabel.textColor = [UIColor whiteColor];
    } else {
        self.contentView.backgroundColor = [UIColor systemGray6Color];
        self.contentView.layer.borderColor = [UIColor separatorColor].CGColor;
        _titleLabel.textColor = [UIColor labelColor];
    }
}

@end

// 标签 Cell（支持多选）
@interface MultiSelectTagCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *titleLabel;
- (void)configureWithTitle:(NSString *)title isSelected:(BOOL)isSelected;
@end

@implementation MultiSelectTagCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 16;
        self.contentView.layer.borderWidth = 1;
        self.contentView.clipsToBounds = YES;
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:13];
        _titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _titleLabel.backgroundColor = [UIColor clearColor];
        [_titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.contentView addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat horizontalPadding = 12.0;
    
    [_titleLabel sizeToFit];
    
    _titleLabel.frame = CGRectMake(horizontalPadding,
                                    (self.contentView.bounds.size.height - _titleLabel.bounds.size.height) / 2,
                                    _titleLabel.bounds.size.width,
                                    _titleLabel.bounds.size.height);
}

- (void)configureWithTitle:(NSString *)title isSelected:(BOOL)isSelected {
    _titleLabel.text = title;
    if (isSelected) {
        self.contentView.backgroundColor = [UIColor systemBlueColor];
        self.contentView.layer.borderColor = [UIColor systemBlueColor].CGColor;
        _titleLabel.textColor = [UIColor whiteColor];
    } else {
        self.contentView.backgroundColor = [UIColor systemGray6Color];
        self.contentView.layer.borderColor = [UIColor separatorColor].CGColor;
        _titleLabel.textColor = [UIColor labelColor];
    }
    
    // 立即更新布局
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end

@implementation AppPublishEditViewController

// 文件扩展名到类型的映射
static NSDictionary<NSString *, NSNumber *> *_fileExtensionToType = nil;
// 所有应用类型
static NSArray<NSDictionary *> *_allAppTypes = nil;

+ (void)initialize {
    if (self == [AppPublishEditViewController class]) {
        _fileExtensionToType = @{
            @"ipa": @(1),
            @"tipa": @(2),
            @"deb": @(3),
            @"js": @(4),
            @"html": @(5),
            @"json": @(6),
            @"sh": @(7),
            @"plist": @(8),
            @"dylib": @(9),
            @"zip": @(10),
            @"rar": @(10),
            @"7z": @(10),
            @"png": @(11),
            @"jpg": @(11),
            @"jpeg": @(11),
            @"gif": @(11),
            @"heic": @(11),
            @"webp": @(11),
            @"bmp": @(11),
            @"mp4": @(12),
            @"mov": @(12),
            @"avi": @(12),
            @"mkv": @(12),
            @"flv": @(12),
            @"m4v": @(12),
            @"other": @(13),
            @"file": @(14),
            @"folder": @(15)
        };
        
        _allAppTypes = @[
            @{@"type": @(1), @"title": @"IPA"},
            @{@"type": @(2), @"title": @"TIPA"},
            @{@"type": @(3), @"title": @"DEB"},
            @{@"type": @(4), @"title": @"JS"},
            @{@"type": @(5), @"title": @"HTML"},
            @{@"type": @(6), @"title": @"JSON"},
            @{@"type": @(7), @"title": @"SH"},
            @{@"type": @(8), @"title": @"PLIST"},
            @{@"type": @(9), @"title": @"DYLIB"},
            @{@"type": @(10), @"title": @"ZIP"},
            @{@"type": @(11), @"title": @"IMAGE"},
            @{@"type": @(12), @"title": @"VIDEO"},
            @{@"type": @(13), @"title": @"OTHER"},
            @{@"type": @(14), @"title": @"FILE"},
            @{@"type": @(15), @"title": @"FOLDER"}
        ];
    }
}

+ (instancetype)publishViewController {
    AppPublishEditViewModel *viewModel = [AppPublishEditViewModel sharedInstance];
    [viewModel resetAllData];
    viewModel.isEditMode = NO;
    AppPublishEditViewController *vc = [[AppPublishEditViewController alloc] init];
    vc.viewModel = viewModel;
    vc.mode = PublishEditModePublish;
    return vc;
}

+ (instancetype)editViewControllerWithAppId:(NSInteger)appId {
    AppPublishEditViewModel *viewModel = [AppPublishEditViewModel sharedInstance];
    [viewModel resetAllData];
    viewModel.isEditMode = YES;
    viewModel.editingAppId = @(appId);
    AppPublishEditViewController *vc = [[AppPublishEditViewController alloc] init];
    vc.viewModel = viewModel;
    vc.mode = PublishEditModeEdit;
    vc.editingAppId = @(appId);
    return vc;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mode = PublishEditModePublish;
        _editingAppId = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    self.isTapViewToHideKeyboard = YES;

    _mediaItems = [NSMutableArray array];
    _selectedTagsSet = [NSMutableSet set];
    _availableTags = @[];
    
    // 确保 viewModel 已经初始化
    if (!_viewModel) {
        _viewModel = [AppPublishEditViewModel sharedInstance];
    }
    
    [self setupUI];
    [self setupNavigationBar];
    [self loadTags];
    
    if (_viewModel.isEditMode && _viewModel.editingAppId) {
        [self loadExistingData];
    } else {
        [_viewModel setupForNewApp];
    }
    
    // 保存原始的 scrollView insets
    _originalContentInset = _scrollView.contentInset;
    _originalScrollIndicatorInsets = _scrollView.horizontalScrollIndicatorInsets;
    
    // 添加键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSValue *keyboardFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
    CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);
    
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    // 找到当前的第一响应者
    UIView *firstResponder = [self findFirstResponderInView:self.view];
    if (!firstResponder) return;
    
    _currentFirstResponder = firstResponder;
    
    // 设置 scrollView 的 contentInset 以留出键盘空间
    UIEdgeInsets contentInset = _originalContentInset;
    contentInset.bottom = keyboardHeight + 20;
    UIEdgeInsets scrollIndicatorInsets = _originalScrollIndicatorInsets;
    scrollIndicatorInsets.bottom = keyboardHeight;
    
    // 计算第一响应者在 scrollView 坐标系中的位置
    CGRect responderFrame = [firstResponder convertRect:firstResponder.bounds toView:_scrollView];
    
    // 计算 scrollView 的有效可见高度
    CGFloat visibleHeight = CGRectGetHeight(_scrollView.bounds) - contentInset.top - contentInset.bottom;
    
    // 计算需要滚动到的位置，确保输入框底部刚好在键盘上方可见
    CGFloat targetY = CGRectGetMaxY(responderFrame) - visibleHeight + contentInset.top;
    CGFloat newOffsetY = MAX(_scrollView.contentOffset.y, targetY);
    
    // 确保不超过最大可滚动范围
    CGFloat maxOffsetY = _scrollView.contentSize.height - CGRectGetHeight(_scrollView.bounds) + contentInset.bottom;
    newOffsetY = MIN(newOffsetY, maxOffsetY);
    newOffsetY = MAX(newOffsetY, 0);
    
    [UIView animateWithDuration:duration delay:0 options:curve << 16 animations:^{
        self.scrollView.contentInset = contentInset;
        self.scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, newOffsetY);
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:duration delay:0 options:curve << 16 animations:^{
        self.scrollView.contentInset = self.originalContentInset;
        self.scrollView.scrollIndicatorInsets = self.originalContentInset;
    } completion:nil];
    
    _currentFirstResponder = nil;
}

- (UIView *)findFirstResponderInView:(UIView *)view {
    if (view.isFirstResponder) {
        return view;
    }
    for (UIView *subview in view.subviews) {
        UIView *responder = [self findFirstResponderInView:subview];
        if (responder) {
            return responder;
        }
    }
    return nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_viewModel.hasUnsavedChanges && !_hasSuccessfullySubmitted) {
        [self saveViewModelData];
        [_viewModel saveDraft];
    }
}

- (void)setupNavigationBar {
    self.title = _viewModel.isEditMode ? @"编辑应用" : @"发布应用";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 编辑模式：取消按钮 + 草稿按钮
//    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelTapped)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(cancelTapped)];
    
    // 左侧第二个按钮：草稿操作
    UIBarButtonItem *draftButton = [[UIBarButtonItem alloc] initWithTitle:@"草稿" style:UIBarButtonItemStylePlain target:self action:@selector(draftButtonTapped)];
    draftButton.tintColor = [UIColor systemOrangeColor];
    
    
    self.navigationItem.leftBarButtonItems = @[cancelButton,draftButton];
    
    UIBarButtonItem *submitButton = [[UIBarButtonItem alloc] initWithTitle:_viewModel.isEditMode ? @"更新" : @"发布" style:UIBarButtonItemStyleDone target:self action:@selector(submitTapped)];
    
    self.navigationItem.rightBarButtonItems = @[submitButton];
}

- (void)draftButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"草稿操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"保存草稿" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveViewModelData];
        [self.viewModel saveDraft];
        
        [SVProgressHUD showSuccessWithStatus:@"草稿已保存"];
        [SVProgressHUD dismissWithDelay:1.5];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"加载草稿" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([self.viewModel loadDraft]) {
            [self populateUIWithViewModel];
            
            [SVProgressHUD showSuccessWithStatus:@"草稿已加载"];
            [SVProgressHUD dismissWithDelay:1.5];
        } else {
            [SVProgressHUD showErrorWithStatus:@"没有找到草稿"];
            [SVProgressHUD dismissWithDelay:1.5];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"清除草稿" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.viewModel clearDraft];
        
        [SVProgressHUD showSuccessWithStatus:@"草稿已清除"];
        [SVProgressHUD dismissWithDelay:1.5];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItems.lastObject;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)setupUI {
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:_scrollView];
    
    _contentView = [[UIView alloc] init];
    _contentView.frame = _scrollView.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_scrollView addSubview:_contentView];
    
    CGFloat yOffset = 16;
    yOffset = [self addSectionWithTitle:@"基本信息" yOffset:yOffset];
    yOffset = [self addFormRowWithLabel:@"应用名称 *" placeholder:@"请输入应用名称" fieldTag:1001 yOffset:yOffset];
    yOffset = [self addFormRowWithLabel:@"Bundle ID" placeholder:@"可选 如: com.example.myapp" fieldTag:1002 yOffset:yOffset];
    yOffset = [self addButtonRowWithTitle:@"从App Store搜索" action:@selector(searchAppStore) yOffset:yOffset];
    yOffset = [self addFormRowWithLabel:@"App Store ID" placeholder:@"可选" fieldTag:1003 yOffset:yOffset keyboardType:UIKeyboardTypeNumberPad];
    yOffset = [self addFormRowWithLabel:@"版本名称" placeholder:@"如: 1.0.0" fieldTag:1004 yOffset:yOffset];
    yOffset = [self addAppTypeRowWithYOffset:yOffset];
    yOffset = [self addFormRowWithLabel:@"下载积分" placeholder:@"0表示免费" fieldTag:1005 yOffset:yOffset keyboardType:UIKeyboardTypeNumberPad];
    yOffset = [self addSwitchRowWithLabel:@"应用状态" subtitle:@"关闭后不在列表显示" yOffset:yOffset];
    
    yOffset += 16;
    yOffset = [self addSectionWithTitle:@"应用图标 *" yOffset:yOffset];
    yOffset = [self addIconSectionWithYOffset:yOffset];
    
    yOffset += 16;
    yOffset = [self addSectionWithTitle:@"主程序文件" yOffset:yOffset];
    yOffset = [self addMainFileSectionWithYOffset:yOffset];
    
    yOffset += 16;
    yOffset = [self addSectionWithTitle:@"截图和视频" subtitle:[NSString stringWithFormat:@"最多%ld个文件", (long)kMaximumMediaCount] yOffset:yOffset];
    yOffset = [self addMediaSectionWithYOffset:yOffset];
    
    yOffset += 16;
    yOffset = [self addSectionWithTitle:@"应用介绍" yOffset:yOffset];
    yOffset = [self addTextViewRowWithLabel:@"应用简介" placeholder:@"详细描述应用功能、特色等..." yOffset:yOffset height:120];
    yOffset = [self addTextViewRowWithLabel:@"更新说明" placeholder:@"本次更新内容..." yOffset:yOffset height:80];
    
    yOffset += 16;
    yOffset = [self addSectionWithTitle:@"标签设置" yOffset:yOffset];
    yOffset = [self addTagsSectionWithYOffset:yOffset];
    
    yOffset += 100;
    _contentView.frame = CGRectMake(0, 0, self.view.bounds.size.width, yOffset);
    _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, yOffset);
    
}

- (CGFloat)addSectionWithTitle:(NSString *)title yOffset:(CGFloat)yOffset {
    return [self addSectionWithTitle:title subtitle:nil yOffset:yOffset];
}

- (CGFloat)addSectionWithTitle:(NSString *)title subtitle:(NSString *)subtitle yOffset:(CGFloat)yOffset {
    SectionHeaderView *header = [[SectionHeaderView alloc] initWithReuseIdentifier:@"header"];
    [header configureWithTitle:title subtitle:subtitle];
    header.frame = CGRectMake(0, yOffset, self.view.bounds.size.width, kSectionHeaderHeight);
    [_contentView addSubview:header];
    return yOffset + kSectionHeaderHeight;
}

- (CGFloat)addFormRowWithLabel:(NSString *)label placeholder:(NSString *)placeholder fieldTag:(NSInteger)tag yOffset:(CGFloat)yOffset {
    return [self addFormRowWithLabel:label placeholder:placeholder fieldTag:tag yOffset:yOffset keyboardType:UIKeyboardTypeDefault];
}

- (CGFloat)addFormRowWithLabel:(NSString *)label placeholder:(NSString *)placeholder fieldTag:(NSInteger)tag yOffset:(CGFloat)yOffset keyboardType:(UIKeyboardType)keyboardType {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, kCellHeight)];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:container];
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, kCellHeight)];
    labelView.text = label;
    labelView.font = [UIFont systemFontOfSize:14];
    labelView.textColor = [UIColor secondaryLabelColor];
    [container addSubview:labelView];
    
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(100, 0, container.bounds.size.width - 100, kCellHeight)];
    field.font = [UIFont systemFontOfSize:15];
    field.textAlignment = NSTextAlignmentRight;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.placeholder = placeholder;
    field.keyboardType = keyboardType;
    field.tag = tag;
    field.delegate = self;
    [container addSubview:field];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, kCellHeight - 0.5, container.bounds.size.width, 0.5)];
    separator.backgroundColor = [UIColor separatorColor];
    separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [container addSubview:separator];
    
    if (tag == 1001) _appNameField = field;
    else if (tag == 1002) _bundleIdField = field;
    else if (tag == 1003) _trackIdField = field;
    else if (tag == 1004) _versionNameField = field;
    else if (tag == 1005) _appRmbField = field;
    
    return yOffset + kCellHeight;
}

- (CGFloat)addButtonRowWithTitle:(NSString *)title action:(SEL)action yOffset:(CGFloat)yOffset {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, kCellHeight)];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:container];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = container.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [button setTitle:title forState:UIControlStateNormal];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:button];
    
    UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    arrow.tintColor = [UIColor tertiaryLabelColor];
    arrow.frame = CGRectMake(container.bounds.size.width - 20, (kCellHeight - 14) / 2, 8, 14);
    arrow.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [container addSubview:arrow];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, kCellHeight - 0.5, container.bounds.size.width, 0.5)];
    separator.backgroundColor = [UIColor separatorColor];
    separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [container addSubview:separator];
    
    return yOffset + kCellHeight;
}

- (CGFloat)addAppTypeRowWithYOffset:(CGFloat)yOffset {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, 70)];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:container];
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 100, 20)];
    labelView.text = @"应用类型";
    labelView.font = [UIFont systemFontOfSize:14];
    labelView.textColor = [UIColor secondaryLabelColor];
    [container addSubview:labelView];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(60, 32);
    layout.minimumInteritemSpacing = 8;
    
    _appTypeCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 30, container.bounds.size.width, 40) collectionViewLayout:layout];
    _appTypeCollectionView.backgroundColor = [UIColor clearColor];
    _appTypeCollectionView.dataSource = self;
    _appTypeCollectionView.delegate = self;
    _appTypeCollectionView.tag = 4;
    _appTypeCollectionView.showsHorizontalScrollIndicator = NO;
    [_appTypeCollectionView registerClass:[AppTypeCell class] forCellWithReuseIdentifier:@"AppTypeCell"];
    _appTypeCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [container addSubview:_appTypeCollectionView];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 69.5, container.bounds.size.width, 0.5)];
    separator.backgroundColor = [UIColor separatorColor];
    separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [container addSubview:separator];
    
    return yOffset + 70;
}

// 根据文件扩展名判断类型
- (NSInteger)detectAppTypeFromFileName:(NSString *)fileName {
    NSString *extension = fileName.pathExtension.lowercaseString;
    if (extension.length > 0) {
        NSNumber *typeNum = _fileExtensionToType[extension];
        if (typeNum) {
            return typeNum.integerValue;
        }
    }
    return 0;
}

// 更新应用类型选择
- (void)updateAppTypeSelection:(NSInteger)appType {
    _viewModel.appType = appType;
    [_appTypeCollectionView reloadData];
    // 滚动到选中项
    for (NSInteger i = 0; i < _allAppTypes.count; i++) {
        if ([_allAppTypes[i][@"type"] integerValue] == appType) {
            [_appTypeCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            break;
        }
    }
}

- (CGFloat)addSwitchRowWithLabel:(NSString *)label subtitle:(NSString *)subtitle yOffset:(CGFloat)yOffset {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, kCellHeight)];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:container];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 100, 20)];
    titleLabel.text = label;
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.textColor = [UIColor secondaryLabelColor];
    [container addSubview:titleLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 200, 16)];
    subtitleLabel.text = subtitle;
    subtitleLabel.font = [UIFont systemFontOfSize:11];
    subtitleLabel.textColor = [UIColor tertiaryLabelColor];
    [container addSubview:subtitleLabel];
    
    _statusSwitch = [[UISwitch alloc] init];
    _statusSwitch.center = CGPointMake(container.bounds.size.width - 30, kCellHeight / 2);
    _statusSwitch.on = YES;
    _statusSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [container addSubview:_statusSwitch];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, kCellHeight - 0.5, container.bounds.size.width, 0.5)];
    separator.backgroundColor = [UIColor separatorColor];
    separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [container addSubview:separator];
    
    return yOffset + kCellHeight;
}

- (CGFloat)addTextViewRowWithLabel:(NSString *)label placeholder:(NSString *)placeholder yOffset:(CGFloat)yOffset height:(CGFloat)height {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, height)];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:container];
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 24)];
    labelView.text = label;
    labelView.font = [UIFont systemFontOfSize:14];
    labelView.textColor = [UIColor secondaryLabelColor];
    [container addSubview:labelView];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 24, container.bounds.size.width, height - 24)];
    textView.font = [UIFont systemFontOfSize:14];
    textView.textContainerInset = UIEdgeInsetsMake(8, 4, 8, 4);
    textView.layer.borderWidth = 0.5;
    textView.layer.borderColor = [UIColor separatorColor].CGColor;
    textView.layer.cornerRadius = 8;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textView.delegate = self;
    [container addSubview:textView];
    
    if ([label isEqualToString:@"应用简介"]) _descriptionTextView = textView;
    else if ([label isEqualToString:@"更新说明"]) _releaseNotesTextView = textView;
    
    return yOffset + height;
}

- (CGFloat)addIconSectionWithYOffset:(CGFloat)yOffset {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(kIconSize, kIconSize);
    layout.minimumInteritemSpacing = 12;
    
    _iconCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, kIconSize) collectionViewLayout:layout];
    _iconCollectionView.backgroundColor = [UIColor clearColor];
    _iconCollectionView.dataSource = self;
    _iconCollectionView.delegate = self;
    _iconCollectionView.tag = 1;
    [_iconCollectionView registerClass:[IconCell class] forCellWithReuseIdentifier:@"IconCell"];
    _iconCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:_iconCollectionView];
    
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, yOffset + kIconSize + 8, self.view.bounds.size.width - 32, 20)];
    tipLabel.text = @"点击图标可从5种方式选择图片来源";
    tipLabel.font = [UIFont systemFontOfSize:12];
    tipLabel.textColor = [UIColor tertiaryLabelColor];
    tipLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:tipLabel];
    
    return yOffset + kIconSize + 30;
}

- (CGFloat)addMainFileSectionWithYOffset:(CGFloat)yOffset {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, 120)];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:container];
    
    // 添加模式切换 Segment
    _mainFileModeSegment = [[UISegmentedControl alloc] initWithItems:@[@"云端链接", @"本地文件"]];
    _mainFileModeSegment.frame = CGRectMake(0, 0, container.bounds.size.width, 32);
    _mainFileModeSegment.selectedSegmentIndex = _viewModel.isCloudMode ? 0 : 1;
    [_mainFileModeSegment addTarget:self action:@selector(mainFileModeChanged:) forControlEvents:UIControlEventValueChanged];
    [container addSubview:_mainFileModeSegment];
    
    // 云端模式 UI
    _mainFileURLField = [[UITextField alloc] initWithFrame:CGRectMake(0, 42, container.bounds.size.width, 40)];
    _mainFileURLField.placeholder = @"输入云端主文件URL地址";
    _mainFileURLField.font = [UIFont systemFontOfSize:14];
    _mainFileURLField.borderStyle = UITextBorderStyleRoundedRect;
    _mainFileURLField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _mainFileURLField.delegate = self;
    [container addSubview:_mainFileURLField];
    
    // 本地文件 UI
    _selectFileButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _selectFileButton.frame = CGRectMake(0, 42, container.bounds.size.width, 40);
    [_selectFileButton setTitle:@"从文件App选择主程序文件" forState:UIControlStateNormal];
    _selectFileButton.titleLabel.font = [UIFont systemFontOfSize:14];
    _selectFileButton.backgroundColor = [UIColor systemBlueColor];
    _selectFileButton.layer.cornerRadius = 8;
    _selectFileButton.tintColor = [UIColor whiteColor];
    _selectFileButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_selectFileButton addTarget:self action:@selector(selectMainFileFromFilesApp) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:_selectFileButton];
    
    // 编辑模式下显示已存在文件的标签
    _existingFileLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 88, container.bounds.size.width, 60)];
    _existingFileLabel.font = [UIFont systemFontOfSize:12];
    _existingFileLabel.textColor = [UIColor secondaryLabelColor];
    _existingFileLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _existingFileLabel.numberOfLines = 3;
    _existingFileLabel.hidden = YES;
    [container addSubview:_existingFileLabel];
    
    // 初始更新 UI 状态
    [self updateMainFileUI];
    
    return yOffset + 130;
}

- (void)mainFileModeChanged:(UISegmentedControl *)sender {
    NSInteger index = sender.selectedSegmentIndex;
    BOOL isCloudMode = (index == 0);
    
    _viewModel.isCloudMode = isCloudMode;
    
    if (isCloudMode) {
        // 切换到云端模式，清除本地文件数据
        _viewModel.mainFileData = nil;
        _viewModel.mainFileName = nil;
    }
    
    [self updateMainFileUI];
}

- (void)updateMainFileUI {
    BOOL isCloudMode = _viewModel.isCloudMode;
    BOOL isEditMode = _viewModel.isEditMode;
    
    // 更新 segment 选中状态
    _mainFileModeSegment.selectedSegmentIndex = isCloudMode ? 0 : 1;
    
    if (isCloudMode) {
        // 云端模式：显示输入框，隐藏选择按钮
        _mainFileURLField.hidden = NO;
        _selectFileButton.hidden = YES;
        
        if (isEditMode && _viewModel.mainFileCloudURL.length > 0) {
            // 编辑模式下显示已有文件信息
            _existingFileLabel.hidden = NO;
            _existingFileLabel.text = [NSString stringWithFormat:@"当前文件: %@", [_viewModel.mainFileCloudURL lastPathComponent]];
        } else {
            _existingFileLabel.hidden = YES;
        }
    } else {
        // 本地文件模式：隐藏输入框，显示选择按钮
        _mainFileURLField.hidden = YES;
        _selectFileButton.hidden = NO;
        
        if (_viewModel.mainFileName) {
            // 已经选择了本地文件，更新按钮标题
            [_selectFileButton setTitle:[NSString stringWithFormat:@"已选择: %@", _viewModel.mainFileName] forState:UIControlStateNormal];
            _existingFileLabel.hidden = YES;
        } else if (isEditMode && _viewModel.mainFileCloudURL.length > 0) {
            // 编辑模式下显示已有服务器文件信息
            _existingFileLabel.hidden = NO;
            _existingFileLabel.text = [NSString stringWithFormat:@"当前文件: %@ (如更换请点击上方按钮)", [_viewModel.mainFileCloudURL lastPathComponent]];
            [_selectFileButton setTitle:@"更换主程序文件" forState:UIControlStateNormal];
        } else {
            _existingFileLabel.hidden = YES;
            [_selectFileButton setTitle:@"从文件App选择主程序文件" forState:UIControlStateNormal];
        }
    }
}

- (CGFloat)addMediaSectionWithYOffset:(CGFloat)yOffset {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(kMediaCellWidth, kMediaCellWidth);
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    
    _mediaCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(16, yOffset + 8, self.view.bounds.size.width - 32, kMediaCellWidth) collectionViewLayout:layout];
    _mediaCollectionView.backgroundColor = [UIColor clearColor];
    _mediaCollectionView.dataSource = self;
    _mediaCollectionView.delegate = self;
    _mediaCollectionView.tag = 2;
    _mediaCollectionView.showsHorizontalScrollIndicator = NO;
    [_mediaCollectionView registerClass:[MediaCell class] forCellWithReuseIdentifier:@"MediaCell"];
    [_mediaCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AddMediaCell"];
    _mediaCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:_mediaCollectionView];
    
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, yOffset + kMediaCellWidth + 8 + 8, self.view.bounds.size.width - 32, 20)];
    tipLabel.text = @"点击+号可从5种方式添加截图或视频";
    tipLabel.font = [UIFont systemFontOfSize:12];
    tipLabel.textColor = [UIColor tertiaryLabelColor];
    tipLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_contentView addSubview:tipLabel];
    
    return yOffset + kMediaCellWidth + 30;
}

- (CGFloat)addTagsSectionWithYOffset:(CGFloat)yOffset {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    
    _tagsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(16, yOffset, self.view.bounds.size.width - 32, 40) collectionViewLayout:layout];
    _tagsCollectionView.backgroundColor = [UIColor clearColor];
    _tagsCollectionView.dataSource = self;
    _tagsCollectionView.delegate = self;
    _tagsCollectionView.tag = 3;
    _tagsCollectionView.showsHorizontalScrollIndicator = NO;
    [_tagsCollectionView registerClass:[MultiSelectTagCell class] forCellWithReuseIdentifier:@"MultiSelectTagCell"];
    _tagsCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // 设置 delegate 和 dataSource 后立即刷新
    [_contentView addSubview:_tagsCollectionView];
    
    return yOffset + 50;
}

- (void)loadTags {
    
    NSArray *tags = [loadData sharedInstance].tags;
    
    if (tags && tags.count > 3) {
        _availableTags = [tags subarrayWithRange:NSMakeRange(3, tags.count - 3)];
    } else {
        _availableTags = tags ?: @[];
    }
    
    [_tagsCollectionView reloadData];
    
    // 强制刷新标签 collection view 的布局
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tagsCollectionView.collectionViewLayout invalidateLayout];
        [self.tagsCollectionView layoutIfNeeded];
        [self.tagsCollectionView reloadData];
    });
}

- (void)loadExistingData {
    [SVProgressHUD showWithStatus:@"加载中..."];
    [_viewModel setupForEditWithAppId:self.viewModel.editingAppId.integerValue completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];;
            if (success) {
                [self populateUIWithViewModel];
            } else {
                
                [self showAlertWithConfirmationFromViewController:self title:@"提示" message:error.localizedDescription confirmTitle:@"确定" cancelTitle:nil onConfirmed:^{
                    [self dismiss];
                } onCancelled:^{
                    [self dismiss];
                }];
            }
        });
    }];
}

- (void)populateUIWithViewModel {
    _appNameField.text = _viewModel.appName;
    _bundleIdField.text = _viewModel.bundleId;
    _trackIdField.text = _viewModel.trackId;
    _versionNameField.text = _viewModel.versionName;
    _appRmbField.text = _viewModel.appRmb;
    _descriptionTextView.text = _viewModel.appDescription;
    _releaseNotesTextView.text = _viewModel.releaseNotes;
    _statusSwitch.on = (_viewModel.appStatus == 0);
    _mainFileURLField.text = _viewModel.mainFileCloudURL;
    
    // 下载并设置图标
    if (_viewModel.existingIconURL) {
        __weak typeof(self) weakSelf = self;
        [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:_viewModel.existingIconURL]
                                                    options:0
                                                   progress:nil
                                                  completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if (image) {
                weakSelf.selectedIcon = image;
                [weakSelf.iconCollectionView reloadData];
            }
        }];
    }
    
    // 加载媒体文件
    [_mediaItems removeAllObjects];
    [_mediaItems addObjectsFromArray:_viewModel.mediaItems];
    [_mediaCollectionView reloadData];
    
    // 加载标签
    [_selectedTagsSet removeAllObjects];
    [_selectedTagsSet addObjectsFromArray:_viewModel.selectedTags];
    [_tagsCollectionView reloadData];
    
    // 更新应用类型 UI
    [_appTypeCollectionView reloadData];
    // 滚动到选中项
    for (NSInteger i = 0; i < _allAppTypes.count; i++) {
        if ([_allAppTypes[i][@"type"] integerValue] == _viewModel.appType) {
            [_appTypeCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            break;
        }
    }
    
    // 更新主文件 UI
    [self updateMainFileUI];
}

- (void)cancelTapped {
    if (_viewModel.hasUnsavedChanges) {
       
        [self showAlertWithConfirmationFromViewController:self title:@"提示" message:@"有未保存的更改，是否保存草稿？" confirmTitle:@"保存" cancelTitle:@"取消" onConfirmed:^{
            [self->_viewModel clearDraft];
            [self dismiss];
        } onCancelled:^{
            [self saveViewModelData];
            [self->_viewModel saveDraft];
            [self dismiss];
        }];
    } else {
        [self dismiss];
    }
    
}

- (void)submitTapped {
    [self.view endEditing:YES];
    [self saveViewModelData];
    NSError *error = nil;
    if (![_viewModel validateDataWithError:&error]) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [SVProgressHUD dismissWithDelay:3];
        
        return;
    }
    [self publishApp];
}

- (void)saveViewModelData {
    _viewModel.appName = _appNameField.text ?: @"";
    _viewModel.bundleId = _bundleIdField.text ?: @"";
    _viewModel.trackId = _trackIdField.text ?: @"";
    _viewModel.versionName = _versionNameField.text ?: @"1.0.0";
    _viewModel.appRmb = _appRmbField.text ?: @"0";
    _viewModel.appDescription = _descriptionTextView.text ?: @"";
    _viewModel.releaseNotes = _releaseNotesTextView.text ?: @"";
    _viewModel.appStatus = _statusSwitch.on ? 0 : 5;
    _viewModel.mainFileCloudURL = _mainFileURLField.text;
    _viewModel.iconImage = _selectedIcon;
    _viewModel.selectedTags = [_selectedTagsSet allObjects].mutableCopy;
    [_viewModel.mediaItems removeAllObjects];
    [_viewModel.mediaItems addObjectsFromArray:_mediaItems];
}

- (void)publishApp {
    if(_viewModel.isEditMode){
        [SVProgressHUD showWithStatus:@"更新..."];
    }else{
        [SVProgressHUD showWithStatus:@"发布中..."];
    }
    
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // 构建 appData
    NSMutableDictionary *appData = [NSMutableDictionary dictionary];
    [appData setValue:_viewModel.appName ?: @"" forKey:@"app_name"];
    [appData setValue:_viewModel.bundleId ?: @"" forKey:@"bundle_id"];
    [appData setValue:@([_viewModel.trackId integerValue]) forKey:@"track_id"];
    [appData setValue:idfv forKey:@"task_id"];
    [appData setValue:@(_viewModel.appType) forKey:@"app_type"];
    [appData setValue:_viewModel.versionName ?: @"1.0.0" forKey:@"version_name"];
    [appData setValue:_viewModel.appDescription ?: @"" forKey:@"app_description"];
    [appData setValue:_viewModel.releaseNotes ?: @"" forKey:@"release_notes"];
    [appData setValue:@([_viewModel.appRmb integerValue]) forKey:@"app_rmb"];
    [appData setValue:@(_viewModel.appStatus) forKey:@"app_status"];
    [appData setValue:[_viewModel.selectedTags copy] forKey:@"tags"];
    
    // 处理主文件URL
    BOOL shouldIncludeMainFileUrl = NO;
    [appData setValue:@NO forKey:@"is_cloud"];
    if (_viewModel.isEditMode) {
        // 编辑模式：如果是云端链接，并且没有选择新的本地文件，才保留
        if (_viewModel.isCloudMode && _viewModel.mainFileCloudURL.length > 0) {
            shouldIncludeMainFileUrl = YES;
            [appData setValue:@YES forKey:@"is_cloud"];
        }
    } else {
        // 新建模式：只有云端链接才添加
        if (_viewModel.isCloudMode && _viewModel.mainFileCloudURL.length > 0) {
            shouldIncludeMainFileUrl = YES;
            [appData setValue:@YES forKey:@"is_cloud"];
        }
    }
    
    if (shouldIncludeMainFileUrl) {
        [appData setValue:_viewModel.mainFileCloudURL forKey:@"mainFileUrl"];
    }
    
    
    NSMutableDictionary *data = _viewModel.isEditMode ? [@{@"app_id": _viewModel.editingAppId} mutableCopy] : [appData mutableCopy];
    
    // 编辑模式下，需要把 appData 的内容合并进去
    if (_viewModel.isEditMode) {
        [data addEntriesFromDictionary:appData];
    }
    
    NSMutableDictionary *params = [data mutableCopy];
    NSString *action = _viewModel.isEditMode ? @"updateAppInfo" : @"webCreateApp";
    [params setValue:action forKey:@"action"];
    
    
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                modules:@"app" parameters:params
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        //返回主线程UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult){
                
                NSError *error = [NSError errorWithDomain:@"setupForEditWithAppId" code:413 userInfo:@{NSLocalizedDescriptionKey: stringResult ?: @"加载失败"}];
                NSLog(@"\n发布软件返回失败error:%@",error);
                [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                [SVProgressHUD dismissWithDelay:3];
                
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if (code !=200) {
                
                NSError *error = [NSError errorWithDomain:@"setupForEditWithAppId" code:414 userInfo:@{NSLocalizedDescriptionKey: msg ?: @"加载失败"}];
                NSLog(@"\n发布软件返回失败error:%@",error);
                [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                [SVProgressHUD dismissWithDelay:3];
                
                return;
            }
            NSLog(@"\n发布软件jsonResult:%@",jsonResult);
            NSDictionary *appInfo = jsonResult[@"appInfo"];
            NSLog(@"\n发布软件appInfo:%@",appInfo);
            if (appInfo) {
                NSInteger appId = self.viewModel.isEditMode ? self.viewModel.editingAppId.integerValue : [jsonResult[@"appInfo"][@"app_id"] integerValue];
                [self uploadAllFilesWithAppId:appId];
            } else {
                [SVProgressHUD dismiss];;
                [SVProgressHUD showErrorWithStatus:jsonResult[@"msg"] ?: @"发布失败"];
            }
        });
        
    } failure:^(NSError *error) {
        //返回主线程UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];;
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        });
    }];
    
}

- (void)uploadAllFilesWithAppId:(NSInteger)appId {
    NSLog(@"开始上传附件软件id:%ld",appId);
    self.viewModel.editingAppId = @(appId);
    MediaManager *manager = [MediaManager sharedInstance];
    manager.appId = appId;
    manager.versionCode = _viewModel.currentVersionCode;
    manager.udid = [NewProfileViewController sharedInstance].userInfo.udid;
    manager.token = [[TokenGenerator sharedGenerator] generateTokenWithUDID:manager.udid];
    
    NSMutableArray<MediaItemModel *> *toUpload = [NSMutableArray array];
    if (_selectedIcon) {
        MediaItemModel *iconItem = [MediaItemModel itemWithLocalImage:_selectedIcon];
        iconItem.mediaType = MediaItemTypeIcon;
        [toUpload addObject:iconItem];
    }
    for (MediaItemModel *item in _mediaItems) {
        if (item.source == MediaSourceNew && !item.isUploading) {
            [toUpload addObject:item];
        }
    }
    // 检查是否需要上传主文件
    BOOL needsUploadMainFile = NO;
    if (_viewModel.mainFileData && !_viewModel.isCloudMode) {
        needsUploadMainFile = YES;
    }
    
    NSLog(@"开始上传附件总:%ld, 需要上传主文件: %d",toUpload.count, needsUploadMainFile);
    
    if (toUpload.count == 0 && !needsUploadMainFile) {
        [self publishSuccessWithAppId:appId];
        return;
    }
    
    __block NSInteger completed = 0;
    __block NSMutableDictionary *results = [NSMutableDictionary dictionary];
    NSInteger totalTasks = toUpload.count + (needsUploadMainFile ? 1 : 0);
    
    // 上传主文件（如果需要）
    if (needsUploadMainFile) {
        NSLog(@"开始上传主文件");
        [manager uploadMainFile:_viewModel.mainFileData fileName:_viewModel.mainFileName completion:^(BOOL success, NSString *fileName, NSString *fileURL, NSError *error) {
            results[@"mainFile"] = @{@"success": @(success), @"fileName": fileName ?: @""};
            completed++;
            [self updateProgress:completed total:totalTasks];
            if (completed == totalTasks) {
                [self handleUploadResults:results forAppId:appId];
            }
        }];
    }
    
    for (MediaItemModel *item in toUpload) {
        item.isUploading = YES;
        NSLog(@"开始循环附件：%@",item);
        NSLog(@"开始循环附件fileName：%@",item.fileName);
        NSLog(@"开始循环附件localData：%@",item.localData);
        NSLog(@"开始循环附件localImage：%@",item.localImage);
        if (item.mediaType == MediaItemTypeIcon) {
            NSLog(@"开始上传主图标");
            [manager uploadIconImage:item.localImage completion:^(BOOL success, NSString *fileName, NSString *fileURL, NSError *error) {
                item.isUploading = NO;
                item.uploadSuccess = success;
                results[item.identifier] = @{@"success": @(success), @"fileName": fileName ?: @""};
                completed++;
                [self updateProgress:completed total:totalTasks];
                if (completed == totalTasks) {
                    [self handleUploadResults:results forAppId:appId];
                }
            }];
        } else if (item.mediaType == MediaItemTypeImage) {
            NSLog(@"开始上传图片");
            [manager uploadImage:item.localImage completion:^(BOOL success, NSString *fileName, NSString *fileURL, NSError *error) {
                item.isUploading = NO;
                item.uploadSuccess = success;
                results[item.identifier] = @{@"success": @(success), @"fileName": fileName ?: @""};
                completed++;
                [self updateProgress:completed total:totalTasks];
                if (completed == totalTasks) {
                    [self handleUploadResults:results forAppId:appId];
                }
            }];
        } else if (item.mediaType == MediaItemTypeVideo) {
            NSLog(@"开始上传视频");
            [manager uploadVideo:item.localVideoURL completion:^(BOOL success, NSString *fileName, NSString *fileURL, NSString *thumbnailFileName, NSString *thumbnailURL, CGFloat duration, NSError *error) {
                item.isUploading = NO;
                item.uploadSuccess = success;
                item.videoDuration = duration;
                results[item.identifier] = @{@"success": @(success), @"fileName": fileName ?: @"", @"thumbnailFileName": thumbnailFileName ?: @""};
                completed++;
                [self updateProgress:completed total:totalTasks];
                if (completed == totalTasks) {
                    [self handleUploadResults:results forAppId:appId];
                }
            }];
        }
    }
    
    NSArray<NSString *> *toDelete = [_viewModel pendingDeleteMediaFiles];
    if (toDelete.count > 0) {
        [manager deleteMediaFiles:toDelete completion:^(NSDictionary *deleteResults) {}];
    }
}

- (void)handleUploadResults:(NSDictionary *)results forAppId:(NSInteger)appId {
    [SVProgressHUD dismiss];;
    [self publishSuccessWithAppId:appId];
}

- (void)publishSuccessWithAppId:(NSInteger)appId {
    _hasSuccessfullySubmitted = YES;
    [_viewModel clearDraft];
    NSString *message = _viewModel.isEditMode ? @"更新成功！" : @"发布成功！";
    
    [self showAlertWithConfirmationFromViewController:self title:@"提示" message:message confirmTitle:@"完成" cancelTitle:nil onConfirmed:^{
        if ([self.delegate respondsToSelector:@selector(publishEditViewController:didSuccessWithAppId:)]) {
            [self.delegate publishEditViewController:self didSuccessWithAppId:appId];
        }
        [self dismiss];
    } onCancelled:^{
        
    }];
}

- (void)updateProgress:(NSInteger)completed total:(NSInteger)total {
    CGFloat progress = (CGFloat)completed / total * 100;
    [SVProgressHUD showProgress:progress / 100 status:[NSString stringWithFormat:@"%ld/%ld (%.0f%%)", (long)completed, (long)total, progress]];
}

- (void)searchAppStore {
    AppSearchViewController *searchVC = [AppSearchViewController sharedInstance];
    searchVC.delegate = self;
    searchVC.keyword = _bundleIdField.text;
    [self.navigationController pushViewController:searchVC animated:YES];
}

#pragma mark - Image Source Selection

- (void)showImageSourceSelectorForType:(ImageSourceType)type {
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    _currentImageSourceType = type;
    NSString *title = (type == ImageSourceTypeIcon) ? @"选择图标来源" : @"选择媒体来源(图片/视频)";
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"App Store搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self searchAppStoreForImage];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"网络图片搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self searchInternetImage];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"相机拍摄" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self takePhoto];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self chooseFromPhotoLibrary];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"文件App选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self chooseFromFilesApp];
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)searchAppStoreForImage {
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    AppSearchViewController *searchVC = [AppSearchViewController new];
    searchVC.delegate = self;
    searchVC.keyword = _bundleIdField.text;
    [self presentViewController:searchVC animated:YES completion:nil];
}

- (void)searchInternetImage {
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    ImageGridSearchViewController *imageSearchVC = [ImageGridSearchViewController new];
    imageSearchVC.searchKeyword = _appNameField.text ?: @"";
    imageSearchVC.delegate = self;
    imageSearchVC.maxiMum = (_currentImageSourceType == ImageSourceTypeIcon) ? 1 : (kMaximumMediaCount - _mediaItems.count);
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:imageSearchVC];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)takePhoto {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showErrorWithStatus:@"相机不可用"];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.allowsEditing = (_currentImageSourceType == ImageSourceTypeIcon);
    
    if (_currentImageSourceType == ImageSourceTypeMedia) {
        // 对于媒体文件，支持拍照和录像
        picker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    } else {
        // 对于图标，只支持拍照
        picker.mediaTypes = @[(NSString *)kUTTypeImage];
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    }
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)chooseFromPhotoLibrary {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = (_currentImageSourceType == ImageSourceTypeIcon);
    
    if (_currentImageSourceType == ImageSourceTypeMedia) {
        // 对于媒体文件，支持图片和视频
        picker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    } else {
        // 对于图标，只支持图片
        picker.mediaTypes = @[(NSString *)kUTTypeImage];
    }
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)chooseFromFilesApp {
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.image", @"public.movie", @"public.video"] inMode:UIDocumentPickerModeOpen];
    picker.delegate = self;
    picker.allowsMultipleSelection = (_currentImageSourceType == ImageSourceTypeMedia);
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)selectMainFileFromFilesApp {
    UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    _currentImageSourceType = ImageSourceTypeMainFile;
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeOpen];
    
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)downloadAndSetIconWithURL:(NSString *)urlString {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                [self setIconImage:image];
            }
        });
    });
}

- (void)setIconImage:(UIImage *)image {
    _selectedIcon = image;
    [_iconCollectionView reloadData];
}

- (void)addMediaItemWithURL:(NSString *)urlString isVideo:(BOOL)isVideo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                if (isVideo) {
                    NSURL *videoURL = [NSURL URLWithString:urlString];
                    [MediaManager generateVideoThumbnail:videoURL completion:^(UIImage *thumbnail, CGFloat duration) {
                        MediaItemModel *item = [MediaItemModel itemWithLocalVideoURL:videoURL thumbnail:thumbnail duration:duration];
                        [self addMediaItem:item];
                    }];
                } else {
                    UIImage *image = [UIImage imageWithData:data];
                    if (image) {
                        MediaItemModel *item = [MediaItemModel itemWithLocalImage:image];
                        [self addMediaItem:item];
                    }
                }
            }
        });
    });
}

- (void)addMediaItem:(MediaItemModel *)item {
    [_mediaItems addObject:item];
    [_viewModel.mediaItems addObject:item]; // 同步添加到 viewModel
    [_mediaCollectionView reloadData];
}

#pragma mark - AppSearchViewControllerDelegate

- (void)didSelectAppModel:(ITunesAppModel *)model controller:(AppSearchViewController *)controller tableView:(UITableView *)tableView cell:(UITableViewCell*)cell {
    if (_currentImageSourceType == ImageSourceTypeIcon && model.artworkUrl512) {
        [self downloadAndSetIconWithURL:model.artworkUrl512];
    }
    _appNameField.text = model.trackName ?: @"";
    _bundleIdField.text = model.bundleId ?: @"";
    _trackIdField.text = model.trackId ?: @"";
    _descriptionTextView.text = model.appDescription ?: @"";
    _versionNameField.text = @"1.0.0";
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - ImageGridSearchViewControllerDelegate

- (void)imageGridSearch:(ImageGridSearchViewController *)controller didSelectImages:(NSArray<ImageModel *> *)imageModels {
    if (_currentImageSourceType == ImageSourceTypeIcon && imageModels.count > 0) {
        [self downloadAndSetIconWithURL:imageModels.firstObject.url];
    } else if (_currentImageSourceType == ImageSourceTypeMedia) {
        for (ImageModel *img in imageModels) {
            [self addMediaItemWithURL:img.url isVideo:NO];
        }
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        // 处理图片
        UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
        if (_currentImageSourceType == ImageSourceTypeIcon) {
            [self setIconImage:image];
        } else if (_currentImageSourceType == ImageSourceTypeMedia) {
            MediaItemModel *item = [MediaItemModel itemWithLocalImage:image];
            [self addMediaItem:item];
        }
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie] && _currentImageSourceType == ImageSourceTypeMedia) {
        // 处理视频
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        if (videoURL) {
            [MediaManager generateVideoThumbnail:videoURL completion:^(UIImage *thumbnail, CGFloat duration) {
                MediaItemModel *item = [MediaItemModel itemWithLocalVideoURL:videoURL thumbnail:thumbnail duration:duration];
                [self addMediaItem:item];
            }];
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        if (_currentImageSourceType == ImageSourceTypeMainFile) {
            [self handleMainFileURL:url];
        } else if (_currentImageSourceType == ImageSourceTypeIcon) {
            [self downloadAndSetIconWithURL:urls.firstObject.absoluteString];
        }else{
            [self handleMediaFileURL:url];
        }
    }
}

- (void)handleMediaFileURL:(NSURL *)url {
    [url startAccessingSecurityScopedResource];
    NSString *fileExtension = url.pathExtension.lowercaseString;
    NSArray *videoExts = @[@"mp4", @"mov", @"m4v", @"avi", @"mkv", @"flv", @"wmv"];
    
    if ([videoExts containsObject:fileExtension]) {
        [MediaManager generateVideoThumbnail:url completion:^(UIImage *thumbnail, CGFloat duration) {
            MediaItemModel *item = [MediaItemModel itemWithLocalVideoURL:url thumbnail:thumbnail duration:duration];
            [self addMediaItem:item];
        }];
    } else {
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                MediaItemModel *item = [MediaItemModel itemWithLocalImage:image];
                [self addMediaItem:item];
            }
        }
    }
    [url stopAccessingSecurityScopedResource];
}

- (void)handleMainFileURL:(NSURL *)url {
    [url startAccessingSecurityScopedResource];
    
    // 读取本地文件数据
    NSError *error = nil;
    NSData *fileData = [NSData dataWithContentsOfURL:url options:0 error:&error];
    
    if (fileData && !error) {
        _viewModel.mainFileData = fileData;
        _viewModel.mainFileName = url.lastPathComponent;
        _viewModel.isCloudMode = NO; // 选择本地文件，标记为非云端模式
        NSLog(@"主文件读取成功，文件大小: %ld bytes", (long)fileData.length);
        
        // 自动检测并更新应用类型
        NSInteger detectedType = [self detectAppTypeFromFileName:url.lastPathComponent];
        if (detectedType > 0) {
            [self updateAppTypeSelection:detectedType];
        }
        
        // 更新 UI
        [self updateMainFileUI];
    } else {
        NSLog(@"主文件读取失败: %@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:@"文件读取失败"];
    }
    
    [url stopAccessingSecurityScopedResource];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView.tag == 1) return 1;
    else if (collectionView.tag == 2) return _mediaItems.count + 1;
    else if (collectionView.tag == 3) return _availableTags.count;
    else if (collectionView.tag == 4) return _allAppTypes.count;
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 1) {
        IconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IconCell" forIndexPath:indexPath];
        [cell configureWithImage:_selectedIcon isEmpty:(_selectedIcon == nil)];
        return cell;
    } else if (collectionView.tag == 2) {
        if (indexPath.item == _mediaItems.count) {
            UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddMediaCell" forIndexPath:indexPath];
            cell.contentView.subviews.firstObject ?: ({
                UIView *addView = [[UIView alloc] initWithFrame:cell.contentView.bounds];
                addView.backgroundColor = [UIColor systemGray6Color];
                addView.layer.cornerRadius = 8;
                addView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                UIImageView *plusIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"plus"]];
                plusIcon.tintColor = [UIColor systemGrayColor];
                plusIcon.frame = CGRectMake(0, 0, 30, 30);
                plusIcon.center = CGPointMake(addView.bounds.size.width / 2, addView.bounds.size.height / 2);
                plusIcon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                [addView addSubview:plusIcon];
                [cell.contentView addSubview:addView];
            });
            return cell;
        }
        MediaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCell" forIndexPath:indexPath];
        MediaItemModel *item = _mediaItems[indexPath.item];
        [cell configureWithMediaItem:item isEditing:YES];
        
        __weak typeof(self) weakSelf = self;
        cell.deleteButton.tag = indexPath.item;
        [cell.deleteButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.deleteButton addTarget:weakSelf action:@selector(deleteMediaItem:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    } else if (collectionView.tag == 3) {
        MultiSelectTagCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultiSelectTagCell" forIndexPath:indexPath];
        NSString *tag = _availableTags[indexPath.item];
        BOOL isSelected = [_selectedTagsSet containsObject:tag];
        [cell configureWithTitle:tag isSelected:isSelected];
        return cell;
    } else if (collectionView.tag == 4) {
        AppTypeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AppTypeCell" forIndexPath:indexPath];
        NSDictionary *typeDict = _allAppTypes[indexPath.item];
        NSString *title = typeDict[@"title"];
        BOOL isSelected = ([typeDict[@"type"] integerValue] == _viewModel.appType);
        [cell configureWithTitle:title isSelected:isSelected];
        return cell;
    }
    return [[UICollectionViewCell alloc] init];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 1) {
        [self showImageSourceSelectorForType:ImageSourceTypeIcon];
    } else if (collectionView.tag == 2) {
        if (indexPath.item == _mediaItems.count) {
            if (_mediaItems.count >= kMaximumMediaCount) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"最多添加%ld个文件", (long)kMaximumMediaCount]];
            } else {
                [self showImageSourceSelectorForType:ImageSourceTypeMedia];
            }
        }
    } else if (collectionView.tag == 3) {
        NSString *tag = _availableTags[indexPath.item];
        if ([_selectedTagsSet containsObject:tag]) {
            [_selectedTagsSet removeObject:tag];
        } else {
            [_selectedTagsSet addObject:tag];
        }
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else if (collectionView.tag == 4) {
        NSDictionary *typeDict = _allAppTypes[indexPath.item];
        _viewModel.appType = [typeDict[@"type"] integerValue];
        [collectionView reloadData];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 1) {
        // 图标cell：固定80x80
        return CGSizeMake(kIconSize, kIconSize);
    } else if (collectionView.tag == 2) {
        // 媒体cell：固定100x100
        return CGSizeMake(kMediaCellWidth, kMediaCellWidth);
    } else if (collectionView.tag == 3) {
        // 标签cell：根据文字长度自适应宽度
        NSString *tag = _availableTags[indexPath.item];
        CGFloat fontSize = 13.0;
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        
        NSDictionary *attributes = @{NSFontAttributeName: font};
        CGSize textSize = [tag sizeWithAttributes:attributes];
        
        // 计算宽度：文字宽度 + 左右padding (各16像素)
        CGFloat horizontalPadding = 24;
        CGFloat cellWidth = textSize.width + horizontalPadding;
        
        // 设置一个较大的固定最小宽度
        cellWidth = MAX(cellWidth, 32);  // 最小宽度80
        
        return CGSizeMake(cellWidth, 32);
    } else if (collectionView.tag == 4) {
        // 应用类型cell：固定60x32
        return CGSizeMake(60, 32);
    }
    return CGSizeMake(60, 32);
}

- (void)deleteMediaItem:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < _mediaItems.count) {
        MediaItemModel *item = _mediaItems[index];
        if (item.source == MediaSourceExisting) {
            item.pendingDelete = !item.pendingDelete;
            [_mediaCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        } else {
            [_mediaItems removeObjectAtIndex:index];
            [_viewModel.mediaItems removeObject:item]; // 同步从 viewModel 中删除
            [_mediaCollectionView reloadData];
        }
    }
}



// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupNavigationBar];
    
    
}

@end
