#import "PrivacyPolicyViewController.h"
#import <WebKit/WebKit.h>
#import "Masonry.h"
#import <UIKit/UIKit.h>
#import "NewProfileViewController.h"
#import "config.h"
@interface PrivacyPolicyViewController ()

@property (nonatomic, strong) UIButton *agreeButton;
@property (nonatomic, strong) UIButton *disagreeButton;
@property (nonatomic, strong) NSString *policyURLString;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *versionDateLabel; // 用于显示版本日期的标签
@property (nonatomic, strong) UISegmentedControl *segmentedControl; // 添加分段控制器属性

@property (nonatomic, assign) BOOL userHasConsented;//用户是否同意过 判断新旧用户 显示选项卡
@property (nonatomic, strong) NSString *currentDisplayVersion; // 当前显示的版本号
@property (nonatomic, assign) BOOL isUserConsentedVersionSameAsLatest; // 用户同意版本和最新版本是否相同

@property (nonatomic, strong) NSString *userConsentedVersion; // 用户同意的版本，作为属性
@property (nonatomic, strong) NSString *userConsentedURL;


@property (nonatomic, strong) NSString *activePolicyVersion; // 最新版
@property (nonatomic, strong) NSString *activePolicyURL;




@end

@implementation PrivacyPolicyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.userHasConsented = NO;
    self.currentDisplayVersion = @"";
    self.isUserConsentedVersionSameAsLatest = NO;
    self.userConsentedVersion = @"";

    [self setupWebView];
    [self setupButtons];
    [self setupTitleLabel];
    [self setupSegmentedControl]; // 添加设置分段控制器的方法调用
    [self setupVersionDateLabel]; // 添加设置版本日期标签的方法调用
    [self checkPolicyVersionAndLoad];
    [self updateViewConstraints];
}

- (void)setupWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, self.viewHeight - 190) configuration:config];
    self.webView.UIDelegate = self;
    [self.view addSubview:self.webView];
}

- (void)setupButtons {
    CGFloat buttonWidth = 100;
    CGFloat buttonHeight = 40;
    CGFloat buttonY = self.viewHeight - buttonHeight - 20;

    self.agreeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.agreeButton.frame = CGRectMake(self.view.bounds.size.width / 2 - buttonWidth - 10, buttonY, buttonWidth, buttonHeight);
    [self.agreeButton setTitle:@"同意" forState:UIControlStateNormal];
    [self.agreeButton addTarget:self action:@selector(agreeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.agreeButton.layer setCornerRadius:8];
    [self.agreeButton setBackgroundColor:[UIColor systemGreenColor]];
    [self.agreeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.agreeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    [self.view addSubview:self.agreeButton];

    self.disagreeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.disagreeButton.frame = CGRectMake(self.view.bounds.size.width / 2 + 10, buttonY, buttonWidth, buttonHeight);
    [self.disagreeButton setTitle:@"拒绝" forState:UIControlStateNormal];
    [self.disagreeButton addTarget:self action:@selector(disagreeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.disagreeButton.layer setCornerRadius:8];
    [self.disagreeButton setBackgroundColor:[UIColor systemRedColor]];
    [self.disagreeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.disagreeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    [self.view addSubview:self.disagreeButton];
}

- (void)setupTitleLabel {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"隐私政策";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:self.titleLabel];
}

- (void)setupSegmentedControl {
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"最新版政策", @"用户同意版本"]];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];
    [self.segmentedControl setSelectedSegmentIndex:0];
    self.segmentedControl.hidden = YES; // 初始隐藏分段控制器
}

- (void)setupVersionDateLabel {
    self.versionDateLabel = [[UILabel alloc] init];
    self.versionDateLabel.textAlignment = NSTextAlignmentCenter;
    self.versionDateLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.versionDateLabel];
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20);
        make.width.equalTo(self.view);
        make.centerX.equalTo(self.view);
    }];

    [self.segmentedControl mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
        make.width.equalTo(self.view).multipliedBy(0.8);
        make.centerX.equalTo(self.view);
        if(!self.isUserConsentedVersionSameAsLatest){
            make.height.equalTo(@30);
        }else{
            make.height.equalTo(@0);
        }
    }];

    [self.webView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom).offset(10);
        make.width.equalTo(self.view);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - 80); // 调整高度以留出空间给版本日期标签
    }];

    CGFloat buttonWidth = 100;
    CGFloat buttonHeight = 40;

    [self.agreeButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.webView.mas_bottom).offset(10);
        make.width.equalTo(@(buttonWidth));
        make.height.equalTo(@(buttonHeight));
        make.left.equalTo(self.view).offset(50);
    }];

    [self.disagreeButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.webView.mas_bottom).offset(10);
        make.width.equalTo(@(buttonWidth));
        make.height.equalTo(@(buttonHeight));
        make.right.equalTo(self.view).offset(-50);
    }];

    [self.versionDateLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.agreeButton.mas_bottom).offset(10);
        make.width.equalTo(self.view);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@20);
    }];
    [UIView animateWithDuration:0.4 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)checkPolicyVersionAndLoad {
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid?:@"";
    NSString *urlString = [NSString stringWithFormat:@"%@/privacy_policies/get_privacy_policy.php?udid=%@",localURL, udid];
    NSDictionary *dic =@{
        @"udid":udid
    };
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodGET urlString:urlString parameters:dic udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        if(!jsonResult){
            NSLog(@"隐私读取错误:%@",stringResult);
            return;
        }
        
        self.activePolicyVersion = jsonResult[@"active_policy_version"];
        self.activePolicyURL = jsonResult[@"active_policy_url"];
        self.userConsentedVersion = jsonResult[@"user_consented_version"]; // 赋值给属性
        self.userConsentedURL = jsonResult[@"user_consented_url"];

        // 处理可能的空值
        if ([self.activePolicyVersion isKindOfClass:[NSNull class]]) {
            self.activePolicyVersion = nil;
        }
        if ([self.activePolicyURL isKindOfClass:[NSNull class]]) {
            self.activePolicyURL = nil;
        }
        if ([self.userConsentedVersion isKindOfClass:[NSNull class]]) {
            self.userConsentedVersion = nil;
        }
        if ([self.userConsentedURL isKindOfClass:[NSNull class]]) {
            self.userConsentedURL = nil;
        }

        // 根据用户同意记录更新 userHasConsented 是否同意过
        self.userHasConsented = (self.userConsentedVersion!= nil);

        // 判断用户同意版本和最新版本是否相同
        self.isUserConsentedVersionSameAsLatest = (self.activePolicyVersion && self.userConsentedVersion && [self.activePolicyVersion isEqualToString:self.userConsentedVersion]);
        // 读取失败
        if (!self.activePolicyVersion || !self.activePolicyURL) {
            NSLog(@"服务器返回的最新政策版本号或URL为空，无法更新");
            [SVProgressHUD showErrorWithStatus:@"读取隐私政策失败\n请稍后重试"];
            [SVProgressHUD dismissWithDelay:3 completion:^{
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                //设置当前显示的版本
                self.currentDisplayVersion = self.activePolicyVersion;
                //最新版URL
                self.policyURLString = [NSString stringWithFormat:@"%@/privacy_policies/%@",localURL, self.activePolicyURL];
                
            }else{
                //设置当前显示的版本
                self.currentDisplayVersion = self.userConsentedVersion;
                //最新版URL
                self.policyURLString = [NSString stringWithFormat:@"%@/privacy_policies/%@",localURL, self.userConsentedURL];
                
            }
            NSURL *policyURL = [NSURL URLWithString:self.policyURLString];
            NSURLRequest *policyRequest = [NSURLRequest requestWithURL:policyURL];
            //显示
            [self.webView loadRequest:policyRequest];
            
            [self updateButtonAppearance];
            [self updateSegmentedControlVisibility]; // 更新分段控制器的可见性
            [self updateVersionDateLabel]; // 更新版本日期标签的文本
            [self updateViewConstraints];//更新约束
        });
        
    } failure:^(NSError *error) {
        
    }];
    
}

- (void)updateButtonAppearance {
    //如果用户同意过 并且当前显示的版本 和用户同意版本相同
    if (self.userHasConsented && [self.currentDisplayVersion isEqualToString:self.userConsentedVersion]) {
        [self.agreeButton setTitle:@"已同意" forState:UIControlStateNormal];
        UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark"];
        [self.agreeButton setImage:checkmarkImage forState:UIControlStateNormal];
//        [self.agreeButton setEnabled:NO];
//        [self.disagreeButton setEnabled:NO];
    } else {
        [self.agreeButton setTitle:@"同意" forState:UIControlStateNormal];
        [self.agreeButton setImage:nil forState:UIControlStateNormal];
        [self.agreeButton setEnabled:YES];
        [self.disagreeButton setEnabled:YES];
    }
}

- (void)updateSegmentedControlVisibility {
    if (self.isUserConsentedVersionSameAsLatest) {
        self.segmentedControl.hidden = YES;
    } else {
        self.segmentedControl.hidden = NO;
    }
}

- (void)updateVersionDateLabel {
    if (self.currentDisplayVersion.length > 0) {
        self.versionDateLabel.text = [NSString stringWithFormat:@"选择的版本日期: %@", self.currentDisplayVersion];
    } else {
        self.versionDateLabel.text = @"选择的版本日期: ";
    }
}

- (void)agreeButtonTapped {
    if (self.agreementHandler) {
        self.agreementHandler(YES);
    }

    // 同意最新版 更新数据库记录
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid?:@"";
    NSString *deviceInfo = [UIDevice currentDevice].model;
    NSString *ipAddress = @"your_ip_address";
    
    NSString *urlString = [NSString stringWithFormat:@"%@/privacy_policies/record_user_consent.php?udid=%@&policy_version=%@&device_info=%@&ip_address=%@",localURL, udid, self.activePolicyVersion, deviceInfo, ipAddress];
    NSLog(@"同意更新数据库记录urlString:%@",urlString);
    NSDictionary *dic = @{
        @"udid":udid,
        @"policy_version":self.activePolicyVersion,
        @"device_info":deviceInfo,
        @"ipAddress":ipAddress,
    };
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodGET urlString:urlString parameters:dic udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult){
                NSLog(@"stringResult:%@",stringResult);
                return;
            }
            self.userHasConsented = YES;
            [self updateButtonAppearance];
        });
        
    } failure:^(NSError *error) {
        
    }];
   
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)disagreeButtonTapped {
    
    if (self.agreementHandler) {
        self.agreementHandler(NO);
    }
    [self dismiss];
    exit(0);
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl {
    [self checkPolicyVersionAndLoad];
    
}

- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    if (CGRectContainsPoint(self.webView.frame, loc)) {
        return NO;
    }
    return YES;
}

@end
