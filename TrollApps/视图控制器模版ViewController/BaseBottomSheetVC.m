#import "BaseBottomSheetVC.h"
#import <objc/runtime.h>

@interface BaseBottomSheetVC () <UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate, UIAdaptivePresentationControllerDelegate>
@property (nonatomic, assign) CGFloat initialHeight;
@property (nonatomic, assign) CGPoint initialPosition;
@property (nonatomic, assign) BOOL isVerticalScrolling; // 判断是否正在垂直滚动
@property (nonatomic, assign) BOOL isHorizontalScrolling;// 判断是否正在水平滚动

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *rightSwipeGesture;

@end

@implementation BaseBottomSheetVC

#pragma mark - Lifecycle

- (instancetype)initWithPositions:(CGFloat)low medium:(CGFloat)medium high:(CGFloat)high {
    self = [super init];
    if (self) {
        _lowPositionHeight = low;
        _mediumPositionHeight = medium;
        _highPositionHeight = high;
        _currentPosition = BottomSheetPositionHigh;
        _allowTapDismiss = YES;
        _allowRightSwipeDismiss = YES;
        _disablePanOnScrollView = YES;
        _autoAdjustForKeyboard = YES;
        _transition = [[BottomSheetTransition alloc] init];
        [self setupGesture];
        [self setupDimmingView];
        [self setupKeyboardNotifications];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.viewHeight <= 0) {
        self.viewHeight = [self heightForPosition:self.currentPosition];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI Setup

- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.layer.cornerRadius = 16;
    self.view.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.view.clipsToBounds = YES;
    
    // 添加导航栏
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44 + [UIApplication sharedApplication].statusBarFrame.size.height)];
    navBar.barTintColor = UIColor.whiteColor;
    navBar.shadowImage = [UIImage new];
    [self.view addSubview:navBar];
    
    // 添加拖拽指示器
    UIView *indicator = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 40)/2, 8, 40, 6)];
    indicator.backgroundColor = UIColor.lightGrayColor;
    indicator.layer.cornerRadius = 3;
    [navBar addSubview:indicator];
}

- (void)setupGesture {
    // 垂直拖动手势
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleVerticalPan:)];
    _panGesture.delegate = self;
    _panGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:_panGesture];
    
    // 水平侧滑手势
    _rightSwipeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalPan:)];
    _rightSwipeGesture.delegate = self;
    _rightSwipeGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:_rightSwipeGesture];
}

- (void)setupDimmingView {
    _dimmingView = [[UIView alloc] init];
    _dimmingView.backgroundColor = UIColor.blackColor;
    _dimmingView.alpha = 0.5;
    _dimmingView.userInteractionEnabled = YES; // 强制开启交互（关键）
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDimmingTap)];
    [_dimmingView addGestureRecognizer:tapGesture];
}

#pragma mark - Keyboard Handling

- (void)setupKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardHeight = keyboardFrame.size.height;
    
    if (self.autoAdjustForKeyboard) {
        [self switchToPosition:self.currentPosition animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    
    if (self.autoAdjustForKeyboard) {
        [self switchToPosition:self.currentPosition animated:YES];
    }
}

#pragma mark - Height Calculation

- (CGFloat)heightForPosition:(BottomSheetPosition)position {
    CGFloat height;
    switch (position) {
        case BottomSheetPositionLow:
            height = self.lowPositionHeight;
            break;
        case BottomSheetPositionMedium:
            height = self.mediumPositionHeight;
            break;
        case BottomSheetPositionHigh:
        default:
            height = self.highPositionHeight;
            break;
    }
    return height - self.keyboardHeight;
}

- (void)setViewHeight:(CGFloat)viewHeight {
    if (_viewHeight == viewHeight) return;
    _viewHeight = viewHeight;
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    // 弹窗的 y 坐标应为屏幕高度 - 弹窗高度（确保顶部留有空白区域给遮罩）
    self.view.frame = CGRectMake(0, screenHeight - viewHeight, [self screenWidth], viewHeight);
    // 打印日志验证 frame 是否正确
    NSLog(@"弹窗 frame: %@", NSStringFromCGRect(self.view.frame));
}

#pragma mark - Gesture Handling

// 辅助函数：获取屏幕宽度
- (CGFloat)screenWidth{
    return [UIScreen mainScreen].bounds.size.width;
}

// 垂直拖动手势处理
- (void)handleVerticalPan:(UIPanGestureRecognizer *)gesture {
    // 如果正在水平滑动，直接忽略垂直手势
    if (self.isHorizontalScrolling) {
        return;
    }
    
    CGPoint translation = [gesture translationInView:self.view.superview];
    
    // 手势开始时，判断是否为垂直滑动
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint velocity = [gesture velocityInView:self.view];
        self.isVerticalScrolling = (fabs(velocity.y) > fabs(velocity.x) * 1.5); // 调整阈值
        if (self.isVerticalScrolling) {
            self.initialHeight = self.viewHeight;
            self.initialPosition = self.view.frame.origin; // 记录初始位置
        } else {
            return;
        }
    }
    
    if (!self.isVerticalScrolling) return;
    
    // 计算新高度（仅处理Y方向变化）
    CGFloat newHeight = self.initialHeight - translation.y;
    newHeight = MAX(self.lowPositionHeight, MIN(newHeight, self.highPositionHeight));
    
    switch (gesture.state) {
        case UIGestureRecognizerStateChanged: {
            // 锁定X轴，仅Y轴变化
            CGRect newFrame = self.view.frame;
            newFrame.size.height = newHeight;
            newFrame.origin.y = [UIScreen mainScreen].bounds.size.height - newHeight;
            newFrame.origin.x = self.initialPosition.x; // 锁定X轴
            self.view.frame = newFrame;
            self.viewHeight = newHeight;
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // 手势结束，重置状态
            self.isVerticalScrolling = NO;
            
            // 计算目标档位并切换
            BottomSheetPosition targetPosition = [self nearestPositionToHeight:newHeight];
            [self switchToPosition:targetPosition animated:YES];
            break;
        }
            
        default:
            break;
    }
}

// 水平侧滑手势处理
- (void)handleHorizontalPan:(UIPanGestureRecognizer *)gesture {
    // 如果正在垂直滑动，直接忽略水平手势
    if (self.isVerticalScrolling) {
        return;
    }
    
    CGPoint translation = [gesture translationInView:self.view];
    CGFloat horizontalMovement = fabs(translation.x);
    CGFloat verticalMovement = fabs(translation.y);
    
    // 手势开始时，判断是否为水平滑动
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 必须是向右滑动，且水平移动明显大于垂直移动
        if (translation.x > 0 && horizontalMovement > verticalMovement * 1.5) {
            self.isHorizontalScrolling = YES;
            self.initialPosition = self.view.frame.origin; // 记录初始位置
        } else {
            return;
        }
    }
    
    if (!self.isHorizontalScrolling) return;
    
    CGFloat progress = translation.x / [self screenWidth];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateChanged: {
            if (translation.x > 0) { // 仅响应向右滑动
                // 锁定Y轴，仅X轴变化
                CGRect newFrame = self.view.frame;
                newFrame.origin.x = self.initialPosition.x + translation.x;
                newFrame.origin.y = self.initialPosition.y; // 锁定Y轴
                self.view.frame = newFrame;
                self.dimmingView.alpha = 0.5 * (1 - progress);
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // 手势结束，重置状态
            self.isHorizontalScrolling = NO;
            
            if (progress > 0.3 && translation.x > 0) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                // 恢复原位（锁定Y轴）
                [UIView animateWithDuration:0.3 animations:^{
                    CGRect resetFrame = self.view.frame;
                    resetFrame.origin.x = self.initialPosition.x;
                    resetFrame.origin.y = self.initialPosition.y; // 保持Y轴不变
                    self.view.frame = resetFrame;
                    self.dimmingView.alpha = 0.5;
                }];
            }
            break;
        }
            
        default:
            break;
    }
}

// 找到最接近给定高度的档位
- (BottomSheetPosition)nearestPositionToHeight:(CGFloat)height {
    CGFloat distanceToLow = fabs(height - self.lowPositionHeight);
    CGFloat distanceToMedium = fabs(height - self.mediumPositionHeight);
    CGFloat distanceToHigh = fabs(height - self.highPositionHeight);
    
    if (distanceToLow <= distanceToMedium && distanceToLow <= distanceToHigh) {
        return BottomSheetPositionLow;
    } else if (distanceToMedium <= distanceToHigh) {
        return BottomSheetPositionMedium;
    } else {
        return BottomSheetPositionHigh;
    }
}

#pragma mark - Position Switching

- (void)switchToPosition:(BottomSheetPosition)position animated:(BOOL)animated {
    if (self.currentPosition == position) return;
    self.currentPosition = position;
    
    CGFloat targetHeight = [self heightForPosition:position];
    if (animated) {
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.9
              initialSpringVelocity:0.3
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.viewHeight = targetHeight;
        } completion:nil];
    } else {
        self.viewHeight = targetHeight;
    }
}

#pragma mark - Dimming View Interaction

- (void)onDimmingTap {
    NSLog(@"遮罩点击 - allowTapDismiss: %@", self.allowTapDismiss ? @"YES" : @"NO");
    if (self.allowTapDismiss) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // 禁用滚动视图上的手势
    if (self.disablePanOnScrollView && gestureRecognizer == self.panGesture) {
        CGPoint location = [gestureRecognizer locationInView:self.view];
        UIView *hitView = [self.view hitTest:location withEvent:nil];
        
        if ([hitView isKindOfClass:[UIScrollView class]] || [hitView.superview isKindOfClass:[UIScrollView class]]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 水平和垂直手势不同时响应
    if ((gestureRecognizer == self.panGesture && otherGestureRecognizer == self.rightSwipeGesture) ||
        (gestureRecognizer == self.rightSwipeGesture && otherGestureRecognizer == self.panGesture)) {
        return NO;
    }
    // 其他手势允许共存
    return YES;
}

#pragma mark - Transition Delegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.transition.isPresenting = YES;
    return self.transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.transition.isPresenting = NO;
    return self.transition;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(nullable UIViewController *)presenting sourceViewController:(UIViewController *)source {
    BottomSheetPresentationController *presentation = [[BottomSheetPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    presentation.dimmingView = self.dimmingView;
    presentation.delegate = self;
    return presentation;
}

@end
