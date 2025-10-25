#import "UserCardViewController.h"
#import "loadData.h"
#import <ZXingObjC/ZXingObjC.h>

@interface UserCardViewController ()

@end

@implementation UserCardViewController {
    UIImageView *avatarImageView;
    UILabel *nicknameLabel;
    UIImageView *qrCodeImageView;
    UIView *containerView; // 容器视图
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.zx_navTitle = @"我的名片";
    [self zx_setMultiTitle:@"我的名片"
                  subTitle:[loadData sharedInstance].userModel.bio
              subTitleFont:[UIFont systemFontOfSize:8]
         subTitleTextColor:[UIColor linkColor]];
    
    self.userID = [loadData sharedInstance].userModel.user_id;
    self.nickname = [loadData sharedInstance].userModel.nickname; // 设置昵称
    self.avatarImage = [loadData sharedInstance].userModel.avatarImage; // 设置默认头像
    
    // 设置 UI
    [self setupUI];
    
    // 生成二维码
    [self generateQRCode];
}

- (void)setupUI {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWidth, 80)];
    label.text = @"我的名片";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.labelColor;
    label.font = [UIFont boldSystemFontOfSize:20];
    
    [self.view addSubview:label];
    // 容器视图
    containerView = [[UIView alloc] initWithFrame:CGRectMake(50, 150, self.view.frame.size.width - 100, 450)];
    containerView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    containerView.layer.cornerRadius = 20;
    containerView.layer.masksToBounds = YES;
    containerView.layer.borderWidth = 1;
    containerView.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.5].CGColor;
    [self.view addSubview:containerView];
    
    // 头像
    avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake((containerView.frame.size.width - 120) / 2, 40, 120, 120)];
    avatarImageView.image = self.avatarImage;
    avatarImageView.layer.cornerRadius = 60;
    avatarImageView.clipsToBounds = YES;
    [containerView addSubview:avatarImageView];
    
    // 昵称
    nicknameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(avatarImageView.frame) + 10, containerView.frame.size.width - 40, 30)];
    nicknameLabel.text = self.nickname;
    nicknameLabel.textAlignment = NSTextAlignmentCenter;
    nicknameLabel.font = [UIFont boldSystemFontOfSize:20];
    [containerView addSubview:nicknameLabel];
    
    // 二维码
    qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake((containerView.frame.size.width - 200) / 2, CGRectGetMaxY(nicknameLabel.frame) + 10, 200, 200)];
    [containerView addSubview:qrCodeImageView];
    
    
    // 保存按钮
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    saveButton.frame = CGRectMake((self.view.frame.size.width - 200) / 2, CGRectGetMaxY(containerView.frame) + 20, 200, 50);
    [saveButton setTitle:@"保存到相册" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveToAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    
    [containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(self.view.frame.size.width - 100));
        make.height.equalTo(@(450));
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
    }];
    [saveButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(200));
        make.height.equalTo(@(50));
        make.centerX.equalTo(self.view);
        make.top.equalTo(containerView.mas_bottom).offset(30);
    }];
    
    
    
}

- (void)generateQRCode {
    // 将用户 ID 转换为字符串mySoulChat://user?id=123456
    NSString *userIDString = [NSString stringWithFormat:@"%@/user/index.php?id=%lld&type=user",localURL, self.userID];
    
    // 生成二维码
    NSError *error = nil;
    ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
    ZXBitMatrix *result = [writer encode:userIDString
                                  format:kBarcodeFormatQRCode
                                   width:500
                                  height:500
                                   error:&error];
    
    if (result) {
        ZXImage *image = [ZXImage imageWithMatrix:result];
        qrCodeImageView.image = [UIImage imageWithCGImage:image.cgimage];
    } else {
        NSLog(@"生成二维码失败: %@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:@"生成二维码失败"];
        [SVProgressHUD dismissWithDelay:2];
    }
}

- (void)saveToAlbum {
    // 将容器视图保存为图片
    UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, NO, 0.0);
    [containerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 保存到相册
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存失败: %@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:@"保存失败"];
        [SVProgressHUD dismissWithDelay:2];
    } else {
        NSLog(@"保存成功");
        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
        [SVProgressHUD dismissWithDelay:15];
    }
}
// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
}
// 消失之前
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 在这里可以进行一些在视图消失之前的清理工作，比如停止动画、保存数据等。
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
}
//消失后
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 在这里可以进行一些清理工作，比如停止动画、取消定时器、保存数据等。
    // 也可以用于记录视图消失的状态，以便在后续的操作中进行判断。
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
}

@end
