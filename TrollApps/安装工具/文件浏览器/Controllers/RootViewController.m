//
//  RootViewController.m
//  SandboxFileManager
//
//  根控制器实现
//

#import "RootViewController.h"
#import "FileListViewController.h"
#import "WindowManager.h"
#import "HistoryManager.h"
#import "FavoriteManager.h"
#import "FileSelectionManager.h"
#import "RecycleBinManager.h"
#import "FileActionHandler.h"
#import "FileNotification.h"
#import "FileOperateTool.h"
#import "FavoriteListViewController.h"
#import "RecycleBinViewController.h"
#import "SelectedFilesViewController.h"
#import "HistoryListViewController.h"
#import "WindowSwitcherViewController.h"

@interface RootViewController () <WindowManagerDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) UINavigationController *browserNavController;
@property (nonatomic, strong) FileListViewController *browserVC;
@property (nonatomic, strong) UINavigationController *historyNavController;
@property (nonatomic, strong) UINavigationController *favoritesNavController;
@property (nonatomic, strong) UINavigationController *recycleBinNavController;
@property (nonatomic, strong) UINavigationController *windowNavController;



@end

@implementation RootViewController

+ (instancetype)rootController {
    RootViewController *root = [[RootViewController alloc] init];
    [root setupViewControllers];
    [root setupTabBarItems];
    [root setupWindowManagement];
    return root;
}

- (void)setupViewControllers {
    // 使用 WindowManager 初始化窗口（会自动从本地存储加载）
    if ([[WindowManager sharedManager] allWindows].count == 0) {
        // 如果没有窗口，创建一个默认窗口
        [[WindowManager sharedManager] createWindowWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    }
    
    // 获取当前窗口
    FileListViewController *currentWindow = [[WindowManager sharedManager] currentWindow];
    if (!currentWindow) {
        // 如果没有当前窗口，创建一个
        currentWindow = [[WindowManager sharedManager] createWindowWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
    }
    
    // 设置 rootViewController
    currentWindow.rootViewController = self;
    self.browserVC = currentWindow;
    self.browserNavController = [[UINavigationController alloc] initWithRootViewController:currentWindow];
    
    // 历史记录
    HistoryListViewController *historyVC = [[HistoryListViewController alloc] init];
    self.historyNavController = [[UINavigationController alloc] initWithRootViewController:historyVC];
    
    // 收藏
    FavoriteListViewController *favoritesVC = [[FavoriteListViewController alloc] init];
    self.favoritesNavController = [[UINavigationController alloc] initWithRootViewController:favoritesVC];
    
    // 回收站
    RecycleBinViewController *recycleBinVC = [[RecycleBinViewController alloc] init];
    self.recycleBinNavController = [[UINavigationController alloc] initWithRootViewController:recycleBinVC];
    
    // 窗口管理（占位）
    UIViewController *windowVC = [[UIViewController alloc] init];
    windowVC.view.backgroundColor = [UIColor systemBackgroundColor];
    self.windowNavController = [[UINavigationController alloc] initWithRootViewController:windowVC];
    
    self.viewControllers = @[
        self.browserNavController,
        self.historyNavController,
        self.favoritesNavController,
        self.recycleBinNavController,
        self.windowNavController
    ];
}

- (void)setupTabBarItems {
    [self setupNormalTabBarItems];
}

- (void)setupNormalTabBarItems {
    NSArray *titles = @[@"文件", @"历史", @"收藏", @"回收站", @"窗口"];
    NSArray *images = @[@"folder", @"clock", @"star", @"trash", @"square.stack"];
    
    for (NSInteger i = 0; i < self.tabBar.items.count; i++) {
        UITabBarItem *item = self.tabBar.items[i];
        item.title = titles[i];
        item.image = [UIImage systemImageNamed:images[i]];
        item.selectedImage = [[UIImage systemImageNamed:images[i]] imageWithTintColor:[UIColor systemBlueColor]];
    }
}

- (void)setupEditTabBarItems {
    NSArray *titles = @[@"拷贝", @"移动", @"删除", @"重命名", @"完成"];
    NSArray *images = @[@"doc.on.doc", @"arrow.right", @"trash", @"pencil", @"checkmark"];
    
    for (NSInteger i = 0; i < self.tabBar.items.count; i++) {
        UITabBarItem *item = self.tabBar.items[i];
        if (i < titles.count) {
            item.title = titles[i];
            item.image = [UIImage systemImageNamed:images[i]];
            item.selectedImage = [[UIImage systemImageNamed:images[i]] imageWithTintColor:[UIColor systemBlueColor]];
        }
    }
    
    // 更新最后一个按钮显示选择数量（作为完成按钮）
    [self updateSelectionCount];
}

- (void)setupWindowManagement {
    // 设置 tabBar 代理
    self.delegate = self;
    
    // 设置 WindowManager 的 delegate
    [WindowManager sharedManager].delegate = self;
    
    // 添加历史记录跳转通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNavigateToPathNotification:)
                                                 name:@"kNotificationNavigateToPath"
                                               object:nil];
}

- (void)enterEditMode {
    self.isEditMode = YES;
    
    // 只修改 tabBar items，不切换视图控制器
    [self setupEditTabBarItems];
    
    // 更新选择数量显示
    [self updateSelectionCount];
}

//退出编辑模式
- (void)exitEditMode {
    if(self.isEditMode){
        self.isEditMode = NO;
        [self.browserVC exitBatchEditMode];
        
    }
    
    // 只修改 tabBar items，不切换视图控制器
    [self setupNormalTabBarItems];
}

- (void)updateSelectionCount {
    NSInteger count = [[FileSelectionManager sharedManager] selectedCount];
    
    // 最后一个按钮作为完成按钮显示选择数量
    if (self.tabBar.items.count > 0) {
        UITabBarItem *doneItem = self.tabBar.items.lastObject;
        doneItem.title = [NSString stringWithFormat:@"完成 (%ld)", (long)count];
    }
}



- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (self.isEditMode) {
        // 编辑模式下，点击标签执行相应操作
        NSInteger index = [self.viewControllers indexOfObject:viewController];
        self.browserVC = [[WindowManager sharedManager] currentWindow];
        switch (index) {
            case 0: // 拷贝
                self.browserVC.isCopyOperation = YES;
                [self.browserVC didSelectAction:FileOperationActionCopy];
                return NO; // 不切换视图
            case 1: // 移动
                self.browserVC.isCopyOperation = NO;
                [self.browserVC didSelectAction:FileOperationActionMove];
                return NO;
            case 2: // 删除
                [self.browserVC didSelectAction:FileOperationActionDelete];
                return NO;
            case 3: // 重命名
                [self.browserVC didSelectAction:FileOperationActionRename];
                return NO;
            case 4: // 完成（原来的窗口按钮位置）
                [self performDoneAction];
                return NO;
            default:
                return YES;
        }
    }
    
    // 正常模式下，点击窗口标签只显示窗口切换器，不切换 tab
    NSInteger index = [self.viewControllers indexOfObject:viewController];
    if (index == 4) { // 窗口标签
        [self switchToWindowManager];
        return NO; // 不切换 tab
    }
    
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    // 强制保持 tabBar items 的标题不变
    if (self.isEditMode) {
        [self setupEditTabBarItems];
    } else {
        [self setupNormalTabBarItems];
    }
}

#pragma mark - Edit Mode Actions


// 点击完成
- (void)performDoneAction {
    [self exitEditMode];
    [[WindowManager sharedManager] currentWindow].isBatchEditing = NO;
}

// 点击切换到文件管理器
- (void)switchToFileBrowser {
    self.selectedIndex = 0;
}

// 点击到历史列表
- (void)switchToHistory {
    self.selectedIndex = 1;
}

// 点击到收藏列表
- (void)switchToFavorites {
    self.selectedIndex = 2;
}

// 点击到回收站
- (void)switchToRecycleBin {
    self.selectedIndex = 3;
}

// 显示窗口
- (void)switchToWindowManager {
    // 使用 browserNavController 的顶层控制器来显示窗口切换器
    // 这样可以确保 view 已经在窗口层级中
    UIViewController *topVC = self.browserNavController.topViewController;
    if (topVC && topVC.view.window != nil) {
        if ([topVC isKindOfClass:[FileListViewController class]]) {
            [(FileListViewController *)topVC showWindowSwitcher];
            return;
        }
    }
    // 备用：使用 browserVC
    if (self.browserVC.view.window != nil) {
        [self.browserVC showWindowSwitcher];
    }
}

- (void)openNewWindowWithPath:(NSString *)path {
    FileListViewController *newWindow = [[WindowManager sharedManager] createWindowWithPath:path];
    
    // 如果当前在文件浏览标签，切换到新窗口
    if (self.selectedIndex == 0) {
        [self.browserNavController setViewControllers:@[newWindow] animated:YES];
    }
}

#pragma mark - Navigation Notification

- (void)handleNavigateToPathNotification:(NSNotification *)notification {
    NSString *path = notification.userInfo[@"path"];
    if (path && path.length > 0) {
        // 切换到文件浏览器标签
        [self switchToFileBrowser];
        
        // 导航到目标路径
        FileListViewController *currentWindow = [[WindowManager sharedManager] currentWindow];
        if (currentWindow) {
            [currentWindow navigateToPath:path];
        }
    }
}

#pragma mark - WindowManagerDelegate

- (void)windowManagerDidAddWindow:(FileListViewController *)windowVC {
    // 设置新窗口的 rootViewController
    windowVC.rootViewController = self;
}

- (void)windowManagerDidRemoveWindow:(FileListViewController *)windowVC {
    // 窗口被删除时的处理
    if (windowVC == self.browserVC) {
        // 如果删除的是当前显示的窗口，更新 browserVC
        self.browserVC = [[WindowManager sharedManager] currentWindow];
    }
}

- (void)windowManagerDidSwitchToWindow:(FileListViewController *)windowVC {
    // 切换窗口时，更新 navigation controller
    if (windowVC) {
        windowVC.rootViewController = self;
        self.browserVC = windowVC;
        
        // 确保在正确的 navigation controller 中显示
        if (self.browserNavController) {
            [self.browserNavController setViewControllers:@[windowVC] animated:YES];
        }
    }
}

@end
