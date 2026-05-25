//
//  FileOperationToolbar.m
//  SandboxFileManager
//
//  文件操作悬浮工具栏实现
//
//

#import "FileOperationToolbar.h"

@interface FileOperationToolbar ()

@property (nonatomic, strong) UIVisualEffectView *backgroundView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) NSMutableArray<UIButton *> *actionButtons;

@end

@implementation FileOperationToolbar

+ (instancetype)toolbar {
    return [[self alloc] initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 12;
    self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    
    // 毛玻璃背景
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.backgroundView];
    
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
    // 堆栈视图
    self.stackView = [[UIStackView alloc] init];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.axis = UILayoutConstraintAxisHorizontal;
    self.stackView.spacing = 10;
    self.stackView.alignment = UIStackViewAlignmentCenter;
    self.stackView.layoutMargins = UIEdgeInsetsMake(0, 10, 0, 10);
    self.stackView.layoutMarginsRelativeArrangement = YES;
    [self.scrollView addSubview:self.stackView];
    
    // 选中数量标签
    self.countLabel = [[UILabel alloc] init];
    self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.countLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.countLabel.textColor = [UIColor secondaryLabelColor];
    self.countLabel.text = @"0 项";
    [self addSubview:self.countLabel];
    
    // 创建按钮
    [self createActionButtons];
    
    // 布局约束
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scrollView.heightAnchor constraintEqualToConstant:40],
        
        [self.stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.stackView.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor],
        
        [self.countLabel.topAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:2],
        [self.countLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.countLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10]
    ]];
    
    // 默认高度
    self.frame = CGRectMake(0, 0, 320, 45);
}

- (void)createActionButtons {
    self.actionButtons = [NSMutableArray array];
    
    NSArray *configs = @[
        @{@"title": @"拷贝", @"image": @"doc.on.doc", @"tag": @(FileOperationActionCopy)},
        @{@"title": @"移动", @"image": @"arrow.right", @"tag": @(FileOperationActionMove)},
        @{@"title": @"删除", @"image": @"trash", @"tag": @(FileOperationActionDelete)},
        @{@"title": @"重命名", @"image": @"pencil", @"tag": @(FileOperationActionRename)},
        @{@"title": @"压缩", @"image": @"archivebox", @"tag": @(FileOperationActionCompress)},
        @{@"title": @"收藏", @"image": @"star", @"tag": @(FileOperationActionFavorite)},
        @{@"title": @"更多", @"image": @"ellipsis.circle", @"tag": @(FileOperationActionMore)},
        @{@"title": @"完成", @"image": @"checkmark", @"tag": @(FileOperationActionDone)}
    ];
    
    for (NSDictionary *config in configs) {
        UIButton *button = [self createButtonWithConfig:config];
        [self.stackView addArrangedSubview:button];
        [self.actionButtons addObject:button];
    }
}


- (UIButton *)createButtonWithConfig:(NSDictionary *)config {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:config[@"title"] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    button.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    button.layer.cornerRadius = 6;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor systemBlueColor].CGColor;
    button.tag = [config[@"tag"] integerValue];;
    button.contentEdgeInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    [button addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)actionButtonTapped:(UIButton *)button {
    FileOperationAction action = (FileOperationAction)button.tag;
    if ([self.delegate respondsToSelector:@selector(toolbar:didSelectAction:)]) {
        [self.delegate toolbar:self didSelectAction:action];
    }
}

- (void)setSelectedCount:(NSInteger)selectedCount {
    _selectedCount = selectedCount;
    [self updateSelectedCount:selectedCount];
}

- (void)updateSelectedCount:(NSInteger)count {
    self.countLabel.text = [NSString stringWithFormat:@"%ld 项", (long)count];
}

- (void)setShowsDoneButton:(BOOL)showsDoneButton {
    _showsDoneButton = showsDoneButton;
    for (UIButton *button in self.actionButtons) {
        if (button.tag == FileOperationActionDone) {
            button.hidden = !showsDoneButton;
        }
    }
}

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    CGFloat toolbarHeight = 54 + view.safeAreaInsets.bottom;
    CGRect startFrame = CGRectMake(0, view.bounds.size.height, view.bounds.size.width, toolbarHeight);
    CGRect endFrame = CGRectMake(0, view.bounds.size.height - toolbarHeight, view.bounds.size.width, toolbarHeight);
    
    self.frame = startFrame;
    [view addSubview:self];
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.frame = endFrame;
        } completion:nil];
    } else {
        self.frame = endFrame;
    }
}

- (void)hideAnimated:(BOOL)animated {
    CGRect endFrame = CGRectMake(self.frame.origin.x, self.superview.bounds.size.height, self.frame.size.width, self.frame.size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.frame = endFrame;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

@end
