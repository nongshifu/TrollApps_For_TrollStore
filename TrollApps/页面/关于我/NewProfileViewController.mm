//
//  ProfileViewController.m
//  TrollApps
//

#import "NewProfileViewController.h"
#import "config.h"
#import <Masonry/Masonry.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
#import "MyFavoritesListViewController.h"
#import "UserModel.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "PublishAppViewController.h"
#import "VIPPackage.h"
#import "VIPPackageCell.h"
#import "TokenGenerator.h"
#import "NetworkClient.h"
#import "ProfileRightViewController.h"
#import "FeedbackViewController.h"
// 是否打印日志
#define MY_NSLog_ENABLED NO
#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface NewProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, TemplateSectionControllerDelegate, TemplateListDelegate>

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UIButton *udidButton;     // UDID获取按钮
@property (nonatomic, strong) UILabel *statusLabel;     // 显示获取状态
@property (nonatomic, strong) UILabel *vipExpireLabel;

@property (nonatomic, strong) UIAlertController *loadingAlert;


@property (nonatomic, assign) BOOL isAnimating; // 动画锁：YES表示正在执行动画
@property (nonatomic, assign) BOOL isBuyIng; // 操作锁：YES正在进行
@property (nonatomic, copy) NSString *localLongTermToken; // 本地存储的长效Token
@property (nonatomic, assign) NSTimeInterval tokenExpireTime; // Token过期时间（1个月）

@end

@implementation NewProfileViewController

+ (instancetype)sharedInstance {
    static NewProfileViewController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance loadUserInfo];
    });
    return sharedInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.templateListDelegate = self;
    
   
    
    // 初始化长效Token相关
    [self loadLongTermToken];
    
    // 设置UI
    [self setupSubviews];
    //设置左右视图
    [self setupSideMenuController];
    // 导航
    [self setupNavigationBar];
    // 设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    // 加载用户数据
    [self loadUserInfo];
    
    // 先加载本地VIP缓存
    [self loadLocalPackages];
    // 再加载远程数据
    [self loadVIPPackagesFromRemote];
    
    // 注册通知监听：UDID更新和App回调
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUDIDUpdatedNotification:)
                                                 name:@"UDIDUpdatedNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppSchemeCallback:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    self.hidesVerticalScrollIndicator = YES;
    self.hidesHorizontalScrollIndicator = YES;
    
}

#pragma mark - 长效Token管理（核心适配点1）
/// 加载本地存储的长效Token
- (void)loadLongTermToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.localLongTermToken = [defaults stringForKey:@"LongTermToken"];
    self.tokenExpireTime = [defaults doubleForKey:@"TokenExpireTime"];
    
    // 检查Token是否过期（1个月=2592000秒）
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime > self.tokenExpireTime) {
        NSLog(@"长效Token已过期，需要重新生成");
        self.localLongTermToken = nil;
        [self generateLongTermToken]; // 生成新的长效Token
    }
}

/// 生成长效Token（有效期1个月）
- (void)generateLongTermToken {
    NSString *idfv = [self getIDFV];
    if (idfv.length == 0) {
        NSLog(@"无法获取IDFV，生成Token失败");
        return;
    }
    
    // 使用TokenGenerator生成Token（与后端SecretKey一致）
    NSString *secretKey = @"a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q"; // 与后端保持一致
    self.localLongTermToken = [[TokenGenerator sharedGenerator] generateTokenWithUDID:idfv secret:secretKey];
    
    // 计算过期时间（当前时间+1个月）
    self.tokenExpireTime = [[NSDate date] timeIntervalSince1970] + 2592000;
    
    // 保存到本地
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.localLongTermToken forKey:@"LongTermToken"];
    [defaults setDouble:self.tokenExpireTime forKey:@"TokenExpireTime"];
    [defaults synchronize];
    NSLog(@"生成新的长效Token：%@，过期时间：%f", self.localLongTermToken, self.tokenExpireTime);
}

#pragma mark - App回调处理（核心适配点2）

/// 处理从浏览器跳转回App的参数
- (void)handleAppSchemeCallback:(NSNotification *)notification {
    // 从通知中获取URL
    NSURL *url = notification.userInfo[UIApplicationLaunchOptionsURLKey];
    if (!url || ![url.scheme isEqualToString:@"trollapps"]) {
        return;
    }
    
    // 解析URL参数
    NSString *query = url.query;
    if (query.length == 0) {
        return;
    }
    
    NSDictionary *params = [self dictionaryFromQueryString:query];
    NSLog(@"从浏览器回调获取参数：%@", params);
    
    // 提取UDID、user_id、token
    NSString *udid = params[@"udid"];
    NSString *userId = params[@"user_id"];
    NSString *token = params[@"token"];
    NSString *status = params[@"status"];
    
    if ([status isEqualToString:@"success"] && udid.length > 0) {
        // 保存UDID到本地
        [self saveUDID:udid];
        
        // 发送通知更新UI
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UDIDUpdatedNotification" object:nil];
        [SVProgressHUD showSuccessWithStatus:@"设备绑定成功"];
    } else if ([status isEqualToString:@"error"]) {
        NSString *message = params[@"message"] ?: @"设备绑定失败";
        [SVProgressHUD showErrorWithStatus:message];
    }
}

/// 将query字符串转为字典
- (NSDictionary *)dictionaryFromQueryString:(NSString *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *keyValue = [pair componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            NSString *key = [keyValue[0] stringByRemovingPercentEncoding];
            NSString *value = [keyValue[1] stringByRemovingPercentEncoding];
            dict[key] = value;
        }
    }
    return dict;
}

#pragma mark - UDID本地存储
/// 保存UDID到本地
- (void)saveUDID:(NSString *)udid {
    NSUUID *vendorID = [UIDevice currentDevice].identifierForVendor;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:udid forKey:[vendorID UUIDString]];
    [defaults synchronize];
}

/// 获取本地存储的UDID
- (NSString *)getUDID {
    // 优先从本地存储获取（通过描述文件获取的UDID）
    NSUUID *vendorID = [UIDevice currentDevice].identifierForVendor;
    NSString *savedUDID = [[NSUserDefaults standardUserDefaults] stringForKey:[vendorID UUIDString]];
    if (savedUDID.length > 0) {
        return savedUDID;
    }
    
    // 否则尝试通过系统接口获取（可能失败，仅作为备用）
    static CFStringRef (*$MGCopyAnswer)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    if (!gestalt) {
        NSLog(@"无法加载libMobileGestalt.dylib");
        return nil;
    }
    
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
    if (!$MGCopyAnswer) {
        NSLog(@"找不到MGCopyAnswer函数");
        dlclose(gestalt);
        return nil;
    }
    
    CFStringRef udidRef = $MGCopyAnswer(CFSTR("UniqueDeviceID"));
    NSString *udid = (__bridge_transfer NSString *)udidRef;
    dlclose(gestalt);
    return udid;
}

/// 获取本机IDFV
- (NSString *)getIDFV {
    return [KeychainTool readAndSaveIDFV];
}



#pragma mark - UI初始化与约束

- (void)setupSubviews {
    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 100;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
    self.avatarImageView.userInteractionEnabled = YES;
    [self.avatarImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeAvatar:)]];
    [self.view addSubview:self.avatarImageView];
    
    // 昵称
    self.nicknameLabel = [[UILabel alloc] init];
    self.nicknameLabel.text = @"未注册用户"; // 默认未注册
    self.nicknameLabel.font = [UIFont boldSystemFontOfSize:24];
    self.nicknameLabel.textAlignment = NSTextAlignmentCenter;
    self.nicknameLabel.userInteractionEnabled = YES;
    [self.nicknameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeNickname:)]];
    [self.view addSubview:self.nicknameLabel];
    
    // UDID按钮
    self.udidButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.udidButton setTitle:@"点击安装获取UDID" forState:UIControlStateNormal]; // 未获取时的文本
    [self.udidButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.udidButton.titleLabel.font = [UIFont systemFontOfSize:16];
    self.udidButton.backgroundColor = [UIColor blueColor];
    self.udidButton.layer.cornerRadius = 8;
    self.udidButton.layer.borderWidth = 1.0;
    self.udidButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
    [self.udidButton addTarget:self action:@selector(handleUDIDButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.udidButton];
    
    // 状态标签（小字提示）
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor systemOrangeColor];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.text = @"UDID用于设备绑定，仅本地存储"; // 提示文本
    [self.view addSubview:self.statusLabel];
    
    // VIP到期时间（默认隐藏）
    self.vipExpireLabel = [[UILabel alloc] init];
    self.vipExpireLabel.text = @"VIP到期时间: 未开通";
    self.vipExpireLabel.font = [UIFont systemFontOfSize:16];
    self.vipExpireLabel.numberOfLines = 0;
    self.vipExpireLabel.textAlignment = NSTextAlignmentCenter;
    self.vipExpireLabel.textColor = [UIColor systemOrangeColor];
    self.vipExpireLabel.hidden = YES; // 默认隐藏
    [self.view addSubview:self.vipExpireLabel];
    
    // 移除原有collectionView，添加备用视图（后期放VIP套餐表格）
    [self.collectionView removeFromSuperview];
    
    [self.view addSubview:self.collectionView];
}


//设置左侧菜单
- (void)setupSideMenuController {
    self.sideMenuController = [self getLGSideMenuController];
    
    // 设置侧滑阈值，这里设置为从屏幕边缘开始 20 点的距离才触发侧滑
    self.sideMenuController.leftViewController = [DemoBaseViewController new];
    self.sideMenuController.rightViewController = [ProfileRightViewController new];
    //设置宽度
    self.sideMenuController.leftViewWidth = 200;
    self.sideMenuController.rightViewWidth = 200;
    // 设置左侧菜单的滑动触发范围
    self.sideMenuController.swipeGestureArea = LGSideMenuSwipeGestureAreaBorders;//全屏可触摸
    //默认不允许触摸侧滑 按钮点击显示
    self.sideMenuController.leftViewSwipeGestureEnabled = YES;
    self.sideMenuController.rightViewSwipeGestureEnabled = YES;

    // 创建弱引用
    __weak typeof(self) weakSelf = self;
    //侧面出现后才可以滑动 用来隐藏
    self.sideMenuController.willShowLeftView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 禁用侧滑手势
        weakSelf.sideMenuController.leftViewSwipeGestureEnabled = YES;
    };

    self.sideMenuController.willHideLeftView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 在左侧菜单即将隐藏时，禁用左滑关闭菜单的手势
        weakSelf.sideMenuController.leftViewSwipeGestureEnabled = YES;
    };

    self.sideMenuController.willShowRightView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 禁用侧滑手势
        weakSelf.sideMenuController.rightViewSwipeGestureEnabled = YES;
    };

    self.sideMenuController.willHideRightView = ^(LGSideMenuController * _Nonnull sideMenuController, UIView * _Nonnull view) {
        // 在左侧菜单即将隐藏时，禁用左滑关闭菜单的手势
        weakSelf.sideMenuController.rightViewSwipeGestureEnabled = YES;
    };
}


- (void)setupNavigationBar {
    self.zx_showSystemNavBar = NO;
    self.zx_hideBaseNavBar = NO;
    [self zx_removeNavGradientBac];
    self.zx_navBar.zx_lineViewHeight = 0;
    self.zx_navBarBackgroundColorAlpha = 0;
    
    [self zx_setLeftBtnWithImg:[UIImage systemImageNamed:@"star.lefthalf.fill"] clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        MyFavoritesListViewController *vc = [MyFavoritesListViewController new];
        [self presentPanModal:vc];
    }];
    [self zx_setSubLeftBtnWithText:@"反馈" clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        FeedbackViewController *vc = [FeedbackViewController new];
        [self presentPanModal:vc];
    }];
    
    
    [self zx_setRightBtnWithImg:[UIImage systemImageNamed:@"gear"] clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        [self.sideMenuController showRightViewAnimated];
    }];
    [self zx_setSubRightBtnWithImg:[UIImage systemImageNamed:@"arrow.2.circlepath"] clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        
        [self loadUserInfo];
        [self animationUI];
    }];
}


#pragma mark - 约束设置与更新

- (void)setupViewConstraints {
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    
    // 头像约束（200x200圆形）
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(safeInsets.top + 60 + get_TOP_NAVIGATION_BAR_HEIGHT);
        make.centerX.equalTo(self.view);
        make.width.height.equalTo(@200);
    }];
    
    // 昵称约束（加粗大字）
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@30);
    }];
    
    // UDID按钮约束
    [self.udidButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(10);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@40);
        make.width.equalTo(@(kWidth-80));
    }];
    
    // 状态标签约束（小字提示）
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.udidButton.mas_bottom).offset(5);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@15);
    }];
    
    // VIP到期时间约束
    [self.vipExpireLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statusLabel.mas_bottom).offset(10);
        make.centerX.equalTo(self.view);
    }];
    
    // 备用视图约束（后期VIP套餐表格）
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipExpireLabel.mas_bottom).offset(20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view.mas_bottom).offset(-get_BOTTOM_TAB_BAR_HEIGHT - 10);
    }];
    
    
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    [UIView animateWithDuration:0.5 animations:^{
        if(self.isScrollingUp && self.scrollY >0 && self.scrollY <=100){
            [self.avatarImageView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@100);
            }];
            self.avatarImageView.layer.cornerRadius = 50;
        }else if(!self.isScrollingUp && self.scrollY <=20){
            [self.avatarImageView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@200);
            }];
            self.avatarImageView.layer.cornerRadius = 100;
        }
        
        // 关键点：添加这行代码强制立即布局
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - 核心：统一UI更新方法
/**
 统一更新用户信息与UI展示
 @param userModel 用户信息模型
 */
- (void)updateUserInfoWithUserModel:(UserModel *)userModel {
    NSLog(@"请求idfv用户数据nickname:%@",userModel.nickname);
    if (!userModel) return;
    
    // 保存最新用户模型
    self.userInfo = userModel;
    
    // 1. 更新昵称
    self.nicknameLabel.text = userModel.nickname.length > 0 ? userModel.nickname : @"未注册用户";
    
    // 2. 更新头像
    if (userModel.avatar.length > 0) {
        NSURL *avatarURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?time=%ld",localURL,userModel.avatar,(long)[NSDate date].timeIntervalSince1970]];
        NSLog(@"avatarURL:%@",avatarURL);
        // 加载图片，使用刷新缓存选项
        [self.avatarImageView sd_setImageWithURL:avatarURL
                              placeholderImage:self.avatarImageView.image?:[UIImage systemImageNamed:@"person.crop.circle.fill"]
                                         options:SDWebImageRefreshCached completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if(image){
                self.userInfo.avatarImage = image;
                CGFloat width = 30;
                self.minImage = [image resizedImageToSize:CGSizeMake(width, width) contentMode:UIViewContentModeScaleAspectFit];
                
                [self saveAvatarToCache:image];
            }
        }];
    }
    
    // 3. 更新UDID显示（核心适配点）
    if (userModel.udid.length > 0) {
        // 已获取UDID
        [self.udidButton setTitle:userModel.udid forState:UIControlStateNormal];
        [self.udidButton setTitleColor:[UIColor colorWithLightColor:[UIColor greenColor] darkColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        self.udidButton.backgroundColor = [UIColor clearColor];
        self.udidButton.layer.borderColor = [UIColor systemGrayColor].CGColor;
        [self.udidButton removeTarget:self action:@selector(handleUDIDButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.udidButton addTarget:self action:@selector(copyIdentifier:) forControlEvents:UIControlEventTouchUpInside];
        self.statusLabel.text = @"UDID已获取，点击可复制";
        self.statusLabel.textColor = [UIColor systemGreenColor];
        
        // 显示VIP信息
        self.vipExpireLabel.hidden = NO;
    } else {
        // 未获取UDID
        [self.udidButton setTitle:@"点击安装获取UDID" forState:UIControlStateNormal];
        [self.udidButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        self.udidButton.backgroundColor = [UIColor blueColor];
        self.udidButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
        [self.udidButton removeTarget:self action:@selector(copyIdentifier:) forControlEvents:UIControlEventTouchUpInside];
        [self.udidButton addTarget:self action:@selector(handleUDIDButton:) forControlEvents:UIControlEventTouchUpInside];
        self.statusLabel.text = @"点击安装描述文件获取UDID，用于设备绑定";
        self.statusLabel.textColor = [UIColor systemOrangeColor];
        
        // 隐藏VIP信息
        self.vipExpireLabel.hidden = YES;
    }
    
    // 4. 更新VIP信息
    BOOL isVIPExpired = [UserModel isVIPExpiredWithDate:userModel.vip_expire_date];
    NSLog(@"是否到期:%d",isVIPExpired);
    NSMutableString *vipText = [NSMutableString string];
    
    // 处理VIP到期时间
    if (!isVIPExpired && userModel.vip_expire_date) {
        [vipText appendFormat:@"VIP到期时间: %@\n", [TimeTool getTimeformatDate:userModel.vip_expire_date]];
    }
    
    // 处理安装量
    if((long)userModel.downloads_number >9999){
        [vipText appendFormat:@"剩余安装量: 无限次"];
    }else{
        [vipText appendFormat:@"剩余安装量: %ld次", (long)userModel.downloads_number];
    }
    
    self.vipExpireLabel.text = vipText;
    
}

#pragma mark - 数据加载与处理
- (void)loadUserInfo {
    NSString *udid = [self getUDID];
    if (udid.length > 0) {
        [self fetchUserInfoFromServerWithUDID:udid];
    } else {
        [self fetchUserInfoFromServerWithIDFV:[self getIDFV]];
    }
}

- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid {

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
                self.userInfo = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
                [self updateUserInfoWithUserModel:self.userInfo];
            }
        });
    } failure:^(NSError *error) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        [self fetchUserInfoFromServerWithIDFV:[self getIDFV]];
    }];
}

- (void)fetchUserInfoFromServerWithIDFV:(NSString *)idfv {
    
    NSDictionary *dic = @{
        @"action":@"getUserInfo",
        @"udid":idfv,
        @"type":@"idfv"
    };
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
                                             parameters:dic
                                                   udid:idfv progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"请求idfv用户数据:%@",stringResult);
            if(!jsonResult){
                [SVProgressHUD showErrorWithStatus:@"读取数据失败"];
                [SVProgressHUD dismissWithDelay:3];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if (code == 200) {
                
                self.userInfo = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
                NSLog(@"请求idfv用户数据:%@",self.userInfo);
                [self updateUserInfoWithUserModel:self.userInfo];
            }else{
                [SVProgressHUD showErrorWithStatus:msg];
                [SVProgressHUD dismissWithDelay:2];
            }
        });
    } failure:^(NSError *error) {
        NSLog(@"从服务器获取IDFV 读取资料失败：%@",error);
        [SVProgressHUD showErrorWithStatus:@"读取用户资料失败\n可尝试刷新"];
        [SVProgressHUD dismissWithDelay:2];

    }];
}

#pragma mark - UDID相关（核心适配点3）
- (void)handleUDIDButton:(UIButton *)sender {
    if ([self canAccessUDID]) {
        [self fetchAndDisplayDeviceIdentifier];
    } else {
        // 检查长效Token
        if (self.localLongTermToken.length == 0) {
            [self generateLongTermToken]; // 生成新Token
        }
        
        // 跳转到浏览器安装描述文件（携带IDFV和Token）
        [self installProfile];
    }
}

- (BOOL)canAccessUDID {
    return [self getUDID].length > 8;
}

- (void)fetchAndDisplayDeviceIdentifier {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *udid = [self getUDID];
        NSString *idfv = [self getIDFV];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (udid.length > 0) {
                [self.udidButton setTitle:udid forState:UIControlStateNormal];
                [self configureLoggedInUIWithIdentifier:udid isUDID:YES];
                [self fetchUserInfoFromServerWithUDID:udid];
            } else {
                [self.udidButton setTitle:idfv forState:UIControlStateNormal];
                [self configureLoggedInUIWithIdentifier:idfv isUDID:NO];
                [self fetchUserInfoFromServerWithIDFV:idfv];
            }
        });
    });
}

- (void)configureLoggedInUIWithIdentifier:(NSString *)identifier isUDID:(BOOL)isUDID {
    [self.udidButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    self.udidButton.backgroundColor = [UIColor clearColor];
    self.udidButton.layer.borderColor = [UIColor systemGrayColor].CGColor;
    [self.udidButton removeTarget:self action:@selector(handleUDIDButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.udidButton addTarget:self action:@selector(copyIdentifier:) forControlEvents:UIControlEventTouchUpInside];
    
    self.statusLabel.text = isUDID ? @"UDID已获取，点击可复制" : @"使用IDFV标识，点击可复制";
    self.statusLabel.textColor = isUDID ? [UIColor systemGreenColor] : [UIColor systemOrangeColor];
    
    // 显示VIP信息
    self.vipExpireLabel.hidden = NO;
}

- (void)copyIdentifier:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = sender.titleLabel.text;
    [self showAlertWithTitle:@"提示" message:@"已复制到剪贴板"];
}

- (void)installProfile {
    // 获取IDFV和长效Token
    NSString *idfv = [self getIDFV];
    NSString *token = self.localLongTermToken;
    
    // 构建请求URL（与后端profile_generator.php对应）
    NSString *url = [NSString stringWithFormat:@"%@/profile_generator.php?idfv=%@&token=%@",localURL, idfv, token];
    NSLog(@"访问安装描述文件:%@",url);
    NSURL *profileURL = [NSURL URLWithString:url];
    
    if ([[UIApplication sharedApplication] canOpenURL:profileURL]) {
        // 打开浏览器下载描述文件
        [[UIApplication sharedApplication] openURL:profileURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 提示用户安装完成后点击刷新
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示"
                                                                                   message:@"请完成描述文件的安装，安装后点击右上角刷新按钮"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:@"已安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self loadUserInfo];
                    }]];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                });
            } else {
                self.statusLabel.text = @"无法打开描述文件";
                self.statusLabel.textColor = [UIColor systemRedColor];
            }
        }];
    } else {
        self.statusLabel.text = @"无法打开描述文件";
        self.statusLabel.textColor = [UIColor systemRedColor];
    }
}

#pragma mark - 头像与昵称修改
- (void)changeAvatar:(UITapGestureRecognizer *)gesture {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改头像"
                                                                   message:@"请选择图片来源"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openCamera];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openPhotoLibrary];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [self showAlertWithTitle:@"提示" message:@"相机不可用"];
    }
}

- (void)openPhotoLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [self showAlertWithTitle:@"提示" message:@"相册不可用"];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    
    if (selectedImage) {
        self.userInfo.avatarImage = selectedImage;
        self.avatarImageView.image = selectedImage;
        [self uploadAvatar];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)targetSize {
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
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
            [self loadUserInfo];
        } else {
            [SVProgressHUD showErrorWithStatus:jsonResult[@"msg"] ?: @"更新失败"];
        }
    } failure:^(NSError *error) {
        NSLog(@"上传失败：%@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"网络错误：%@", error.localizedDescription]];
    }];
}

- (void)changeNickname:(UITapGestureRecognizer *)gesture {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改昵称"
                                                                   message:@"请输入新的昵称"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入昵称";
        textField.text = self.nicknameLabel.text;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newNickname = alert.textFields.firstObject.text;
        newNickname = [newNickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (newNickname.length == 0) {
            [self showAlertWithTitle:@"提示" message:@"昵称不能为空"];
        } else if (newNickname.length > 10) {
            [self showAlertWithTitle:@"提示" message:@"昵称长度不能超过10位"];
        } else {
            self.nicknameLabel.text = newNickname;
            self.userInfo.nickname = newNickname;
            [self updateUserInfoWithNickname:newNickname];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateUserInfoWithNickname:(NSString *)nickname {
    [SVProgressHUD showWithStatus:@"正在更新昵称...."];
    // 使用统一的更新方法
    self.userInfo.nickname = nickname;
    NSDictionary *dic = [self.userInfo yy_modelToJSONObject];
    NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    newDic[@"action"] = @"updateProfile";
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
                                             parameters:newDic
                                                   udid:self.userInfo.udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
           
            // 解析响应数据
            if (jsonResult) {
                NSInteger code = [jsonResult[@"code"] intValue];
               
                
                if (code ==200) {
                    NSDictionary *userData = jsonResult[@"data"];
                    
                    // 使用YYModel将数据映射到UserInfo对象
                    UserModel *updatedUserInfo = [UserModel yy_modelWithDictionary:userData];
                    
                    if (updatedUserInfo) {
                        // 更新单例中的用户信息
                        self.userInfo = updatedUserInfo;
                        [NewProfileViewController sharedInstance].userInfo = updatedUserInfo;
                 
                        // 显示成功提示
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" message:@"个人资料已更新" preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self loadUserInfo];
                        }]];
                        [self presentViewController:alert animated:YES completion:nil];
                        
                        return;
                    }
                }
            }
            
            // 如果解析失败，显示通用错误
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"更新失败，无法解析响应数据" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 停止加载指示器
            // 显示错误提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"失败" message:[NSString stringWithFormat:@"更新失败: %@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
    
}


#pragma mark - 其他功能
- (void)animationUI {
    if (self.isAnimating) return;
    self.isAnimating = YES;
    
    CGAffineTransform originalTransform = self.avatarImageView.transform;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.avatarImageView.transform = CGAffineTransformScale(originalTransform, 1.1, 1.1);
        self.nicknameLabel.transform = CGAffineTransformScale(originalTransform, 0.8, 0.8);
        self.udidButton.transform = CGAffineTransformScale(originalTransform, 0.9, 0.9);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.avatarImageView.transform = originalTransform;
            self.nicknameLabel.transform = originalTransform;
            self.udidButton.transform = originalTransform;
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
        }];
    }];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleUDIDUpdatedNotification:(NSNotification *)notification {
    [self loadUserInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self animationUI];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UDIDUpdatedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 数据加载
/// 加载本地缓存的套餐数据
- (void)loadLocalPackages {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"VIPPackagesCache"];
    if (data) {
        NSArray *dictArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (dictArray) {
            [self updateWithDictionaryArray:dictArray];
        }
    }
}

/// 从远程加载套餐数据
- (void)loadVIPPackagesFromRemote {
    // 格式化日期为时间戳或ISO格式
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSString *remoteDataURL = [NSString stringWithFormat:@"%@/vip.json?time=%@",localURL,timestamp];
    
    [SVProgressHUD showWithStatus:@"加载套餐中..."];
    
    NSDictionary *dictionary = @{
        @"action":@"loadVIPPackages"
    };
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodGET
                                              urlString:remoteDataURL
                                             parameters:dictionary
                                                   udid:[NewProfileViewController sharedInstance].userInfo.udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (jsonResult &&
                [jsonResult[@"status"] isEqualToString:@"success"] &&
                [jsonResult[@"data"] isKindOfClass:[NSArray class]]) {
                
                NSArray *packagesArray = jsonResult[@"data"];
                [self updateWithDictionaryArray:packagesArray];
                
                // 缓存到本地
                NSData *cacheData = [NSJSONSerialization dataWithJSONObject:packagesArray options:0 error:nil];
                if (cacheData) {
                    [[NSUserDefaults standardUserDefaults] setObject:cacheData forKey:@"VIPPackagesCache"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            } else {
                [SVProgressHUD showErrorWithStatus:@"加载套餐失败"];
                [SVProgressHUD dismissWithDelay:2];
            }
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"加载套餐失败"];
        [SVProgressHUD dismissWithDelay:2];
    }];
}

/// 用字典数组更新数据
- (void)updateWithDictionaryArray:(NSArray *)dictArray {
    NSLog(@"用字典数组更新数据:%@",dictArray);
    for (NSDictionary *dict in dictArray) {
        VIPPackage *package = [VIPPackage yy_modelWithDictionary:dict];
        if (package) {
            [self.dataSource addObject:package];
        }
    }
    [self refreshTable];
    [self handleNoMoreData];
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page {
    // 第一页时清空数据源
    if(page <=1 ){
        [self.dataSource removeAllObjects];
        [self loadVIPPackagesFromRemote];  // 再加载远程数据
    }else{
        NSLog(@"vip加载更多套餐");
    }
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    NSLog(@"表格模型：%@",object);
    if ([object isKindOfClass:[VIPPackage class]]) {
        return [[TemplateSectionController alloc] initWithCellClass:[VIPPackageCell class] modelClass:[VIPPackage class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 10, 0) cellHeight:50];
    }
    return nil;
}

#pragma mark - SectionController 代理协议
/// 刷新指定Cell
- (void)refreshCell:(UICollectionViewCell *)cell {
    NSLog(@"刷新指定Cell:%@",cell);
}

// 原始索引回调（保留 IGListKit 原生行为）
- (void)templateSectionController:(TemplateSectionController *)sectionController
             didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"点击了index:%ld",index);
}

// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    
    if([model isKindOfClass:[VIPPackage class]]){
        VIPPackage *vipPackage = (VIPPackage *)model;
        [self didSelectVIPPackage:vipPackage];
    }
}

#pragma mark - 购买VIP相关
- (void)didSelectVIPPackage:(VIPPackage *)package {
    if (self.isBuyIng) {
        [SVProgressHUD showInfoWithStatus:@"操作频繁-稍后重试"];
        [SVProgressHUD dismissWithDelay:1 completion:^{
            self.isBuyIng = NO;
        }];
        return;
    }
    
    self.isBuyIng = YES;
    NSString *udid = self.userInfo.udid;
    if (udid.length == 0) {
        [SVProgressHUD showInfoWithStatus:@"请先安装描述文件登录"];
        [SVProgressHUD dismissWithDelay:2 completion:^{
            self.isBuyIng = NO;
        }];
        return;
    }
    
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD dismissWithDelay:0.4 completion:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"购买确认"
                                                                       message:[NSString stringWithFormat:@"确定购买%@吗？", package.title]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self.isBuyIng = NO;
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self handlePurchaseWithPackage:package];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)handlePurchaseWithPackage:(VIPPackage *)package {
    self.loadingAlert = [UIAlertController alertControllerWithTitle:@"处理中"
                                                            message:@"正在处理购买请求..."
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:self.loadingAlert animated:YES completion:^{
        NSDictionary *parameters = @{
            
            @"udid": self.userInfo.udid,
            @"vipLevel": @(package.level),
            @"VIPPackage": [package yy_modelToJSONObject]
        };
        
        NSString *url = [NSString stringWithFormat:@"%@/purchase_vip.php", localURL];
        
        [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                  urlString:url
                                                 parameters:parameters
                                                       udid:self.userInfo.udid
                                                   progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"请求购买返回jsonResult:%@",jsonResult);
                NSLog(@"请求购买返回stringResult:%@",stringResult);
                [self handlePurchaseSuccessWithResponse:jsonResult package:package];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handlePurchaseFailureWithError:error];
            });
        }];
    }];
}

- (void)handlePurchaseSuccessWithResponse:(id)responseObject package:(VIPPackage *)package {
    self.isBuyIng = NO;
    [self.loadingAlert dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"购买结果返回:%@",responseObject);
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSInteger code = [responseObject[@"code"] intValue];
        NSString *message = responseObject[@"msg"];
        if (code ==200) {
            // 提取核心数据
            NSDictionary *dataDict = responseObject[@"data"];
            NSDictionary *userInfoDict = responseObject[@"userInfo"];
            NSLog(@"购买结果返回dataDict:%@",dataDict);
            // 更新用户信息
            if (userInfoDict) {
                UserModel *updatedUser = [UserModel yy_modelWithDictionary:userInfoDict];
                if (updatedUser) {
                    // 使用统一的UI更新方法
                    [self updateUserInfoWithUserModel:updatedUser];
                    
                    // 显示购买成功提示
                    NSString *message = [NSString stringWithFormat:@"您已成功购买%@！", package.title];
                    [self showAlertWithTitle:@"购买成功" message:message];
                }
            }
        }else{
            
            [self showAlertWithTitle:@"购买失败" message:message];
        }
        
        
    }
}

- (void)handlePurchaseFailureWithError:(NSError *)error {
    self.isBuyIng = NO;
    [self.loadingAlert dismissViewControllerAnimated:YES completion:nil];
    [self showAlertWithTitle:@"网络错误" message:@"购买失败，请检查网络连接"];
}

/**
 * 当滚动视图滚动时调用此方法。
 *
 * @param offset 滚动视图的偏移量
 * @param isScrollingUp 表示滚动方向是否为向上滚动，YES 为向上滚动，NO 为向下滚动
 */
- (void)scrollViewDidScrollWithOffset:(CGFloat)offset isScrollingUp:(BOOL)isScrollingUp{
    if(isScrollingUp){
        NSLog(@"向上滚动:%f",offset);
    }else{
        NSLog(@"向下滚动:%f",offset);
    }
    self.isScrollingUp = isScrollingUp;
    [self updateViewConstraints];
}

//输入框和键盘高度
- (CGFloat)keyboardOffsetFromInputView{
    return 100;
}


#pragma mark - 头像的保存
// 保存头像到本地缓存
- (void)saveAvatarToCache:(UIImage *)avatar {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = UIImagePNGRepresentation(avatar);
        if (imageData) {
            [imageData writeToFile:kAvatarCachePath atomically:YES];
            NSLog(@"头像已保存到本地缓存");
        }
    });
}

// 从本地缓存加载头像
- (UIImage *)loadAvatarFromCache {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:kAvatarCachePath]) {
        UIImage *cachedImage = [UIImage imageWithContentsOfFile:kAvatarCachePath];
        NSLog(@"从本地缓存加载头像成功");
        return cachedImage;
    }
    NSLog(@"本地缓存中没有头像");
    return nil;
}

// 清除头像缓存（可在用户登出等场景调用）
- (void)clearAvatarCache {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:kAvatarCachePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:kAvatarCachePath error:&error]) {
            NSLog(@"头像缓存已清除");
        } else {
            NSLog(@"清除头像缓存失败: %@", error.localizedDescription);
        }
    }
}

@end
