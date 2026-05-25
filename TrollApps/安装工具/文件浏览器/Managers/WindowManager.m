//
//  WindowManager.m
//  SandboxFileManager
//
//  窗口管理器实现
//

#import "WindowManager.h"
#import <UIKit/UIKit.h>

static NSString *const kWindowStateKey = @"SandboxFileManagerWindowState";
static NSString *const kWindowPathsKey = @"windowPaths";
static NSString *const kWindowSnapshotsKey = @"windowSnapshots";
static NSString *const kCurrentWindowIndexKey = @"currentWindowIndex";

@interface WindowManager ()

@property (nonatomic, strong) NSMutableArray<FileListViewController *> *windows;
@property (nonatomic, weak) FileListViewController *currentWindow;

@end

@implementation WindowManager

+ (instancetype)sharedManager {
    static WindowManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WindowManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.windows = [NSMutableArray array];
        
        // 尝试加载窗口状态
        [self loadWindowState];
    }
    return self;
}

- (NSArray<FileListViewController *> *)allWindows {
    return [self.windows copy];
}

- (NSInteger)windowCount {
    return self.windows.count;
}

- (FileListViewController *)createWindowWithPath:(NSString *)path {
    FileListViewController *windowVC = [[FileListViewController alloc] init];
    windowVC.currentDirPath = path ?: [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    windowVC.windowIndex = self.windows.count;
    
    // 强制加载视图，触发 viewDidLoad，初始化内部的表格视图
    (void)windowVC.view;
    
    [self.windows addObject:windowVC];
    [self switchToWindow:windowVC];
    
    // 保存状态
    [self saveWindowState];
    
    if ([self.delegate respondsToSelector:@selector(windowManagerDidAddWindow:)]) {
        [self.delegate windowManagerDidAddWindow:windowVC];
    }
    
    return windowVC;
}

- (void)switchToWindow:(FileListViewController *)windowVC {
    if (!windowVC) return;
    
    NSInteger index = [self.windows indexOfObject:windowVC];
    if (index == NSNotFound) return;
    
    self.currentWindow = windowVC;
    
    // 保存状态
    [self saveWindowState];
    
    if ([self.delegate respondsToSelector:@selector(windowManagerDidSwitchToWindow:)]) {
        [self.delegate windowManagerDidSwitchToWindow:windowVC];
    }
}

- (void)switchToWindowAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.windows.count) return;
    
    [self switchToWindow:self.windows[index]];
}

- (void)closeWindow:(FileListViewController *)windowVC {
    if (!windowVC) return;
    
    // 如果只有一个窗口，不允许删除
    if (self.windows.count <= 1) {
        return;
    }
    
    NSInteger index = [self.windows indexOfObject:windowVC];
    if (index == NSNotFound) return;
    
    [self.windows removeObjectAtIndex:index];
    
    // 更新剩余窗口的索引
    for (NSInteger i = 0; i < self.windows.count; i++) {
        self.windows[i].windowIndex = i;
    }
    
    // 如果关闭的是当前窗口，切换到其他窗口
    if (windowVC == self.currentWindow) {
        if (self.windows.count > 0) {
            NSInteger newIndex = (index < self.windows.count) ? index : self.windows.count - 1;
            [self switchToWindow:self.windows[newIndex]];
        } else {
            self.currentWindow = nil;
        }
    }
    
    // 保存状态
    [self saveWindowState];
    
    if ([self.delegate respondsToSelector:@selector(windowManagerDidRemoveWindow:)]) {
        [self.delegate windowManagerDidRemoveWindow:windowVC];
    }
}

- (void)closeWindowAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.windows.count) return;
    
    [self closeWindow:self.windows[index]];
}

- (void)closeAllWindows {
    for (FileListViewController *windowVC in [self.windows copy]) {
        [self closeWindow:windowVC];
    }
}

- (NSInteger)indexOfWindow:(FileListViewController *)windowVC {
    return [self.windows indexOfObject:windowVC];
}

#pragma mark - 持久化存储

- (void)saveWindowState {
    // 收集所有窗口的路径和截图
    NSMutableArray *windowPaths = [NSMutableArray array];
    NSMutableArray *windowSnapshots = [NSMutableArray array];
    
    for (FileListViewController *windowVC in self.windows) {
        [windowPaths addObject:windowVC.currentDirPath ?: @""];
        
        // 将截图转换为 Base64 字符串存储
        if (windowVC.windowSnapshot) {
            NSData *imageData = UIImagePNGRepresentation(windowVC.windowSnapshot);
            if (imageData) {
                NSString *base64String = [imageData base64EncodedStringWithOptions:0];
                [windowSnapshots addObject:base64String];
            } else {
                [windowSnapshots addObject:@""];
            }
        } else {
            [windowSnapshots addObject:@""];
        }
    }
    
    // 获取当前窗口索引
    NSInteger currentIndex = [self indexOfWindow:self.currentWindow];
    if (currentIndex == NSNotFound) {
        currentIndex = 0;
    }
    
    // 保存到 UserDefaults
    NSDictionary *state = @{
        kWindowPathsKey: [windowPaths copy],
        kWindowSnapshotsKey: [windowSnapshots copy],
        kCurrentWindowIndexKey: @(currentIndex)
    };
    
    [[NSUserDefaults standardUserDefaults] setObject:state forKey:kWindowStateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)loadWindowState {
    // 从 UserDefaults 加载
    NSDictionary *state = [[NSUserDefaults standardUserDefaults] objectForKey:kWindowStateKey];
    if (!state) {
        return NO;
    }
    
    NSArray *windowPaths = state[kWindowPathsKey];
    if (!windowPaths || ![windowPaths isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *windowSnapshots = state[kWindowSnapshotsKey];
    if (!windowSnapshots || ![windowSnapshots isKindOfClass:[NSArray class]]) {
        windowSnapshots = nil;
    }
    
    NSNumber *currentIndexNum = state[kCurrentWindowIndexKey];
    NSInteger currentIndex = currentIndexNum ? [currentIndexNum integerValue] : 0;
    
    // 清空现有窗口
    [self.windows removeAllObjects];
    
    // 创建窗口
    for (NSInteger i = 0; i < windowPaths.count; i++) {
        NSString *path = windowPaths[i];
        if (![path isKindOfClass:[NSString class]]) {
            path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        }
        if (path.length == 0) {
            path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        }
        
        FileListViewController *windowVC = [[FileListViewController alloc] init];
        windowVC.currentDirPath = path;
        windowVC.windowIndex = i;
        
        // 加载截图
        if (windowSnapshots && i < (NSInteger)windowSnapshots.count) {
            id snapshotData = windowSnapshots[i];
            if ([snapshotData isKindOfClass:[NSString class]] && [(NSString *)snapshotData length] > 0) {
                NSData *imageData = [[NSData alloc] initWithBase64EncodedString:(NSString *)snapshotData options:0];
                if (imageData) {
                    UIImage *snapshot = [UIImage imageWithData:imageData];
                    if (snapshot) {
                        windowVC.windowSnapshot = snapshot;
                    }
                }
            }
        }
        
        // 强制加载视图，触发 viewDidLoad，初始化内部的表格视图
        (void)windowVC.view;
        
        [self.windows addObject:windowVC];
    }
    
    // 如果没有窗口，创建一个默认窗口
    if (self.windows.count == 0) {
        [self createWindowWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
        return YES;
    }
    
    // 切换到当前窗口
    if (currentIndex >= 0 && currentIndex < self.windows.count) {
        [self switchToWindow:self.windows[currentIndex]];
    } else {
        [self switchToWindow:self.windows.firstObject];
    }
    
    return YES;
}

@end