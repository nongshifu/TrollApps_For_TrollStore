//
//  AnnouncementDetailViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "AnnouncementDetailViewController.h"
#import "AnnouncementModel.h"
#import "NetworkClient.h"
#import "FAKExtensions.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface AnnouncementDetailViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) AnnouncementModel *announcement;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *dividerView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UILabel *imagesTitleLabel;
@property (nonatomic, strong) UICollectionView *imagesCollectionView;
@property (nonatomic, strong) NSArray<NSString *> *imagesUrls;

@end

@implementation AnnouncementDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"公告详情";
    
    [self setupUI];
    [self setupConstraints];
    [self loadAnnouncement];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)setupUI {
    // 导航栏按钮
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonTapped)];
    self.navigationItem.rightBarButtonItem = closeButton;
    
    // ScrollView
    self.scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:self.scrollView];
    
    // ContentView
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    // Icon
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.layer.cornerRadius = 30;
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.backgroundColor = [UIColor systemBlueColor];
    [self.contentView addSubview:self.iconImageView];
    
    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];
    
    // Time
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:13];
    self.timeLabel.textColor = [UIColor secondaryLabelColor];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.timeLabel];
    
    // Divider
    self.dividerView = [[UIView alloc] init];
    self.dividerView.backgroundColor = [UIColor systemGray5Color];
    [self.contentView addSubview:self.dividerView];
    
    // Content
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont systemFontOfSize:16];
    self.contentLabel.textColor = [UIColor labelColor];
    self.contentLabel.numberOfLines = 0;
    [self.contentView addSubview:self.contentLabel];
    
    // 图片标题
    self.imagesTitleLabel = [[UILabel alloc] init];
    self.imagesTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.imagesTitleLabel.textColor = [UIColor labelColor];
    self.imagesTitleLabel.text = @"附件图片";
    self.imagesTitleLabel.hidden = YES;
    [self.contentView addSubview:self.imagesTitleLabel];
    
    // 图片CollectionView
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    
    self.imagesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.imagesCollectionView.backgroundColor = [UIColor clearColor];
    self.imagesCollectionView.dataSource = self;
    self.imagesCollectionView.delegate = self;
    self.imagesCollectionView.scrollEnabled = NO;
    self.imagesCollectionView.hidden = YES;
    [self.imagesCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [self.contentView addSubview:self.imagesCollectionView];
}

- (void)setupConstraints {
    // ScrollView
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // ContentView
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    // Icon
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(30);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@60);
    }];
    
    // Title
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconImageView.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    // Time
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.titleLabel);
    }];
    
    // Divider
    [self.dividerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.timeLabel.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@1);
    }];
    
    // Content
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dividerView.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    // 图片标题
    [self.imagesTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(30);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    // 图片CollectionView
    [self.imagesCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imagesTitleLabel.mas_bottom).offset(15);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@0);
    }];
    
    // 底部约束
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.imagesCollectionView.mas_bottom).offset(30).priorityHigh();
        make.bottom.equalTo(self.contentLabel.mas_bottom).offset(30).priorityMedium();
    }];
}

- (void)loadAnnouncement {
    if (!self.announcementUuid) {
        return;
    }
    
    NSDictionary *params = @{
        @"action": @"getOneAnnouncement",
        @"announcement_uuid": self.announcementUuid
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                               modules:@"announcement"
                                            parameters:params
                                              progress:nil
                                               success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code != 200) {
                NSLog(@"获取公告失败: %@", jsonResult[@"msg"]);
                return;
            }
            
            NSDictionary *data = jsonResult[@"data"];
            if (data) {
                self.announcement = [AnnouncementModel yy_modelWithDictionary:data];
                [self updateUI];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"网络错误: %@", error);
        });
    }];
}

- (void)updateUI {
    // Set background color if available
    if (self.announcement.announcement_color.length > 0) {
        self.iconImageView.backgroundColor = [self colorWithHexString:self.announcement.announcement_color];
    }
    
    // Icon
    if (self.announcement.announcement_icon.length > 0) {
        UIImage *iconImage = [UIImage fak_imageWithIconName:self.announcement.announcement_icon size:30 color:[UIColor whiteColor]];
        if (iconImage) {
            self.iconImageView.image = iconImage;
        } else {
            self.iconImageView.image = [UIImage systemImageNamed:@"megaphone.fill"];
        }
    } else {
        self.iconImageView.image = [UIImage systemImageNamed:@"megaphone.fill"];
    }
    self.iconImageView.tintColor = [UIColor whiteColor];
    
    // Title
    self.titleLabel.text = self.announcement.announcement_title;
    
    // Time
    self.timeLabel.text = [NSString stringWithFormat:@"发布于 %@", self.announcement.formattedPublishTime];
    
    // Content
    self.contentLabel.text = self.announcement.announcement_content;
    
    // 处理图片
    [self handleImages];
}

- (void)handleImages {
    if (self.announcement.announcement_images.count > 0) {
        self.imagesUrls = self.announcement.announcement_images;
        self.imagesTitleLabel.hidden = NO;
        self.imagesCollectionView.hidden = NO;
        [self.imagesCollectionView reloadData];
        
        // 计算CollectionView高度
        NSInteger itemsPerRow = 3;
        NSInteger rows = (self.imagesUrls.count + itemsPerRow - 1) / itemsPerRow;
        CGFloat itemHeight = 120;
        CGFloat spacing = 10;
        CGFloat totalHeight = rows * itemHeight + (rows - 1) * spacing;
        
        [self.imagesCollectionView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(totalHeight));
        }];
    } else {
        self.imagesTitleLabel.hidden = YES;
        self.imagesCollectionView.hidden = YES;
        [self.imagesCollectionView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
    }
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagesUrls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor systemGray6Color];
    cell.layer.cornerRadius = 8;
    cell.clipsToBounds = YES;
    
    UIImageView *imageView = [cell.contentView viewWithTag:100];
    if (!imageView) {
        imageView = [[UIImageView alloc] init];
        imageView.tag = 100;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [cell.contentView addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView);
        }];
    }
    
    NSString *urlString = self.imagesUrls[indexPath.item];
    NSURL *url = [NSURL URLWithString:urlString];
    [imageView sd_setImageWithURL:url placeholderImage:[UIImage systemImageNamed:@"photo"]];
    
    return cell;
}

#pragma mark - UICollectionView Delegate FlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (collectionView.bounds.size.width - 20) / 3;
    return CGSizeMake(width, 120);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    NSString *urlString = self.imagesUrls[indexPath.item];
    [self showImageViewerWithUrl:urlString];
}

#pragma mark - 图片查看器

- (void)showImageViewerWithUrl:(NSString *)urlString {
    UIViewController *imageViewer = [[UIViewController alloc] init];
    imageViewer.view.backgroundColor = [UIColor blackColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 3;
    scrollView.delegate = (id<UIScrollViewDelegate>)self;
    [imageViewer.view addSubview:scrollView];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [scrollView addSubview:imageView];
    
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(imageViewer.view);
    }];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scrollView);
        make.width.height.equalTo(imageViewer.view);
    }];
    
    NSURL *url = [NSURL URLWithString:urlString];
    [imageView sd_setImageWithURL:url];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [closeButton addTarget:self action:@selector(closeImageViewer) forControlEvents:UIControlEventTouchUpInside];
    [imageViewer.view addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageViewer.view.mas_safeAreaLayoutGuideTop).offset(15);
        make.right.equalTo(imageViewer.view).offset(-20);
    }];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imageViewer];
//    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)closeImageViewer {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)closeButtonTapped {
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        // 如果是 push 进来的，使用 pop
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // 如果是模态进来的，使用 dismiss
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    if (!hexString || hexString.length == 0) {
        return [UIColor systemBackgroundColor];
    }
    
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (cleanString.length != 6) {
        return [UIColor systemBackgroundColor];
    }
    
    unsigned int red, green, blue;
    [[NSScanner scannerWithString:[cleanString substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&red];
    [[NSScanner scannerWithString:[cleanString substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&green];
    [[NSScanner scannerWithString:[cleanString substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&blue];
    
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

@end
