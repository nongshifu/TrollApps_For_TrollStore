#import "QRCodeScannerViewController.h"
#import "UserProfileViewController.h"
#import "ShowOneAppViewController.h"
#import "ShowOneToolViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

@interface QRCodeScannerViewController ()<ZXCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) ZXCapture *capture;
@property (nonatomic, strong) UIButton *flashlightButton;
@property (nonatomic, strong) UIButton *albumButton;
@end

@implementation QRCodeScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = @"扫一扫";
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;

    // 添加关闭按钮
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonTapped)];
    self.navigationItem.leftBarButtonItem = closeButton;

    // 初始化扫码器
    self.capture = [[ZXCapture alloc] init];
    self.capture.layer.frame = self.view.bounds;
    self.capture.camera = self.capture.back;
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.delegate = self;
    [self.view.layer addSublayer:self.capture.layer];
}

- (void)setupFloatingButtons {
    // 手电筒按钮
    self.flashlightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.flashlightButton setImage:[UIImage systemImageNamed:@"flashlight.off.fill"] forState:UIControlStateNormal];
    self.flashlightButton.frame = CGRectMake(20, self.view.bounds.size.height - 80 - get_BOTTOM_SAFE_AREA_HEIGHT, 60, 60);
    self.flashlightButton.layer.cornerRadius = 30;
    self.flashlightButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    [self.flashlightButton addTarget:self action:@selector(toggleFlashlight) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashlightButton];

    // 相册按钮
    self.albumButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.albumButton setImage:[UIImage systemImageNamed:@"photo.fill.on.rectangle.fill"] forState:UIControlStateNormal];
    self.albumButton.frame = CGRectMake(self.view.bounds.size.width - 80, self.view.bounds.size.height - 80 - get_BOTTOM_SAFE_AREA_HEIGHT, 60, 60);
    self.albumButton.layer.cornerRadius = 30;
    self.albumButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    [self.albumButton addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.albumButton];
}

- (void)toggleFlashlight {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (device.torchMode == AVCaptureTorchModeOff) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [self.flashlightButton setImage:[UIImage systemImageNamed:@"flashlight.on.fill"] forState:UIControlStateNormal];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [self.flashlightButton setImage:[UIImage systemImageNamed:@"flashlight.off.fill"] forState:UIControlStateNormal];
        }
        [device unlockForConfiguration];
    }
}

- (void)openAlbum {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];

    // 获取选择的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        // 识别图片中的二维码
        [self scanQRCodeFromImage:image];
    }
}



- (void)scanQRCodeFromImage:(UIImage *)image {
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    
    if (features.count == 0) {
        NSLog(@"未识别到二维码");
        [SVProgressHUD showErrorWithStatus:@"未识别到二维码"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    
    // 1. 提取二维码中的URL字符串
    CIQRCodeFeature *feature = [features firstObject];
    NSString *scanResult = feature.messageString;
    if (!scanResult || scanResult.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"二维码内容为空"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    NSLog(@"二维码识别结果：%@", scanResult);
    NSString * type = [self getParamFromURLString:scanResult withKey:@"type"];
    // 2. 用封装函数提取参数（支持任意URL格式，无需硬写range）
    // 场景1：提取 "openuser" 参数（如 "xxx?openuser=123" 或 "xxx?other=456&openuser=123"）
    NSString *openid = [self getParamFromURLString:scanResult withKey:@"id"];
    
    // 3. 根据参数类型处理逻辑
    if ([type isEqualToString:@"user"]) {
        // 处理用户ID逻辑
        int64_t userID = [openid longLongValue];
        NSLog(@"识别到的用户 ID: %lld", userID);
        
        [UserModel getUserInfoWithUserId:openid success:^(UserModel * _Nonnull userModel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UserProfileViewController *vc = [UserProfileViewController new];
                vc.user_udid = userModel.udid;
                [self presentPanModal:vc];
            });
        } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
            [SVProgressHUD showErrorWithStatus:@"读取用户数据失败"];
            [SVProgressHUD dismissWithDelay:1];
        }];
        
    } else if ([type isEqualToString:@"app"]) {
        // 新增：处理APP详情逻辑（原来的range2判断逻辑移到这里）
        NSLog(@"识别到的APP ID: %@", openid);
        // 示例：跳转到APP详情页（根据你的业务补充）
         ShowOneAppViewController *appVC = [ShowOneAppViewController new];
         appVC.app_id = [openid longLongValue];
         [self presentPanModal:appVC];
        
    } else if ([type isEqualToString:@"tool"]) {
        // 新增：处理APP详情逻辑（原来的range2判断逻辑移到这里）
        NSLog(@"识别到的APP ID: %@", openid);
        // 示例：跳转到APP详情页（根据你的业务补充）
         ShowOneToolViewController *appVC = [ShowOneToolViewController new];
         appVC.tool_id = [openid longLongValue];
         [self presentPanModal:appVC];
        
    } else {
        // 未识别到有效参数
        [SVProgressHUD showErrorWithStatus:@"二维码中未包含有效用户ID或APP ID"];
        [SVProgressHUD dismissWithDelay:1.5];
    }
}

- (NSString *)getParamFromURLString:(NSString *)urlString withKey:(NSString *)key {
    // 1. 过滤无效输入
    if (!urlString || urlString.length == 0 || !key || key.length == 0) {
        return nil;
    }
    
    // 2. 关键修改：用新方法替换废弃方法，指定 URL 查询参数允许的字符集
    // URLQueryAllowedCharacterSet：保留 &、= 等分隔符，仅编码特殊字符（中文、空格等）
    NSString *encodedURLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    if (!url) {
        NSLog(@"URL格式无效：%@", urlString);
        return nil;
    }
    
    // 3. 后续逻辑不变（提取查询参数、分割键值对等）
    NSString *query = url.query;
    if (!query || query.length == 0) {
        NSLog(@"URL无查询参数：%@", urlString);
        return nil;
    }
    
    NSArray *paramPairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in paramPairs) {
        NSArray *keyValue = [pair componentsSeparatedByString:@"="];
        if (keyValue.count < 1) continue;
        
        NSString *paramKey = [keyValue[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![paramKey isEqualToString:key]) continue;
        
        NSString *paramValue = (keyValue.count >= 2) ? keyValue[1] : @"";
        // 解码URL编码（保持不变，处理中文/特殊字符）
        return [paramValue stringByRemovingPercentEncoding];
    }
    
    NSLog(@"URL中未找到参数Key：%@（URL：%@）", key, urlString);
    return nil;
}


- (void)closeButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}


// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = YES;
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self.capture start];
    // 添加悬浮按钮
    [self setupFloatingButtons];
}
// 消失之前
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 在这里可以进行一些在视图消失之前的清理工作，比如停止动画、保存数据等。
}
//消失后
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 在这里可以进行一些清理工作，比如停止动画、取消定时器、保存数据等。
    // 也可以用于记录视图消失的状态，以便在后续的操作中进行判断。
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // 应用将要进入前台，进行一些准备工作
    NSLog(@"应用将要进入前台");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // 应用已经完全进入前台并且处于活动状态，更新用户界面等操作
    NSLog(@"应用已经完全进入前台并且处于活动状态");
}
@end
