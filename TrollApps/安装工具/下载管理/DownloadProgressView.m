//
//  DownloadProgressView.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/22.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DownloadProgressView.h"

// 常量定义
static const CGFloat kCircleSize = 40;         // 圆形直径
static const CGFloat kCapsuleWidth = 280;      // 展开后宽度
static const CGFloat kExpandDuration = 0.3;    // 展开动画时长
static const CGFloat kAutoShrinkDelay = 3;     // 自动缩回延迟（秒）

@interface DownloadProgressView ()

// 子视图
@property (nonatomic, strong) UIView *circleView;      // 圆形背景
@property (nonatomic, strong) CAShapeLayer *progressLayer; // 环形进度条
@property (nonatomic, strong) UILabel *percentLabel;   // 百分比标签
@property (nonatomic, strong) UIView *capsuleView;     // 展开后的胶囊视图
@property (nonatomic, strong) UILabel *fileNameLabel;  // 文件名标签
@property (nonatomic, strong) UIButton *actionButton;  // 操作按钮（展开后显示）

// 状态变量
@property (nonatomic, assign) CGFloat currentProgress; // 当前进度
@property (nonatomic, assign) BOOL isExpanded;         // 是否展开
@property (nonatomic, strong) NSTimer *shrinkTimer;    // 自动缩回计时器
@property (nonatomic, assign) CGPoint panStartPoint;   // 拖动起点
@property (nonatomic, copy) NSString *currentFileName; // 当前文件名

@end

// 拖动范围限制（距离屏幕边缘的最小距离）
static const CGFloat kMinMargin = 5;

@implementation DownloadProgressView

#pragma mark - 单例初始化

+ (instancetype)sharedView {
    static DownloadProgressView *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DownloadProgressView alloc] init];
        [instance setupUI];
        [instance setupGesture];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, kCircleSize, kCircleSize);
        self.userInteractionEnabled = YES;
        self.currentProgress = 0;
        self.isExpanded = NO;
        self.autoSnapToEdge = YES; // 默认开启自动贴边
    }
    return self;
}

#pragma mark - UI初始化

- (void)setupUI {
    // 1. 圆形进度视图（默认显示）
    self.circleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCircleSize, kCircleSize)];
    self.circleView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    self.circleView.layer.cornerRadius = kCircleSize / 2;
    self.circleView.clipsToBounds = YES;
    [self addSubview:self.circleView];
    
    // 2. 环形进度条
    self.progressLayer = [CAShapeLayer layer];
    self.progressLayer.lineWidth = 3;
    self.progressLayer.fillColor = [UIColor clearColor].CGColor;
    self.progressLayer.strokeColor = [UIColor systemBlueColor].CGColor;
    self.progressLayer.strokeEnd = 0;
    [self.circleView.layer addSublayer:self.progressLayer];
    
    // 3. 百分比标签
    self.percentLabel = [[UILabel alloc] initWithFrame:self.circleView.bounds];
    self.percentLabel.textColor = [UIColor whiteColor];
    self.percentLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.percentLabel.textAlignment = NSTextAlignmentCenter;
    self.percentLabel.text = @"0%";
    [self.circleView addSubview:self.percentLabel];
    
    // 4. 展开后的胶囊视图（默认隐藏）
    self.capsuleView = [[UIView alloc] initWithFrame:CGRectMake(kCircleSize, 0, kCapsuleWidth - kCircleSize, kCircleSize)];
    self.capsuleView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    self.capsuleView.hidden = YES;
    [self addSubview:self.capsuleView];
    
    // 5. 文件名标签
    self.fileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.capsuleView.bounds.size.width - 80, kCircleSize)];
    self.fileNameLabel.textColor = [UIColor whiteColor];
    self.fileNameLabel.font = [UIFont systemFontOfSize:13];
    self.fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.capsuleView addSubview:self.fileNameLabel];
    
    // 6. 操作按钮（展开后显示）
    self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.actionButton.frame = CGRectMake(self.capsuleView.bounds.size.width - 60, 0, 50, kCircleSize);
    self.actionButton.tintColor = [UIColor whiteColor];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.actionButton setTitle:@"操作" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(showActionMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.capsuleView addSubview:self.actionButton];
    
    // 初始化进度条路径
    [self updateProgressLayerPath];
}

// 设置环形进度条路径
- (void)updateProgressLayerPath {
    CGFloat radius = (kCircleSize - self.progressLayer.lineWidth) / 2;
    CGPoint center = CGPointMake(kCircleSize / 2, kCircleSize / 2);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:radius
                                                    startAngle:-M_PI_2
                                                      endAngle:M_PI_2 * 3
                                                     clockwise:YES];
    self.progressLayer.path = path.CGPath;
}

#pragma mark - 手势处理（拖动+点击）

- (void)setupGesture {
    // 1. 点击手势（切换展开/收起）
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self addGestureRecognizer:tap];
    
    // 2. 拖动手势（支持拖动到屏幕边缘）
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self addGestureRecognizer:pan];
}

// 点击事件：展开/收起
- (void)tapAction {
    if(_enableExpanded){
        if (self.isExpanded) {
            [self shrink]; // 已展开则收起（或显示操作菜单）
        } else {
            [self expand]; // 未展开则展开
        }
    }
    if([self.delegate respondsToSelector:@selector(iconClick:)]){
        [self.delegate iconClick:self.currentTask];
    }
    
}

// 拖动事件：随手指移动，限制范围+松手贴边
- (void)panAction:(UIPanGestureRecognizer *)pan {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    CGRect screenBounds = keyWindow.bounds;
    CGPoint translation = [pan translationInView:keyWindow];
    CGPoint center = self.center;
    
    // 计算新位置（未限制前）
    CGFloat newCenterX = center.x + translation.x;
    CGFloat newCenterY = center.y + translation.y;
    
    // 限制X轴范围（不超出屏幕左右边缘）
    CGFloat minX = kCircleSize/2 + kMinMargin;
    CGFloat maxX = screenBounds.size.width - kCircleSize/2 - kMinMargin;
    newCenterX = MAX(minX, MIN(maxX, newCenterX));
    
    // 限制Y轴范围（不超出屏幕上下边缘）
    CGFloat minY = kCircleSize/2 + kMinMargin + [UIApplication sharedApplication].statusBarFrame.size.height; // 避开状态栏
    CGFloat maxY = screenBounds.size.height - kCircleSize/2 - kMinMargin;
    newCenterY = MAX(minY, MIN(maxY, newCenterY));
    
    // 更新中心位置
    self.center = CGPointMake(newCenterX, newCenterY);
    [pan setTranslation:CGPointZero inView:keyWindow];
    
    // 松手后处理
    if (pan.state == UIGestureRecognizerStateEnded) {
        // 如果开启自动贴边，则贴边；否则保持当前位置
        if (self.autoSnapToEdge) {
            [self snapToEdge];
        }
    }
}


// 拖动结束后贴边（补充收缩后贴边）
- (void)snapToEdge {
    if (!self.autoSnapToEdge) return;
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    CGFloat screenWidth = keyWindow.bounds.size.width;
    CGFloat targetX = (self.center.x < screenWidth / 2) ?
        kCircleSize/2 + kMinMargin : // 左边缘
        screenWidth - kCircleSize/2 - kMinMargin; // 右边缘
    
    [UIView animateWithDuration:0.2 animations:^{
        self.center = CGPointMake(targetX, self.center.y);
    }];
}

#pragma mark - 展开/收起动画

// 展开为胶囊视图（补充边界检查）确保展开后不超出屏幕）
- (void)expand {
    if (self.isExpanded) return;
    
    self.isExpanded = YES;
    self.capsuleView.hidden = NO;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGPoint currentCenter = self.center; // 用中心位置作为基准
    BOOL isOnRightSide = (currentCenter.x > screenWidth / 2);
    
    [UIView animateWithDuration:kExpandDuration animations:^{
        if (isOnRightSide) {
            // 右半屏向左展开：保持中心y不变，宽度扩展到kCapsuleWidth
            self.center = CGPointMake(currentCenter.x - (kCapsuleWidth - kCircleSize)/2, currentCenter.y);
            self.bounds = CGRectMake(0, 0, kCapsuleWidth, kCircleSize);
        } else {
            // 左半屏向右展开：保持中心y不变，宽度扩展到kCapsuleWidth
            self.center = CGPointMake(currentCenter.x + (kCapsuleWidth - kCircleSize)/2, currentCenter.y);
            self.bounds = CGRectMake(0, 0, kCapsuleWidth, kCircleSize);
        }
        self.layer.cornerRadius = kCircleSize / 2;
    } completion:^(BOOL finished) {
        [self startAutoShrinkTimer];
    }];
}

// 收缩为圆形视图（对应展开方向调整）
- (void)shrink {
    if (!self.isExpanded) return;
    
    self.isExpanded = NO;
    [self invalidateAutoShrinkTimer];
    
    // 获取屏幕宽度和当前位置
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat currentX = self.frame.origin.x;
    BOOL isOnRightSide = (currentX + kCircleSize/2) > screenWidth / 2;
    
    [UIView animateWithDuration:kExpandDuration animations:^{
        if (isOnRightSide) {
            // 右半屏 → 向右收缩回原位置
            self.frame = CGRectMake(
                currentX + (kCapsuleWidth - kCircleSize), // 向右移动收缩的宽度
                self.frame.origin.y,
                kCircleSize,
                kCircleSize
            );
        } else {
            // 左半屏 → 向左收缩回原位置（原逻辑）
            self.frame = CGRectMake(
                currentX + (kCapsuleWidth - kCircleSize),
                self.frame.origin.y,
                kCircleSize,
                kCircleSize
            );
        }
        self.layer.cornerRadius = 0;
    } completion:^(BOOL finished) {
        self.capsuleView.hidden = YES;
    }];
}

#pragma mark - 自动缩回计时器

- (void)startAutoShrinkTimer {
    [self invalidateAutoShrinkTimer];
    self.shrinkTimer = [NSTimer scheduledTimerWithTimeInterval:kAutoShrinkDelay
                                                       target:self
                                                     selector:@selector(autoShrink)
                                                     userInfo:nil
                                                      repeats:NO];
}

// 自动缩回
- (void)autoShrink {
    if (self.isExpanded) {
        [self shrink];
        
        // 缩回后自动贴边（如果开启了该功能）
        if (self.autoSnapToEdge) {
            [self snapToEdge];
        }
    }
}

- (void)invalidateAutoShrinkTimer {
    if (self.shrinkTimer) {
        [self.shrinkTimer invalidate];
        self.shrinkTimer = nil;
    }
}

#pragma mark - 操作菜单（展开后点击显示）

- (void)showActionMenu {
    // 创建操作菜单（兼容iPad的popover样式）
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"下载操作"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 根据任务状态添加按钮
    if (self.currentTask.state == NSURLSessionTaskStateRunning) {
        // 正在运行 → 暂停
        UIAlertAction *pauseAction = [UIAlertAction actionWithTitle:@"暂停" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self pauseDownload];
        }];
        [alert addAction:pauseAction];
    } else if (self.currentTask.state == NSURLSessionTaskStateSuspended) {
        // 已暂停 → 恢复
        UIAlertAction *resumeAction = [UIAlertAction actionWithTitle:@"恢复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self resumeDownload];
        }];
        [alert addAction:resumeAction];
    }
    
    // 通用按钮：取消、重新下载
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self cancelDownload];
    }];
    [alert addAction:cancelAction];
    
    UIAlertAction *restartAction = [UIAlertAction actionWithTitle:@"重新下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self restartDownload];
    }];
    [alert addAction:restartAction];
    
    // 优化菜单显示位置，避免超出屏幕
    UIViewController *topVC = [self topViewController];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // iPad适配
        alert.popoverPresentationController.sourceView = self.actionButton;
        alert.popoverPresentationController.sourceRect = self.actionButton.bounds;
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    } else {
        // iPhone适配：根据位置调整弹出源
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if (self.center.x > screenWidth / 2) {
            // 右侧位置：从右侧弹出
            alert.popoverPresentationController.sourceView = self;
            alert.popoverPresentationController.sourceRect = CGRectMake(self.bounds.size.width - 10, self.bounds.size.height/2, 1, 1);
        } else {
            // 左侧位置：从左侧弹出
            alert.popoverPresentationController.sourceView = self;
            alert.popoverPresentationController.sourceRect = CGRectMake(10, self.bounds.size.height/2, 1, 1);
        }
    }
    
    // 显示菜单
    [topVC presentViewController:alert animated:YES completion:nil];
}

// 获取顶层控制器（用于显示操作菜单）
- (UIViewController *)topViewController {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *topVC = window.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

#pragma mark - 公共方法

- (void)showWithTask:(NSURLSessionDownloadTask *)task fileName:(NSString *)fileName {
    self.currentTask = task;
    self.currentFileName = fileName;
    self.fileNameLabel.text = fileName;
    self.currentProgress = 0;
    self.percentLabel.text = @"0%";
    self.progressLayer.strokeEnd = 0;
    
    // 添加到顶层窗口（避免被其他视图覆盖）
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    
    // 初始位置：右下角
    self.center = CGPointMake(keyWindow.bounds.size.width - kCircleSize/2 - 10,
                             keyWindow.bounds.size.height - kCircleSize/2 - 80);
}

- (void)updateProgress:(CGFloat)progress {
    // 限制进度范围0~1
    self.currentProgress = MAX(0, MIN(1, progress));
    
    // 更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressLayer.strokeEnd = self.currentProgress;
        self.percentLabel.text = [NSString stringWithFormat:@"%.0f%%", self.currentProgress * 100];
    });
}

- (void)dismiss {
    [self removeFromSuperview];
    self.currentTask = nil;
    [self invalidateAutoShrinkTimer];
}

#pragma mark - 下载控制方法

/**
 * 暂停当前下载任务
 */
- (void)pauseDownload {
    if (self.currentTask && self.currentTask.state == NSURLSessionTaskStateRunning) {
        [self.currentTask suspend];
        NSLog(@"下载已暂停");
        
        // 更新UI状态（可选）
        dispatch_async(dispatch_get_main_queue(), ^{
            self.percentLabel.text = [NSString stringWithFormat:@"%@（已暂停）", self.percentLabel.text];
        });
    }
}

/**
 * 恢复当前下载任务
 */
- (void)resumeDownload {
    if (self.currentTask && self.currentTask.state == NSURLSessionTaskStateSuspended) {
        [self.currentTask resume];
        NSLog(@"下载已恢复");
        
        // 更新UI状态（可选）
        dispatch_async(dispatch_get_main_queue(), ^{
            self.percentLabel.text = [NSString stringWithFormat:@"%@（下载中）", self.percentLabel.text];
        });
    }
}

/**
 * 取消当前下载任务
 */
- (void)cancelDownload {
    if (self.currentTask) {
        [self.currentTask cancel];
        NSLog(@"下载已取消");
        
        // 隐藏进度视图
        [self dismiss];
    }
}

/**
 * 重新下载当前文件
 */
- (void)restartDownload {
    if (self.currentTask && self.delegate && [self.delegate respondsToSelector:@selector(downloadRestart:)]) {
        // 调用代理方法处理重新下载逻辑
        [self.delegate downloadRestart:self.currentTask];
        
        // 重置进度视图
        [self updateProgress:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.percentLabel.text = @"0%";
        });
    }
}

#pragma mark - 生命周期

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateProgressLayerPath]; // 确保进度条路径正确
}

- (void)dealloc {
    [self invalidateAutoShrinkTimer];
}

@end
