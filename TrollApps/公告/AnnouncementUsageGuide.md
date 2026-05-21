# 公告管理器使用指南

## 基本使用

### 1. 在 AppDelegate 或主控制器中调用

```objc
// 在应用启动后显示公告
#import "AnnouncementManager.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 延迟一点时间显示公告，等界面完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootVC = self.window.rootViewController;
        [[AnnouncementManager sharedManager] showAnnouncementIfNeededFromViewController:rootVC];
    });
    
    return YES;
}
```

### 2. 在某个视图控制器中调用

```objc
#import "AnnouncementManager.h"

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 每次进入页面时检查是否有公告需要显示
    [[AnnouncementManager sharedManager] showAnnouncementIfNeededFromViewController:self];
}
```

### 3. 手动获取公告

```objc
// 手动获取最新公告
[[AnnouncementManager sharedManager] fetchLatestAnnouncementWithCompletion:^(AnnouncementModel * _Nullable announcement, NSError * _Nullable error) {
    if (error) {
        NSLog(@"获取公告失败: %@", error);
        return;
    }
    
    if (announcement) {
        NSLog(@"获取到公告: %@", announcement.announcement_title);
        // 你可以在这里手动显示公告
        [[AnnouncementManager sharedManager] showAnnouncement:announcement fromViewController:self];
    }
}];
```

### 4. 检查公告状态

```objc
AnnouncementModel *announcement = [AnnouncementManager sharedManager].latestAnnouncement;

// 检查是否已经显示过
BOOL hasShown = [[AnnouncementManager sharedManager] hasShownAnnouncement:announcement];

// 检查是否应该显示
AnnouncementDisplayState state = [[AnnouncementManager sharedManager] shouldDisplayAnnouncement:announcement];
```

## 弹窗模式说明

| 模式值 | 说明 | 行为 |
|--------|------|------|
| 0 | 不弹窗 | 永远不显示 |
| 1 | 可关闭弹窗 | 每次启动都显示，可以关闭 |
| 2 | 强制弹窗 | 每次启动都显示，不可关闭 |
| 3 | 仅弹窗一次 | 只显示一次，显示后不再显示 |

## 清除显示历史

```objc
// 清除所有公告的显示历史
[[AnnouncementManager sharedManager] clearDisplayHistory];
```

## 注意事项

1. 确保网络请求模块 `NetworkClient` 已正确导入
2. 确保 `AnnouncementModel` 已正确配置
3. 弹窗模式 `2（强制）` 暂时通过模态框显示，如需完全禁用关闭可以进一步修改代码
