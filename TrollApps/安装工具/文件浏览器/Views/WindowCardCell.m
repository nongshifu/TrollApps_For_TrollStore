//
//  WindowCardCell.m
//  SandboxFileManager
//
//  窗口卡片单元格
//
//

#import "WindowCardCell.h"
#import "FileListTableViewController.h"

static const CGFloat kDismissThreshold = 150.0; // 触发关闭的最小距离
static const CGFloat kMaxScale = 1.1; // 最大缩放比例

@interface WindowCardCell ()

@property (nonatomic, strong) UIView *cardContainer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *pathLabel;
@property (nonatomic, strong) UIView *activeIndicator;
@property (nonatomic, strong) UIView *snapshotView;
@property (nonatomic, strong) UIImageView *snapshotImageView;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) CGFloat initialY;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL shouldDismiss;

@end

@implementation WindowCardCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupGesture];
    }
    return self;
}

- (void)setupUI {
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 创建卡片容器
    self.cardContainer = [[UIView alloc] initWithFrame:self.contentView.bounds];
    self.cardContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.cardContainer.backgroundColor = [UIColor systemBackgroundColor];
    self.cardContainer.layer.cornerRadius = 16;
    self.cardContainer.layer.masksToBounds = YES;
    self.cardContainer.layer.borderWidth = 2;
    self.cardContainer.layer.borderColor = [UIColor secondaryLabelColor].CGColor;
    [self.contentView addSubview:self.cardContainer];
    
    // 创建截图占位视图
    self.snapshotView = [[UIView alloc] initWithFrame:CGRectZero];
    self.snapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.snapshotView.backgroundColor = [UIColor systemGray6Color];
    [self.cardContainer addSubview:self.snapshotView];
    
    // 给截图视图添加一个渐变色效果
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.snapshotView.bounds;
    gradient.colors = @[(id)[UIColor systemGray5Color].CGColor, (id)[UIColor systemGray6Color].CGColor];
    [self.snapshotView.layer addSublayer:gradient];
    
    // 创建截图显示的 image view
    self.snapshotImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.snapshotImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.snapshotImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.snapshotImageView.clipsToBounds = NO;
    self.snapshotImageView.hidden = YES;
    [self.snapshotView addSubview:self.snapshotImageView];
    
    // 创建活动指示器（如果是当前窗口）
    self.activeIndicator = [[UIView alloc] initWithFrame:CGRectZero];
    self.activeIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.activeIndicator.backgroundColor = [UIColor systemBlueColor];
    self.activeIndicator.hidden = YES;
    [self.snapshotView addSubview:self.activeIndicator];
    
    // 创建标题标签
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor labelColor];
    [self.cardContainer addSubview:self.titleLabel];
    
    // 创建路径标签
    self.pathLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pathLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.pathLabel.font = [UIFont systemFontOfSize:12];
    self.pathLabel.textColor = [UIColor secondaryLabelColor];
    self.pathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.cardContainer addSubview:self.pathLabel];
    
    // 创建关闭按钮
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    self.closeButton.backgroundColor = [UIColor systemRedColor];
    self.closeButton.layer.cornerRadius = 11;
    self.closeButton.layer.masksToBounds = YES;
    self.closeButton.tintColor = [UIColor whiteColor];
    
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cardContainer addSubview:self.closeButton];
}

- (void)setupGesture {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panGesture.delegate = self;
    // 只添加到cardContainer，不影响contentView的点击
    [self.cardContainer addGestureRecognizer:self.panGesture];
}

- (void)closeButtonTapped:(UIButton *)button {
    // 直接触发关闭
    [self dismissCard];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.cardContainer];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.isDragging = YES;
            self.initialY = 0;
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGFloat newY = self.initialY + translation.y;
            
            // 只允许向上滑动
            if (newY < 0) {
                // 计算缩放比例
                CGFloat dragDistance = fabs(newY);
                CGFloat scaleProgress = MIN(dragDistance / kDismissThreshold, 1.0);
                CGFloat scale = 1.0 - (scaleProgress * 0.2);
                
                // 应用变换
                CGAffineTransform transform = CGAffineTransformMakeTranslation(0, newY);
                transform = CGAffineTransformScale(transform, scale, scale);
                self.cardContainer.transform = transform;
                
                // 检查是否应该关闭
                self.shouldDismiss = dragDistance >= kDismissThreshold;
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (self.shouldDismiss) {
                // 滑动足够远，执行关闭动画
                [self dismissCard];
            } else {
                // 滑动不够，恢复原位
                [self resetCard];
            }
            self.isDragging = NO;
            break;
        }
            
        default:
            break;
    }
}

- (void)dismissCard {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        // 移动到屏幕外
        CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -self.contentView.bounds.size.height);
        transform = CGAffineTransformScale(transform, 0.8, 0.8);
        self.cardContainer.transform = transform;
        self.cardContainer.alpha = 0;
    } completion:^(BOOL finished) {
        // 通知代理
        if ([self.delegate respondsToSelector:@selector(windowCardCellWillClose:)]) {
            [self.delegate windowCardCellWillClose:self];
        }
    }];
}

- (void)resetCard {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.cardContainer.transform = CGAffineTransformIdentity;
        self.cardContainer.alpha = 1;
    } completion:nil];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self resetCard];
    self.shouldDismiss = NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGesture) {
        CGPoint translation = [self.panGesture translationInView:self.cardContainer];
        CGPoint velocity = [self.panGesture velocityInView:self.cardContainer];
        
        // 严格的垂直滑动判断 - 必须明显是向上滑动
        CGFloat verticalRatio = fabs(translation.y) / (fabs(translation.x) + 0.1);
        
        // 只有当：
        // 1. 垂直方向占绝对主导（verticalRatio > 2.5）
        // 2. 明显向上滑动（距离或速度）
        BOOL isStrongVertical = verticalRatio > 2.5;
        BOOL isUpSwipe = translation.y < -25 || velocity.y < -300;
        
        return isStrongVertical && isUpSwipe;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 不和任何手势共存，避免冲突
    return NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottomHeight = 80;
    CGFloat containerWidth = self.cardContainer.bounds.size.width;
    CGFloat containerHeight = self.cardContainer.bounds.size.height;
    
    // 布局截图视图
    CGFloat snapshotHeight = containerHeight - bottomHeight;
    self.snapshotView.frame = CGRectMake(0, 0, containerWidth, snapshotHeight);
    
    // 更新渐变层
    for (CALayer *layer in self.snapshotView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.snapshotView.bounds;
        }
    }
    
    // 如果有截图，调整 imageView 位置
    if (self.snapshotImageView.image && !self.snapshotImageView.hidden) {
        UIImage *snapshot = self.snapshotImageView.image;
        CGFloat imageWidth = snapshot.size.width;
        CGFloat imageHeight = snapshot.size.height;
        CGFloat scaleFactor = containerWidth / imageWidth;
        CGFloat scaledHeight = imageHeight * scaleFactor;
        
        CGFloat yOffset = (snapshotHeight - scaledHeight) / 2;
        self.snapshotImageView.frame = CGRectMake(0, yOffset, containerWidth, scaledHeight);
    } else {
        self.snapshotImageView.frame = self.snapshotView.bounds;
    }
    
    // 布局活动指示器
    self.activeIndicator.frame = CGRectMake(0, snapshotHeight - 4, containerWidth, 4);
    
    // 布局标题和路径
    self.titleLabel.frame = CGRectMake(12, snapshotHeight + 8, containerWidth - 24, 24);
    self.pathLabel.frame = CGRectMake(12, snapshotHeight + 36, containerWidth - 24, 18);
    
    // 布局关闭按钮 - 右上角
    self.closeButton.frame = CGRectMake(containerWidth - 22 - 10, 10, 22, 22);
}

- (void)configureWithTitle:(NSString *)title path:(NSString *)path snapshot:(UIImage *)snapshot isActive:(BOOL)isActive {
    self.titleLabel.text = title ?: @"窗口";
    
    NSString *displayPath = path ?: @"";
    if (displayPath.length > 30) {
        displayPath = [NSString stringWithFormat:@"…%@", [displayPath substringFromIndex:displayPath.length - 27]];
    }
    self.pathLabel.text = displayPath;
    
    // 设置截图
    if (snapshot) {
        self.snapshotImageView.image = snapshot;
        self.snapshotImageView.hidden = NO;
    } else {
        self.snapshotImageView.hidden = YES;
    }
    
    // 设置活动状态
    self.activeIndicator.hidden = !isActive;
    if (isActive) {
        self.cardContainer.layer.borderColor = [UIColor systemBlueColor].CGColor;
        self.cardContainer.layer.shadowColor = [UIColor systemBlueColor].CGColor;
        self.cardContainer.layer.shadowOpacity = 0.5;
        self.cardContainer.layer.shadowOffset = CGSizeMake(0, 8);
        self.cardContainer.layer.shadowRadius = 16;
    } else {
        self.cardContainer.layer.borderColor = [UIColor clearColor].CGColor;
        self.cardContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.cardContainer.layer.shadowOpacity = 0.15;
        self.cardContainer.layer.shadowOffset = CGSizeMake(0, 4);
        self.cardContainer.layer.shadowRadius = 8;
    }
}

@end
