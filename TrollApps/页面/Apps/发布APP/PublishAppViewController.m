//
//  PublishAppViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "PublishAppViewController.h"
#import "AppInfoModel.h"
#import "NewProfileViewController.h"
#import <Masonry/Masonry.h>
#import <Photos/Photos.h>
#import "AppSearchViewController.h"
#import "NewProfileViewController.h"
#import "DocumentPickerViewController.h"
#import "config.h"
#import "HXPhotoPicker.h"
#import "HXAssetManager.h"
#import "HXPhotoTools.h"
#import "FileUtils.h"
#import "UploadManager.h"
#import "TaskManager.h"
#import "TokenGenerator.h"
#import "NetworkClient.h"
//草稿字符串
#define kPublishAppDraft @"PublishAppDraft"

//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

// 宏定义：文件大小限制（例如：50MB，1MB=1024*1024字节）
#define MAX_FILE_SIZE (200 * 1024 * 1024)

@interface PublishAppViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, HXPhotoViewDelegate,AppSearchViewControllerDelegate,UIDocumentPickerDelegate>

#pragma mark - 主UI元素
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

#pragma mark - 应用信息输入项
@property (nonatomic, strong) UIImageView *appIconView; // 应用图标
@property (nonatomic, strong) UIImage *selectappIconImage; // 选择头像后的图片对象
@property (nonatomic, strong) UIButton *fileUploadButton; // 上传图标按钮

@property (nonatomic, strong) UITextField *appNameField; // 应用名称
@property (nonatomic, strong) UITextField *bundleIDField; // BundleID

@property (nonatomic, strong) UILabel *appTypeLabel; // 主类型标题
@property (nonatomic, strong) UISegmentedControl *appTypeSegment; // 主类型选择

@property (nonatomic, strong) UILabel *tagsLabel; // 标签标题
@property (nonatomic, strong) UIView *tagsContainer; // 标签容器
@property (nonatomic, strong) NSMutableArray<UIButton *> *tagButtons; // 标签按钮集合

@property (nonatomic, strong) UILabel *descriptionLabel; // 描述标题
@property (nonatomic, strong) UIButton *descriptionCleanButton; // 描述清理
@property (nonatomic, strong) UITextView *descriptionTextView; // 描述输入框
@property (nonatomic, strong) UILabel *descCountLabel; // 描述字数统计

@property (nonatomic, strong) UILabel *releaseNotesLabel; // 更新标题
@property (nonatomic, strong) UITextView *releaseNotesTextView;// 更新信息

@property (nonatomic, strong) UILabel *imageCountLabel; // 图片视频提示
@property (nonatomic, strong) UIButton *publishButton; // 发布按钮

@property (nonatomic, strong) UIProgressView *progressView;//进度条


@property (nonatomic, strong) HXPhotoView *photoView;//图片选择器
@property (nonatomic, strong) HXPhotoManager *manager;//图片管理
@property (nonatomic, strong) AppSearchViewController *appSaearchViewController;//AppStore搜索
@property (nonatomic, strong) UIView *myNavigationBar;//导航


#pragma mark - 数据相关
@property (nonatomic, strong) NSArray<NSString *> *allTags; // 全部标签
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedTags; // 选中的标签

// 上传任务管理
@property (nonatomic, strong) UploadTask *uploadTask;
@property (nonatomic, assign) BOOL isUploading;

@property (nonatomic, strong) NSMutableArray *fileArray;//选择的文件
@property (nonatomic, strong) NSMutableArray *mediaArray;//选择的图片视频文件
@end

@implementation PublishAppViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"发布应用";
    self.isTapViewToHideKeyboard = YES;
    [self setupNavigationBar];
    [self initData];
    [self setupSubviews];
    [self setupTags];
    [self loadDraftIfExists];
    [self setupViewConstraints];
    [self updateViewConstraints];
    
    
    
}

#pragma mark - 初始化
- (void)setupNavigationBar {
    self.zx_hideBaseNavBar  =YES;
    self.zx_showSystemNavBar = YES;
    self.tabBarController.tabBar.hidden = YES;
    
    // 返回按钮
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(cancelPublish) forControlEvents:UIControlEventTouchUpInside];
    
    
    // 草稿按钮
    UIButton *draftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [draftBtn setTitle:@"草稿" forState:UIControlStateNormal];
    [draftBtn addTarget:self action:@selector(draftButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.myNavigationBar = [UIView new];
    [self.view addSubview:self.myNavigationBar];
    
    
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    UIBarButtonItem *draftItem = [[UIBarButtonItem alloc] initWithCustomView:draftBtn];
    if([self isPresentedByHWPanModal] ){
        
        
        NSLog(@"isPresentedByHWPanModal");
        self.titleLabel = [UILabel new];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        self.titleLabel.text = self.title;
        
        [self.myNavigationBar addSubview:self.titleLabel];
        [self.myNavigationBar addSubview:backBtn];
        [self.myNavigationBar addSubview:draftBtn];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(20);
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(20);
        }];
        
        [self.myNavigationBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(kWidth);
            make.height.mas_equalTo(50);
        }];
        [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self.myNavigationBar).offset(20);
            make.height.mas_equalTo(20);
            
        }];
        [draftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.myNavigationBar).offset(20);
            make.right.equalTo(self.myNavigationBar).offset(-20);
            make.height.mas_equalTo(20);
        }];
    }else{
        
        self.navigationController.navigationBarHidden = NO;
        NSLog(@"isSystemModal");
        self.navigationItem.leftBarButtonItem = backItem;
        self.navigationItem.rightBarButtonItem = draftItem;
    }
    
    
}

- (void)initData {
    if(!self.app_info){
        self.app_info = [[AppInfoModel alloc] init];
    }
    
    self.selectedTags = [NSMutableArray array];
    // 初始化默认标签（与AppInfo中定义的标签对应）
    self.allTags = @[@"巨魔IPA", @"游戏辅助", @"多开软件", @"定位", @"脚本",
                     @"有根越狱插件", @"无根插件", @"影音", @"工具",
                     @"系统增强", @"其他"];
    //初始化上传为NO
    self.isUploading = NO;
}

#pragma mark - UI布局
- (void)setupSubviews {
    // 滚动视图（适配小屏设备）
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    
    [self.view addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    // 应用图标
    self.appIconView = [[UIImageView alloc] init];
    self.appIconView.contentMode = UIViewContentModeCenter;
    self.appIconView.layer.cornerRadius = 15;
    self.appIconView.clipsToBounds = YES;
    self.appIconView.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.3];
    self.appIconView.image = [UIImage systemImageNamed:@"photo.fill"];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uploadIcon)];
    tapGesture.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.appIconView.userInteractionEnabled = YES;
    [self.appIconView addGestureRecognizer:tapGesture];
    [self.contentView addSubview:self.appIconView];
    
    // 上传图标按钮
    self.fileUploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.fileUploadButton setTitle:@"选择上传文件" forState:UIControlStateNormal];
    self.fileUploadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.fileUploadButton addTarget:self action:@selector(uploadFile) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.fileUploadButton];
    
    // 应用名称输入框
    self.appNameField = [self createTextFieldWithPlaceholder:@"请输入应用名称"];
    self.appNameField.returnKeyType = UIReturnKeyNext;
    self.appNameField.delegate = self;
    self.appNameField.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.7];
    [self.contentView addSubview:self.appNameField];
    
    // BundleID输入框
    self.bundleIDField = [self createTextFieldWithPlaceholder:@"BundleID（如：com.example.app)"];
    self.bundleIDField.returnKeyType = UIReturnKeyNext;
    self.bundleIDField.delegate = self;
    self.bundleIDField.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.7];
    [self.contentView addSubview:self.bundleIDField];
    
    // 应用类型
    self.appTypeLabel = [self createTitleLabelWithText:@"应用主类型"];
    [self.contentView addSubview:self.appTypeLabel];
    
    self.appTypeSegment = [[UISegmentedControl alloc] initWithItems:@[@"IPA", @"deb", @"zip", @"其他"]];
    self.appTypeSegment.selectedSegmentIndex = 0;
    self.appTypeSegment.tintColor = [UIColor systemBlueColor];
    [self.contentView addSubview:self.appTypeSegment];
    
    // 标签
    self.tagsLabel = [self createTitleLabelWithText:@"应用标签（可多选）"];
    [self.contentView addSubview:self.tagsLabel];
    
    self.tagsContainer = [[UIView alloc] init];
    self.tagsContainer.backgroundColor = [UIColor systemGray6Color];
    self.tagsContainer.layer.cornerRadius = 8;
    [self.contentView addSubview:self.tagsContainer];
    
    // 描述
    self.descriptionLabel = [self createTitleLabelWithText:@"应用描述"];
    [self.contentView addSubview:self.descriptionLabel];
    
    //描述清理图标
    self.descriptionCleanButton = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"trash.fill"] target:self action:@selector(cleanDescription:)];
    [self.contentView addSubview:self.descriptionCleanButton];
    
    //描述输入框
    self.descriptionTextView = [[UITextView alloc] init];
    self.descriptionTextView.font = [UIFont systemFontOfSize:16];
    self.descriptionTextView.layer.borderColor = [UIColor systemGray3Color].CGColor;
    self.descriptionTextView.layer.borderWidth = 1;
    self.descriptionTextView.layer.cornerRadius = 8;
    self.descriptionTextView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
    self.descriptionTextView.delegate = self;
    self.descriptionTextView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.7];
    [self.contentView addSubview:self.descriptionTextView];
    
    self.descCountLabel = [[UILabel alloc] init];
    self.descCountLabel.font = [UIFont systemFontOfSize:12];
    self.descCountLabel.textColor = [UIColor systemGray4Color];
    self.descCountLabel.text = @"0/500";
    [self.contentView addSubview:self.descCountLabel];
    
    // 更新描述白天
    self.releaseNotesLabel = [self createTitleLabelWithText:@"更新说明"];
    [self.contentView addSubview:self.releaseNotesLabel];
    //更新信息
    self.releaseNotesTextView = [[UITextView alloc] init];
    self.releaseNotesTextView.font = [UIFont systemFontOfSize:16];
    self.releaseNotesTextView.layer.borderColor = [UIColor systemGray3Color].CGColor;
    self.releaseNotesTextView.layer.borderWidth = 1;
    self.releaseNotesTextView.layer.cornerRadius = 8;
    self.releaseNotesTextView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
    self.releaseNotesTextView.delegate = self;
    self.releaseNotesTextView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.7];
    [self.contentView addSubview:self.releaseNotesTextView];
    
    // 图片视频描述
    self.imageCountLabel = [self createTitleLabelWithText:@"截图/视频 介绍"];
    [self.contentView addSubview:self.imageCountLabel];
    
    
    
    self.photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(10,
                                                                   kHeight - 150,
                                                                   kWidth - 20,
                                                                   (kWidth-40)/6*2
                                                                   )
                                                manager:self.manager];
    self.photoView.delegate = self;
    self.photoView.layer.cornerRadius = 10;
    self.photoView.layer.masksToBounds = YES;
    self.photoView.outerCamera = YES;
    self.photoView.lineCount = 6;
    self.photoView.alpha = 1;
    self.photoView.layer.borderWidth = 0.5;
    self.photoView.layer.borderColor = [UIColor quaternaryLabelColor].CGColor;
    self.photoView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.7];
    //照片选择器
    [self.contentView addSubview:self.photoView];
    [self.photoView refreshView];
    
    
    // 发布按钮
    self.publishButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.publishButton setTitle:@"发布应用" forState:UIControlStateNormal];
    self.publishButton.backgroundColor = [UIColor systemBlueColor];
    [self.publishButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.publishButton.layer.cornerRadius = 8;
    self.publishButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.publishButton addTarget:self action:@selector(publishApp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.publishButton];
    
    self.progressView = [[UIProgressView alloc] init];
    [self.view addSubview:self.progressView];
    
    
}


#pragma mark - 约束设置
- (void)setupViewConstraints {
    
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
//        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - 80);
    }];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
        make.height.greaterThanOrEqualTo(self.scrollView); // 确保内容视图至少和滚动视图一样高
    }];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
        make.height.greaterThanOrEqualTo(self.scrollView); // 确保内容视图至少和滚动视图一样高
    }];
    
    // 应用图标
    [self.appIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.contentView).offset(20);
        make.width.height.equalTo(@100);
    }];
    
    
    // 应用名称
    [self.appNameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(20);
        make.left.equalTo(self.appIconView.mas_right).offset(20);
        make.right.equalTo(self.contentView).inset(20);
        make.height.equalTo(@40);
    }];
    
    // BundleID
    [self.bundleIDField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameField.mas_bottom).offset(15);
        make.left.right.height.equalTo(self.appNameField);
    }];
    
    // 上传图标按钮
    [self.fileUploadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appIconView.mas_bottom).offset(10);
        make.centerX.equalTo(self.contentView);
    }];
    
    
    // 应用类型
    [self.appTypeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.fileUploadButton.mas_bottom).offset(15);
        make.left.equalTo(self.contentView).inset(20);
        make.height.equalTo(@20);
    }];
    
    [self.appTypeSegment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appTypeLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView).inset(20);
        make.height.equalTo(@30);
    }];
    
    // 标签
    [self.tagsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appTypeSegment.mas_bottom).offset(25);
        make.left.equalTo(self.contentView).inset(20);
        make.height.equalTo(@20);
    }];
    
    [self.tagsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView).inset(20);
        make.height.greaterThanOrEqualTo(@40); // 高度自适应内容
    }];
    
    // 描述
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsContainer.mas_bottom).offset(25);
        make.left.equalTo(self.contentView).inset(20);
        make.height.equalTo(@20);
    }];
    // 描述清理按钮
    [self.descriptionCleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsContainer.mas_bottom).offset(25);
        make.right.equalTo(self.contentView.mas_right).offset(-20);
        make.height.width.equalTo(@20);
    }];
    //描述输入框
    [self.descriptionTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView).inset(20);
        make.height.equalTo(@150);
    }];
    
    //底部文字字数
    [self.descCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionTextView.mas_bottom).offset(5);
        make.right.equalTo(self.contentView).inset(25);
        make.height.equalTo(@15);
    }];
    
    //更新提示
    [self.releaseNotesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descCountLabel.mas_bottom).offset(5);
        make.left.equalTo(self.contentView).inset(20);
        make.height.equalTo(@15);
    }];
    
    //更新说明
    [self.releaseNotesTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.releaseNotesLabel.mas_bottom).offset(5);
        make.left.right.equalTo(self.contentView).inset(20);
        make.height.equalTo(@50);
    }];
    
    // 图片视频描述
    [self.imageCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.releaseNotesTextView.mas_bottom).offset(25);
        make.left.equalTo(self.contentView).inset(20);
        make.height.equalTo(@20);
    }];
    
    //图片视频选择器
    [self.photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageCountLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.contentView).inset(20);
        make.height.equalTo(@((kWidth-40)/6*2));
        make.bottom.equalTo(self.contentView).offset(-20);
    }];
    
    // 发布按钮
    [self.publishButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        make.left.right.equalTo(self.contentView).inset(20);
        make.height.equalTo(@50);
    }];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        if([self isPresentedByHWPanModal] ){
            make.top.equalTo(self.view).offset(50);
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        }else{
            make.edges.equalTo(self.view);
        }
    }];
    
    // 发布按钮
    [self.publishButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        make.left.right.equalTo(self.view).inset(20);
        make.height.equalTo(@50);
    }];
    
}

//视图布局完成
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 在这里进行与布局完成后相关的操作，比如获取子视图的最终尺寸等
    NSLog(@"视图布局完成");
//    [self.tagsContainer setRandomGradientBackgroundWithColorCount:2 alpha:0.1];
}


#pragma mark - 标签初始化
- (void)setupTags {
    self.tagButtons = [NSMutableArray array];
    CGFloat margin = 10;
    CGFloat tagHeight = 25;
    CGFloat currentX = margin;
    CGFloat currentY = margin;
    
    for (NSString *tag in self.allTags) {
        UIButton *tagBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        tagBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [tagBtn setTitle:tag forState:UIControlStateNormal];
        [tagBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [tagBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        tagBtn.backgroundColor = [UIColor whiteColor];
        
        tagBtn.layer.cornerRadius = tagHeight / 2;
        tagBtn.layer.borderColor = [UIColor systemGray3Color].CGColor;
        tagBtn.layer.borderWidth = 1;
        [tagBtn addTarget:self action:@selector(tagButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tagsContainer addSubview:tagBtn];
        [self.tagButtons addObject:tagBtn];
        
        // 计算标签宽度
        CGSize tagSize = [tag sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
        CGFloat tagWidth = tagSize.width + 20; // 左右内边距
        
        // 自动换行布局
        if (currentX + tagWidth + margin > kWidth - 40) { // 减去容器左右内边距
            currentX = margin;
            currentY += tagHeight + margin;
        }
        
        [tagBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(currentX));
            make.top.equalTo(@(currentY));
            make.width.equalTo(@(tagWidth));
            make.height.equalTo(@(tagHeight));
        }];
        
        currentX += tagWidth + margin;
    }
    
    // 调整标签容器高度
    [self.tagsContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(currentY + tagHeight + margin));
    }];
}


#pragma mark - 事件处理

//图标上传点击
- (void)uploadIcon {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择图标"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"商店搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        self.appSaearchViewController = [AppSearchViewController new];
        self.appSaearchViewController.delegate = self;
        if(self.appNameField.text.length>0){
            self.appSaearchViewController.keyword = self.appNameField.text;
        }
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:self.appSaearchViewController];
        [self presentViewController:navVC animated:YES completion:nil];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openCamera];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openPhotoLibrary];
    }]];
    
    
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

//文件上传点击
- (void)uploadFile {
    // 支持的文件类型 (这里以所有文件类型为例，实际应根据需求设置)
    NSArray *documentTypes = @[(NSString *)kUTTypeItem]; // 所有文件类型
    
    
    // 创建文件选择控制器
    DocumentPickerViewController *documentPicker = [[DocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeImport];
    
    // 设置代理
    documentPicker.delegate = self;
    
    // 允许选择多个文件 (可选)
    documentPicker.allowsMultipleSelection = NO;
    // 设置全屏显示
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    
    // 显示文件选择器
    [self presentViewController:documentPicker animated:YES completion:nil];
    
}

//相机点击
- (void)openCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate = self;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:@"相机不可用"];
        [SVProgressHUD dismissWithDelay:2];
    }
}

//打开相册
- (void)openPhotoLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        
        [SVProgressHUD showErrorWithStatus:@"相册不可用"];
        [SVProgressHUD dismissWithDelay:2];
    }
}

//标签点击
- (void)tagButtonTapped:(UIButton *)sender {
    sender.selected = !sender.selected;
    sender.backgroundColor = sender.selected ? [UIColor blueColor] : [UIColor whiteColor];
    
    if (sender.selected) {
        [self.selectedTags addObject:sender.titleLabel.text];
    } else {
        [self.selectedTags removeObject:sender.titleLabel.text];
    }
}

// 表单验证
- (void)publishApp {
    // 表单验证
    if (self.appNameField.text.length == 0) {
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"signature"] status:@"请输入应用名称"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    
    if (self.bundleIDField.text.length == 0) {
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"signature"] status:@"请输入Bundle ID"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    
    if (self.descriptionTextView.text.length == 0) {
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"signature"] status:@"请输入应用描述"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    
    if (self.selectedTags.count == 0) {
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"grid"] status:@"请至少选择一个标签"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    
    // 验证Bundle ID格式（简单验证）
    if (![self validateBundleID:self.bundleIDField.text]) {
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"xmark.circle"] status:@"Bundle ID格式不正确（例：com.company.app）"];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }
    
    // 验证描述长度
    if (self.descriptionTextView.text.length > 500) {
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"xmark.circle"] status:@"描述不能超过500字"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    
    // 验证图标是否已设置
    if (self.appIconView.image == [UIImage systemImageNamed:@"app.badge.fill"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"是否使用默认图标发布？"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self startPublishProcess];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 开始发布流程
    [self startPublishProcess];
}

- (void)cleanDescription:(UIButton *)sender{
    self.descriptionTextView.text = @"";
}

#pragma mark - 草稿相关功能

//草稿导航条
- (void)setupDraftNavigationItem {
    // 添加草稿按钮到导航栏
    UIBarButtonItem *draftItem = [[UIBarButtonItem alloc] initWithTitle:@"草稿"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(draftButtonTapped:)];
    self.navigationItem.rightBarButtonItem = draftItem;
}

// 草稿操作提示
- (void)draftButtonTapped:(UIBarButtonItem *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"草稿操作"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 保存草稿
    [alert addAction:[UIAlertAction actionWithTitle:@"保存草稿"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self saveDraft];
    }]];
    
    // 删除草稿（如果存在）
    if ([self hasSavedDraft]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"删除草稿"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self deleteDraft];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    // 适配iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

// 保存草稿
- (void)saveDraft {
    // 构建草稿数据模型
    NSMutableDictionary *draftDict = [NSMutableDictionary dictionary];
    draftDict[@"appName"] = self.appNameField.text ?: @"";
    draftDict[@"bundleID"] = self.bundleIDField.text ?: @"";
    draftDict[@"appType"] = @(self.appTypeSegment.selectedSegmentIndex);
    draftDict[@"selectedTags"] = self.selectedTags;
    draftDict[@"appDescription"] = self.descriptionTextView.text ?: @"";
    
    // 保存图标（转为Base64）
    if (self.appIconView.image && self.appIconView.image != [UIImage systemImageNamed:@"app.badge.fill"]) {
        NSData *iconData = UIImagePNGRepresentation(self.appIconView.image);
        draftDict[@"appIconBase64"] = [iconData base64EncodedStringWithOptions:0];
    }
    
    // 保存选中的图片视频（HXPhotoView数据）
    if (self.manager.afterSelectedArray.count > 0) {
        [self.manager saveLocalModelsToFile];
    }
    
    // 保存到本地（使用UserDefaults，复杂场景建议用CoreData）
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:draftDict forKey:kPublishAppDraft];
    [defaults synchronize];
    
    [SVProgressHUD showSuccessWithStatus:@"草稿保存成功"];
    [SVProgressHUD dismissWithDelay:1.0];
}

// 删除草稿
- (void)deleteDraft {
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"确认删除"
                                                                          message:@"确定要删除当前草稿吗？"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil]];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"删除"
                                                     style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction * _Nonnull action) {
        // 清除本地草稿
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:kPublishAppDraft];
        [defaults synchronize];
        
        [self.manager deleteLocalModelsInFile];
        
        [SVProgressHUD showSuccessWithStatus:@"草稿已删除"];
        [SVProgressHUD dismissWithDelay:1.0];
    }]];
    
    [self presentViewController:confirmAlert animated:YES completion:nil];
}

// 判断草稿存在
- (BOOL)hasSavedDraft {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kPublishAppDraft] != nil;
}

//加载草稿数据
- (void)loadDraftIfExists {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *draftDict = [defaults objectForKey:kPublishAppDraft];
    if (!draftDict) return;
    
    // 加载基本信息
    self.appNameField.text = draftDict[@"appName"];
    self.bundleIDField.text = draftDict[@"bundleID"];
    self.appTypeSegment.selectedSegmentIndex = [draftDict[@"appType"] integerValue];
    self.descriptionTextView.text = draftDict[@"appDescription"];
    [self textViewDidChange:self.descriptionTextView]; // 更新字数统计
    
    // 加载标签选择状态
    NSArray *savedTags = draftDict[@"selectedTags"];
    for (NSString *tag in savedTags) {
        for (UIButton *tagBtn in self.tagButtons) {
            if ([tagBtn.titleLabel.text isEqualToString:tag]) {
                tagBtn.selected = YES;
                tagBtn.backgroundColor = [UIColor blueColor];
                [self.selectedTags addObject:tag];
            }
        }
    }
    
    // 加载应用图标
    if (draftDict[@"appIconBase64"]) {
        NSData *iconData = [[NSData alloc] initWithBase64EncodedString:draftDict[@"appIconBase64"] options:0];
        self.appIconView.image = [UIImage imageWithData:iconData];
    }
    
    // 加载媒体资源（图片/视频）
    [self.manager getLocalModelsInFileWithAddData:YES];
    //刷新
    [self.photoView refreshView];
}


#pragma mark - 辅助方法

- (BOOL)validateBundleID:(NSString *)bundleID {
    // 简单的Bundle ID格式验证（字母、数字、点、下划线、连字符）
    NSString *pattern = @"^[a-zA-Z0-9_.-]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:bundleID];
}

- (void)popBack {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kPublishAppDraft];
    [defaults synchronize];
    
    [self.manager deleteLocalModelsInFile];
    [self dismiss];
    
}

#pragma mark - 工具方法


#pragma mark - 输入框代理方法
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.appNameField) {
        [self.bundleIDField becomeFirstResponder];
    } else if (textField == self.bundleIDField) {
        [self.descriptionTextView becomeFirstResponder];
    }
    return YES;
}

#pragma mark - 文本视图代理方法
- (void)textViewDidChange:(UITextView *)textView {
    NSInteger count = textView.text.length;
    self.descCountLabel.text = [NSString stringWithFormat:@"%ld/500", (long)count];
    
    // 超过限制时显示红色提示
    if (count > 500) {
        self.descCountLabel.textColor = [UIColor systemRedColor];
    } else {
        self.descCountLabel.textColor = [UIColor systemGray4Color];
    }
}

#pragma mark - 图标选择相关
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    
    if (selectedImage) {
        self.appIconView.image = selectedImage;
        
        self.selectappIconImage = selectedImage;;
        [self updateStatusLabel];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 工具方法
- (UITextField *)createTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *textField = [[UITextField alloc] init];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.placeholder = placeholder;
    textField.font = [UIFont systemFontOfSize:16];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    return textField;
}

- (UILabel *)createTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor labelColor];
    return label;
}

#pragma mark - 导航栏事件
- (void)cancelPublish {
    if ([self hasUnsavedChanges]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"有未保存的内容，确定要取消吗？"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存草稿 - 退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self saveDraft];
            [self dismiss];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"直接退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self dismiss];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self dismiss];
    }
}

// 检查是否有未保存的修改
- (BOOL)hasUnsavedChanges {
    return self.appNameField.text.length > 0 ||
    self.bundleIDField.text.length > 0 ||
    self.descriptionTextView.text.length > 0 ||
    self.selectedTags.count > 0 ;
}


#pragma mark - 更新后的HXPhotoManager配置

- (HXPhotoManager *)manager {
    if (!_manager) {
        // 创建弱引用
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.maxNum = 12;
        _manager.configuration.photoMaxNum = 0;
        _manager.configuration.videoMaxNum = 0;
        _manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit =YES;//视频过大自动跳转编辑
        _manager.configuration.videoMaximumDuration = 60;//视频最大时长
        _manager.configuration.saveSystemAblum = YES;//是否保存系统相册
        _manager.configuration.lookLivePhoto = YES; //是否开启查看LivePhoto功能呢 - 默认 NO
        _manager.configuration.photoCanEdit = YES;
        _manager.configuration.photoCanEdit = YES;
        _manager.configuration.videoCanEdit = YES;
        _manager.configuration.selectTogether = YES;//同时选择视频图片
        _manager.configuration.showOriginalBytes =YES;//原图显示大小
        _manager.configuration.showOriginalBytesLoading =YES;
        _manager.configuration.requestOriginalImage = NO;//默认非圆图
        _manager.configuration.clarityScale = 2.0f;
        _manager.configuration.allowPreviewDirectLoadOriginalImage =NO;//预览大图时允许不先加载小图，直接加载原图
        _manager.configuration.livePhotoAutoPlay =NO;//查看LivePhoto是否自动播放，为NO时需要长按才可播放
        _manager.configuration.replacePhotoEditViewController = NO;
        _manager.configuration.editAssetSaveSystemAblum = YES;
        _manager.configuration.customAlbumName = @"TrollApps";
        
    }
    return _manager;
}

- (void)addAssModelToManagerWith:(NSArray *)screenshotUrls ipadScreenshotUrls:(NSArray *)ipadScreenshotUrls{
    [self.manager clearSelectedList];
    if (self.manager.afterSelectPhotoCountIsMaximum) {
        [self.view hx_showImageHUDText:@"图片已达到最大数"];
        return;
    }
    NSMutableArray <HXCustomAssetModel *>*assets = [NSMutableArray array];
    for (NSString *url in screenshotUrls) {
        HXCustomAssetModel *asset = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:url] selected:YES];
        [assets addObject:asset];
    }
    for (NSString *url in ipadScreenshotUrls) {
        HXCustomAssetModel *asset = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:url] selected:YES];
        [assets addObject:asset];
    }
    
    [self.manager addCustomAssetModel:assets];
    self.photoView.manager = self.manager;
    [self.photoView refreshView];
}

/**
 * 从HXPhotoModel中获取正确的资源URL
 */
- (NSURL *)getURLFromPhotoModel:(HXPhotoModel *)model {
    if (!model) return nil;
    
    // 1. 处理图片类型（区分本地/网络）
    if (model.type == HXPhotoModelMediaTypePhoto) {
        // 优先处理本地图片（有asset或imageURL）
        if (model.asset) {
            // 本地相册图片：使用imageURL（需通过request方法获取，这里直接返回已获取的路径）
            return model.imageURL;
        } else if (model.imageURL) {
            // 已缓存的本地图片路径
            return model.imageURL;
        }
        // 网络图片：使用networkPhotoUrl
        else if (model.networkPhotoUrl) {
            return model.networkPhotoUrl;
        }
    }
    // 2. 处理视频类型（区分本地/网络）
    else if (model.type == HXPhotoModelMediaTypeVideo) {
        // 本地视频：使用videoURL（需通过export方法获取，这里返回已导出的路径）
        if (model.asset) {
            return model.videoURL;
        }
        // 网络视频：直接使用videoURL（网络视频初始化时会赋值）
        else if (model.videoURL) {
            return model.videoURL;
        }
    }
    // 3. 处理LivePhoto（特殊类型）
    else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        // LivePhoto的视频部分
        if (model.livePhotoVideoURL) {
            return model.livePhotoVideoURL;
        }
        // LivePhoto的图片部分
        else if (model.networkPhotoUrl) {
            return model.networkPhotoUrl;
        }
    }
    
    return nil;
}

#pragma mark - 商店搜索点击后回调

- (void)didSelectAppModel:(ITunesAppModel *)model {
    if(!model)return;
    self.iTunesAppModel = model;
    self.app_info.track_id = self.iTunesAppModel.trackId;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"使用此App数据填充"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if(model.trackName.length > 0){
            self.appNameField.text = model.trackName;
        }
        if(model.bundleId.length > 0){
            self.bundleIDField.text = model.bundleId;
        }
        
        // 限制文字长度为500字
        if (model.appDescription.length > 0) {
            NSString *originalText = model.appDescription;
            // 判断是否超过500字
            if (originalText.length > 500) {
                // 截断到前500字
                NSString *truncatedText = [originalText substringToIndex:500];
                self.descriptionTextView.text = truncatedText;
            } else {
                // 未超过则直接赋值
                self.descriptionTextView.text = originalText;
            }
        }
        //软件截图 不添加
        //        if(model.screenshotUrls.count > 0 || model.ipadScreenshotUrls.count>0){
        //            [self addAssModelToManagerWith:model.screenshotUrls ipadScreenshotUrls:model.ipadScreenshotUrls];
        //        }
        if(model.artworkUrl512.length > 0 ){
            [self.appIconView sd_setImageWithURL:[NSURL URLWithString:model.artworkUrl512] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if(image){
                    //赋值给头像上传
                    self.selectappIconImage = image;
                }
            }];
        }
        [self dismiss];
    }]];
    
    [[self.view getTopViewController] presentViewController:alert animated:YES completion:nil];
    
    
}

#pragma mark -  用AppInfo数据填充UI（更新软件时使用）

/// 用AppInfo数据填充UI（更新软件时使用）
- (void)fillUIWithAppInfo:(AppInfoModel *)appInfo {
    NSLog(@"用AppInfo数据填充UI（更新软件时使用）更新软件:%@",appInfo.app_name);
    if (!appInfo) return;
    
    // 1. 应用名称
    self.appNameField.text = appInfo.app_name;
    
    // 2. BundleID（不可修改，更新时保持不变）
    self.bundleIDField.text = appInfo.bundle_id;
    self.bundleIDField.enabled = NO; // 更新时禁止修改BundleID
    self.bundleIDField.alpha = 0.7;
    
    // 3. 应用类型
    self.appTypeSegment.selectedSegmentIndex = appInfo.app_type;
    
    // 4. 应用描述
    self.descriptionTextView.text = appInfo.app_description ?: @"";
    [self textViewDidChange:self.descriptionTextView]; // 触发字数统计更新
    
    // 5. 选中标签
    [self.selectedTags removeAllObjects];
    [self.selectedTags addObjectsFromArray:appInfo.tags ?: @[]];
    // 更新标签按钮状态
    [self updateTagButtonsState];
    
    // 6. 应用图标
    if (appInfo.appIcon) {
        self.appIconView.image = appInfo.appIcon;
    } else if (appInfo.icon_url.length > 0) {
        // 从网络加载图标
        [self.appIconView sd_setImageWithURL:[NSURL URLWithString:appInfo.icon_url]
                            placeholderImage:[UIImage systemImageNamed:@"photo.fill"]];
    }
    self.appIconView.contentMode = UIViewContentModeScaleAspectFit;
    // 7. 媒体文件（图片/视频）
    if (appInfo.fileNames.count > 0) {
        [self loadMediaFilesFromAppInfo:appInfo];
    }
    
    // 8. 调整发布按钮文字
    [self.publishButton setTitle:@"更新应用" forState:UIControlStateNormal];
}

/// 同步标签按钮的选中状态
- (void)updateTagButtonsState {
    for (UIButton *tagBtn in self.tagButtons) {
        NSString *tagText = tagBtn.titleLabel.text;
        tagBtn.selected = [self.selectedTags containsObject:tagText];
        tagBtn.backgroundColor = tagBtn.selected ? [UIColor blueColor] : [UIColor whiteColor];
    }
}


/// 从AppInfo加载媒体文件并记录原始URL
- (void)loadMediaFilesFromAppInfo:(AppInfoModel *)appInfo {
    //清除本地
    [self.manager clearSelectedList];
    
    //新建模型数组
    NSMutableArray<HXCustomAssetModel *> *assets = [NSMutableArray array];
    
    // 创建文件名到URL的映射，用于快速查找缩略图
    NSMutableDictionary<NSString *, NSString *> *fileNameToURLMap = [NSMutableDictionary dictionary];
    for (NSString *fileName in appInfo.fileNames) {
        NSString *urlString = [NSString stringWithFormat:@"%@/%@%@",localURL, self.app_info.save_path, fileName];
        [fileNameToURLMap setObject:urlString forKey:fileName];
    }
    
    //遍历
    for (NSString *fileName in appInfo.fileNames) {
        //排除主图图标
        if([fileName containsString:@"icon.png"]) continue;
        
        //封装完整URL
        NSString *urlString = [NSString stringWithFormat:@"%@/%@%@",localURL, self.app_info.save_path, fileName];
        
        // 排除缩略图文件
        if ([fileName containsString:@"thumbnail"]) {
            NSLog(@"跳过缩略图文件：%@", fileName);
            continue;
        }
        
        //判断URL合法
        NSURL *fileURL = [NSURL URLWithString:urlString];
        if (!fileURL) continue;
        
        // 创建网络资源模型
        HXCustomAssetModel *asset;
        if ([FileUtils isImageFileWithURL:fileURL]) {
            asset = [HXCustomAssetModel assetWithNetworkImageURL:fileURL selected:YES];
        } else if ([FileUtils isVideoFileWithURL:fileURL]) {
            // 根据视频文件名查找对应的缩略图
            NSString *thumbnailURLString = nil;
            CGFloat videoDuration = 0;
            
            // 获取视频文件名（不含扩展名）
            NSString *videoNameWithoutExt = [fileName stringByDeletingPathExtension];
            
            // 构建可能的缩略图文件名
            NSString *expectedThumbnailName = [NSString stringWithFormat:@"%@_thumbnail", videoNameWithoutExt];
            
            // 在映射中查找匹配的缩略图
            for (NSString *possibleThumbnailName in fileNameToURLMap.keyEnumerator) {
                if ([possibleThumbnailName containsString:expectedThumbnailName] &&
                    [possibleThumbnailName containsString:@"thumbnail"] &&
                    [FileUtils isImageFileWithURL:[NSURL URLWithString:fileNameToURLMap[possibleThumbnailName]]]) {
                    thumbnailURLString = fileNameToURLMap[possibleThumbnailName];
                    
                    // 从缩略图文件名中提取时长信息
                    NSArray *components = [possibleThumbnailName componentsSeparatedByString:@"_thumbnail_"];
                    if (components.count == 2) {
                        NSString *durationPart = [components[1] stringByDeletingPathExtension];
                        videoDuration = [durationPart floatValue];
                        NSLog(@"从文件名提取视频时长: %@ -> %.1f秒", possibleThumbnailName, videoDuration);
                    }
                    break;
                }
            }
            
            // 如果找到缩略图，使用它；否则使用默认值
            NSURL *thumbnailURL = thumbnailURLString ? [NSURL URLWithString:thumbnailURLString] : [NSURL URLWithString:@""];
            
            // 视频（使用找到的缩略图URL和提取的时长）
            asset = [HXCustomAssetModel assetWithNetworkVideoURL:fileURL
                                                   videoCoverURL:thumbnailURL
                                                   videoDuration:videoDuration
                                                        selected:YES];
        } else {
            continue; // 非图片和视频文件跳过
        }
        
        if (asset) [assets addObject:asset];
    }
    
    NSLog(@"HXCustomAssetModelassets:%@", assets);
    [self.manager addCustomAssetModel:assets];
    self.photoView.manager = self.manager;
    [self.photoView refreshView];
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    NSLog(@"判断页面更新还是发布:%@",self.category == CategoryTypePublish ? @"更新":@"发布新软件");
    if (self.category == CategoryTypeUpdate) {
        [self fillUIWithAppInfo:self.app_info];
        self.titleLabel.text = @"更新应用"; // 更新标题
    }
}

#pragma mark - 发布流程处理 ==================
// 发布流程
- (void)startPublishProcess {
    // 创建一个任务
    [self createUploadTask];
    
    [SVProgressHUD showWithStatus:self.category ? @"正在准备发布..." : @"正在准备更新..."];
    NSLog(@"当前照片管理数组:%@",self.manager.afterSelectedArray);
    NSLog(@"云端附件列表:%@",self.app_info.fileNames);
    
    // 1. 转换HXPhotoModel数组为URL数组（所有图片视频媒体文件URL ）
    if(!self.fileArray){
        self.fileArray = [NSMutableArray array];//其他附件
    }
    if(!self.mediaArray){
        self.mediaArray = [NSMutableArray array];//视频图片
    }
    
    
    // 2. 处理本地选择的媒体列表，生成最新附件列表
    for (NSString *fileName in self.app_info.fileNames) {
        NSURL *url = [NSURL URLWithString:fileName];
        BOOL isImageURL = [self isImageURL:url];
        BOOL isVideoURL = [self isVideoURL:url];
        //不是图片或者视频就是其他附件
        if(!isImageURL && !isVideoURL){
            [self.fileArray addObject:fileName];
        }
        //添加主题图片(例外)
        if(isImageURL && [fileName containsString:@"icon.png"]){
            [self.mediaArray addObject:fileName];
        }
    }
    NSLog(@"其他附件:%@",self.fileArray);
    
    // 创建一个dispatch_group来跟踪所有异步操作
    dispatch_group_t group = dispatch_group_create();
    
    NSArray<HXPhotoModel *> *selectedMedias = self.manager.afterSelectedArray;
    
    // 标记是否有错误发生
    __block BOOL hasError = NO;
    
    for (HXPhotoModel *model in selectedMedias) {
        // 进入一个异步操作
        dispatch_group_enter(group);
        
        [self getMediaURLFromModel:model completion:^(NSURL *url) {
            if (url) {
                NSString *fileName = [url lastPathComponent];
                NSLog(@"遍历媒体附件:%@",fileName);
                NSString *scheme = url.scheme.lowercaseString;
                if ([scheme isEqualToString:@"file"]) {
                    // 本地新增附件：添加到列表
                    NSError *error;
                    NSData *fileData = [NSData dataWithContentsOfURL:url options:0 error:&error];
                    if(fileData && !error){
                        // 如果是发布新软件 附带版本号1
                        if(self.category == CategoryTypePublish){
                            fileName = [NSString stringWithFormat:@"1_%@",fileName];
                        } else {
                            // 如果是更新新软件 附带旧版本号+1
                            fileName = [NSString stringWithFormat:@"%ld_%@",self.app_info.current_version_code+1,fileName];
                        }
                        // 添加到上传列表
                        NSLog(@"添加到上传列表:%@",fileName);
                        [[UploadManager sharedManager] addFileData:fileData fileName:fileName toTask:self.uploadTask];
                        
                        // 检查是否为视频文件，如果是则生成并上传缩略图
                        if ([self isVideoURL:url]) {
                            dispatch_group_enter(group); // 为缩略图操作增加一个异步任务
                            
                            [self generateVideoThumbnailDataWithURL:url completion:^(NSData *thumbnailData, NSString *thumbnailFileName, NSNumber *duration) {
                                if (thumbnailData && thumbnailFileName) {
                                    // 为缩略图添加版本号前缀
                                    NSString *versionedThumbnailName;
                                    if(self.category == CategoryTypePublish){
                                        versionedThumbnailName = [NSString stringWithFormat:@"1_%@", thumbnailFileName];
                                    } else {
                                        versionedThumbnailName = [NSString stringWithFormat:@"%ld_%@", self.app_info.current_version_code+1, thumbnailFileName];
                                    }
                                    NSLog(@"缩略图versionedThumbnailName：%@",versionedThumbnailName);
                                    NSLog(@"缩略图thumbnailData：%@",thumbnailData);
                                    // 上传缩略图
                                    [[UploadManager sharedManager] addFileData:thumbnailData
                                                                      fileName:versionedThumbnailName
                                                                        toTask:self.uploadTask];
                                    
                                    // 将缩略图文件名添加到媒体数组
                                    [self.mediaArray addObject:versionedThumbnailName];
                                    
                                    
                                    NSLog(@"视频缩略图已添加到上传列表: %@", versionedThumbnailName);
                                } else {
                                    NSLog(@"生成视频缩略图失败: %@", fileName);
                                }
                                
                                dispatch_group_leave(group); // 缩略图操作完成
                            }];
                        }
                    } else {
                        NSLog(@"读取文件数据失败: %@", error.localizedDescription);
                        hasError = YES;
                    }
                }
                NSLog(@"添加到mediaArray:%@",fileName);
                [self.mediaArray addObject:fileName];
            } else {
                NSLog(@"获取媒体URL失败");
                hasError = YES;
            }
            
            // 离开一个异步操作
            dispatch_group_leave(group);
        }];
    }
    
    // 当所有异步操作完成时执行
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (hasError) {
            [SVProgressHUD showErrorWithStatus:@"获取部分媒体文件失败"];
            return;
        }
        
        // 合并附件和媒体
        NSArray *allFileNames = [self.mediaArray arrayByAddingObjectsFromArray:self.fileArray];
        self.app_info.fileNames = [NSMutableArray arrayWithArray:allFileNames];
        
        // 2.1 将头像转换为临时URL（插入下标0）
        if (self.appIconView.image && self.selectappIconImage) {
            //移除旧的图标
            for (NSString *name in self.app_info.fileNames) {
                if([name containsString:@"icon.png"]){
                    [self.app_info.fileNames removeObject:name];
                }
            }
            // 如果修改了头像 上传到上传管理
            NSData *iconData = UIImageJPEGRepresentation(self.selectappIconImage,0.5);
            NSString *tempIconPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"icon.png"];
            [iconData writeToFile:tempIconPath atomically:YES];
            NSURL *iconURL = [NSURL fileURLWithPath:tempIconPath];
            NSData *fileData = [NSData dataWithContentsOfURL:iconURL];
            NSString *fileName = @"1_icon.png";
            if(self.category == CategoryTypeUpdate){
                fileName = [NSString stringWithFormat:@"%ld_icon.png",self.app_info.current_version_code+1];
            }
            [[UploadManager sharedManager] addFileData:fileData fileName:fileName toTask:self.uploadTask];
            //添加新头像
            [self.app_info.fileNames addObject:fileName];
        }
        
        NSLog(@"最终上传的文件列表:%@",self.app_info.fileNames);
        
        // 执行上传
        [self uploadAppInfo];
    });
}

#pragma mark - 任务检查和恢复
// 检查是否有未完成的任务
- (void)checkPendingTasks {
    // 从本地加载未完成的任务
    if (self.category == CategoryTypeUpdate && self.app_info) {
        // 更新模式，查找对应应用ID的任务
        self.uploadTask = [[TaskManager sharedManager] getTaskByAppID:self.app_info.app_id];
        NSLog(@"更新模式，查找对应应用ID的任务:task_id%@ app_id:%ld  app_name:%@",self.uploadTask.task_id,self.uploadTask.app_id,self.uploadTask.app_name);
    } else {
        // 发布模式，查找最近的未完成任务
        NSArray *incompleteTasks = [[TaskManager sharedManager] getIncompleteTasks];
        NSLog(@"查找最近的未完成任务:%@",incompleteTasks);
        if (incompleteTasks.count > 0) {
            self.uploadTask = incompleteTasks[0];
            NSLog(@"有本地任务尚未完成：%@",self.uploadTask);
        }else{
            NSLog(@"遍历不到 准备新建");
            [self createUploadTask];
        }
    }
    if (self.uploadTask) {
        // 恢复任务状态
        [self updateUIWithTask:self.uploadTask];
    }
}

// 根据任务恢复UI
- (void)updateUIWithTask:(UploadTask *)task {
    if(!task) return;
    self.app_info = [AppInfoModel yy_modelWithDictionary:task.dictionary];
    NSLog(@"根据任务恢复UI app_info:%@",self.app_info.app_name);
   
    
    
    [self fillUIWithAppInfo:self.app_info];
    
    [self updateStatusLabel];
    self.progressView.progress = task.progress;
    
    if (task.status == UploadTaskStatusUploading) {
        self.isUploading = YES;
        [self.publishButton setTitle:@"暂停上传" forState:UIControlStateNormal];
    } else {
        self.isUploading = NO;
        [self.publishButton setTitle:self.category == CategoryTypePublish ? @"发布应用" : @"更新应用" forState:UIControlStateNormal];
    }
}

#pragma mark - 任务管理


// 上传应用信息（区分发布和更新）
- (void)uploadAppInfo {
    // 构建请求参数
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    NSLog(@"请求的UDID：%@",udid);
    self.app_info.udid = udid;
    self.app_info.idfv = [NewProfileViewController sharedInstance].userInfo.idfv;
    self.app_info.task_id = self.uploadTask.task_id;
    
    
    // 3. 完善AppInfo
    
    self.app_info.tags = self.selectedTags;
    self.app_info.app_name = self.appNameField.text;
    self.app_info.app_type = self.appTypeSegment.selectedSegmentIndex;
    self.app_info.app_description = self.descriptionTextView.text;
    self.app_info.bundle_id = self.bundleIDField.text;
    self.app_info.release_notes = self.releaseNotesTextView.text; // 假设添加了版本说明输入框
    
    // 4. 构建保存路径
    NSString *appTypeDir = [self appTypeDirectory];//获取文件类型字符串 IPA/DEB/ZIP
    NSInteger userId = [NewProfileViewController sharedInstance].userInfo.user_id;
    NSString *publishDate = [TimeTool stringFromDate:[NSDate date]];
    self.app_info.save_path = [NSString stringWithFormat:@"%@/%@/%ld", appTypeDir, publishDate, userId];
    
    
    
    NSDictionary *app_info = [self.app_info yy_modelToJSONObject];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:app_info];
    
    // 区分发布/更新
    if (self.category == CategoryTypePublish) {
        params[@"action"] = @"createApp";
        
    } else {
        params[@"action"] = @"updateVersion";
    }
    
    params[@"udid"] = udid;
    NSLog(@"准备请求字典:%@",params);
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/app_api.php",localURL]
                                             parameters:params udid:self.app_info.udid
                                               progress:^(NSProgress *progress) {
        NSLog(@"完成比例: %.2f%%", progress.fractionCompleted * 100);
        NSLog(@"已完成: %lld 字节", progress.completedUnitCount);
        NSLog(@"总大小: %lld 字节", progress.totalUnitCount);
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"发送返回jsonResult:%@",jsonResult);
        NSLog(@"发送返回stringResult:%@",stringResult);
        NSLog(@"发送返回dataResult:%@",dataResult);
        if(!jsonResult){
            [SVProgressHUD showErrorWithStatus:@"JSON解析错误"];
            [SVProgressHUD dismissWithDelay:3];
            return;
        }
        NSString *status = jsonResult[@"status"];
        NSString *msg = jsonResult[@"msg"];
        
        if([status isEqualToString:@"success"]){
            NSDictionary *appInfo = jsonResult[@"appInfo"];
            NSLog(@"上传app信息后返回：%@",appInfo);
            if(appInfo){
                
                self.app_info = [AppInfoModel yy_modelWithDictionary:appInfo];
                NSLog(@"赋值app_info：%ld",self.app_info.app_id);
                self.uploadTask.app_id = self.app_info.app_id;
                self.uploadTask.app_name = self.app_info.app_name;
                self.uploadTask.task_id = self.app_info.task_id;
                self.uploadTask.dictionary = appInfo;
                
                
                NSLog(@"上传配置信息后返回.fileItems：%@",self.uploadTask.fileItems);
                
                [SVProgressHUD showSuccessWithStatus:msg];
                [SVProgressHUD dismissWithDelay:0.3 completion:^{
                    [self startUpload];
                }];
            }
            
        }else{
            [SVProgressHUD showErrorWithStatus:msg];
            [SVProgressHUD dismissWithDelay:3];
        }
        
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

//开始上传新任务
- (void)startUpload {
    NSLog(@"开始上传新任务");
    // 确保有上传任务 如果不存在 就创建一个任务
    if (!self.uploadTask) {
        NSLog(@"不存在上传任务 应该在页面打开的时候就初始化或者读取上次未完成任务");
        
    }
    
    // 验证表单
    if (![self hasUnsavedChanges]) {
        return;
    }
    
    self.isUploading = YES;
    [self.publishButton setTitle:@"暂停上传" forState:UIControlStateNormal];
    
    // 获取用户信息
    self.uploadTask.udid = [NewProfileViewController sharedInstance].userInfo.udid;
    self.uploadTask.idfv = [NewProfileViewController sharedInstance].userInfo.idfv;
    
    // 开始上传
    NSLog(@"开始上传fileItems:%@",self.uploadTask.fileItems);
    
    [[UploadManager sharedManager] startTask:self.uploadTask progress:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
            NSLog(@"上传进度:%f",progress);
            [self updateStatusLabel];
        });
    } success:^(NSDictionary *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:self.category == CategoryTypePublish ? @"应用发布成功" : @"应用更新成功"];
            [SVProgressHUD dismissWithDelay:1 completion:^{
                [self dismiss];
            }];
            
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            [SVProgressHUD dismissWithDelay:3 completion:^{
                
            }];
            
            self.isUploading = NO;
            [self.publishButton setTitle:self.category == CategoryTypePublish ? @"发布应用" : @"更新应用" forState:UIControlStateNormal];
            [self updateStatusLabel];
        });
    }];
    
    
    
}

// 暂停上传任务
- (void)pauseUpload {
    self.isUploading = NO;
    [self.publishButton setTitle:self.category == CategoryTypePublish ? @"发布应用" : @"更新应用" forState:UIControlStateNormal];
    
    // 暂停上传任务
    [[UploadManager sharedManager] pauseTask:self.uploadTask];
    [self updateStatusLabel];
}

// 创建新的上传任务
- (void)createUploadTask {
    // 创建新的上传任务
    
    NSDictionary *dictionary = [self.app_info yy_modelToJSONObject];
    NSLog(@"创建新的上传任务app_info:%@",dictionary);
    
    self.uploadTask = [[UploadManager sharedManager] createTaskWithAppName:self.appNameField.text
                                                                  bundleID:self.bundleIDField.text
                                                               versionName:@"1.0.0"
                                                              releaseNotes:@"首次发布版本"
                                                                      tags:self.selectedTags
                                                                      udid:[NewProfileViewController sharedInstance].userInfo.udid
                                                                      idfv:[NewProfileViewController sharedInstance].userInfo.idfv
                                                                dictionary:dictionary];
    NSLog(@"创建新的上传任务uploadTask:%@",self.uploadTask);
    
    // 如果是更新模式，设置appID
    if (self.category == CategoryTypeUpdate && self.app_info) {
        self.uploadTask.app_id = self.app_info.app_id;
    }
}

//更新任务UI
- (void)updateStatusLabel {
    NSString *mesage = nil;
    if (!self.uploadTask) {
        mesage = @"准备上传";
    }
    
    if (self.isUploading) {
        NSInteger completedCount = 0;
        for (UploadFileItem *fileItem in self.uploadTask.fileItems) {
            if (fileItem.status == UploadFileStatusCompleted) {
                completedCount++;
            }
        }
        mesage = [NSString stringWithFormat:@"上传中 %ld/%ld", completedCount, self.uploadTask.fileItems.count];
    } else {
        switch (self.uploadTask.status) {
            case UploadTaskStatusReady:
                mesage = @"准备上传";
                break;
            case UploadTaskStatusUploading:
                mesage = @"上传中 (已暂停)";
                
                break;
            case UploadTaskStatusPaused:
                mesage = @"已暂停";
                
                break;
            case UploadTaskStatusCompleted:
                mesage = @"上传完成";
                
                break;
            case UploadTaskStatusFailed:
                mesage = @"上传失败";
                
                break;
            default:
                mesage = @"未知状态";
                
                break;
        }
    }
    
    
    [SVProgressHUD showWithStatus:mesage];
    [SVProgressHUD dismissWithDelay:1];
    
}

#pragma mark - 辅助函数

- (NSString *)appTypeDirectory {
    switch (self.app_info.app_type) {
        case 0: return @"ipa";
        case 1: return @"deb";
        case 2: return @"zip";
        default: return @"other";
    }
}

- (void)dealloc {
    // 暂停上传任务
    if (self.isUploading && self.uploadTask) {
        //        [[UploadManager sharedManager] pauseTask:self.uploadTask];
    }
}



#pragma mark - 辅助方法：提取文件名（仅文件名.后缀）

// 从模型中获取媒体的URL（区分图片/视频）
- (void)getMediaURLFromModel:(HXPhotoModel *)model completion:(void(^)(NSURL *url))completion {
    // 根据媒体子类型获取对应URL
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        // 图片：优先用本地URL，无则用网络URL
        if (model.imageURL) {
            NSLog(@"本地图URL...直接返回:%@",model.imageURL);
            completion(model.imageURL);
        } else if (model.networkPhotoUrl) {
            NSLog(@"网络图URL...直接返回:%@",model.networkPhotoUrl);
            completion(model.networkPhotoUrl);
        } else {
            // 本地相册图片：通过方法获取URL
            [model requestImageURLStartRequestICloud:^(PHContentEditingInputRequestID requestId, HXPhotoModel *model) {
                NSLog(@"正在获取本地图片URL...");
            } progressHandler:^(CGFloat progress, HXPhotoModel *model) {
                NSLog(@"获取进度：%.2f", progress);
            } success:^(NSURL *imageURL, HXPhotoModel *model, NSDictionary *info) {
                NSLog(@"正在获取本地图片URL...直接返回:%@",imageURL);
                completion(imageURL);
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                NSLog(@"else正在获取本地图片URL...错误返回:%@",info);
                completion(nil);
            }];
        }
    } else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        // 视频：优先用本地视频URL，无则用网络URL
        if (model.videoURL && [model.videoURL.scheme.lowercaseString isEqualToString:@"file"]) {
            NSLog(@"本地视频URL...返回:%@",model.videoURL);
            completion(model.videoURL);
        } else if (model.networkPhotoUrl) { // 网络视频可能存储在networkPhotoUrl
            NSLog(@"网络视频URL...返回:%@",model.networkPhotoUrl);
            completion(model.networkPhotoUrl);
        } else {
            // 本地相册视频：导出URL
            [model exportVideoWithPresetName:AVAssetExportPresetMediumQuality
                          startRequestICloud:^(PHImageRequestID requestId, HXPhotoModel *model) {
                NSLog(@"正在导出本地视频...");
            } iCloudProgressHandler:^(CGFloat progress, HXPhotoModel *model) {
                NSLog(@"iCloud下载进度：%.2f", progress);
            } exportProgressHandler:^(float progress, HXPhotoModel *model) {
                NSLog(@"导出进度：%.2f", progress);
            } success:^(NSURL *videoURL, HXPhotoModel *model) {
                NSLog(@"导出本地视频URL...返回:%@",model.videoURL);
                completion(videoURL);
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                NSLog(@"导出本地视频URL出错...返回info:%@",info);
                completion(nil);
            }];
        }
    } else {
        // 不支持的媒体类型
        NSLog(@"不支持的媒体类型");
        completion(nil);
    }
}

// 辅助方法：判断URL是否为媒体文件（图片/视频）
- (BOOL)isImageURL:(NSURL *)url {
    NSString *pathExtension = url.pathExtension.lowercaseString;
    // 图片格式
    NSArray *imageExts = @[@"jpg", @"jpeg", @"png", @"gif", @"heic"];
    
    return [imageExts containsObject:pathExtension];
}
// 辅助方法：判断URL是否为媒体文件（图片/视频）
- (BOOL)isVideoURL:(NSURL *)url {
    NSString *pathExtension = url.pathExtension.lowercaseString;
   
    // 视频格式
    NSArray *videoExts = @[@"mp4", @"mov", @"avi", @"mkv", @"flv"];
    return [videoExts containsObject:pathExtension];
}

/// 照片/视频发生改变、HXPohotView初始化、manager赋值时调用 - 选择、移动顺序、删除、刷新视图
/// 调用 refreshView 会触发此代理
- (void)photoViewChangeComplete:(HXPhotoView *)photoView
                   allAssetList:(NSArray<PHAsset *> *)allAssetList
                    photoAssets:(NSArray<PHAsset *> *)photoAssets
                    videoAssets:(NSArray<PHAsset *> *)videoAssets
                       original:(BOOL)isOriginal {
    NSLog(@"photoViewChangeComplete:%ld",allAssetList.count);
    NSLog(@"afterSelectedArray:%ld",self.manager.afterSelectedArray.count);
    
}

/**
 生成视频缩略图、时长并通过回调返回结果（文件名包含原始视频名）
 
 @param videoURL 视频文件URL
 @param completion 回调block，返回三个参数：
                   thumbnailData: 缩略图的NSData
                   fileName: 生成的缩略图文件名(原始视频名_thumbnail_时长.png)
                   duration: 视频时长(秒，NSNumber)
 */
- (void)generateVideoThumbnailDataWithURL:(NSURL *)videoURL
                               completion:(void(^)(NSData *thumbnailData,
                                                  NSString *fileName,
                                                  NSNumber *duration))completion {
    // 校验视频URL
    if (!videoURL) {
        NSLog(@"错误：视频URL为空");
        if (completion) completion(nil, nil, nil);
        return;
    }
    
    // 1. 获取原始视频文件名（不含扩展名）
    NSString *originalFileName = [videoURL lastPathComponent];
    // 移除扩展名（例如"2_xxx.mp4" -> "2_xxx"）
    NSString *originalNameWithoutExt = [originalFileName stringByDeletingPathExtension];
    
    // 异步处理视频解析（避免阻塞主线程）
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 2. 获取视频资源
        AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
        
        // 3. 计算视频时长（秒）
        CMTime videoDuration = videoAsset.duration;
        CGFloat durationSeconds = CMTimeGetSeconds(videoDuration);
        NSNumber *duration = @(durationSeconds);
        
        // 4. 生成缩略图（取视频第一帧）
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:videoAsset];
        imageGenerator.appliesPreferredTrackTransform = YES; // 保持视频方向正确
        imageGenerator.maximumSize = CGSizeMake(300, 0); // 限制宽度为200，高度自适应
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        
        // 取视频第1秒处的帧（避免取0秒可能是黑屏的情况）
        CMTime thumbnailTime = CMTimeMakeWithSeconds(0, 600);
        NSError *error = nil;
        CGImageRef thumbnailImageRef = [imageGenerator copyCGImageAtTime:thumbnailTime
                                                              actualTime:NULL
                                                                   error:&error];
        
        if (error || !thumbnailImageRef) {
            NSLog(@"生成缩略图失败：%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, nil, duration); // 即使失败也返回时长
            });
            return;
        }
        
        // 5. 处理缩略图数据
        UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef];
        CGImageRelease(thumbnailImageRef); // 释放CGImage资源
        NSData *thumbnailData = UIImagePNGRepresentation(thumbnailImage);
        
        // 6. 生成规范文件名（包含原始视频名+时长）
        // 格式：原始文件名_thumbnail_时长.png（例如"2_xxx_thumbnail_1.6.png"）
        NSString *formattedDuration = [NSString stringWithFormat:@"%.1f", durationSeconds];
        formattedDuration = [formattedDuration stringByReplacingOccurrencesOfString:@":" withString:@"_"];
        NSString *fileName = [NSString stringWithFormat:@"%@_thumbnail_%@.png", originalNameWithoutExt, formattedDuration];
        NSLog(@"缩略图fileName：%@", fileName);
        
        // 7. 主线程回调结果
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(thumbnailData, fileName, duration);
            }
        });
    });
}


//输入框和键盘高度
- (CGFloat)keyboardOffsetFromInputView{
    return 100;
}


#pragma mark - 文件上传选择文件代理 UIDocumentPickerDelegate

#pragma mark - 文件上传选择文件代理 UIDocumentPickerDelegate
// 处理文件选择完成（支持多文件+去重）
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (urls.count == 0) {
        [SVProgressHUD showErrorWithStatus:@"未选择文件"];
        return;
    }
    
    // 初始化文件数组（若为nil）
    if (!self.fileArray) {
        self.fileArray = [NSMutableArray array];
    }
    
    // 1. 循环处理每个选中的文件
    for (NSURL *selectedFileURL in urls) {
        // 检查是否有权限访问文件
        BOOL canAccess = [selectedFileURL startAccessingSecurityScopedResource];
        if (!canAccess) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"无法访问文件: %@", selectedFileURL.lastPathComponent]];
//            continue; // 跳过当前文件，处理下一个
        }
        
        // 2. 获取文件基本信息
        NSString *fileName = [selectedFileURL lastPathComponent];
        NSString *fileType = [selectedFileURL pathExtension].lowercaseString;
        NSError *error = nil;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:selectedFileURL.path error:&error];
        NSNumber *fileSize = fileAttributes[NSFileSize];
        
        // 日志输出当前处理的文件
        NSLog(@"处理文件: %@, 类型: %@, 大小: %@ bytes", fileName, fileType, fileSize);
        
        // 3. 校验文件是否已存在（去重逻辑：通过文件路径的哈希值判断唯一性）
        NSString *fileUniqueKey = [self uniqueKeyForFileURL:selectedFileURL];
        if ([self isFileAlreadyAdded:fileUniqueKey]) {
            [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"文件已添加: %@", fileName]];
            [selectedFileURL stopAccessingSecurityScopedResource];
            continue; // 已存在，跳过
        }
        
        // 4. 校验文件大小
        if (fileSize.integerValue > MAX_FILE_SIZE) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"文件过大（最大支持%ldMB）: %@",
                                               (long)(MAX_FILE_SIZE / 1024 / 1024), fileName]];
            [selectedFileURL stopAccessingSecurityScopedResource];
            continue;
        }
        
        // 5. 校验文件格式
        NSSet *allowedFileTypes = [NSSet setWithObjects:
                                   // 图片格式
                                   @"jpg", @"jpeg", @"png", @"gif", @"bmp", @"heic", @"heif",
                                   // 视频格式
                                   @"mp4", @"mov", @"avi", @"m4v", @"mpg", @"mpeg", @"flv", @"wmv",
                                   // 其他指定格式
                                   @"ipa", @"ipas", @"zip", @"js", @"html", @"json", @"deb", @"sh",
                                   nil];
        
        if (![allowedFileTypes containsObject:fileType]) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"不支持的格式: .%@（文件: %@）", fileType, fileName]];
            [selectedFileURL stopAccessingSecurityScopedResource];
            continue;
        }
        
        // 6. 为文件生成系统图标
        UIImage *fileIcon = [self generateFileIconWithURL:selectedFileURL fileType:fileType];
        
        // 7. 封装文件信息字典（包含唯一标识用于去重）
        NSDictionary *fileInfo = @{
            @"uniqueKey": fileUniqueKey, // 用于后续去重判断
            @"url": selectedFileURL,
            @"name": fileName,
            @"type": fileType,
            @"size": fileSize ?: @0, // 防止size为nil
            @"icon": fileIcon
        };
        
        // 8. 添加到文件数组
        [self.fileArray addObject:fileInfo];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"已添加文件: %@", fileName]];
        
        // 释放当前文件的安全访问权限
        [selectedFileURL stopAccessingSecurityScopedResource];
    }
}

#pragma mark - 辅助方法（去重+图标生成）

/**
 生成文件的唯一标识（基于文件路径的哈希值，避免因临时路径变化导致的误判）
 */
- (NSString *)uniqueKeyForFileURL:(NSURL *)fileURL {
    // 取文件路径的字符串，通过MD5哈希生成唯一标识（解决临时路径变化问题）
    NSString *filePath = fileURL.path;
    const char *str = [filePath UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *uniqueKey = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [uniqueKey appendFormat:@"%02X", result[i]];
    }
    return uniqueKey;
}

/**
 检查文件是否已添加到数组中（通过唯一标识判断）
 */
- (BOOL)isFileAlreadyAdded:(NSString *)uniqueKey {
    for (NSDictionary *existingFile in self.fileArray) {
        if ([existingFile[@"uniqueKey"] isEqualToString:uniqueKey]) {
            return YES; // 已存在
        }
    }
    return NO; // 未添加
}

// 处理文件选择取消
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        NSLog(@"用户取消了文件选择");
    }];
}

/**
 根据文件URL和类型生成系统默认图标
 @param fileURL 文件路径
 @param fileType 文件扩展名（如"ipa"、"zip"）
 @return 生成的图标（默认为通用文件图标）
 */
- (UIImage *)generateFileIconWithURL:(NSURL *)fileURL fileType:(NSString *)fileType {
    // 方法1：使用UIDocumentInteractionController获取文件图标（推荐，系统会根据文件类型返回对应图标）
    UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    UIImage *icon = docController.icons.lastObject; // 最后一个是最大的图标
    
    if (icon) {
        return icon;
    }
    
    // 方法2：如果方法1失败，根据文件类型手动指定图标
    if ([self isImageType:fileType]) {
        // 图片类型：返回通用图片图标
        return [UIImage systemImageNamed:@"photo"];
    } else if ([self isVideoType:fileType]) {
        // 视频类型：返回通用视频图标
        return [UIImage systemImageNamed:@"video"];
    } else if ([@"ipa" isEqualToString:fileType] || [@"ipas" isEqualToString:fileType]) {
        // IPA类型：返回应用图标
        return [UIImage systemImageNamed:@"app"];
    } else if ([@"zip" isEqualToString:fileType]) {
        // 压缩包类型：返回压缩包图标
        return [UIImage systemImageNamed:@"folder"];
    } else if ([@"js" isEqualToString:fileType] || [@"html" isEqualToString:fileType] || [@"json" isEqualToString:fileType]) {
        // 文本/代码类型：返回文档图标
        return [UIImage systemImageNamed:@"doc.text"];
    } else if ([@"deb" isEqualToString:fileType]) {
        // DEB包：返回包图标
        return [UIImage systemImageNamed:@"gear"];
    } else if ([@"sh" isEqualToString:fileType]) {
        // 脚本文件：返回终端图标
        return [UIImage systemImageNamed:@"terminal"];
    } else {
        // 其他类型：返回通用文件图标
        return [UIImage systemImageNamed:@"doc"];
    }
}

// 辅助方法：判断是否为图片类型
- (BOOL)isImageType:(NSString *)fileType {
    NSSet *imageTypes = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", @"bmp", @"heic", @"heif", nil];
    return [imageTypes containsObject:fileType];
}

// 辅助方法：判断是否为视频类型
- (BOOL)isVideoType:(NSString *)fileType {
    NSSet *videoTypes = [NSSet setWithObjects:@"mp4", @"mov", @"avi", @"m4v", @"mpg", @"mpeg", @"flv", @"wmv", nil];
    return [videoTypes containsObject:fileType];
}

@end
