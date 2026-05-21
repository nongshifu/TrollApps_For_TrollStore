//
//  FilePreviewViewController.m
//  SandboxFileManager
//
//  文件预览控制器实现
//

#import "FilePreviewViewController.h"
#import "FileModel.h"
#import "FileActionHandler.h"
#import "FileEnum.h"
#import "FileNotification.h"
#import "SandboxTool.h"
#import <AVFoundation/AVFoundation.h>
#import <QuickLook/QuickLook.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>

static NSString * const kPreviewCellIdentifier = @"PreviewCell";

@interface FilePreviewViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, QLPreviewControllerDataSource, QLPreviewControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) AVPlayerViewController *playerController;
@property (nonatomic, strong) QLPreviewController *quickLookController;
@property (nonatomic, strong) UICollectionView *thumbnailCollectionView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *pageLabel;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *fileIconView;
@property (nonatomic, strong) UILabel *fileInfoLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, assign) BOOL isPlaying;

@end

@implementation FilePreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.fileList.count > 0) {
        FileModel *firstModel = self.fileList.firstObject;
        self.currentDirPath = [firstModel.filePath stringByDeletingLastPathComponent];
    }
    
    [self setupUI];
    [self setupGestures];
    [self loadCurrentFile];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleFileListChangedNotification:)
                                                 name:kNotificationFileListChanged
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.playerController.player pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationFileListChanged object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.title = @"预览";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                               target:self
                                                                               action:@selector(closeButtonTapped)];
    

    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                 target:self
                                                                                 action:@selector(actionButtonTapped)];
    self.navigationItem.leftBarButtonItem = closeButton;
    self.navigationItem.rightBarButtonItem = actionButton;

    self.mainScrollView = [[UIScrollView alloc] init];
    self.mainScrollView.pagingEnabled = YES;
    self.mainScrollView.showsHorizontalScrollIndicator = NO;
    self.mainScrollView.delegate = self;
    self.mainScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mainScrollView];

    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainScrollView addSubview:self.containerView];

    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.clipsToBounds = YES;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.imageView];

    self.fileIconView = [[UIImageView alloc] init];
    self.fileIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.fileIconView.tintColor = [UIColor systemGrayColor];
    self.fileIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.fileIconView.hidden = YES;
    [self.containerView addSubview:self.fileIconView];

    self.fileInfoLabel = [[UILabel alloc] init];
    self.fileInfoLabel.font = [UIFont systemFontOfSize:14];
    self.fileInfoLabel.textColor = [UIColor secondaryLabelColor];
    self.fileInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.fileInfoLabel.numberOfLines = 0;
    self.fileInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fileInfoLabel.hidden = YES;
    [self.containerView addSubview:self.fileInfoLabel];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.containerView addSubview:self.loadingIndicator];

    self.playerController = [[AVPlayerViewController alloc] init];
    [self addChildViewController:self.playerController];
    self.playerController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.playerController.view.hidden = YES;
    [self.containerView addSubview:self.playerController.view];
    [self.playerController didMoveToParentViewController:self];

    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage systemImageNamed:@"play.circle.fill"] forState:UIControlStateNormal];
    self.playButton.tintColor = [UIColor whiteColor];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.playButton.hidden = YES;
    [self.playButton addTarget:self action:@selector(playButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.playButton];

    self.quickLookController = [[QLPreviewController alloc] init];
    self.quickLookController.dataSource = self;
    self.quickLookController.delegate = self;
    self.quickLookController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.quickLookController.view.hidden = YES;
    [self addChildViewController:self.quickLookController];
    [self.containerView addSubview:self.quickLookController.view];
    [self.quickLookController didMoveToParentViewController:self];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 16);

    self.thumbnailCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.thumbnailCollectionView.dataSource = self;
    self.thumbnailCollectionView.delegate = self;
    self.thumbnailCollectionView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.thumbnailCollectionView.showsHorizontalScrollIndicator = NO;
    self.thumbnailCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.thumbnailCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kPreviewCellIdentifier];
    [self.view addSubview:self.thumbnailCollectionView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    self.titleLabel.textColor = [UIColor secondaryLabelColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.pageLabel = [[UILabel alloc] init];
    self.pageLabel.font = [UIFont systemFontOfSize:11];
    self.pageLabel.textColor = [UIColor tertiaryLabelColor];
    self.pageLabel.textAlignment = NSTextAlignmentRight;
    self.pageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pageLabel];

    [self setupConstraints];
    [self updateUI];
}

- (void)setupConstraints {
    CGFloat thumbnailHeight = 80;

    [NSLayoutConstraint activateConstraints:@[
        [self.mainScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.mainScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mainScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mainScrollView.bottomAnchor constraintEqualToAnchor:self.thumbnailCollectionView.topAnchor constant:-10],

        [self.containerView.topAnchor constraintEqualToAnchor:self.mainScrollView.topAnchor],
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.mainScrollView.leadingAnchor],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.mainScrollView.trailingAnchor],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.mainScrollView.bottomAnchor],
        [self.containerView.widthAnchor constraintEqualToAnchor:self.mainScrollView.widthAnchor],
        [self.containerView.heightAnchor constraintEqualToAnchor:self.mainScrollView.heightAnchor],

        [self.imageView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.imageView.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],
        [self.imageView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.imageView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],

        [self.fileIconView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.fileIconView.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor constant:-30],
        [self.fileIconView.widthAnchor constraintEqualToConstant:100],
        [self.fileIconView.heightAnchor constraintEqualToConstant:100],

        [self.fileInfoLabel.topAnchor constraintEqualToAnchor:self.fileIconView.bottomAnchor constant:16],
        [self.fileInfoLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.fileInfoLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],

        [self.playerController.view.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
        [self.playerController.view.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.playerController.view.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [self.playerController.view.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],

        [self.playButton.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.playButton.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],
        [self.playButton.widthAnchor constraintEqualToConstant:80],
        [self.playButton.heightAnchor constraintEqualToConstant:80],

        [self.quickLookController.view.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
        [self.quickLookController.view.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.quickLookController.view.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [self.quickLookController.view.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],

        [self.thumbnailCollectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.thumbnailCollectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.thumbnailCollectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        [self.thumbnailCollectionView.heightAnchor constraintEqualToConstant:thumbnailHeight],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-60],

        [self.pageLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.pageLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.pageLabel.widthAnchor constraintEqualToConstant:50],
    ]];
}

- (void)setupGestures {
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipe];

    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.containerView addGestureRecognizer:longPress];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self showNextFile];
    } else if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        [self showPreviousFile];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }

    FileModel *model = self.fileList[self.currentIndex];
    NSString *extension = [model.filePath pathExtension].lowercaseString;

    if ([self isImageExtension:extension]) {
        [self showSaveImageAlert:model.filePath isVideo:NO];
    } else if ([self isVideoExtension:extension]) {
        [self showSaveImageAlert:model.filePath isVideo:YES];
    }
}

- (void)showSaveImageAlert:(NSString *)path isVideo:(BOOL)isVideo {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存到相册"
                                                                   message:isVideo ? @"确定保存视频到系统相册？" : @"确定保存图片到系统相册？"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (isVideo) {
            [self saveVideoToPhotoLibrary:path];
        } else {
            [self saveImageToPhotoLibrary:path];
        }
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)saveImageToPhotoLibrary:(NSString *)path {
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (!image) {
        [self showSaveResult:NO message:@"无法读取图片"];
        return;
    }

    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showSaveResult:NO message:@"没有相册访问权限，请在设置中开启"];
            });
            return;
        }

        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [self showSaveResult:YES message:@"图片已保存到相册"];
                } else {
                    [self showSaveResult:NO message:error.localizedDescription];
                }
            });
        }];
    }];
}

- (void)saveVideoToPhotoLibrary:(NSString *)path {
    NSURL *videoURL = [NSURL fileURLWithPath:path];

    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showSaveResult:NO message:@"没有相册访问权限，请在设置中开启"];
            });
            return;
        }

        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [self showSaveResult:YES message:@"视频已保存到相册"];
                } else {
                    [self showSaveResult:NO message:error.localizedDescription];
                }
            });
        }];
    }];
}

- (void)showSaveResult:(BOOL)success message:(NSString *)message {
    NSString *title = success ? @"成功" : @"失败";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleFileListChangedNotification:(NSNotification *)notification {
    if (!self.currentDirPath) {
        return;
    }
    
    NSString *currentFilePath = self.currentModel.filePath;
    NSArray *allModels = [SandboxTool getFirstLevelFileModelsWithDirPath:self.currentDirPath displayType:DisplayTypeAll];
    
    NSMutableArray *newFileList = [NSMutableArray array];
    for (FileModel *model in allModels) {
        if (model.itemType != FileItemTypeFolder) {
            [newFileList addObject:model];
        }
    }
    
    if (newFileList.count == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    NSInteger newIndex = 0;
    for (NSInteger i = 0; i < newFileList.count; i++) {
        FileModel *model = newFileList[i];
        NSString *fileNameWithoutExt = [model.filePath stringByDeletingPathExtension];
        NSString *currentFileNameWithoutExt = [currentFilePath stringByDeletingPathExtension];
        if ([fileNameWithoutExt isEqualToString:currentFileNameWithoutExt]) {
            newIndex = i;
            break;
        }
    }
    
    self.fileList = newFileList;
    self.currentIndex = newIndex;
    [self loadCurrentFile];
    [self.thumbnailCollectionView reloadData];
    [self scrollToCurrentThumbnail];
}

- (void)showNextFile {
    if (self.currentIndex < self.fileList.count - 1) {
        self.currentIndex++;
        [self loadCurrentFile];
        [self scrollToCurrentThumbnail];
    }
}

- (void)showPreviousFile {
    if (self.currentIndex > 0) {
        self.currentIndex--;
        [self loadCurrentFile];
        [self scrollToCurrentThumbnail];
    }
}

- (void)scrollToCurrentThumbnail {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    [self.thumbnailCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)updateUI {
    self.pageLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)(self.currentIndex + 1), (long)self.fileList.count];
    self.titleLabel.text = self.currentModel.fileName;
    [self.thumbnailCollectionView reloadData];
}

- (void)loadCurrentFile {
    [self.playerController.player pause];
    self.playerController.view.hidden = YES;
    self.imageView.hidden = YES;
    self.fileIconView.hidden = YES;
    self.fileInfoLabel.hidden = YES;
    self.quickLookController.view.hidden = YES;
    self.loadingIndicator.hidden = YES;
    self.playButton.hidden = YES;
    self.isPlaying = NO;

    FileModel *model = self.fileList[self.currentIndex];
    self.currentModel = model;
    [self updateUI];

    [self.mainScrollView setContentOffset:CGPointZero animated:NO];
    [self.quickLookController reloadData];

    NSString *extension = [model.filePath pathExtension].lowercaseString;

    if ([self isImageExtension:extension]) {
        [self loadImage:model.filePath];
    } else if ([self isVideoExtension:extension] || [self isAudioExtension:extension]) {
        [self loadVideo:model.filePath isAudio:[self isAudioExtension:extension]];
    } else if ([self isDocumentExtension:extension]) {
        [self loadDocument:model.filePath];
    } else if ([self isPlistExtension:extension]) {
        [self showPlistFile:model];
    } else {
        [self showFileInfo:model];
    }
}

- (BOOL)isImageExtension:(NSString *)extension {
    NSArray *imageExtensions = @[@"png", @"jpg", @"jpeg", @"gif", @"bmp", @"tiff", @"heic", @"heif", @"webp"];
    return [imageExtensions containsObject:extension];
}

- (BOOL)isVideoExtension:(NSString *)extension {
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi", @"m4v", @"wmv", @"flv", @"mkv", @"rmvb"];
    return [videoExtensions containsObject:extension];
}

- (BOOL)isDocumentExtension:(NSString *)extension {
    NSArray *docExtensions = @[@"pdf", @"doc", @"docx", @"xls", @"xlsx", @"ppt", @"pptx", @"txt", @"rtf", @"pages", @"numbers", @"keynote"];
    return [docExtensions containsObject:extension];
}

- (void)loadImage:(NSString *)path {
    self.imageView.hidden = NO;
    self.loadingIndicator.hidden = NO;
    [self.loadingIndicator startAnimating];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingIndicator stopAnimating];
            self.imageView.image = image;
        });
    });
}

- (void)loadVideo:(NSString *)path isAudio:(BOOL)isAudio {
    self.playerController.view.hidden = NO;
    
    if (isAudio) {
        // 对于音频文件，显示图标和播放按钮
        self.fileIconView.hidden = NO;
        self.fileIconView.image = [UIImage systemImageNamed:@"music.note"];
        self.fileIconView.tintColor = [UIColor systemPinkColor];
        self.playButton.hidden = NO;
        
        self.fileInfoLabel.hidden = NO;
        NSString *sizeStr = [self.currentModel formattedFileSize];
        NSString *dateStr = [self.currentModel formattedModificationDate];
        self.fileInfoLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", self.currentModel.fileName, sizeStr, dateStr];
    }
    
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    self.playerController.player = player;
    
    if (!isAudio) {
        [player play];
    }
}

- (void)loadDocument:(NSString *)path {
    self.quickLookController.view.hidden = NO;
    [self.quickLookController reloadData];
}

- (void)showFileInfo:(FileModel *)model {
    self.fileIconView.hidden = NO;
    self.fileInfoLabel.hidden = NO;

    if (model.itemType == FileItemTypeFolder) {
        self.fileIconView.image = [UIImage systemImageNamed:@"folder.fill"];
        self.fileIconView.tintColor = [UIColor systemBlueColor];
    } else {
        self.fileIconView.image = [self iconForFileExtension:model.filePath.pathExtension.lowercaseString];
        self.fileIconView.tintColor = [UIColor systemGrayColor];
    }

    NSString *sizeStr = [model formattedFileSize];
    NSString *dateStr = [model formattedModificationDate];
    self.fileInfoLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", model.fileName, sizeStr, dateStr];
}

- (void)showPlistFile:(FileModel *)model {
    self.fileIconView.hidden = NO;
    self.fileInfoLabel.hidden = NO;
    self.playButton.hidden = YES;

    self.fileIconView.image = [UIImage systemImageNamed:@"doc.text.fill"];
    self.fileIconView.tintColor = [UIColor systemTealColor];

    NSString *sizeStr = [model formattedFileSize];
    NSString *dateStr = [model formattedModificationDate];
    self.fileInfoLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@\n\n点击编辑", model.fileName, sizeStr, dateStr];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlistEditor)];
    self.containerView.userInteractionEnabled = YES;
    [self.containerView addGestureRecognizer:tap];
}

- (void)openPlistEditor {
    PlistEditorViewController *editorVC = [[PlistEditorViewController alloc] init];
    editorVC.fileModel = self.currentModel;
    editorVC.filePath = self.currentModel.filePath;
    [self.navigationController pushViewController:editorVC animated:YES];
}

- (void)playButtonTapped {
    if (self.isPlaying) {
        [self.playerController.player pause];
        [self.playButton setImage:[UIImage systemImageNamed:@"play.circle.fill"] forState:UIControlStateNormal];
        self.isPlaying = NO;
    } else {
        [self.playerController.player play];
        [self.playButton setImage:[UIImage systemImageNamed:@"pause.circle.fill"] forState:UIControlStateNormal];
        self.isPlaying = YES;
    }
}

- (void)actionButtonTapped {
    [[FileActionHandler sharedHandler] showActionSheetForModel:self.currentModel
                                            fromViewController:self
                                                      delegate:nil];
}

- (void)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fileList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPreviewCellIdentifier forIndexPath:indexPath];

    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }

    FileModel *model = self.fileList[indexPath.item];

    UIImageView *thumbnailView = [[UIImageView alloc] init];
    thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
    thumbnailView.clipsToBounds = YES;
    thumbnailView.frame = cell.contentView.bounds;
    thumbnailView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:thumbnailView];

    NSString *extension = [model.filePath pathExtension].lowercaseString;
    BOOL showPlayIcon = NO;

    if (model.itemType == FileItemTypeFolder) {
        thumbnailView.image = [UIImage systemImageNamed:@"folder.fill"];
        thumbnailView.tintColor = [UIColor systemBlueColor];
        thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    } else if ([self isImageExtension:extension]) {
        thumbnailView.image = [UIImage imageWithContentsOfFile:model.filePath];
        thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
    } else if ([self isVideoExtension:extension]) {
        UIImage *videoThumbnail = [self thumbnailForVideo:model.filePath];
        if (videoThumbnail) {
            thumbnailView.image = videoThumbnail;
            thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
        } else {
            thumbnailView.image = [UIImage systemImageNamed:@"video.fill"];
            thumbnailView.tintColor = [UIColor systemBlueColor];
            thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        }
        showPlayIcon = YES;
    } else if ([self isAudioExtension:extension]) {
        thumbnailView.image = [UIImage systemImageNamed:@"music.note"];
        thumbnailView.tintColor = [UIColor systemPinkColor];
        thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        showPlayIcon = YES;
    } else if ([self isPlistExtension:extension]) {
        thumbnailView.image = [UIImage systemImageNamed:@"doc.text.fill"];
        thumbnailView.tintColor = [UIColor systemTealColor];
        thumbnailView.contentMode = UIViewContentModeScaleAspectFit;

        UIImageView *editIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"pencil.circle.fill"]];
        editIcon.tintColor = [UIColor whiteColor];
        editIcon.contentMode = UIViewContentModeScaleAspectFit;
        editIcon.frame = CGRectMake((80 - 30) / 2, (80 - 30) / 2, 30, 30);
        [cell.contentView addSubview:editIcon];
    } else {
        thumbnailView.image = [self iconForFileExtension:extension];
        thumbnailView.tintColor = [UIColor systemGrayColor];
        thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    }

    if (showPlayIcon) {
        UIImageView *playIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"play.circle.fill"]];
        playIcon.tintColor = [UIColor whiteColor];
        playIcon.contentMode = UIViewContentModeScaleAspectFit;
        playIcon.frame = CGRectMake((80 - 30) / 2, (80 - 30) / 2, 30, 30);
        [cell.contentView addSubview:playIcon];
    }

    if (indexPath.item == self.currentIndex) {
        cell.layer.borderWidth = 2;
        cell.layer.borderColor = [UIColor systemBlueColor].CGColor;
    } else {
        cell.layer.borderWidth = 0;
    }

    return cell;
}

- (UIImage *)iconForFileExtension:(NSString *)extension {
    // 压缩文件
    NSArray *archiveExtensions = @[@"zip", @"rar", @"7z", @"tar", @"gz", @"bz2", @"xz", @"lzh"];
    if ([archiveExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"doc.zipper"];
    }
    
    // 文档文件
    NSArray *docExtensions = @[@"pdf", @"doc", @"docx", @"txt", @"rtf", @"pages", @"numbers", @"keynote", @"ppt", @"pptx", @"xls", @"xlsx", @"csv"];
    if ([docExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"doc.text"];
    }
    
    // 代码文件
    NSArray *codeExtensions = @[@"h", @"m", @"swift", @"c", @"cpp", @"java", @"py", @"js", @"html", @"css", @"xml", @"json", @"plist"];
    if ([codeExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"chevron.left.forwardslash.chevron.right"];
    }
    
    // 可执行文件
    NSArray *executableExtensions = @[@"app", @"exe", @"dmg", @"pkg", @"deb", @"rpm"];
    if ([executableExtensions containsObject:extension]) {
        return [UIImage systemImageNamed:@"app.fill"];
    }
    
    // 默认文档图标
    return [UIImage systemImageNamed:@"doc.fill"];
}

- (BOOL)isAudioExtension:(NSString *)extension {
    NSArray *audioExtensions = @[@"mp3", @"wav", @"flac", @"aac", @"ogg", @"m4a", @"wma", @"aiff"];
    return [audioExtensions containsObject:extension];
}

- (BOOL)isPlistExtension:(NSString *)extension {
    NSArray *plistExtensions = @[@"plist", @"xml"];
    return [plistExtensions containsObject:extension];
}

- (UIImage *)thumbnailForVideo:(NSString *)videoPath {
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;

    NSError *error = nil;
    CMTime time = CMTimeMakeWithSeconds(0, 60);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];

    if (imageRef) {
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        return image;
    }
    return nil;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.currentIndex = indexPath.item;
    [self loadCurrentFile];
    [collectionView reloadData];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(60, 60);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.mainScrollView) {
        CGFloat pageWidth = scrollView.frame.size.width;
        NSInteger page = (NSInteger)(scrollView.contentOffset.x / pageWidth);
        if (page != self.currentIndex && page >= 0 && page < self.fileList.count) {
            self.currentIndex = page;
            [self updateUI];
            [self.thumbnailCollectionView reloadData];
            [self scrollToCurrentThumbnail];
        }
    }
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [NSURL fileURLWithPath:self.currentModel.filePath];
}

@end
