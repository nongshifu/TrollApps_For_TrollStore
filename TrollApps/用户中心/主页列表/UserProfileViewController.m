//
//  UserProfileViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
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
#import "ContactHelper.h"
#import "WebToolModel.h"
#import "MoodStatusModel.h"
#import "MyCollectionViewController.h"
#import "loadData.h"

// 目标 .m 文件顶部（必须在所有 #import 之前！）
#undef MY_NSLog_ENABLED // 取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // 当前文件单独启用

@interface UserProfileViewController ()<TemplateSectionControllerDelegate, UITextViewDelegate, TemplateListDelegate, CommentInputViewDelegate,UIPageViewControllerDelegate,UIPageViewControllerDataSource,UISearchBarDelegate>

@property (nonatomic, strong) UserModel *userInfo;

@property (nonatomic, strong) UIImageView *avatarImageView;//头像
@property (nonatomic, strong) UILabel *nicknameLabel;//名字
@property (nonatomic, strong) UILabel *bioLabel;//简介
@property (nonatomic, strong) UILabel *jianjie;//简介
@property (nonatomic, strong) UIButton *contact;//联系对方
@property (nonatomic, strong) UIButton *followButtom;//关注按钮
@property (nonatomic, strong) UIButton *showFollowListButton;//显示粉丝列表

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) UIButton *sortButton;

@property (nonatomic, strong) CommentInputView *commentInputView;// 输入框容器（含发送按钮）
@property (nonatomic, assign) CGFloat originalInputHeight; // 输入框原始高度（默认40）
@property (nonatomic, assign) CGFloat expandedInputHeight; // 展开后高度（100）


@property (nonatomic, strong) NSMutableArray <UserListViewController*>*viewControllers;
@property (nonatomic, strong) UIPageViewController *pageViewController; // 页面控制器
@property (nonatomic, strong) UserListViewController *currentVC;//所选择的控制器

@property (nonatomic, strong) UISearchBar *searchBar; // 搜索框
@property (nonatomic, assign) BOOL isSearch; // 搜索状态

@end

@implementation UserProfileViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"用户中心";

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
    
    
    // 初始化关注按钮（使用自定义类型，避免系统默认样式干扰）
    self.followButtom = [UIButton buttonWithType:UIButtonTypeCustom];
    self.followButtom.layer.cornerRadius = 10;
    self.followButtom.layer.masksToBounds = YES; // 确保圆角生效
    self.followButtom.titleLabel.font = [UIFont systemFontOfSize:13];
    self.followButtom.backgroundColor = [UIColor redColor];

    // 3. 可选：设置按钮文字（如需要）
    [self.followButtom setTitle:@"关注" forState:UIControlStateNormal];
    [self.followButtom setTitle:@"已关注" forState:UIControlStateSelected];
    [self.followButtom setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // 文字也设为白色
    self.followButtom.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10); // 整体内边距


    // 绑定点击事件
    [self.followButtom addTarget:self action:@selector(followButtomTap:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.followButtom];
    
    
    
    
    
    self.contact = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.contact setTitle:@"@ TA" forState:UIControlStateNormal];
    [self.contact addTarget:self action:@selector(contactButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.contact];
    
    // 昵称
    self.nicknameLabel = [[UILabel alloc] init];
    self.nicknameLabel.text = @"用户中心"; // 默认未注册
    self.nicknameLabel.font = [UIFont boldSystemFontOfSize:20];
    self.nicknameLabel.textAlignment = NSTextAlignmentCenter;
    self.nicknameLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editProfile:)];
    tapGesture2.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.nicknameLabel.userInteractionEnabled = YES;
    [self.nicknameLabel addGestureRecognizer:tapGesture2];
    [self.view addSubview:self.nicknameLabel];
    
    // 个性签名
    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.text = @"个性签名"; // 默认未注册
    self.bioLabel.font = [UIFont boldSystemFontOfSize:10];
    self.bioLabel.textAlignment = NSTextAlignmentCenter;
    self.bioLabel.numberOfLines = 3;
    self.bioLabel.textColor = [UIColor secondaryLabelColor];
    [self.view addSubview:self.bioLabel];
    
    
    // 简介
    self.jianjie = [[UILabel alloc] init];
    self.jianjie.text = @"简介"; // 默认未注册
    self.jianjie.font = [UIFont boldSystemFontOfSize:12];
    self.jianjie.textAlignment = NSTextAlignmentCenter;
    self.jianjie.numberOfLines = 0;
    self.jianjie.textColor = [UIColor orangeColor];
    self.jianjie.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editProfile:)];
    tapGesture3.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    self.jianjie.userInteractionEnabled = YES;
    [self.jianjie addGestureRecognizer:tapGesture3];
    [self.view addSubview:self.jianjie];
    
    self.showFollowListButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.showFollowListButton.layer.cornerRadius = 10;
    self.showFollowListButton.layer.masksToBounds = YES; // 确保圆角生效
    self.showFollowListButton.titleLabel.font = [UIFont systemFontOfSize:13];
    self.showFollowListButton.backgroundColor = [UIColor systemGrayColor];

    // 3. 可选：设置按钮文字（如需要）
    [self.showFollowListButton setTitle:@"查看Ta的 收藏/粉丝/关注" forState:UIControlStateNormal];
    
    [self.showFollowListButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // 文字也设为白色
    self.showFollowListButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10); // 整体内边距
    // 绑定点击事件
    [self.showFollowListButton addTarget:self action:@selector(showFollowListButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.showFollowListButton];
    
    
    // 选项卡标题
    NSArray *titles = @[@"App",@"工具", @"评论", @"动态"];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:titles];
    self.segmentedControl.selectedSegmentIndex = 0;
    // 绑定事件（值改变时触发）
    [self.segmentedControl addTarget:self
                              action:@selector(segmentedControlValueChanged:)
                    forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];
    
    // 搜索框（新增）
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 150, 35)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"搜索内容...";
    self.searchBar.searchTextField.layer.borderWidth = 1;
    self.searchBar.searchTextField.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.2].CGColor;
//    self.searchBar.alpha = 0;
    // 设置背景图片为透明
    [self.searchBar setBackgroundImage:[UIImage new]];
    
    // 设置搜索框的背景颜色
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        searchField.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3]
                                                         darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.1]
        ];
        searchField.font = [UIFont systemFontOfSize:12];
        searchField.layer.cornerRadius = 10.0;
        searchField.layer.masksToBounds = YES;
    }
    
    [self.view addSubview:self.searchBar];
    
    //排序
    self.sortButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sortButton.layer.cornerRadius = 15;
    self.sortButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.sortButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    self.sortButton.backgroundColor = [UIColor colorWithLightColor:[UIColor whiteColor] darkColor:[[UIColor whiteColor] colorWithAlphaComponent:0.2]];
    [self.sortButton setTitle:@"NEW" forState:UIControlStateNormal];
    
    [self.sortButton addTarget:self action:@selector(sortButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sortButton];
    
    self.contact = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.contact setTitle:@"@ Ta" forState:UIControlStateNormal];
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
    for (int i = 0; i < 4; i++) {
        UserListViewController *controller = [[UserListViewController alloc] init];
        controller.templateListDelegate = self;
        controller.hidesVerticalScrollIndicator = YES;
        controller.sort = self.sortButton.selected;
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
    CGFloat height = 36;
    [self.contact mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-25);
        make.top.equalTo(self.view).offset(15);

    }];
    
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(25);
        make.centerX.equalTo(self.view);
        make.width.height.equalTo(@140);
       
    }];
    [self.followButtom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.right.equalTo(self.avatarImageView);
        make.height.mas_equalTo(@25);
    }];
    
    
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(15);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@200);
       
    }];
    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(15);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@(kWidth-40));
       
    }];
    //简介数据摘要
    [self.jianjie mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioLabel.mas_bottom).offset(15);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@(kWidth-40));
       
    }];
    //粉丝列表按钮
    [self.showFollowListButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.jianjie.mas_bottom).offset(15);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(25);
    }];
    
    //选项卡
    [self.segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.showFollowListButton.mas_bottom).offset(15);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.height.mas_equalTo(height);
    }];
    
    
    
    //排序按钮
    [self.sortButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.segmentedControl);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.height.mas_equalTo(height);
        make.width.equalTo(@45);
    }];
    
    // 搜索框约束（新增）
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.segmentedControl.mas_right).offset(5);
        make.right.equalTo(self.sortButton.mas_left).offset(-5);
        make.height.mas_equalTo(height);
        make.centerY.equalTo(self.segmentedControl);
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
    
    
    if(self.currentVC.isScrollingUp && self.currentVC.scrollY >0 && self.currentVC.scrollY <=50){
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
        [self.bioLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.nicknameLabel.mas_bottom).offset(10);
            make.left.equalTo(self.avatarImageView.mas_right).offset(10);
            make.right.equalTo(self.view.mas_right).offset(-20);
            
        }];
        self.bioLabel.textAlignment = NSTextAlignmentLeft;
        
        [self.jianjie mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.bioLabel.mas_bottom).offset(10);
            make.left.equalTo(self.avatarImageView.mas_right).offset(10);
            make.right.equalTo(self.view.mas_right).offset(-20);
            
        }];
        self.jianjie.textAlignment = NSTextAlignmentLeft;
        
        
        [self.followButtom mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.avatarImageView.mas_bottom).offset(15);
            make.height.mas_equalTo(@20);
            make.centerX.equalTo(self.avatarImageView);
        }];
        self.followButtom.layer.cornerRadius = 10;
        
        [self.showFollowListButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.jianjie.mas_bottom).offset(15);
            make.left.equalTo(self.avatarImageView);
            make.height.mas_equalTo(25);
        }];
        
    }else if(!self.currentVC.isScrollingUp && self.currentVC.scrollY <=20){
        [self.avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(25);
            make.centerX.equalTo(self.view);
            make.width.height.equalTo(@140);
            
        }];
        self.avatarImageView.layer.cornerRadius = 70;
        [self.followButtom mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.right.equalTo(self.avatarImageView);
            make.height.mas_equalTo(@25);
        }];
        self.followButtom.layer.cornerRadius = 12.5;
        
        [self.nicknameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarImageView.mas_bottom).offset(15);
            make.centerX.equalTo(self.view);
            make.width.equalTo(@200);
            
        }];
        [self.bioLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.nicknameLabel.mas_bottom).offset(10);
            make.centerX.equalTo(self.view);
            make.width.equalTo(@(kWidth-40));
            
        }];
        self.bioLabel.textAlignment = NSTextAlignmentCenter;
        self.nicknameLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.jianjie mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.bioLabel.mas_bottom).offset(15);
            make.centerX.equalTo(self.view);
            make.width.equalTo(@(kWidth-40));
            
        }];
        self.jianjie.textAlignment = NSTextAlignmentCenter;
        
        [self.showFollowListButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.jianjie.mas_bottom).offset(15);
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(25);
        }];
        
        
    }
    
    
    [self.currentVC.scrollToTopButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.currentVC.collectionView.mas_bottom).offset(-10);
        make.width.height.equalTo(@35);
        make.right.equalTo(self.currentVC.collectionView.mas_right).offset(-10);
    }];
    
    
    // 表格视图约束
    CGFloat offsetY = self.selectedIndex == 2 ? 50 :0;//如果在评论列表页面 上移动50给评论视图
    [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
       
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - offsetY);
    }];
    
    
    [UIView animateWithDuration:0.4 animations:^{
        //仅在评论列表显示发布评论视图 并且非搜索状态
        self.commentInputView.alpha = (self.selectedIndex == 2 && !self.isSearch);
        
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
    
    //读取数据
    if(self.currentVC.dataSource.count == 0 ){
        [self.currentVC loadDataWithPage:1];
    }
    NSString *title = self.currentVC.sort ? @"HOT" : @"NEW";
    [self.sortButton setTitle:title forState:UIControlStateNormal];
}

- (void)sortButtonTap:(UIButton*)button {
    
    //重置页码
    self.currentVC.page = 1;
    
    //设置排序
    self.currentVC.sort = !self.currentVC.sort;
    //设置按钮标题
    NSString *title = self.currentVC.sort ? @"HOT" : @"NEW";
    //设置按钮标题
    [button setTitle:title forState:UIControlStateNormal];
    //重新加载数据
    [self.currentVC refreshLoadInitialData];
    
    
}

- (void)contactButtonTap:(UIButton*)button{
    if(!self.userInfo)return;
    [[ContactHelper shared] showContactActionSheetWithUserInfo:self.userInfo];
    
}

// 头像昵称点击 修改资料
- (void)editProfile:(UITapGestureRecognizer *)gestureRecognizer {
    
    NSString *myudid = [NewProfileViewController sharedInstance].userInfo.udid;
    if([self.userInfo.udid isEqualToString:myudid] || [NewProfileViewController sharedInstance].userInfo.role){
        EditUserProfileViewController *vc = [EditUserProfileViewController new];
        vc.udid = self.userInfo.udid;
        [self presentPanModal:vc];
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

// 请求用户数据
- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid {
    _user_udid = udid;
    
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    [UserModel getUserInfoWithUdid:self.user_udid success:^(UserModel * _Nonnull userModel) {
        
        [self updateWithUserModel:userModel];
        
    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        [self showAlertFromViewController:self title:@"请求返回错误" message:[NSString stringWithFormat:@"%@",error]];
    }];
    
}

/// 更新用户模型并刷新UI
- (void)updateWithUserModel:(UserModel *)userModel {
    //设置页面用户
    self.userInfo = userModel;
    //设置页面udid
    self.user_udid = self.userInfo.udid;
    NSString *userDic = [userModel yy_modelToJSONString];
    NSLog(@"userDic:%@",userDic);
    [SVProgressHUD showImage:[UIImage systemImageNamed:@"smiley.fill"] status:userModel.mutualFollowStatusText];
    [SVProgressHUD dismissWithDelay:1];
    //读取数据
    for (int i = 0; i<self.viewControllers.count; i++) {
        UserListViewController *controller = self.viewControllers[i];
        controller.sort = NO;
        controller.selectedIndex = i;
        controller.showMyApp = NO;
        controller.user_udid = self.userInfo.udid;
        controller.keyword = self.searchBar.text;
        if(i == 0) [controller loadDataWithPage:1];
        
    }
    //刷新融云缓存
    [[loadData sharedInstance] refreshUserInfoCache:userModel];
    // 1. 更新昵称
    self.nicknameLabel.text = userModel.nickname.length > 0 ? userModel.nickname : @"用户名";
    
    // 2. 更新头像
    if (userModel.avatar.length > 0) {
        NSURL *avatarURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?time=%ld",userModel.avatar,(long)[NSDate date].timeIntervalSince1970]];
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
    self.bioLabel.text =userModel.bio.length>0 ? userModel.bio : @"个性签名";
    // 统计信息（下载量+注册时间）
    NSString *total = [NSString stringWithFormat:@"APP: %ld 个 · 收到攒: %ld · 评论: %ld · 粉丝量：%ld\n", userModel.app_count,userModel.like_count,userModel.reply_count,userModel.follower_count];
    NSString *registerDate = [TimeTool getTimeformatDateForDay:userModel.register_time];
    self.jianjie.text = [NSString stringWithFormat:@"%@注册于 %@", total, registerDate];
    if(userModel.isFollow){
        self.followButtom.selected = YES;
        self.followButtom.backgroundColor = [UIColor systemBlueColor];
    }
    if([userModel.udid isEqual:[NewProfileViewController sharedInstance].userInfo.udid]){
        self.followButtom.backgroundColor = [UIColor systemGrayColor];
        [self.followButtom setTitle:@"自己" forState:UIControlStateNormal];
        [self.followButtom setTitle:@"自己" forState:UIControlStateSelected];
        self.followButtom.enabled = NO;
    }
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
        if([appInfoModel.udid isEqualToString:self.userInfo.udid] || [self.user_udid isEqualToString:self.userInfo.udid]) return;
        NSLog(@"appInfoModel：%@",appInfoModel.app_name);
        ShowOneAppViewController *vc = [ShowOneAppViewController new];
        vc.app_id = appInfoModel.app_id;
        [self presentPanModal:vc];
        
        
    }
    else if([model isKindOfClass:[MoodStatusModel class]]){
        
        MoodStatusModel *moodStatusModel = (MoodStatusModel *)model;
        
        
        
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
    [self fetchUserInfoFromServerWithUDID:self.user_udid];
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    if(!self.user_udid)return;
    
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


#pragma mark - 关注按钮的点击

//查看粉丝列表
- (void)followButtomTap:(UIButton *)sender {
 
    
    // 这里添加网络请求逻辑（调用关注/取关接口）
    BOOL isFollow = sender.selected; // YES=关注，NO=取关
    [self requestFollowAction:!isFollow];
}

// 显示关注列表
- (void)showFollowListButtonTap:(UIButton *)sender {
    if(!self.userInfo.isShowFollows){
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"smiley"] status:@"对方设置了隐私-无法查看哦"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    MyCollectionViewController *vc = [MyCollectionViewController new];
    vc.selectedIndex = 0;
    vc.showFollowList = self.userInfo.isShowFollows;
    vc.target_udid = self.userInfo.udid;
    [self presentPanModal:vc];
 
}

// 模拟网络请求
- (void)requestFollowAction:(BOOL)isFollow {
    // 实际项目中调用接口，根据结果更新状态
    // 如果接口失败，需要将按钮状态还原：self.followButtom.selected = !isFollow;
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    // 构建请求参数（根据实际接口调整）
    NSDictionary *params = @{
        @"action": @"followAction",
        @"udid": udid,
        @"target_udid": self.user_udid,
        @"isFollow": @(isFollow),
        
    };
    
    [SVProgressHUD showWithStatus:@"发送中..."];
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user/user_api.php",localURL]
                                             parameters:params
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"关注用户返回jsonResult:%@",jsonResult);
        NSLog(@"关注用户返回stringResult:%@",stringResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult || !jsonResult[@"code"]){
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"];
            
            if (code == 200) {
                NSDictionary *data = jsonResult[@"data"];
                BOOL isFollow = [data[@"isFollow"] boolValue];
                self.followButtom.selected = isFollow;
                self.followButtom.backgroundColor = isFollow ? [UIColor systemBlueColor]:[UIColor systemPinkColor];
                if(isFollow){
                    [SendMessage sendRCIMTextMessageToUDID:self.user_udid messageText:@"我关注你了" success:^{
                        
                    } error:^(NSString * _Nonnull errorMsg) {
                        
                    }];
                }
                
            }
            [SVProgressHUD showSuccessWithStatus:msg];
            [SVProgressHUD dismissWithDelay:1];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"网络错误，发送失败"];
        [SVProgressHUD dismissWithDelay:2];
    }];
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
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    // 构建请求参数（根据实际接口调整）
    NSDictionary *params = @{
        @"action": @"user_comment",
        @"to_id": self.user_udid,
        @"action_type": @(Comment_type_UserComment),
        @"content": commentContent,
        
    };
    
    [SVProgressHUD showWithStatus:@"发送中..."];
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user/user_api.php",localURL]
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
        //设置按钮标题
        NSString *title = self.currentVC.sort ? @"HOT" : @"NEW";
        //设置按钮标题
        [self.sortButton setTitle:title forState:UIControlStateNormal];
        //读取数据
        if(self.currentVC.dataSource.count == 0 ){
            [self.currentVC loadDataWithPage:1];
        }
        
        // 表格视图约束
        CGFloat offsetY = self.selectedIndex == 2 ? 50 :0;//如果在评论列表页面 上移动50给评论视图
        [self.pageViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
           
            make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - offsetY);
        }];
        
        [UIView animateWithDuration:0.4 animations:^{
            //仅在评论列表显示发布评论视图
        
            self.commentInputView.alpha = self.selectedIndex ==2;
            
            CGFloat offsHeight = self.keyboardIsShow ? self.keyboardHeight : 0;
            self.commentInputView.frame = CGRectMake(0, self.viewHeight - offsHeight - self.originalInputHeight, kWidth, self.originalInputHeight);
            self.commentInputView.textView.frame = CGRectMake(10, 8, kWidth - 90, self.keyboardIsShow ? self.expandedInputHeight -10 : self.originalInputHeight -10);
            
        }];
    }
}


#pragma mark - UISearchBarDelegate

// 实时输入时触发（延迟搜索，避免频繁请求）
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // 延迟0.5秒执行，避免输入过程中频繁请求
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSearch:) object:nil];
    [self performSelector:@selector(handleSearch:) withObject:searchText afterDelay:0.5];
}

// 点击搜索按钮时触发
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.isSearch = NO;
    [searchBar resignFirstResponder]; // 收起键盘
    [self handleSearch:searchBar.text];
    [self updateViewConstraints];
}

// 取消搜索时触发
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    self.isSearch = NO;
    [self handleSearch:@""]; // 清空搜索
    [self updateViewConstraints];
}

// 处理搜索逻辑（同步关键词到子控制器）
- (void)handleSearch:(NSString *)keyword {
    NSString *trimmedKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // 同步到所有子控制器
    for (UserListViewController *vc in self.viewControllers) {
        vc.keyword = trimmedKeyword;
        vc.page = 1;
        [vc.dataSource removeAllObjects];
        [vc loadDataWithPage:vc.page];
    }
}

// 开始编辑时显示取消按钮
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    self.isSearch = YES;
    searchBar.showsCancelButton = NO;
    return YES;
}

// 结束编辑时隐藏取消按钮
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.isSearch = NO;
    searchBar.showsCancelButton = NO;
    [self updateViewConstraints];
}



@end
