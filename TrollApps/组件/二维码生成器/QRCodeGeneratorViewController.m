//
//  QRCodeGeneratorViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/26.

#import "QRCodeGeneratorViewController.h"
#import <ZXingObjC/ZXingObjC.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <Masonry/Masonry.h>

@interface QRCodeGeneratorViewController ()

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, strong) UIImageView *qrCodeImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *urlCopyButton;
@property (nonatomic, strong) UIButton *saveButton;

@end

@implementation QRCodeGeneratorViewController

#pragma mark - Lifecycle

- (instancetype)initWithURLString:(NSString *)urlString title:(NSString *)title {
    self = [super init];
    if (self) {
        _urlString = urlString;
        _titleString = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    [self setupUI];
    [self generateQRCode];
}

#pragma mark - Setup UI

- (void)setupUI {
    
    self.title = @"二维码生成器";
    
    // 导航栏返回按钮
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    // 标题标签
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = _titleString;
    _titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.numberOfLines = 0;
    _titleLabel.textColor = [UIColor darkTextColor];
    [self.view addSubview:_titleLabel];
    
    // 二维码图片
    _qrCodeImageView = [[UIImageView alloc] init];
    _qrCodeImageView.contentMode = UIViewContentModeScaleAspectFit;
    _qrCodeImageView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_qrCodeImageView];
    
    // 保存按钮
    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_saveButton setTitle:@"保存到相册" forState:UIControlStateNormal];
    [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_saveButton setBackgroundColor:[UIColor colorWithRed:0.1 green:0.6 blue:0.9 alpha:1.0]];
    [_saveButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [_saveButton addTarget:self action:@selector(saveToAlbumAction) forControlEvents:UIControlEventTouchUpInside];
    [_saveButton.layer setCornerRadius:8.0];
    [self.view addSubview:_saveButton];
    
    // 拷贝链接按钮
    _urlCopyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_urlCopyButton setTitle:@"拷贝链接" forState:UIControlStateNormal];
    [_urlCopyButton setTitleColor:[UIColor colorWithRed:0.1 green:0.6 blue:0.9 alpha:1.0] forState:UIControlStateNormal];
    [_urlCopyButton setBackgroundColor:[UIColor whiteColor]];
    [_urlCopyButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [_urlCopyButton addTarget:self action:@selector(copyLinkAction) forControlEvents:UIControlEventTouchUpInside];
    [_urlCopyButton.layer setCornerRadius:8.0];
    [_urlCopyButton.layer setBorderWidth:1.0];
    [_urlCopyButton.layer setBorderColor:[UIColor colorWithRed:0.1 green:0.6 blue:0.9 alpha:1.0].CGColor];
    [self.view addSubview:_urlCopyButton];
    
    // 设置布局约束
    [self setupConstraints];
}

- (void)setupConstraints {
    // 标题约束
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(50);
        make.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(80);
    }];
    
    // 二维码约束
    [_qrCodeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerY.equalTo(self.view).offset(-100);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(300);
    }];
    
    // 保存按钮约束
    [_saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_qrCodeImageView.mas_bottom).offset(20);
        make.leading.trailing.equalTo(self.view).inset(20);
        make.height.mas_equalTo(50);
    }];
    
    // 拷贝按钮约束
    [_urlCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_saveButton.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.view).inset(20);
        make.height.mas_equalTo(50);
    }];
}

#pragma mark - QR Code Generation

- (void)generateQRCode {
    if (!_urlString || _urlString.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"URL不能为空"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    NSError *error = nil;
    ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
    ZXBitMatrix *result = [writer encode:_urlString
                                  format:kBarcodeFormatQRCode
                                   width:500
                                  height:500
                                   error:&error];
    
    if (result) {
        ZXImage *image = [ZXImage imageWithMatrix:result];
        _qrCodeImageView.image = [UIImage imageWithCGImage:image.cgimage];
    } else {
        NSLog(@"生成二维码失败: %@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:@"生成二维码失败"];
        [SVProgressHUD dismissWithDelay:2];
    }
}

#pragma mark - Actions

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveToAlbumAction {
    if (!_qrCodeImageView.image) {
        [SVProgressHUD showErrorWithStatus:@"没有可保存的二维码"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // 合并标题和二维码为一张图片
    UIImage *combinedImage = [self createCombinedImage];
    
    // 保存到相册
    UIImageWriteToSavedPhotosAlbum(combinedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)copyLinkAction {
    if (!_urlString || _urlString.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"没有可拷贝的链接"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = _urlString;
    
    [SVProgressHUD showSuccessWithStatus:@"链接已拷贝"];
    [SVProgressHUD dismissWithDelay:1];
}

#pragma mark - Image Processing
- (UIImage *)createCombinedImage {
    // 获取二维码图片
    UIImage *qrImage = _qrCodeImageView.image;
    
    // 设置字体和间距
    UIFont *titleFont = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    CGFloat horizontalPadding = 20; // 左右边距
    CGFloat verticalPadding = 20;   // 垂直边距
    CGFloat spacingBetweenTitleAndQR = 20; // 标题与二维码间距
    
    // 计算标题所需高度（考虑多行情况）
    CGFloat titleHeight = 0;
    if (_titleString && _titleString.length > 0) {
        // 创建段落样式（居中对齐）
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        // 计算标题在给定宽度下的高度
        CGSize titleSize = [_titleString boundingRectWithSize:CGSizeMake(qrImage.size.width - horizontalPadding * 2, CGFLOAT_MAX)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName: titleFont,
                                                                  NSParagraphStyleAttributeName: paragraphStyle}
                                                        context:nil].size;
        titleHeight = ceil(titleSize.height);
    }
    
    // 计算总高度
    CGFloat totalHeight = qrImage.size.height + titleHeight + spacingBetweenTitleAndQR + verticalPadding * 2;
    CGSize size = CGSizeMake(qrImage.size.width, totalHeight);
    
    // 开始绘图上下文
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    // 绘制背景
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    
    // 绘制标题（如果有）
    if (_titleString && _titleString.length > 0) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        CGRect titleRect = CGRectMake(horizontalPadding,
                                     verticalPadding,
                                     size.width - horizontalPadding * 2,
                                     titleHeight);
        
        [_titleString drawInRect:titleRect
                   withAttributes:@{NSFontAttributeName: titleFont,
                                  NSForegroundColorAttributeName: [UIColor darkTextColor],
                                  NSParagraphStyleAttributeName: paragraphStyle}];
    }
    
    // 绘制二维码
    CGFloat qrY = titleHeight + verticalPadding * 2;
    [qrImage drawInRect:CGRectMake(0, qrY, qrImage.size.width, qrImage.size.height)];
    
    // 从上下文获取图片并结束
    UIImage *combinedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return combinedImage;
}
#pragma mark - Photo Album Delegate

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        [SVProgressHUD showErrorWithStatus:@"保存失败"];
        NSLog(@"保存图片失败: %@", error.localizedDescription);
    } else {
        [SVProgressHUD showSuccessWithStatus:@"已保存到相册"];
    }
    [SVProgressHUD dismissWithDelay:2];
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    self.navigationController.navigationBarHidden = NO;
}
@end
