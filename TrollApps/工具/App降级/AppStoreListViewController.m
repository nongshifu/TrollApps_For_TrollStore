//
//  AppListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2026/3/26.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "AppListViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
// 苹果私有API 前置声明（用于调用系统下载管道）
@interface SSDownloadMetadata : NSObject
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

@interface SSDownload : NSObject
- (instancetype)initWithMetadata:(SSDownloadMetadata *)metadata;
@end

@interface SSDownloadManager : NSObject
+ (instancetype)sharedManager;
- (void)addDownload:(SSDownload *)download;
@end

@interface SSPurchase : NSObject
@property (nonatomic, copy) NSNumber *itemIdentifier;
@property (nonatomic, copy) NSString *buyParameters;
@end

@interface SSPurchaseManager : NSObject
+ (instancetype)sharedManager;
- (void)addPurchase:(SSPurchase *)purchase withCompletionBlock:(void(^)(NSError *error))completion;
@end

// 简单的版本Cell
@interface VersionCell : UITableViewCell
@end
@implementation VersionCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}
@end

@interface AppListViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <AppDowngradeModel *>*allApps;
@property (nonatomic, strong) NSArray <AppDowngradeModel *>*filteredApps;

@property (nonatomic, strong) NSArray *currentVersionList; // 保存当前版本列表
@property (nonatomic, strong) AppDowngradeModel *currentApp; // 保存当前选中的APP
@property (nonatomic, strong) NSString *currentTrackId; // 保存当前trackId

@end

@implementation AppListViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"应用降级";

    // 搜索框
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"搜索应用";
    self.searchBar.delegate = self;
    self.searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, 56);

    // 表格
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    // 加载已安装APP
    [self loadInstalledApps];
}

- (void)loadInstalledApps {
    self.allApps = [AppDowngradeModel getInstalledApps];
    self.filteredApps = self.allApps;
    [self.tableView reloadData];
}

#pragma mark - UITableView

#pragma mark - UITableView 代理（同时支持主列表和版本列表）
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 判断是不是版本列表的tableView
    if (tableView.tag == 999) {
        return self.currentVersionList.count;
    }
    // 原来的主列表
    return self.filteredApps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 判断是不是版本列表的tableView
    if (tableView.tag == 999) {
        VersionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VersionCell" forIndexPath:indexPath];
        NSDictionary *versionInfo = self.currentVersionList[indexPath.row];
        NSString *version = versionInfo[@"version"] ?: @"未知版本";
        NSString *buildId = versionInfo[@"buildId"] ?: @"";
        
        cell.textLabel.text = [NSString stringWithFormat:@"版本 %@", version];
        cell.detailTextLabel.text = buildId.length > 0 ? [NSString stringWithFormat:@"Build: %@", buildId] : nil;
        return cell;
    }
    
    // 原来的主列表逻辑
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    AppDowngradeModel *app = self.filteredApps[indexPath.row];
    cell.textLabel.text = app.appName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  •  %@", app.bundleId, app.currentVersion];
    cell.imageView.image = app.appIcon ?: [UIImage imageNamed:@"default"];
    return cell;
}

#pragma mark - 核心：点击应用 → 弹出版本列表 → 选择后系统级下载（桌面显示进度）
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
    
    // 原来的主列表点击逻辑
    AppDowngradeModel *app = self.filteredApps[indexPath.row];
    [SVProgressHUD showWithStatus:@"正在获取历史版本..."];
    
    [AppDowngradeModel getAppTrackIdWithBundleId:app.bundleId completion:^(NSString * _Nonnull trackId, NSError * _Nonnull error) {
        if (error || !trackId) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"获取应用信息失败"];
            });
            return;
        }
        
        [AppDowngradeModel getAppHistoryVersionsWithTrackId:trackId completion:^(NSArray * _Nonnull versionList, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                if (error || versionList.count == 0) {
                    [SVProgressHUD showErrorWithStatus:@"暂无历史版本"];
                    return;
                }
                // 弹出版本列表
                [self showVersionList:versionList app:app trackId:trackId];
            });
        }];
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
    
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - 核心：调用系统itunesstored服务，实现AppStore同款桌面下载进度
- (void)startSystemDownloadWithApp:(AppDowngradeModel *)app trackId:(NSString *)trackId buildId:(NSString *)buildId {
    [SVProgressHUD showSuccessWithStatus:@"已发起下载，请到桌面查看进度"];
    [SVProgressHUD dismissWithDelay:1.5];
    
    // 1. 构造下载元数据
    SSDownloadMetadata *metadata = [[SSDownloadMetadata alloc] init];
    metadata.itemIdentifier = @(trackId.longLongValue); // 应用的Apple ID
    metadata.bundleIdentifier = app.bundleId; // 应用Bundle ID
    metadata.title = app.appName; // 应用名称
    metadata.kind = @"software"; // 类型：软件
    metadata.isUserInitiated = YES; // 用户主动发起
    metadata.downloadPriority = @(1000); // 最高优先级
    metadata.applicationVariant = @"iOS";
    metadata.versionIdentifier = @(buildId.longLongValue); // 目标版本的buildId
    
    // 构造重下载参数（核心：指定历史版本）
    metadata.purchaseRedownloadParameters = [NSString stringWithFormat:@"productType=C&appExt=ipa&salableAdamId=%@&extVersionId=%@", trackId, buildId];
    
    // 2. 创建下载任务
    SSDownload *download = [[SSDownload alloc] initWithMetadata:metadata];
    
    // 3. 提交给系统下载管理器，itunesstored进程接管，桌面自动显示进度
    [[SSDownloadManager sharedManager] addDownload:download];
}

#pragma mark - UISearchBar 搜索逻辑
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.filteredApps = self.allApps;
    } else {
        self.filteredApps = [self.allApps filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"appName CONTAINS[cd] %@ OR bundleId CONTAINS[cd] %@", searchText, searchText]];
    }
    [self.tableView reloadData];
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
    sheetVC.view.backgroundColor = [UIColor systemBackgroundColor];
    
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
    [self presentViewController:nav animated:YES completion:nil];
}

// 关闭底部卡片
- (void)closeVersionSheet {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
