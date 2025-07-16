//
//  UserProfileViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "UserProfileViewController.h"
#import "ShowOneAppViewController.h"
#import "NewProfileViewController.h"
#import "UserModelCell.h"
#import "AppInfoCell.h"
#import "AppInfoModel.h"
#import "CommentInputView.h"
#import "AppCommentCell.h"
#import "UserListViewController.h"
#import "EditUserProfileViewController.h"

//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface UserProfileViewController ()<TemplateSectionControllerDelegate, UITextViewDelegate, TemplateListDelegate, CommentInputViewDelegate,UIPageViewControllerDelegate,UIPageViewControllerDataSource>
@property (nonatomic, strong) UIImageView *avatarImageView;//头像
@property (nonatomic, strong) UILabel *nicknameLabel;//名字
@property (nonatomic, strong) UILabel *jianjie;//简介
@property (nonatomic, strong) UIButton *contact;//联系对方

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) UIButton *sortButton;

@property (nonatomic, strong) CommentInputView *commentInputView;// 输入框容器（含发送按钮）
@property (nonatomic, assign) CGFloat originalInputHeight; // 输入框原始高度（默认40）
@property (nonatomic, assign) CGFloat expandedInputHeight; // 展开后高度（100）


@property (nonatomic, strong) NSMutableArray <UserListViewController*>*viewControllers;
@property (nonatomic, strong) UIPageViewController *pageViewController; // 页面控制器
@property (nonatomic, strong) UserListViewController *currentVC;//所选择的控制器

@end

@implementation UserProfileViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"用户中心";
//    self.hidesVerticalScrollIndicator = YES;
//
//    self.templateListDelegate = self;
    

    
    self.originalInputHeight = 50;
    self.expandedInputHeight = 80;
    self.keyboardIsShow = NO;

    // 初始化UI
    [self setupSubviews];
    //注册键盘
    [self registerKeyboardNotifications];
    //初始化页面切换
    [self setupViewControllers];
    //设置页面
    [self setupPageViewController];
   
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
}

#pragma mark - 写UI

- (void)setupSubviews {
    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 70;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
    self.avatarImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editProfile:)];
    tapGesture.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.avatarImageView.userInteractionEnabled = YES;
    [self.avatarImageView addGestureRecognizer:tapGesture];
    
   
    [self.view addSubview:self.avatarImageView];
    
    // 昵称
    self.nicknameLabel = [[UILabel alloc] init];
    self.nicknameLabel.text = @"用户中心"; // 默认未注册
    self.nicknameLabel.font = [UIFont boldSystemFontOfSize:24];
    self.nicknameLabel.textAlignment = NSTextAlignmentCenter;
    self.nicknameLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editProfile:)];
    tapGesture2.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.nicknameLabel.userInteractionEnabled = YES;
    [self.nicknameLabel addGestureRecognizer:tapGesture2];
    [self.view addSubview:self.nicknameLabel];
    
    // 简介
    self.jianjie = [[UILabel alloc] init];
    self.jianjie.text = @"简介"; // 默认未注册
    self.jianjie.font = [UIFont boldSystemFontOfSize:14];
    self.jianjie.textAlignment = NSTextAlignmentCenter;
    self.jianjie.numberOfLines = 0;
    self.jianjie.textColor = [UIColor orangeColor];
    self.jianjie.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editProfile:)];
    tapGesture3.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.jianjie.userInteractionEnabled = YES;
    [self.jianjie addGestureRecognizer:tapGesture3];
    [self.view addSubview:self.jianjie];
    
    
    // 选项卡标题
    NSArray *titles = @[@"Apps", @"评论"];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:titles];
    self.segmentedControl.selectedSegmentIndex = 0;
    // 绑定事件（值改变时触发）
    [self.segmentedControl addTarget:self
                              action:@selector(segmentedControlValueChanged:)
                    forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];
    
    //排序
    self.sortButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sortButton.layer.cornerRadius = 15;
    self.sortButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.sortButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    self.sortButton.backgroundColor = [UIColor colorWithLightColor:[UIColor whiteColor] darkColor:[[UIColor whiteColor] colorWithAlphaComponent:0.2]];
    [self.sortButton setTitle:@"NEW" forState:UIControlStateNormal];
    [self.sortButton addTarget:self action:@selector(sortButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sortButton];
    
    self.contact = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.contact setTitle:@"联系TA" forState:UIControlStateNormal];
    [self.contact addTarget:self action:@selector(contactButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.contact];
    
    
    // 创建评论输入视图
    self.commentInputView = [[CommentInputView alloc] initWithOriginalHeight:50 expandedHeight:80];
    self.commentInputView.delegate = self;
    self.commentInputView.frame = CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 50);
    [self.view addSubview:self.commentInputView];
    [self.view bringSubviewToFront:self.commentInputView];
    
}

// 初始化子页面控制器
- (void)setupViewControllers {
    self.viewControllers = [NSMutableArray array];
    for (int i = 0; i < 2; i++) {
        UserListViewController *controller = [[UserListViewController alloc] init];
        controller.templateListDelegate = self;
        controller.hidesVerticalScrollIndicator = YES;
        controller.typeString = @"newest";
        controller.selectedIndex = i;
        controller.showMyApp = NO;
        controller.user_udid = self.userInfo.udid ? self.userInfo.udid:@"";
        controller.collectionView.backgroundColor = [UIColor clearColor];
        controller.view.backgroundColor = [UIColor clearColor];
        [controller.view removeDynamicBackground];
        [self.viewControllers addObject:controller];
        
    }
}

// 初始化分页控制器
- (void)setupPageViewController {
    // 配置分页控制器（水平滚动，带滚动效果）
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:@{UIPageViewControllerOptionInterPageSpacingKey: @10}];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    
    
    // 设置初始页面
    self.currentVC = self.viewControllers[0];
    [self.pageViewController setViewControllers:@[self.currentVC]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    // 添加到当前控制器
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    [self.view sendSubviewToBack:self.pageViewController.view];
}

#pragma mark - 设置和更新约束

//设置约束
- (void)setupViewConstraints {
    [self.contact mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-25);
        make.top.equalTo(self.view).offset(15);

    }];
    
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(25);
        make.centerX.equalTo(self.view);
        make.width.height.equalTo(@140);
       
    }];
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(15);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@200);
       
    }];
    [self.jianjie mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(15);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@(kWidth-40));
       
    }];
    //选项卡
    [self.segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.jianjie.mas_bottom).offset(15);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.width.equalTo(@100);
        make.height.equalTo(@30);
    }];
    //排序按钮
    [self.sortButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.jianjie.mas_bottom).offset(15);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.height.equalTo(@30);
        make.width.equalTo(@50);
    }];
    // 表格视图约束（合并冲突的旧约束）
    [self.pageViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sortButton.mas_bottom).offset(15);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
    
    CGFloat offsHeight = self.keyboardIsShow ? self.keyboardHeight : 0;
    self.commentInputView.frame = CGRectMake(0, self.viewHeight - offsHeight - self.originalInputHeight, kWidth, self.originalInputHeight);
    
    self.commentInputView.textView.frame = CGRectMake(10, 8, kWidth - 90, self.keyboardIsShow ? self.expandedInputHeight -10 : self.originalInputHeight -10);
    
    
}

//更新约束 拖动等会调用 适配UI
- (void)updateViewConstraints{
    //调用父类
    [super updateViewConstraints];
    
    
    if(self.currentVC.isScrollingUp && self.currentVC.scrollY >0 && self.currentVC.scrollY <=100){
        CGFloat width = 60;
        [self.avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(20);
            make.left.equalTo(self.view.mas_left).offset(20);
            make.width.height.equalTo(@(width));
        }];
        self.avatarImageView.layer.cornerRadius = width/2;
        
        [self.nicknameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(20);
            make.left.equalTo(self.avatarImageView.mas_right).offset(10);
            make.right.equalTo(self.view.mas_right).offset(-20);
            
        }];
        self.nicknameLabel.textAlignment = NSTextAlignmentLeft;
        
        [self.jianjie mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.nicknameLabel.mas_bottom).offset(10);
            make.left.equalTo(self.avatarImageView.mas_right).offset(10);
            make.right.equalTo(self.view.mas_right).offset(-20);
            
        }];
        self.jianjie.textAlignment = NSTextAlignmentLeft;
        
    }else if(!self.currentVC.isScrollingUp && self.currentVC.scrollY <=20){
        [self.avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(25);
            make.centerX.equalTo(self.view);
            make.width.height.equalTo(@140);
            
        }];
        self.avatarImageView.layer.cornerRadius = 70;
        
        [self.nicknameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarImageView.mas_bottom).offset(15);
            make.centerX.equalTo(self.view);
            make.width.equalTo(@200);
            
        }];
        self.nicknameLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.jianjie mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.nicknameLabel.mas_bottom).offset(15);
            make.centerX.equalTo(self.view);
            make.width.equalTo(@(kWidth-40));
            
        }];
        self.jianjie.textAlignment = NSTextAlignmentCenter;
        
        
    }
    
    
    // 表格视图约束
    CGFloat offsetY = self.selectedIndex ==0 ? 0 :50;//如果在评论列表页面 上移动50给评论视图
    [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
       
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - offsetY);
    }];
    
    [UIView animateWithDuration:0.4 animations:^{
        //仅在评论列表显示发布评论视图
        self.commentInputView.alpha = self.selectedIndex;
        
        CGFloat offsHeight = self.keyboardIsShow ? self.keyboardHeight : 0;
        self.commentInputView.frame = CGRectMake(0, self.viewHeight - offsHeight - self.originalInputHeight, kWidth, self.originalInputHeight);
        self.commentInputView.textView.frame = CGRectMake(10, 8, kWidth - 90, self.keyboardIsShow ? self.expandedInputHeight -10 : self.originalInputHeight -10);
        
        // 刷新布局
        [self.view layoutIfNeeded];
    }];
    
   

}

#pragma mark -  点击事件处理

- (void)segmentedControlValueChanged:(UISegmentedControl *)sender {
    self.selectedIndex = sender.selectedSegmentIndex;
    NSLog(@"点击了selectedIndex:%ld",self.selectedIndex);
    
    // 设置初始页面
    self.currentVC = (UserListViewController*)self.viewControllers[self.selectedIndex];
    [self.pageViewController setViewControllers:@[self.currentVC]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
    
    
    [self updateViewConstraints];
}

- (void)sortButtonTap:(UIButton*)button {
    NSArray *title = @[@"newest",@"hottest"];
    // 获取下标
    NSUInteger arrayIndex = [title indexOfObject:self.currentVC.typeString];
    //重置页码
    self.currentVC.page = 1;
    //取反操作
    self.currentVC.typeString = title[!arrayIndex];
    //设置排序
    self.currentVC.sort = arrayIndex;
    //重新加载数据
    [self.currentVC refreshLoadInitialData];
    //更新按钮
    NSString *buttonTitle = !arrayIndex ?@"HOT":@"NEW";
    [self.sortButton setTitle:buttonTitle forState:UIControlStateNormal];
    
    
    
}

- (void)contactButtonTap:(UIButton*)button{
    if(!self.userInfo)return;
    [self showContactActionSheetWithUserInfo:self.userInfo];
}

// 头像昵称点击 修改资料
- (void)editProfile:(UITapGestureRecognizer *)gestureRecognizer {
    
    NSString *myudid = [NewProfileViewController sharedInstance].userInfo.udid;
    if([self.userInfo.udid isEqualToString:myudid]){
        EditUserProfileViewController *vc = [EditUserProfileViewController new];
        vc.udid = self.userInfo.udid;
        [self presentPanModal:vc];
    }
}

// 显示联系作者的操作菜单
- (void)showContactActionSheetWithUserInfo:(UserModel *)userInfo {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"联系作者"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 1. 手机号（拨打电话）
    if (userInfo.phone.length == 11) {
        UIAlertAction *phoneAction = [UIAlertAction actionWithTitle:@"联系作者手机"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
            [self makePhoneCall:userInfo.phone];
        }];
        [alertController addAction:phoneAction];
    }
    
    // 2. Email（发送邮件）
    if (userInfo.email.length > 0 && [self isValidEmail:userInfo.email]) {
        UIAlertAction *emailAction = [UIAlertAction actionWithTitle:@"联系作者Email"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            [self sendEmailTo:userInfo.email];
        }];
        [alertController addAction:emailAction];
    }
    
    // 3. QQ（打开QQ聊天）
    if (userInfo.qq.length > 4) {
        UIAlertAction *qqAction = [UIAlertAction actionWithTitle:@"联系作者QQ"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
            [self openQQChat:userInfo.qq];
        }];
        [alertController addAction:qqAction];
    }
    
    // 4. 微信（提示复制微信号）
    if (userInfo.wechat.length > 4) {
        UIAlertAction *wechatAction = [UIAlertAction actionWithTitle:@"联系作者微信"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
            [self copyWechatID:userInfo.wechat];
        }];
        [alertController addAction:wechatAction];
    }
    
    // 5. TG（打开Telegram聊天）
    if (userInfo.tg.length > 4) {
        UIAlertAction *tgAction = [UIAlertAction actionWithTitle:@"联系作者TG"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
            [self openTelegramChat:userInfo.tg];
        }];
        [alertController addAction:tgAction];
    }
    
    // 取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    
    // 显示菜单
    
    [[self.view getTopViewController] presentViewController:alertController animated:YES completion:nil];
    
}

#pragma mark - 联系方式具体实现

// 拨打电话
- (void)makePhoneCall:(NSString *)phoneNumber {
    // 移除可能的空格或特殊字符
    NSString *cleanedPhone = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", cleanedPhone]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
        [[UIApplication sharedApplication] openURL:phoneURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开拨号界面"];
            }
        }];
    } else {
        [SVProgressHUD showErrorWithStatus:@"设备不支持拨打电话功能"];
    }
}

// 发送邮件
- (void)sendEmailTo:(NSString *)emailAddress {
    if (![self isValidEmail:emailAddress]) {
        [SVProgressHUD showErrorWithStatus:@"邮箱地址无效"];
        return;
    }
    
    NSURL *emailURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", emailAddress]];
    
    if ([[UIApplication sharedApplication] canOpenURL:emailURL]) {
        [[UIApplication sharedApplication] openURL:emailURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开邮件应用"];
            }
        }];
    } else {
        [SVProgressHUD showErrorWithStatus:@"未安装邮件应用"];
    }
}

// 打开QQ聊天（需要QQ客户端）
- (void)openQQChat:(NSString *)qqNumber {
    // QQ URL Scheme格式：mqq://im/chat?chat_type=wpa&uin=QQ号&version=1&src_type=web
    NSURL *qqURL = [NSURL URLWithString:[NSString stringWithFormat:@"mqq://im/chat?chat_type=wpa&uin=%@&version=1&src_type=web", qqNumber]];
    
    if ([[UIApplication sharedApplication] canOpenURL:qqURL]) {
        [[UIApplication sharedApplication] openURL:qqURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开QQ"];
            }
        }];
    } else {
        // 未安装QQ时提示复制QQ号
        [self copyTextToPasteboard:qqNumber tip:@"QQ号已复制，请手动添加好友"];
    }
}

// 复制微信号（微信没有直接聊天的URL Scheme，只能复制）
- (void)copyWechatID:(NSString *)wechatID {
    [self copyTextToPasteboard:wechatID tip:@"微信号已复制，请在微信中添加好友"];
}

// 打开Telegram聊天
- (void)openTelegramChat:(NSString *)tgUsername {
    // Telegram URL Scheme格式：tg://resolve?domain=用户名（不带@）
    NSString *cleanedUsername = [tgUsername stringByReplacingOccurrencesOfString:@"@" withString:@""];
    NSURL *tgURL = [NSURL URLWithString:[NSString stringWithFormat:@"tg://resolve?domain=%@", cleanedUsername]];
    
    if ([[UIApplication sharedApplication] canOpenURL:tgURL]) {
        [[UIApplication sharedApplication] openURL:tgURL options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                [SVProgressHUD showErrorWithStatus:@"无法打开Telegram"];
            }
        }];
    } else {
        // 未安装Telegram时提示复制用户名
        [self copyTextToPasteboard:tgUsername tip:@"TG用户名已复制，请在Telegram中搜索"];
    }
}

#pragma mark - 工具方法

// 验证邮箱格式
- (BOOL)isValidEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

// 复制文本到剪贴板并提示
- (void)copyTextToPasteboard:(NSString *)text tip:(NSString *)tip {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;
    [SVProgressHUD showSuccessWithStatus:tip];
}

// 显示弹窗（复用方法）
- (void)showAlertFromViewController:(UIViewController *)vc title:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    [vc presentViewController:alert animated:YES completion:nil];
}


#pragma mark - 读取用户数据

/// 更新用户模型并刷新UI
- (void)updateWithUserModel:(UserModel *)userModel {
    
    // 1. 更新昵称
    self.nicknameLabel.text = userModel.nickname.length > 0 ? userModel.nickname : @"用户名";
    
    // 2. 更新头像
    if (userModel.avatar.length > 0) {
        NSURL *avatarURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?time=%ld",localURL,userModel.avatar,(long)[NSDate date].timeIntervalSince1970]];
        NSLog(@"avatarURL:%@",avatarURL);
        // 加载图片，使用刷新缓存选项
        [self.avatarImageView sd_setImageWithURL:avatarURL
                              placeholderImage:self.avatarImageView.image?:[UIImage systemImageNamed:@"person.crop.circle.fill"]
                                         options:SDWebImageRefreshCached completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if(image){
                self.avatarImageView.image = image;
                
            }
        }];
    }
    // 统计信息（下载量+注册时间）
    NSString *total = [NSString stringWithFormat:@"发布APP: %ld 个 · 收到攒: %ld · 评论: %ld\n", userModel.app_count,userModel.like_count,userModel.reply_count];
    NSString *registerDate = [TimeTool getTimeformatDateForDay:userModel.register_time];
    self.jianjie.text = [NSString stringWithFormat:@"%@注册于 %@", total, registerDate];
}


// 请求用户数据
- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid {
    _user_udid = udid;
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
            if(!jsonResult && stringResult){
                [self showAlertFromViewController:self title:@"请求返回错误" message:stringResult];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *message = jsonResult[@"message"];
            
            if (code == 200) {
                NSDictionary *data =jsonResult[@"data"];
                NSLog(@"读取用户数据字典:%@",data);
                self.userInfo = [UserModel yy_modelWithDictionary:data];
                if(self.userInfo.udid.length>5){
                    [self updateWithUserModel:self.userInfo];
                    
                    for (UserListViewController *vc in self.viewControllers) {
                        vc.user_udid = self.userInfo.udid;
                        
                        static dispatch_once_t onceToken;
                        dispatch_once(&onceToken, ^{
                            [vc loadDataWithPage:1];
                            
                        });
                        
                    }
                    
                    
                }
                
                
                
            }else{
                [self showAlertFromViewController:self title:@"请求返回错误" message:message];
            }
            
        });
        
    } failure:^(NSError *error) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        [self showAlertFromViewController:self title:@"请求返回错误" message:[NSString stringWithFormat:@"%@",error]];
    }];
}



/**
 * 当滚动视图滚动时调用此方法。
 *
 * @param offset 滚动视图的偏移量
 * @param isScrollingUp 表示滚动方向是否为向上滚动，YES 为向上滚动，NO 为向下滚动
 */
- (void)scrollViewDidScrollWithOffset:(CGFloat)offset isScrollingUp:(BOOL)isScrollingUp {
//    if(isScrollingUp){
//        NSLog(@"向上滚动:%f",offset);
//    }else{
//        NSLog(@"向下滚动:%f",offset);
//    }
    self.currentVC.isScrollingUp = isScrollingUp;
    [self updateViewConstraints];
}

#pragma mark - SectionController 代理协议

// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    if([model isKindOfClass:[AppInfoModel class]]){
        AppInfoModel *appInfoModel = (AppInfoModel *)model;
        NSLog(@"appInfoModel：%@",appInfoModel.app_name);
        ShowOneAppViewController *vc = [ShowOneAppViewController new];
        vc.app_id = appInfoModel.app_id;
        [self presentPanModal:vc];
        
        
    }
    
}



#pragma mark - 键盘事件
/// 注册键盘通知
- (void)registerKeyboardNotifications {
    // 键盘弹出通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    // 键盘收起通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

/// 键盘即将弹出
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardHeight = keyboardFrame.size.height;
    self.keyboardIsShow = YES;
    self.commentInputView.keyboardHeight = keyboardFrame.size.height;
    self.commentInputView.keyboardIsShow = YES;
    [self updateViewConstraints];
}

/// 键盘即将收起
- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    self.keyboardIsShow = NO;
    self.commentInputView.keyboardIsShow = NO;
    [self updateViewConstraints];

}


#pragma mark - 事件处理

// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    if(!self.user_udid)return;
    [self fetchUserInfoFromServerWithUDID:self.user_udid];
}


//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return NO;
}


//侧滑手势
- (BOOL)allowScreenEdgeInteractive{
    return NO;
}


- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取手势的位置
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    
    if (CGRectContainsPoint(self.pageViewController.view.frame, loc)) {
        return NO;
    }
    
    // 默认返回 YES，允许拖拽
    return YES;
}



#pragma mark - CommentInputViewDelegate
- (void)commentInputViewDidSendComment:(NSString *)content {
    // 处理评论发送逻辑（替换原sendComment方法）
    [self.commentInputView.textView resignFirstResponder];
    [self sendComment];
}


/// 发送评论
- (void)sendComment {
    NSLog(@"点击发送按钮");
    NSString *commentContent = [self.commentInputView.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (commentContent.length == 0) {
        [SVProgressHUD showInfoWithStatus:@"评论内容不能为空"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    
    // 隐藏键盘
    [self.commentInputView.textView resignFirstResponder];
    NSString *udid =[NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    Comment_type comment_type = Comment_type_UserComment;
    // 构建请求参数（根据实际接口调整）
    NSDictionary *params = @{
        @"action": @"user_comment",
        @"to_id": self.user_udid,
        @"comment_type": @(comment_type),
        @"content": commentContent,
        
    };
    
    [SVProgressHUD showWithStatus:@"发送中..."];
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
                                             parameters:params
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"发布评论返回:%@",jsonResult);
        NSLog(@"发布评论stringResult返回:%@",stringResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult || !jsonResult[@"code"]){
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"];
            
            if (code == 200) {
                [SVProgressHUD showSuccessWithStatus:msg];
                self.commentInputView.textView.text = @""; // 清空输入框
                self.commentInputView.textPromptLabel.alpha = 1;
                // 刷新评论列表（重新加载第一页）
                [self.currentVC loadDataWithPage:1];
            } else {
                [SVProgressHUD showErrorWithStatus:msg];
            }
            [SVProgressHUD dismissWithDelay:1];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"网络错误，发送失败"];
        [SVProgressHUD dismissWithDelay:2];
    }];
}

#pragma mark - UIPageViewControllerDataSource

// 返回上一页
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    UserListViewController * vc = (UserListViewController * )viewController;
    NSInteger index = [self.viewControllers indexOfObject:vc];
    NSLog(@"index:%ld",index);
    if (index <= 0) return nil; // 第一页没有上一页
    return self.viewControllers[index - 1];
}

// 返回下一页
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    UserListViewController * vc = (UserListViewController * )viewController;
    NSInteger index = [self.viewControllers indexOfObject:vc];
    NSLog(@"index:%ld",index);
    if (index >= self.viewControllers.count - 1) return nil; // 最后一页没有下一页
    return self.viewControllers[index + 1];
}

#pragma mark - UIPageViewControllerDelegate

// 页面切换完成后调用
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        // 获取当前显示的页面索引
        UserListViewController *VC = (UserListViewController*)pageViewController.viewControllers.firstObject;
        
        NSInteger index = [self.viewControllers indexOfObject:VC];
        self.selectedIndex = index;
        self.segmentedControl.selectedSegmentIndex = index;
        self.currentVC = self.viewControllers[index];
        self.currentVC.user_udid = self.userInfo.udid;
        
        NSArray *title = @[@"newest",@"hottest"];
        // 获取下标
        NSUInteger arrayIndex = [title indexOfObject:self.currentVC.typeString];
        
        NSString *buttonTitle = !arrayIndex ?@"HOT":@"NEW";
        [self.sortButton setTitle:buttonTitle forState:UIControlStateNormal];
        
        // 表格视图约束
        CGFloat offsetY = self.selectedIndex ==0 ? 0 :50;//如果在评论列表页面 上移动50给评论视图
        [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
           
            make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - offsetY);
        }];
        
        [UIView animateWithDuration:0.4 animations:^{
            //仅在评论列表显示发布评论视图
            self.commentInputView.alpha = self.selectedIndex;
            
            CGFloat offsHeight = self.keyboardIsShow ? self.keyboardHeight : 0;
            self.commentInputView.frame = CGRectMake(0, self.viewHeight - offsHeight - self.originalInputHeight, kWidth, self.originalInputHeight);
            self.commentInputView.textView.frame = CGRectMake(10, 8, kWidth - 90, self.keyboardIsShow ? self.expandedInputHeight -10 : self.originalInputHeight -10);
            
        }];
    }
}

@end
