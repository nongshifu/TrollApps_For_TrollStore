//
//  AppListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2026/3/26.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//


#import "AppStoreListViewController.h"
#import "AppStoreAuth.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import "LoginViewController.h"
#import "VersionCell.h"
#import "AppIconCell.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

// 苹果私有API 前置声明（用于调用系统下载管道）
@interface NSObject (SSDownloadPrivate)
+ (instancetype)sharedManager;
- (void)addDownload:(id)download;
- (instancetype)initWithMetadata:(id)metadata;
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *applicationVariant;
@property (nonatomic, copy) NSNumber *downloadPriority;
@property (nonatomic, copy) NSString *kind;
@property (nonatomic, assign) BOOL isUserInitiated;
@property (nonatomic, copy) NSNumber *itemIdentifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSNumber *versionIdentifier;
@property (nonatomic, copy) NSString *purchaseRedownloadParameters;
@end


@interface SSPurchase : NSObject
@property (nonatomic, copy) NSNumber *itemIdentifier;
@property (nonatomic, copy) NSString *buyParameters;
@end

@interface SSPurchaseManager : NSObject
+ (instancetype)sharedManager;
- (void)addPurchase:(SSPurchase *)purchase withCompletionBlock:(void(^)(NSError *error))completion;
@end


@interface AppStoreListViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <AppDowngradeModel *>*allApps;
@property (nonatomic, strong) NSArray <AppDowngradeModel *>*filteredApps;
@property (nonatomic, strong) NSArray *searchResults; // 搜索结果
@property (nonatomic, assign) BOOL isSearching; // 是否正在搜索

@property (nonatomic, strong) NSArray *currentVersionList; // 保存当前版本列表
@property (nonatomic, strong) AppDowngradeModel *currentApp; // 保存当前选中的APP
@property (nonatomic, strong) NSString *currentTrackId; // 保存当前trackId
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UILabel *bottomLabel; // 标题
@property (nonatomic, strong) UIButton *loginButton; // 登录按钮
@end

@implementation AppStoreListViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.isTapViewToHideKeyboard = YES;
    
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    //标题
    self.titleLabel = [UILabel new];
    self.titleLabel.text = @"应用降级工具";
    self.titleLabel.frame = CGRectMake(0, 0, kWidth, 50);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    // 标题
    self.bottomLabel = [UILabel new];
    self.bottomLabel.text = @"仅支持当前苹果账号再AppStore下载的APP\n第三方安装,巨魔,爱思等不支持";
    self.bottomLabel.frame = CGRectMake(0, self.viewHeight - 60, kWidth, 40);
    self.bottomLabel.numberOfLines = 2;
    self.bottomLabel.font = [UIFont systemFontOfSize:10];
    self.bottomLabel.textColor = [UIColor secondaryLabelColor];
    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.bottomLabel];
    
    // 登录按钮
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.frame = CGRectMake(20, self.viewHeight - 40, kWidth - 40, 30);
    self.loginButton.layer.cornerRadius = 10;
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];

    // 搜索框
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"搜索应用";
    self.searchBar.delegate = self;
    self.searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, 56);
    // 设置背景图片为透明
    [self.searchBar setBackgroundImage:[UIImage new]];
    
    // 设置搜索框的背景颜色
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        searchField.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3]
                                                         darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.1]
        ];
        searchField.layer.cornerRadius = 10.0;
        searchField.layer.masksToBounds = YES;
    }

    // 表格
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 50, kWidth-20, self.viewHeight - 130) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.2];
    
    self.tableView.layer.cornerRadius = 10;
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView registerClass:[AppIconCell class] forCellReuseIdentifier:@"AppIconCell"];
    
    [self.view addSubview:self.tableView];

    // 加载已安装APP
    [self loadInstalledApps];
    
    // 检查登录状态
    [self checkLoginStatus];
}

- (void)loadInstalledApps {
    self.allApps = [AppDowngradeModel getInstalledApps];
    self.filteredApps = self.allApps;
    NSLog(@"遍历系统App数量：%ld",self.allApps.count);
    [self.tableView reloadData];
}

- (void)checkLoginStatus {
    if ([[AppStoreAuth sharedInstance] isLoggedIn]) {
        AppStoreAccount *account = [[AppStoreAuth sharedInstance] getCurrentAccount];
        [self.loginButton setTitle:[NSString stringWithFormat:@"已登录: %@", account.email] forState:UIControlStateNormal];
        self.loginButton.backgroundColor = [UIColor systemGreenColor];
    } else {
        [self.loginButton setTitle:@"点击登录App Store" forState:UIControlStateNormal];
        self.loginButton.backgroundColor = [UIColor systemBlueColor];
    }
}

- (void)showLoginPrompt {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"需要登录" message:@"请登录App Store以获取应用历史版本" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentLoginViewController];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [[self.view getTopViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)loginButtonTapped {
    if (![[AppStoreAuth sharedInstance] isLoggedIn]) {
        [self presentLoginViewController];
    }
}

- (void)presentLoginViewController {
    LoginViewController *loginVC = [[LoginViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    loginVC.loginCompletion = ^(BOOL success, NSError *error) {
        if (success) {
            // 登录成功，更新登录状态
            [self checkLoginStatus];
            [self.tableView reloadData];
        }
    };
    [[self.view getTopViewController] presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UITableView

- (void)updateViewConstraints{
    [super updateViewConstraints];
    if(self.tableView.superview){
        self.tableView.frame = CGRectMake(10, 50, kWidth-20, self.viewHeight - 130);
    }
    if(self.bottomLabel.superview){
        self.bottomLabel.frame = CGRectMake(0, self.viewHeight - 80, kWidth, 40);
    }
    if(self.loginButton.superview){
        self.loginButton.frame = CGRectMake(20, self.viewHeight - 40, kWidth - 40, 30);
    }
}

#pragma mark - UITableView 代理（同时支持主列表、搜索结果和版本列表）
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 判断是不是版本列表的tableView
    if (tableView.tag == 999) {
        return self.currentVersionList.count;
    }
    
    // 搜索结果
    if (self.isSearching) {
        return self.searchResults.count;
    }
    
    // 原来的主列表
    return self.filteredApps.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 999) return 60;
    return 80; // 固定高度，不会再变
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 999) {
        VersionCell *cell = [[VersionCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"VersionCell"];
        NSDictionary *versionInfo = self.currentVersionList[indexPath.row];
        NSString *version = versionInfo[@"version"] ?: @"未知版本";
        NSString *buildId = versionInfo[@"buildId"] ?: @"";
        cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.2];
        cell.textLabel.text = [NSString stringWithFormat:@"版本 %@", version];
        cell.detailTextLabel.text = buildId.length > 0 ? [NSString stringWithFormat:@"Build: %@", buildId] : nil;
        return cell;
    }

    // ✅ 统一使用 filteredApps（本地搜索已经过滤好的）
    AppIconCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppIconCell" forIndexPath:indexPath];
    AppDowngradeModel *app = self.filteredApps[indexPath.row];
    
    cell.titleLabel.text = app.appName ?: @"";
    cell.subTitleLabel.text = [NSString stringWithFormat:@"%@  •  %@", app.bundleId, app.currentVersion];

    cell.appIconView.image = [UIImage _applicationIconImageForBundleIdentifier:app.bundleId
                                                                      format:(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) ? 8 : 10
                                                                       scale:[UIScreen mainScreen].scale] ?: [UIImage systemImageNamed:@"applelogo"];

    return cell;
}

#pragma mark - 核心：点击应用 → 弹出版本列表 → 选择后系统级下载（桌面显示进度）
#pragma mark - 核心：点击应用 → 底部弹窗选择操作
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 判断是不是版本列表的tableView
    if (tableView.tag == 999) {
        // 版本列表点击：选择版本，开始系统下载
        NSDictionary *versionInfo = self.currentVersionList[indexPath.row];
        NSString *buildId = versionInfo[@"buildId"] ?: @"";
        
        // 关闭底部卡片
        [self dismissViewControllerAnimated:YES completion:^{
            // 调用系统下载
            [self startSystemDownloadWithApp:self.currentApp trackId:self.currentTrackId buildId:buildId];
        }];
        return;
    }

    // ------------------------------
    // 统一获取当前点击的 App 模型
    // ------------------------------
    AppDowngradeModel *app = self.filteredApps[indexPath.row];

    // ------------------------------
    // 底部弹出选择菜单
    // ------------------------------
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:app.appName
                                                                     message:app.bundleId
                                                              preferredStyle:UIAlertControllerStyleActionSheet];

    // 1. 应用降级
    [sheet addAction:[UIAlertAction actionWithTitle:@"应用降级（历史版本）" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self startDowngradeWithApp:app];
    }]];

    // 2. 复制 App 标识符
    [sheet addAction:[UIAlertAction actionWithTitle:@"复制 App 标识符" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard.generalPasteboard.string = app.bundleId;
        [SVProgressHUD showSuccessWithStatus:@"已复制 BundleID"];
    }]];

    // 3. 打开 App Store
    [sheet addAction:[UIAlertAction actionWithTitle:@"打开 App Store" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openAppStoreWithApp:app];
    }]];

    // 取消
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    // 显示弹窗
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - 开始降级（原来的获取版本逻辑）
- (void)startDowngradeWithApp:(AppDowngradeModel *)app {
    [SVProgressHUD showWithStatus:@"正在获取历史版本..."];
    
    [AppDowngradeModel getAppTrackIdWithBundleId:app.bundleId completion:^(NSString * _Nonnull trackId, NSError * _Nonnull error) {
        if (error || !trackId) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"获取应用信息失败"];
                [SVProgressHUD dismissWithDelay:1];
            });
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AppDowngradeModel getAppHistoryVersionsWithTrackId:trackId completion:^(NSArray * _Nonnull versionList, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    if (error || versionList.count == 0) {
                        [SVProgressHUD showErrorWithStatus:@"暂无历史版本"];
                        [SVProgressHUD dismissWithDelay:1];
                        return;
                    }
                    [self showVersionList:versionList app:app trackId:trackId];
                });
            }];
        });
    }];
}

#pragma mark - 打开 App Store
- (void)openAppStoreWithApp:(AppDowngradeModel *)app {
    [SVProgressHUD showWithStatus:@"正在跳转到 App Store..."];
    
    [AppDowngradeModel getAppTrackIdWithBundleId:app.bundleId completion:^(NSString * _Nonnull trackId, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if (error || !trackId) {
                [SVProgressHUD showErrorWithStatus:@"获取 App Store 信息失败"];
                return;
            }
            // 打开 App Store
            NSString *urlStr = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", trackId];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr] options:@{} completionHandler:nil];
        });
    }];
}

#pragma mark - 底部弹出版本选择列表
- (void)showVersionActionSheet:(NSArray *)versionList app:(AppDowngradeModel *)app trackId:(NSString *)trackId {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ 历史版本", app.appName]
                                                                     message:@"选择版本后将自动在桌面下载安装"
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 取消按钮
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // 遍历添加所有历史版本
    for (NSDictionary *versionInfo in versionList) {
        NSString *versionStr = versionInfo[@"version"] ?: @"未知版本";
        NSString *buildId = versionInfo[@"buildId"] ?: @"";
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:versionStr style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"选择降级版本：%@ buildId：%@", versionStr, buildId);
            // 核心：调用系统下载管道，桌面显示进度
            [self startSystemDownloadWithApp:app trackId:trackId buildId:buildId];
        }];
        [sheet addAction:action];
    }
    
    [[self.view getTopViewController] presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - 核心：调用系统itunesstored服务，实现AppStore同款桌面下载进度
- (void)startSystemDownloadWithApp:(AppDowngradeModel *)app trackId:(NSString *)trackId buildId:(NSString *)buildId {
    // 检查是否已登录
    if (![[AppStoreAuth sharedInstance] isLoggedIn]) {
        [SVProgressHUD showErrorWithStatus:@"请先登录App Store"];
        [self showLoginPrompt];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"正在准备下载..."];
    
    // ====================== 动态获取私有类（关键：解决链接报错） ======================
    Class SSDownloadMetadataClass = NSClassFromString(@"SSDownloadMetadata");
    Class SSDownloadClass = NSClassFromString(@"SSDownload");
    Class SSDownloadManagerClass = NSClassFromString(@"SSDownloadManager");
    
    // 校验类是否存在（巨魔权限必备）
    if (!SSDownloadMetadataClass || !SSDownloadClass || !SSDownloadManagerClass) {
        [SVProgressHUD showErrorWithStatus:@"设备不支持系统降级"];
        return;
    }

    // 1. 动态创建 SSDownloadMetadata
    id metadata = [[SSDownloadMetadataClass alloc] init];
    [metadata setValue:@(trackId.longLongValue) forKey:@"itemIdentifier"];
    [metadata setValue:app.bundleId forKey:@"bundleIdentifier"];
    [metadata setValue:app.appName forKey:@"title"];
    [metadata setValue:@"software" forKey:@"kind"];
    [metadata setValue:@(YES) forKey:@"isUserInitiated"];
    [metadata setValue:@(1000) forKey:@"downloadPriority"];
    [metadata setValue:@"iOS" forKey:@"applicationVariant"];
    [metadata setValue:@(buildId.longLongValue) forKey:@"versionIdentifier"];
    
    // 核心重下参数
    NSString *params = [NSString stringWithFormat:@"productType=C&appExt=ipa&salableAdamId=%@&extVersionId=%@", trackId, buildId];
    [metadata setValue:params forKey:@"purchaseRedownloadParameters"];

    // 2. 动态创建 SSDownload
    id download = [[SSDownloadClass alloc] initWithMetadata:metadata];

    // 3. 动态调用 SSDownloadManager 提交下载
    id manager = [SSDownloadManagerClass sharedManager];
    [manager addDownload:download];
    
    [SVProgressHUD showSuccessWithStatus:@"已发起下载，请到桌面查看"];
    [SVProgressHUD dismissWithDelay:1.5];
}

#pragma mark - UISearchBar 搜索逻辑
#pragma mark - UISearchBar 搜索逻辑【本地搜索：appName + bundleId】
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (searchText.length == 0) {
        self.isSearching = NO;
        self.filteredApps = self.allApps;
        [self.tableView reloadData];
        return;
    }
    
    // 本地过滤：匹配 应用名称 或 BundleID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
        @"appName CONTAINS[cd] %@ OR bundleId CONTAINS[cd] %@",
        searchText, searchText
    ];
    
    self.filteredApps = [self.allApps filteredArrayUsingPredicate:predicate];
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    self.isSearching = NO;
    self.filteredApps = self.allApps;
    [self.tableView reloadData];
    [searchBar resignFirstResponder];
}


#pragma mark - 底部卡片弹出版本列表（美观版）
- (void)showVersionList:(NSArray *)versionList app:(AppDowngradeModel *)app trackId:(NSString *)trackId {
    // 保存数据，给后面的 tableView 用
    self.currentVersionList = versionList;
    self.currentApp = app;
    self.currentTrackId = trackId;
    
    // 创建一个简单的控制器来显示版本列表
    UIViewController *sheetVC = [[UIViewController alloc] init];
    sheetVC.title = [NSString stringWithFormat:@"%@ 历史版本", app.appName];
    sheetVC.view.backgroundColor = [UIColor clearColor];
    
    // 创建表格
    UITableView *tableView = [[UITableView alloc] initWithFrame:sheetVC.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tag = 999; // 标记这是版本列表的tableView
    [tableView registerClass:[VersionCell class] forCellReuseIdentifier:@"VersionCell"];
    [sheetVC.view addSubview:tableView];
    
    // 关闭按钮
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(closeVersionSheet)];
    sheetVC.navigationItem.leftBarButtonItem = closeItem;
    
    // 包装成导航控制器，方便显示标题
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sheetVC];
    
    // iOS 15+ 底部卡片样式
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        sheet.detents = @[
            [UISheetPresentationControllerDetent mediumDetent],
            [UISheetPresentationControllerDetent largeDetent]
        ];
        sheet.prefersGrabberVisible = YES;
        sheet.preferredCornerRadius = 20;
    }
    
    // 显示
    [[self.view getTopViewController] presentViewController:nav animated:YES completion:nil];
}

// 关闭底部卡片
- (void)closeVersionSheet {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 视图代理
- (BOOL)isAutoHandleKeyboardEnabled{
    return NO;
}

@end
