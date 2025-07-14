//
//  EditUserProfileViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "EditUserProfileViewController.h"
#import "NewProfileViewController.h"
#import "UserModel.h"
#import "NetworkClient.h"
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>
//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}
@interface EditUserProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIButton *changeAvatarButton;
@property (nonatomic, strong) UILabel *vipLabel;

@property (nonatomic, strong) UITextField *nicknameTextField;
@property (nonatomic, strong) UITextField *phoneTextField;
@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) UITextField *wechatTextField;
@property (nonatomic, strong) UITextField *qqTextField;
@property (nonatomic, strong) UITextField *tgTextField;
@property (nonatomic, strong) UISegmentedControl *genderSegmentedControl;
@property (nonatomic, strong) UITextView *bioTextView;
@property (nonatomic, strong) UILabel *bioCountLabel;

@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIImage *selectedAvatarImage;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@end

@implementation EditUserProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(!self.userInfo){
        self.userInfo = [NewProfileViewController sharedInstance].userInfo;
    }
    
    
    //点击视图 隐藏键盘
    self.isTapViewToHideKeyboard = YES;
    
    // 设置背景色
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 设置导航栏
    [self setupNavigationBar];
    
    // 初始化UI组件
    [self initializeUIComponents];
    
    // 设置约束
    [self setupConstraints];
    
    // 加载用户数据
    [self loadUserData];
}

- (void)setupNavigationBar {
    // 设置返回按钮
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTapped:)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)initializeUIComponents {
    UIColor * textFieldBackgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    
    // 创建滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    
    // 创建内容视图
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView = contentView;
    [self.scrollView addSubview:self.contentView];
    
    
    // 圆形头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 60.0;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.borderWidth = 2.0;
    self.avatarImageView.layer.borderColor = [UIColor systemGray6Color].CGColor;
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.avatarImageView];
    
    // 更改头像按钮
    self.changeAvatarButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.changeAvatarButton setTitle:@"更改头像" forState:UIControlStateNormal];
    [self.changeAvatarButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [self.changeAvatarButton addTarget:self action:@selector(changeAvatarButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.changeAvatarButton.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.changeAvatarButton];
    
    // VIP标签
    self.vipLabel = [[UILabel alloc] init];
    self.vipLabel.textAlignment = NSTextAlignmentCenter;
    self.vipLabel.font = [UIFont systemFontOfSize:14.0];
    self.vipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.vipLabel];
    
    // 昵称输入框
    self.nicknameTextField = [[UITextField alloc] init];
    self.nicknameTextField.placeholder = @"昵称";
    self.nicknameTextField.backgroundColor = textFieldBackgroundColor;
    self.nicknameTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.nicknameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.nicknameTextField];
    
    // 手机号输入框
    self.phoneTextField = [[UITextField alloc] init];
    self.phoneTextField.placeholder = @"手机号";
    self.phoneTextField.backgroundColor = textFieldBackgroundColor;
    self.phoneTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.phoneTextField.keyboardType = UIKeyboardTypePhonePad;
    self.phoneTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.phoneTextField];
    
    // 邮箱输入框
    self.emailTextField = [[UITextField alloc] init];
    self.emailTextField.placeholder = @"邮箱";
    self.emailTextField.backgroundColor = textFieldBackgroundColor;
    self.emailTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.emailTextField];
    
    // 微信输入框
    self.wechatTextField = [[UITextField alloc] init];
    self.wechatTextField.placeholder = @"微信";
    self.wechatTextField.backgroundColor = textFieldBackgroundColor;
    self.wechatTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.wechatTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.wechatTextField];
    
    // QQ输入框
    self.qqTextField = [[UITextField alloc] init];
    self.qqTextField.placeholder = @"QQ";
    self.qqTextField.backgroundColor = textFieldBackgroundColor;
    self.qqTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.qqTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.qqTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.qqTextField];
    
    // TG输入框
    self.tgTextField = [[UITextField alloc] init];
    self.tgTextField.placeholder = @"Telegram";
    self.tgTextField.backgroundColor = textFieldBackgroundColor;
    self.tgTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.tgTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.tgTextField];
    
    // 性别选择器
    self.genderSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"保密", @"男", @"女"]];
    self.genderSegmentedControl.selectedSegmentIndex = 0;
    self.genderSegmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.genderSegmentedControl];
    
    // 个人简介文本视图
    self.bioTextView = [[UITextView alloc] init];
    self.bioTextView.font = [UIFont systemFontOfSize:16.0];
    self.bioTextView.layer.borderWidth = 1.0;
    self.bioTextView.backgroundColor = textFieldBackgroundColor;
    self.bioTextView.layer.borderColor = [UIColor systemGray3Color].CGColor;
    self.bioTextView.layer.cornerRadius = 5.0;
    self.bioTextView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.bioTextView.delegate = self;
    self.bioTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.bioTextView];
    
    // 字数统计标签
    self.bioCountLabel = [[UILabel alloc] init];
    self.bioCountLabel.text = @"0/200";
    self.bioCountLabel.font = [UIFont systemFontOfSize:12.0];
    self.bioCountLabel.textColor = [UIColor systemGrayColor];
    self.bioCountLabel.textAlignment = NSTextAlignmentRight;
    self.bioCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.bioCountLabel];
    
    // 保存按钮
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveButton.backgroundColor = [UIColor systemBlueColor];
    self.saveButton.layer.cornerRadius = 8.0;
    [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.saveButton];
}

- (void)setupConstraints {
    // 设置滚动视图和内容视图的约束
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
    
    // 设置其他控件的约束
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(40);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@120);
    }];
    
    [self.changeAvatarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(10);
        make.centerX.equalTo(self.contentView);
    }];
    
    [self.vipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.changeAvatarButton.mas_bottom).offset(10);
        make.centerX.equalTo(self.contentView);
    }];
    
    [self.nicknameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipLabel.mas_bottom).offset(30);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    [self.phoneTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameTextField.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    [self.emailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.phoneTextField.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    [self.wechatTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.emailTextField.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    [self.qqTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.wechatTextField.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    [self.tgTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qqTextField.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    [self.genderSegmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tgTextField.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    [self.bioTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.genderSegmentedControl.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@120);
    }];
    
    [self.bioCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioTextView.mas_bottom).offset(5);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@20);
        make.bottom.equalTo(self.contentView).offset(-20);
    }];
    
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(self.contentView).offset(40);
        make.right.equalTo(self.contentView).offset(-40);
        make.height.equalTo(@48);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - 80);
    }];
    
    [self.saveButton mas_updateConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(self.contentView).offset(40);
        make.right.equalTo(self.contentView).offset(-40);
        make.height.equalTo(@48);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
}

- (void)loadUserData {
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if (!self.userInfo || udid.length < 5) {
        NSLog(@"用户未登录");
        [SVProgressHUD showInfoWithStatus:@"您还未登录\n请先登录绑定UDID"];
        [SVProgressHUD dismissWithDelay:3 completion:^{
            [self dismiss];
        }];
        return;
    }
    NSDictionary *dic = @{
        @"action":@"getUserInfo",
        @"udid":udid,
        @"type":@"udid"
    };
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
                                             parameters:dic
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"请求udid用户数据:%@",stringResult);
            if (jsonResult &&
                [jsonResult[@"status"] isEqualToString:@"success"]) {
                UserModel *user = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
                if(user && user.udid.length>5){
                    [NewProfileViewController sharedInstance].userInfo = user;
                    // 加载头像
                    if (user.avatar.length > 0) {
                        // 假设avatar是URL
                        NSURL *avatarURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?time=%ld",localURL,user.avatar,(long)[NSDate date].timeIntervalSince1970]];
                        [self.avatarImageView sd_setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:@"default_avatar"]];
                    } else {
                        self.avatarImageView.image = [UIImage imageNamed:@"default_avatar"];
                    }
                    
                    
                    // 设置其他信息
                    self.nicknameTextField.text = user.nickname;
                    self.phoneTextField.text = user.phone;
                    self.emailTextField.text = user.email;
                    
                    // 设置社交账号
                    self.wechatTextField.text = user.wechat ?: @"";
                    self.qqTextField.text = user.qq ?: @"";
                    self.tgTextField.text = user.tg ?: @"";
                    
                    // 设置性别
                    if (user.gender) {
                        self.genderSegmentedControl.selectedSegmentIndex = user.gender;
                    } else {
                        self.genderSegmentedControl.selectedSegmentIndex = 0; // 默认为保密
                    }
                    
                    // 设置个人简介
                    self.bioTextView.text = user.bio ?: @"";
                    [self updateBioCountLabel];
                    
                    // 设置VIP状态
                    if ([UserModel isVIPExpiredWithDate:user.vip_expire_date]) {
                        self.vipLabel.text = @"普通用户";
                        self.vipLabel.textColor = [UIColor systemGrayColor];
                    } else {
                        self.vipLabel.text = [NSString stringWithFormat:@"VIP %ld · 到期日: %@", (long)user.vip_level, [TimeTool getTimeformatDate:user.vip_expire_date]];
                        self.vipLabel.textColor = [UIColor systemOrangeColor];
                    }
                }
                
            }
        });
    } failure:^(NSError *error) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        
    }];
    
}

- (void)changeAvatarButtonTapped:(UIButton *)sender {
    // 创建图片选择器
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    
    // 显示选择器
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"选择头像" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 添加拍照选项
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }]];
    }
    
    // 添加相册选项
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }]];
    }
    
    // 添加取消选项
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    // 获取选择的图片
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    
    if (selectedImage) {
        self.avatarImageView.image = selectedImage;
        self.selectedAvatarImage = selectedImage;
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updateBioCountLabel];
    
    // 限制最大长度
    if (textView.text.length > 200) {
        textView.text = [textView.text substringToIndex:200];
        [self updateBioCountLabel];
    }
}

- (void)updateBioCountLabel {
    self.bioCountLabel.text = [NSString stringWithFormat:@"%lu/200", (unsigned long)self.bioTextView.text.length];
}

- (void)saveButtonTapped:(UIButton *)sender {
    // 收起键盘
    [self.view endEditing:YES];
    
    // 获取当前用户信息
    
    
    if (!self.userInfo || [NewProfileViewController sharedInstance].userInfo.udid.length < 5) {
        NSLog(@"用户未登录");
        [SVProgressHUD showInfoWithStatus:@"您还未登录\n请先登录绑定UDID"];
        [SVProgressHUD dismissWithDelay:3 completion:^{
            [self dismiss];
        }];
        return;
    }
    UserModel *userInfo = [[UserModel alloc] init];
    // 更新用户信息
    userInfo.nickname = self.nicknameTextField.text;
    userInfo.phone = self.phoneTextField.text;
    userInfo.email = self.emailTextField.text;
    userInfo.wechat = self.wechatTextField.text;
    userInfo.qq = self.qqTextField.text;
    userInfo.tg = self.tgTextField.text;
    userInfo.gender = self.genderSegmentedControl.selectedSegmentIndex;
    userInfo.bio = self.bioTextView.text;
    
    
    // 显示加载指示器
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    loadingIndicator.center = self.view.center;
    loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
    
    // 使用统一的更新方法
    NSDictionary *dic = [userInfo yy_modelToJSONObject];
    NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    newDic[@"action"] = @"updateProfile";
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
                                             parameters:newDic
                                                   udid:self.userInfo.udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 停止加载指示器
            [loadingIndicator stopAnimating];
            NSLog(@"修改用户资料返回:%@",jsonResult);
            if(!jsonResult){
                // 如果解析失败，显示通用错误
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:stringResult preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if (code == 200) {
                // 显示成功提示
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" message:msg preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    // 如果选择了新头像，将其转换为Base64并更新到userInfo
                    if (self.selectedAvatarImage) {
                        [self uploadAvatar];
                    }
                    [self loadUserData];
                    [self dismiss];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            }else{
                // 如果解析失败，显示通用错误
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:msg preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 停止加载指示器
            [loadingIndicator stopAnimating];
            
            // 显示错误提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"失败" message:[NSString stringWithFormat:@"更新失败: %@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
    
    
}

- (void)uploadAvatar {
    // 1. 验证图片是否存在
    if (!self.userInfo.avatarImage) {
        [SVProgressHUD showErrorWithStatus:@"请先选择头像图片"];
        return;
    }
    
    // 2. 压缩图片（控制大小，避免base64过长）
    NSData *imageData = UIImageJPEGRepresentation(self.userInfo.avatarImage, 0.7); // 降低压缩质量至0.7
    if (!imageData) {
        [SVProgressHUD showErrorWithStatus:@"图片处理失败"];
        return;
    }
    NSLog(@"图片原始大小：%.2f KB", imageData.length / 1024.0); // 打印大小，排查过大问题
    
    // 3. 转换为base64（不含前缀）
    NSString *base64Image = [imageData base64EncodedStringWithOptions:0];
    if (base64Image.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"base64编码失败"];
        return;
    }
    
    // 4. 构建参数（确保key正确）
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"action"] = @"updateAvatar";
    params[@"avatar"] = base64Image; // 关键：确保key与PHP端一致
    
    // 5. 打印参数（排查是否被修改）
    NSLog(@"上传参数：%@", params);
    
    // 6. 发送请求（使用表单提交而非JSON，避免base64转义问题）
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php", localURL]
                                             parameters:params
                                                   udid:self.userInfo.udid
                                               progress:^(NSProgress *progress) {
        CGFloat progressValue = progress.fractionCompleted;
        [SVProgressHUD showProgress:progressValue status:[NSString stringWithFormat:@"上传中...%.0f%%", progressValue * 100]];
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"上传成功响应：%@", jsonResult);
        NSInteger code = [jsonResult[@"code"] integerValue];
        if (code == 200) { // 假设SUCCESS为0
            [SVProgressHUD showSuccessWithStatus:jsonResult[@"msg"] ?: @"头像更新成功"];
            // 更新UI...
            [self loadUserData];
        } else {
            [SVProgressHUD showErrorWithStatus:jsonResult[@"msg"] ?: @"更新失败"];
        }
    } failure:^(NSError *error) {
        NSLog(@"上传失败：%@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"网络错误：%@", error.localizedDescription]];
    }];
}
- (void)backButtonTapped:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    if (!self.userInfo || [NewProfileViewController sharedInstance].userInfo.udid.length < 5) {
        NSLog(@"用户未登录");
        [SVProgressHUD showInfoWithStatus:@"您还未登录\n请先登录绑定UDID"];
        [SVProgressHUD dismissWithDelay:3 completion:^{
            [self dismiss];
        }];
        return;
    }
}


//输入框和键盘高度
- (CGFloat)keyboardOffsetFromInputView{
    return 100;
}

@end
