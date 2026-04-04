//
//  LoginViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2026/3/31.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "LoginViewController.h"
#import "AppStoreAuth.h"
#import <SVProgressHUD/SVProgressHUD.h>

// 本地存储的Key
static NSString * const kSavedEmailKey = @"com.appdowngrade.savedEmail";
static NSString * const kSavedPasswordKey = @"com.appdowngrade.savedPassword";
static NSString * const kRememberPasswordKey = @"com.appdowngrade.rememberPassword";

@interface LoginViewController ()
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIView *inputContainerView;
@property (nonatomic, strong) UIView *rememberContainerView;
@property (nonatomic, strong) UILabel *rememberLabel;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadSavedAccountInfo];
}

#pragma mark - UI Setup

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"登录App Store";
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    
    // 添加取消按钮
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonTapped)];
    self.navigationItem.leftBarButtonItem = cancelItem;
    
    // 创建滚动视图，适配小屏幕
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];
    
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:20],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-20],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor]
    ]];
    
    // Logo图标
    self.logoImageView = [[UIImageView alloc] init];
    self.logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoImageView.tintColor = [UIColor systemBlueColor];
    
    // 使用系统图标作为Logo
    if (@available(iOS 13.0, *)) {
        self.logoImageView.image = [UIImage systemImageNamed:@"lock.shield.fill"];
    } else {
        self.logoImageView.image = [UIImage imageNamed:@"AppIcon"];
    }
    [contentView addSubview:self.logoImageView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"App Store 登录";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:self.titleLabel];
    
    // 说明文字
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionLabel.text = @"请使用您的 Apple ID 登录以获取应用历史版本信息。\n您的账号信息仅用于访问App Store\n不会上传至任何第三方服务器。";
    self.descriptionLabel.font = [UIFont systemFontOfSize:13];
    self.descriptionLabel.textColor = [UIColor secondaryLabelColor];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.numberOfLines = 0;
    [contentView addSubview:self.descriptionLabel];
    
    // 输入框容器
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainerView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.inputContainerView.layer.cornerRadius = 12;
    self.inputContainerView.layer.masksToBounds = YES;
    [contentView addSubview:self.inputContainerView];
    
    // 邮箱输入框
    self.emailField = [[UITextField alloc] init];
    self.emailField.translatesAutoresizingMaskIntoConstraints = NO;
    self.emailField.placeholder = @"Apple ID (邮箱)";
    self.emailField.font = [UIFont systemFontOfSize:16];
    self.emailField.textColor = [UIColor labelColor];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.emailField.returnKeyType = UIReturnKeyNext;
    self.emailField.delegate = self;
    
    // 添加左侧图标
    UIView *emailLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 44)];
    UIImageView *emailIcon = [[UIImageView alloc] initWithFrame:CGRectMake(12, 10, 20, 20)];
    if (@available(iOS 13.0, *)) {
        emailIcon.image = [[UIImage systemImageNamed:@"person.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    emailIcon.tintColor = [UIColor secondaryLabelColor];
    emailIcon.contentMode = UIViewContentModeScaleAspectFit;
    [emailLeftView addSubview:emailIcon];
    self.emailField.leftView = emailLeftView;
    self.emailField.leftViewMode = UITextFieldViewModeAlways;
    [self.inputContainerView addSubview:self.emailField];
    
    // 分隔线
    UIView *separatorLine = [[UIView alloc] init];
    separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    separatorLine.backgroundColor = [UIColor separatorColor];
    [self.inputContainerView addSubview:separatorLine];
    
    // 密码输入框
    self.passwordField = [[UITextField alloc] init];
    self.passwordField.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordField.placeholder = @"密码";
    self.passwordField.font = [UIFont systemFontOfSize:16];
    self.passwordField.textColor = [UIColor labelColor];
    self.passwordField.secureTextEntry = YES;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.delegate = self;
    
    // 添加左侧图标
    UIView *passwordLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 44)];
    UIImageView *passwordIcon = [[UIImageView alloc] initWithFrame:CGRectMake(12, 10, 20, 20)];
    if (@available(iOS 13.0, *)) {
        passwordIcon.image = [[UIImage systemImageNamed:@"lock.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    passwordIcon.tintColor = [UIColor secondaryLabelColor];
    passwordIcon.contentMode = UIViewContentModeScaleAspectFit;
    [passwordLeftView addSubview:passwordIcon];
    self.passwordField.leftView = passwordLeftView;
    self.passwordField.leftViewMode = UITextFieldViewModeAlways;
    [self.inputContainerView addSubview:self.passwordField];
    
    // 记住密码区域
    self.rememberContainerView = [[UIView alloc] init];
    self.rememberContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:self.rememberContainerView];
    
    self.rememberLabel = [[UILabel alloc] init];
    self.rememberLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.rememberLabel.text = @"记住密码";
    self.rememberLabel.font = [UIFont systemFontOfSize:14];
    self.rememberLabel.textColor = [UIColor labelColor];
    [self.rememberContainerView addSubview:self.rememberLabel];
    
    self.rememberSwitch = [[UISwitch alloc] init];
    self.rememberSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.rememberSwitch.onTintColor = [UIColor systemBlueColor];
    [self.rememberSwitch addTarget:self action:@selector(rememberSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.rememberContainerView addSubview:self.rememberSwitch];
    
    // 登录按钮
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loginButton setTitle:@"登 录" forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    self.loginButton.layer.cornerRadius = 12;
    self.loginButton.layer.masksToBounds = YES;
    
    // 添加按钮阴影效果
    self.loginButton.layer.shadowColor = [UIColor systemBlueColor].CGColor;
    self.loginButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.loginButton.layer.shadowRadius = 8;
    self.loginButton.layer.shadowOpacity = 0.3;
    
    [self.loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:self.loginButton];
    
    // 隐私说明
    UILabel *privacyLabel = [[UILabel alloc] init];
    privacyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    privacyLabel.text = @"🔒 您的账号信息将安全地存储在设备钥匙串中\nApp降级依赖开源库\nhttps://github.com/majd/ipatool";
    privacyLabel.font = [UIFont systemFontOfSize:11];
    privacyLabel.numberOfLines = 0;
    privacyLabel.textColor = [UIColor tertiaryLabelColor];
    privacyLabel.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:privacyLabel];
    
    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        // Logo
        [self.logoImageView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:20],
        [self.logoImageView.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [self.logoImageView.widthAnchor constraintEqualToConstant:80],
        [self.logoImageView.heightAnchor constraintEqualToConstant:80],
        
        // 标题
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.logoImageView.bottomAnchor constant:16],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:30],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-30],
        
        // 说明文字
        [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:30],
        [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-30],
        
        // 输入框容器
        [self.inputContainerView.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor constant:30],
        [self.inputContainerView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [self.inputContainerView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [self.inputContainerView.heightAnchor constraintEqualToConstant:88],
        
        // 邮箱输入框
        [self.emailField.topAnchor constraintEqualToAnchor:self.inputContainerView.topAnchor],
        [self.emailField.leadingAnchor constraintEqualToAnchor:self.inputContainerView.leadingAnchor],
        [self.emailField.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor],
        [self.emailField.heightAnchor constraintEqualToConstant:44],
        
        // 分隔线
        [separatorLine.topAnchor constraintEqualToAnchor:self.emailField.bottomAnchor],
        [separatorLine.leadingAnchor constraintEqualToAnchor:self.inputContainerView.leadingAnchor constant:40],
        [separatorLine.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor],
        [separatorLine.heightAnchor constraintEqualToConstant:0.5],
        
        // 密码输入框
        [self.passwordField.topAnchor constraintEqualToAnchor:separatorLine.bottomAnchor],
        [self.passwordField.leadingAnchor constraintEqualToAnchor:self.inputContainerView.leadingAnchor],
        [self.passwordField.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor],
        [self.passwordField.heightAnchor constraintEqualToConstant:44],
        
        // 记住密码区域
        [self.rememberContainerView.topAnchor constraintEqualToAnchor:self.inputContainerView.bottomAnchor constant:16],
        [self.rememberContainerView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [self.rememberContainerView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [self.rememberContainerView.heightAnchor constraintEqualToConstant:30],
        
        [self.rememberLabel.leadingAnchor constraintEqualToAnchor:self.rememberContainerView.leadingAnchor],
        [self.rememberLabel.centerYAnchor constraintEqualToAnchor:self.rememberContainerView.centerYAnchor],
        
        [self.rememberSwitch.trailingAnchor constraintEqualToAnchor:self.rememberContainerView.trailingAnchor],
        [self.rememberSwitch.centerYAnchor constraintEqualToAnchor:self.rememberContainerView.centerYAnchor],
        
        // 登录按钮
        [self.loginButton.topAnchor constraintEqualToAnchor:self.rememberContainerView.bottomAnchor constant:24],
        [self.loginButton.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [self.loginButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [self.loginButton.heightAnchor constraintEqualToConstant:50],
        
        // 隐私说明
        [privacyLabel.topAnchor constraintEqualToAnchor:self.loginButton.bottomAnchor constant:16],
        [privacyLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [privacyLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [privacyLabel.bottomAnchor constraintLessThanOrEqualToAnchor:contentView.bottomAnchor constant:-20]
    ]];
    
    // 添加按钮点击动画
    [self.loginButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.loginButton addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
}

#pragma mark - Button Animation

- (void)buttonTouchDown:(UIButton *)button {
    [UIView animateWithDuration:0.1 animations:^{
        button.transform = CGAffineTransformMakeScale(0.97, 0.97);
        button.alpha = 0.9;
    }];
}

- (void)buttonTouchUp:(UIButton *)button {
    [UIView animateWithDuration:0.1 animations:^{
        button.transform = CGAffineTransformIdentity;
        button.alpha = 1.0;
    }];
}

#pragma mark - Account Storage

- (void)loadSavedAccountInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedEmail = [defaults objectForKey:kSavedEmailKey];
    BOOL rememberPassword = [defaults boolForKey:kRememberPasswordKey];
    
    // 无论是否有保存的邮箱，都设置记住密码开关的状态
    self.rememberSwitch.on = rememberPassword;
    
    if (savedEmail) {
        self.emailField.text = savedEmail;
        
        if (rememberPassword) {
            // 从本地存储获取密码
            NSString *savedPassword = [defaults objectForKey:kSavedPasswordKey];
            if (savedPassword) {
                self.passwordField.text = savedPassword;
            }
        }
    }
}

- (void)saveAccountInfo:(NSString *)email password:(NSString *)password {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:email forKey:kSavedEmailKey];
    [defaults setBool:self.rememberSwitch.isOn forKey:kRememberPasswordKey];
    
    if (self.rememberSwitch.isOn && password) {
        // 保存密码到本地存储
        [defaults setObject:password forKey:kSavedPasswordKey];
    } else {
        // 清除保存的密码
        [defaults removeObjectForKey:kSavedPasswordKey];
    }
    
    [defaults synchronize];
}

- (void)clearSavedAccountInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:kSavedEmailKey];
    [defaults removeObjectForKey:kSavedPasswordKey];
    [defaults removeObjectForKey:kRememberPasswordKey];
    [defaults synchronize];
}

// 钥匙串相关方法已移除，改用本地存储

#pragma mark - Actions

- (void)loginButtonTapped {
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;
    
    if (!email || email.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"请输入Apple ID"];
        return;
    }
    
    if (!password || password.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"请输入密码"];
        return;
    }
    
    // 隐藏键盘
    [self.view endEditing:YES];
    
    [SVProgressHUD showWithStatus:@"正在登录..."];
    
    // 保存账号信息
    [self saveAccountInfo:email password:password];
    
    [[AppStoreAuth sharedInstance] loginWithEmail:email password:password completion:^(AppStoreAccount *account, NSError *error) {
        [SVProgressHUD dismiss];
        
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            if (self.loginCompletion) {
                self.loginCompletion(NO, error);
            }
        } else {
            
            
            [SVProgressHUD showSuccessWithStatus:@"登录成功"];
            if (self.loginCompletion) {
                self.loginCompletion(YES, nil);
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }];
}

- (void)cancelButtonTapped {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.loginCompletion) {
        self.loginCompletion(NO, [NSError errorWithDomain:@"Login" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"用户取消登录"}]);
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self loginButtonTapped];
    }
    return YES;
}

#pragma mark - UISwitch Actions

- (void)rememberSwitchValueChanged:(UISwitch *)sender {
    // 立即保存开关状态
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:kRememberPasswordKey];
    
    // 如果关闭了记住密码，清除已保存的密码
    if (!sender.isOn) {
        [defaults removeObjectForKey:kSavedPasswordKey];
    }
    
    [defaults synchronize];
}

@end
