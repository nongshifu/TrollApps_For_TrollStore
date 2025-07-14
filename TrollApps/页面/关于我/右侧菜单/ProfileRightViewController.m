

//
//  ProfileRightViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/12.
//

#import "ProfileRightViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <mach/mach.h>
#import <mach/task.h>
#import "EditUserProfileViewController.h"
#import "FeedbackViewController.h"
@interface ProfileRightViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UILabel *topTitle;
@property (nonatomic, strong) UITableView *tableView;
// 模拟分组数据
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *settingsGroups;
// 模拟分组标题
@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;
// 模拟副标题数据，改为可变数组
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSString *> *> *settingsSubTitles;


@end

@implementation ProfileRightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setTopTitle];
    [self setTableView];
    [self setupSettingsData];
    [self updateViewConstraints];
    
    
}


- (void)setTopTitle {
    self.topTitle = [[UILabel alloc] initWithFrame:CGRectMake(20,  [UIApplication sharedApplication].statusBarFrame.size.height, [UIScreen mainScreen].bounds.size.width, 30)];
    self.topTitle.text = @"设置中心";
    self.topTitle.font = [UIFont boldSystemFontOfSize:20];
    self.topTitle.textAlignment = NSTextAlignmentLeft;
    self.topTitle.textColor = [UIColor secondaryLabelColor];
    [self.view addSubview:self.topTitle];
}

- (void)setTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor]; // 设置表格背景透明
    self.tableView.layer.cornerRadius = 15; // 设置表格视图圆角为 15
    self.tableView.clipsToBounds = YES; // 裁剪超出圆角的部分
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // 去除分隔线
    // 调整分组头部和底部间距
    self.tableView.sectionHeaderHeight = 35;
    self.tableView.sectionFooterHeight = 0;
    // 隐藏滚动条
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.tableView];
}

- (void)setupSettingsData {
    // 账号与安全分组
    NSArray<NSString *> *accountSecurityGroup = @[@"账号信息"];
    NSMutableArray<NSString *> *accountSecuritySubTitles = [@[@"查看和修改账号信息"] mutableCopy];
    // 隐私设置分组
    NSArray<NSString *> *privacyGroup = @[@"隐私权限"];
    NSMutableArray<NSString *> *privacySubTitles = [@[@"权限检查"] mutableCopy];
   
    // 关于应用分组
    NSArray<NSString *> *aboutAppGroup = @[@"版本信息", @"检查更新", @"意见反馈", @"隐私政策"];
    NSMutableArray<NSString *> *aboutAppSubTitles = [@[@"查看应用当前版本", @"检查是否有新版本", @"提交使用意见和反馈", @"查看应用隐私政策"] mutableCopy];
    // 清理缓存分组
    NSArray<NSString *> *cacheGroup = @[@"清理图片缓存", @"应用内存占用", @"清理整个APP缓存"];
    NSUInteger sdImageCacheSize = [[SDImageCache sharedImageCache] totalDiskSize];
    int64_t usedMemory = [self getUsedMemory];
    int64_t sandboxSize = [self getSandboxSize];
    NSMutableArray<NSString *> *cacheSubTitles = [@[[NSString stringWithFormat:@"当前占用 %.2f MB", (float)sdImageCacheSize / (1024 * 1024)],
                                                    [NSString stringWithFormat:@"已使用 %.2f MB", (float)usedMemory / (1024 * 1024)],
                                                    [NSString stringWithFormat:@"当前占用 %.2f MB", (float)sandboxSize / (1024 * 1024)]] mutableCopy];
    NSArray<NSString *> *testGroup = @[@""];
    NSMutableArray<NSString *> *testSubTitles = [@[@""] mutableCopy];
    
    self.settingsGroups = @[accountSecurityGroup, privacyGroup, aboutAppGroup, cacheGroup, testGroup, testGroup];
    self.settingsSubTitles = [@[accountSecuritySubTitles, privacySubTitles, aboutAppSubTitles, cacheSubTitles, testSubTitles, testSubTitles] mutableCopy];
    self.sectionTitles = @[@"账号与安全", @"隐私设置", @"关于应用", @"清理缓存", @"TrollApps", @""];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.settingsGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.settingsGroups[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = self.settingsGroups[indexPath.section][indexPath.row];
    cell.detailTextLabel.text = self.settingsSubTitles[indexPath.section][indexPath.row];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3]; // 设置 cell 背景半透明，白色，透明度 0.3
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // 在这里处理单元格点击事件，例如跳转到相应的设置页面
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: {
                [self OpenEditUserProfileViewController];
                break;
            }
            
                
            default:
                break;
        }
    }
    //权限设置
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0: {
                [self openPrivacyPermission];
                break;
            }
        }
        
    }
    //关于应用
    else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0: {
                DemoBaseViewController *vc = [DemoBaseViewController new];
                [self presentPanModal:vc];
                break;
            }
                
                
            case 1: {
                
                break;
            }
            case 2: {
                FeedbackViewController *vc = [FeedbackViewController new];
                [self presentPanModal:vc];
                break;
            }

            default:
                break;
        }
    }
    
    // 清理缓存分组
    else if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0: { // 清理图片缓存
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认清理" message:@"确定要清理图片缓存吗？" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    [SVProgressHUD showWithStatus:@"正在清理图片缓存..."];
                    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
                        [SVProgressHUD dismiss];
                        NSUInteger sdImageCacheSize = [[SDImageCache sharedImageCache] totalDiskSize];
                        self.settingsSubTitles[indexPath.section][indexPath.row] = [NSString stringWithFormat:@"当前占用 %.2f MB", (float)sdImageCacheSize / (1024 * 1024)];
                        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                        NSLog(@"SD 图片缓存已清理");
                    }];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
                break;
            }
            case 1: { // 统计显示内存大小
                // 获取内存大小
                int64_t usedMemory = [self getUsedMemory];
                NSString *memoryString = [NSString stringWithFormat:@"已使用内存: %.2f MB", (float)usedMemory / (1024 * 1024)];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"内存信息" message:memoryString preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                break;
            }
            case 2: { // 清理整个沙盒缓存 大小显示
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认清理" message:@"确定要清理整个沙盒缓存吗？" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    [SVProgressHUD showWithStatus:@"正在清理沙盒缓存..."];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        // 清理沙盒缓存
                        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
                        NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:cachePath];
                        for (NSString *file in files) {
                            NSString *filePath = [cachePath stringByAppendingPathComponent:file];
                            NSError *error;
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                            if (error) {
                                NSLog(@"清理文件 %@ 失败: %@", filePath, error);
                            }
                        }
                        // 计算清理后的沙盒大小
                        int64_t sandboxSize = [self getSandboxSize];
                        NSString *sandboxString = [NSString stringWithFormat:@"清理后沙盒大小: %.2f MB", (float)sandboxSize / (1024 * 1024)];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD dismiss];
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"沙盒缓存信息" message:sandboxString preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                            // 更新副标题显示
                            self.settingsSubTitles[indexPath.section][indexPath.row] = [NSString stringWithFormat:@"当前占用 %.2f MB", (float)sandboxSize / (1024 * 1024)];
                            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                        });
                    });
                }]];
                [self presentViewController:alert animated:YES completion:nil];
                break;
            }
            default:
                break;
        }
    }
    NSLog(@"点击了设置项: %@", self.settingsGroups[indexPath.section][indexPath.row]);
}

// 获取已使用内存大小
- (int64_t)getUsedMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kerr == KERN_SUCCESS) {
        return info.resident_size;
    } else {
        return 0;
    }
}

// 获取沙盒大小
- (int64_t)getSandboxSize {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *tmpPath = NSTemporaryDirectory();
    NSArray *paths = @[documentsPath, cachePath, tmpPath];
    int64_t totalSize = 0;
    for (NSString *path in paths) {
        NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:path];
        for (NSString *file in files) {
            NSString *filePath = [path stringByAppendingPathComponent:file];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            if (attrs) {
                totalSize += [attrs fileSize];
            }
        }
    }
    return totalSize;
}

#pragma mark - 子类重写的方法
- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(get_TOP_NAVIGATION_BAR_HEIGHT + 50);
        make.bottom.equalTo(self.view).offset(-get_BOTTOM_TAB_BAR_HEIGHT);
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
    }];
}

#pragma mark - 调用函数

- (void)openPrivacyPermission{
    // 隐私权限
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"隐私权限状态" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 定位权限
    NSString *locationTitle = @"定位权限";
    if ([self isLocationAuthorized]) {
        locationTitle = [locationTitle stringByAppendingString:@"  ✓"];
    }
    UIAlertAction *locationAction = [UIAlertAction actionWithTitle:locationTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (![self isLocationAuthorized]) {
            CLLocationManager *locationManager = [[CLLocationManager alloc] init];
            [locationManager requestWhenInUseAuthorization];
        }
    }];
    [alertController addAction:locationAction];
    
    // 通知权限
    NSString *notificationTitle = @"通知权限";
    if ([self isNotificationAuthorized]) {
        notificationTitle = [notificationTitle stringByAppendingString:@"  ✓"];
    }
    UIAlertAction *notificationAction = [UIAlertAction actionWithTitle:notificationTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (![self isNotificationAuthorized]) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    // 授权成功的处理
                } else {
                    // 授权失败的处理
                }
            }];
        }
    }];
    [alertController addAction:notificationAction];
    
    // 相机权限
    NSString *cameraTitle = @"相机权限";
    if ([self isCameraAuthorized]) {
        cameraTitle = [cameraTitle stringByAppendingString:@"  ✓"];
    }
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:cameraTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (![self isCameraAuthorized]) {
            AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (status == AVAuthorizationStatusNotDetermined) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        // 授权成功的处理
                    } else {
                        // 授权失败的处理
                    }
                }];
            }
        }
    }];
    [alertController addAction:cameraAction];
    
    // 相册权限
    NSString *photoTitle = @"相册权限";
    if ([self isPhotoAuthorized]) {
        photoTitle = [photoTitle stringByAppendingString:@"  ✓"];
    }
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:photoTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (![self isPhotoAuthorized]) {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            if (status == PHAuthorizationStatusNotDetermined) {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        // 授权成功的处理
                    } else {
                        // 授权失败的处理
                    }
                }];
            }
        }
    }];
    [alertController addAction:photoAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)OpenEditUserProfileViewController{
    EditUserProfileViewController *vc = [EditUserProfileViewController new];
    [[self.view getTopViewController] presentPanModal:vc];
   
}

// 权限检查函数
- (BOOL)isLocationAuthorized {
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = locationManager.authorizationStatus;
    } else {
        status = [CLLocationManager authorizationStatus];
    }
    return status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

-(BOOL)isNotificationAuthorized{
    __block BOOL isAuthorized = NO;
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        isAuthorized = settings.authorizationStatus == UNAuthorizationStatusAuthorized;
    }];
    // 由于是异步操作，这里简单等待一下结果
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    return isAuthorized;
}

-(BOOL)isCameraAuthorized{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return status == AVAuthorizationStatusAuthorized;
}

-(BOOL)isPhotoAuthorized{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    return status == PHAuthorizationStatusAuthorized;
}


@end
