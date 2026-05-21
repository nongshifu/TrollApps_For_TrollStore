//
//  LoadDialogView.m
//  soul
//
//  Created by 十三哥 on 2026/3/27.
//
#import "LoadDialogView.h"
#import "CustomDialogView.h"
#import <objc/runtime.h>

@interface LoadDialogView ()
@property (nonatomic, strong) UITapGestureRecognizer *threeFingerTapGesture;
@property (nonatomic, strong) NSTimer *gestureCheckTimer;
@end

@implementation LoadDialogView

#pragma mark - 【自动启动】程序启动就加载，无需调用
+ (void)load {
    [[LoadDialogView sharedInstance] startAutoMonitor];
}

#pragma mark - 单例
+ (instancetype)sharedInstance {
    static LoadDialogView *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - 启动全局监听
- (void)startAutoMonitor {
    // 启动每秒检查定时器
    [self startCheckTimer];
    
    // 首次添加手势
    [self addThreeFingerGestureToTopViewController];
    
    NSLog(@"✅ LoadDialogView 三指双击监听已启动");
}

#pragma mark - 每秒检查：确保手势永远在顶层控制器
- (void)startCheckTimer {
    if (self.gestureCheckTimer) {
        [self.gestureCheckTimer invalidate];
        self.gestureCheckTimer = nil;
    }
    
    self.gestureCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              target:self
                                                            selector:@selector(addThreeFingerGestureToTopViewController)
                                                            userInfo:nil
                                                             repeats:YES];
}

#pragma mark - 【核心】移除旧手势 → 添加新手势到顶层VC
- (void)addThreeFingerGestureToTopViewController {
    UIViewController *topVC = [self getTopViewController];
    if (!topVC || !topVC.view) return;
    
    // 先移除所有旧的三指手势（防止重复、防止被覆盖）
    for (UIView *view in [self allViewControllersViews]) {
        for (UITapGestureRecognizer *gest in view.gestureRecognizers) {
            if ([gest isKindOfClass:[UITapGestureRecognizer class]] && gest.numberOfTouchesRequired == 3) {
                [view removeGestureRecognizer:gest];
            }
        }
    }
    
    // 创建新的 三指双击 手势
    self.threeFingerTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(threeFingerDoubleTapTriggered)];
    self.threeFingerTapGesture.numberOfTapsRequired = 2;      // 双击
    self.threeFingerTapGesture.numberOfTouchesRequired = 3;   // 三指
    
    // 添加到顶层控制器
    [topVC.view addGestureRecognizer:self.threeFingerTapGesture];
    
    // 允许手势与滚动/控件共存
    self.threeFingerTapGesture.cancelsTouchesInView = NO;
    topVC.view.userInteractionEnabled = YES;
}

#pragma mark - 三指双击触发
- (void)threeFingerDoubleTapTriggered {
    NSLog(@"👆 触发三指双击 → 打开自定义弹窗");
    [self showCustomDialogView];
}

#pragma mark - 三指打开自定义弹窗
- (void)showCustomDialogView {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入弹窗内容"
                                                                   message:@"请依次输入标题、副标题、按钮、底部提示"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"标题";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"副标题";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"按钮文字";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"底部提示";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *title = alert.textFields[0].text.length ? alert.textFields[0].text : nil;
        NSString *subtitle = alert.textFields[1].text.length ? alert.textFields[1].text : nil;
        NSString *btnTitle = alert.textFields[2].text.length ? alert.textFields[2].text : nil;
        NSString *bottomTip = alert.textFields[3].text.length ? alert.textFields[3].text : nil;
        
        [CustomDialogView showWithTitle:title subtitle:subtitle buttonTitle:btnTitle bottomTip:bottomTip];
    }]];
    
    [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 获取顶层控制器
- (UIViewController *)getTopViewController {
    UIViewController *topVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

#pragma mark - 获取所有VC的view（用于清理旧手势）
- (NSArray<UIView *> *)allViewControllersViews {
    NSMutableArray *array = [NSMutableArray array];
    UIViewController *root = [[UIApplication sharedApplication] keyWindow].rootViewController;
    [self collectViewsFromViewController:root toArray:array];
    return array;
}

- (void)collectViewsFromViewController:(UIViewController *)vc toArray:(NSMutableArray *)array {
    if (!vc) return;
    if (vc.view) [array addObject:vc.view];
    for (UIViewController *child in vc.childViewControllers) {
        [self collectViewsFromViewController:child toArray:array];
    }
    if (vc.presentedViewController) {
        [self collectViewsFromViewController:vc.presentedViewController toArray:array];
    }
}

@end
