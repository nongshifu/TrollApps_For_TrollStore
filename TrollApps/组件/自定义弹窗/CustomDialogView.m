#import "CustomDialogView.h"
// 定义默认文案常量（方便统一维护）
#define kDefaultTitle @"对方已无法和您对话"
#define kDefaultSubtitle @"亲爱的Souler，对方账号因多人标记，疑似性别作假，为维护您的私聊体验，已限制对方与您的聊天，感谢理解。"
#define kDefaultButtonTitle @"我知道了"
#define kDefaultBottomTip @"若您想要恢复对话，可点击申请>"

@interface CustomDialogView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UILabel *bottomTipLabel;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation CustomDialogView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 全屏半透明遮罩
    self.frame = [UIScreen mainScreen].bounds;
    // 自适应暗黑/亮色模式的遮罩背景
    UIColor *maskColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [[UIColor blackColor] colorWithAlphaComponent:0.7];
        } else {
            return [[UIColor blackColor] colorWithAlphaComponent:0.3];
        }
    }];
    self.backgroundColor = maskColor;

    // 容器视图（宽高为屏幕一半，居中）
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    CGFloat containerW = screenW/3*2+20;
    CGFloat containerH = screenH * 0.5 - 90;
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake((screenW - containerW)/2, (screenH - containerH)/2, containerW, containerH)];
    // 自适应暗黑/亮色模式的容器背景
    UIColor *containerBgColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.01 green:0.01 blue:0.1 alpha:1];
        } else {
            return [UIColor whiteColor];
        }
    }];
    self.containerView.backgroundColor = containerBgColor;
    self.containerView.layer.cornerRadius = 15;
    self.containerView.clipsToBounds = YES;
    [self addSubview:self.containerView];

    // 顶部图片区域
    self.topImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, containerW, containerH * 0.35)];
    // Base64字符串转NSData
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:DIALOG_TOP_BG_BASE64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    // NSData转UIImage
    UIImage *topImage = [UIImage imageWithData:imageData];
    // 赋值给imageView
    self.topImageView.image = topImage; // 兜底图片（可选）
    
    self.topImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.containerView addSubview:self.topImageView];
    CGFloat titleSize = 18.0f;
    // 标题（自适应颜色）
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.topImageView.frame) + 40, containerW - 40, titleSize)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:titleSize weight:UIFontWeightMedium];
    UIColor *titleColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor whiteColor];
        } else {
            return [UIColor blackColor];
        }
    }];
    self.titleLabel.textColor = titleColor;
    [self.containerView addSubview:self.titleLabel];

    // 副标题（自适应颜色）
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.titleLabel.frame) + 15, containerW - 40, 60)];
    self.subtitleLabel.numberOfLines = 0;
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.font = [UIFont systemFontOfSize:13.5];
    UIColor *subtitleColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor lightGrayColor];
        } else {
            return [UIColor darkGrayColor];
        }
    }];
    self.subtitleLabel.textColor = subtitleColor;
    [self.containerView addSubview:self.subtitleLabel];

    // 按钮（颜色保持浅青色，适配两种模式）
    CGFloat actionButtonSize = 38.0f;
    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(30, CGRectGetMaxY(self.subtitleLabel.frame) + 20, containerW - 60, actionButtonSize)];
    self.actionButton.backgroundColor = [UIColor colorWithRed:0.38466 green:0.739215 blue:0.778431 alpha:1.0];
    self.actionButton.layer.cornerRadius = actionButtonSize/2;
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.actionButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.actionButton];

    // 底部提示（自适应颜色）
    self.bottomTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.actionButton.frame) + 10, containerW - 40, 20)];
    self.bottomTipLabel.textAlignment = NSTextAlignmentCenter;
    self.bottomTipLabel.font = [UIFont systemFontOfSize:12];
    UIColor *tipColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:1.0];
        } else {
            return [UIColor colorWithRed:0.1 green:0.5 blue:0.8 alpha:1.0];
        }
    }];
    self.bottomTipLabel.textColor = tipColor;
    [self.containerView addSubview:self.bottomTipLabel];
    
    
    // ========== 新增：底部关闭叉号按钮 ==========
    CGFloat closeButtonWH = 30;
    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(
                                                                  (screenW - closeButtonWH)/2,
                                                                  CGRectGetMaxY(self.containerView.frame) + 20,
                                                                  closeButtonWH,
                                                                  closeButtonWH
                                                                  )];
    self.closeButton.layer.cornerRadius = closeButtonWH/2;
    self.closeButton.layer.borderWidth = 1;
    self.closeButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    [self.closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle buttonTitle:(NSString *)buttonTitle bottomTip:(NSString *)bottomTip {
    // 赋值时判断是否为nil，nil则用默认值
    self.titleLabel.text = title ?: kDefaultTitle;
    self.subtitleLabel.text = subtitle ?: kDefaultSubtitle;
    [self.actionButton setTitle:buttonTitle ?: kDefaultButtonTitle forState:UIControlStateNormal];
    self.bottomTipLabel.text = bottomTip ?: kDefaultBottomTip;
}

// ========== 核心修改：参数nil时使用默认值 ==========
+ (void)showWithTitle:(NSString *)title subtitle:(NSString *)subtitle buttonTitle:(NSString *)buttonTitle bottomTip:(NSString *)bottomTip {
    CustomDialogView *dialog = [[CustomDialogView alloc] init];
    // 传入参数前先做nil判断，nil则替换为默认值
    NSString *finalTitle = title ?: kDefaultTitle;
    NSString *finalSubtitle = subtitle ?: kDefaultSubtitle;
    NSString *finalButtonTitle = buttonTitle ?: kDefaultButtonTitle;
    NSString *finalBottomTip = bottomTip ?: kDefaultBottomTip;
    
    [dialog setTitle:finalTitle subtitle:finalSubtitle buttonTitle:finalButtonTitle bottomTip:finalBottomTip];
    [[UIApplication sharedApplication].keyWindow addSubview:dialog];
}

+ (void)showDefault{
    [CustomDialogView showWithTitle:nil subtitle:nil buttonTitle:nil bottomTip:nil];
}


- (void)dismiss {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


@end
