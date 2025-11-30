// CustomContainerView.m
#import "MiniButtonView.h"

@implementation MiniButtonView 
// 普通初始化方法
- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 0);
        [self setDefaultParameters];
    }
    return self;
}

// 带 frame 的初始化方法
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.frame = frame;
        self.contentSize = CGSizeMake(frame.size.width, 0);
        [self setDefaultParameters];
    }
    return self;
}


- (instancetype)initWithStrings:(NSArray<NSString *> *)strings icons:(NSArray<NSString *> * _Nullable)icons fontSize:(CGFloat)size{
    self = [super init];
    if (self) {
        self.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 0);
        
        [self setDefaultParameters];
        
        self.titles = strings? [strings mutableCopy] : @[];
        self.icons = icons? [icons copy] : @[];
        self.fontSize = size;
        
        if (self.titles ) {
            [self createButtons];
            [self refreshLayout];
        }
    }
    return self;
}

- (void)setDefaultParameters{
    
    self.buttonBcornerRadius = 0;
    self.refreshHeight = 0;
    self.animationTime = 0;
    self.buttons = [NSMutableArray array];
    self.fontSize = 14;
    self.buttonSpace = 3;
    self.delegate = self;
    
    self.buttonBackgroundColorAlpha = 1;
    self.buttonBackageColorArray = @[];
    self.autoLineBreak = NO; // 默认不自动换行
    self.hidesScrollIndicator = YES; // 默认隐藏滚动条
    self.userInteractionEnabled = YES;
}

- (void)createButtons {
    for (NSInteger i = 0; i < self.titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.userInteractionEnabled = YES;
        if (self.buttonBackageColorArray && i < self.buttonBackageColorArray.count) {
            if(self.buttonBackgroundColorAlpha <1){
                button.backgroundColor = [self.buttonBackageColorArray[i] colorWithAlphaComponent:self.buttonBackgroundColorAlpha];
            }else{
                button.backgroundColor = self.buttonBackageColorArray[i];
            }
            
        } else if(self.buttonBackageColor){
            button.backgroundColor = self.buttonBackageColor;
        }else{
            button.backgroundColor = [self randomColorWithAlpha:self.buttonBackgroundColorAlpha];
        }

        button.layer.cornerRadius = self.buttonBcornerRadius;
        [button setTitle:self.titles[i] forState:UIControlStateNormal];

        // 判断图标是否存在
        UIImage *iconImage = [UIImage new];
        if (self.icons && i < self.icons.count && self.icons[i].length > 0) {
            iconImage = [UIImage systemImageNamed:self.icons[i]];
            if(!iconImage){
                iconImage = [UIImage imageNamed:self.icons[i]];
            }
            [button setImage:iconImage forState:UIControlStateNormal];
        } else {
            button.imageView.image = iconImage;
        }

        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        button.imageView.userInteractionEnabled = YES;
        
        button.titleLabel.font = [UIFont boldSystemFontOfSize:self.fontSize];
        button.titleLabel.numberOfLines = 1;
        button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        //文字设置颜色
        if (self.titleColors && i < self.titleColors.count && self.titleColors[i]) {
            [button setTitleColor:self.titleColors[i] forState:UIControlStateNormal];
        } else if(self.titleColor){
            [button setTitleColor:self.titleColor forState:UIControlStateNormal];
        }
        
        //设置图标颜色
        if (self.iconColors && i < self.iconColors.count && self.iconColors[i]) {
            // 2. 单独设置图标颜色（不影响文字）
            button.imageView.tintColor = self.iconColors[i];
            
            
        } else if(self.tintIconColor){
            
            button.tintColor = self.tintIconColor;
        }
        

        // 创建长按手势识别器
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)];
        longPressGesture.minimumPressDuration = 0.5;
        [button addGestureRecognizer:longPressGesture];

        // 创建双击手势识别器
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonDoubleTapped:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        [button addGestureRecognizer:doubleTapGesture];
        
        // 为按钮添加点击手势识别器
        UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped:)];
        singleTapGesture.cancelsTouchesInView = NO; // 允许触摸事件传递给按钮
        [button addGestureRecognizer:singleTapGesture];
        
        // 让点击手势识别器在双击手势识别器之后响应
        [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];


        button.tag = i;
        [_buttons addObject:button];
        [self addSubview:button];

        // 设置边距属性在添加手势识别器之后
        if (button.imageView.image) {
            button.imageEdgeInsets = UIEdgeInsetsMake(_space, 0, _space, _space);
        }
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        button.contentEdgeInsets = UIEdgeInsetsMake(0, _space, 0, _space);
        NSLog(@"buttom:%d   buttom:%@", button.userInteractionEnabled, button);
    }
    [self refreshLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self refreshLayout];
}

- (BOOL)refreshLayout {
    __weak typeof(self) weakSelf = self;
    __block BOOL updated = NO;
    
    // 动画块中使用 weakSelf 避免循环引用，同时在 Block 内部先判断 weakSelf 非 nil
    [UIView animateWithDuration:self.animationTime animations:^{
        // 先判断 weakSelf 是否有效，避免访问 nil 的属性
        if (!weakSelf) return;
        
        CGFloat totalWidth = CGRectGetWidth(weakSelf.frame);
        CGFloat buttonHeight = 0;
        CGFloat x = 0;
        CGFloat y = 0;
        // 使用 weakSelf 的属性，确保访问的是最新值
        CGFloat space = weakSelf.space;
        space = MAX(space, 3); // 保证最小间距为 3
        CGFloat maxButtonHeight = 0;
        CGFloat totalHeight = 0;
        CGFloat buttonSpace = weakSelf.buttonSpace; // 缓存 buttonSpace，避免多次访问
        
        for (UIButton *button in weakSelf.buttons) {
            CGSize textSize = [button.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            CGSize imageSize = button.imageView.image? button.imageView.image.size : CGSizeZero;
            
            CGFloat buttonWidth = textSize.width;
            if (button.imageView.image) {
                buttonWidth += imageSize.width + space * 3; // 使用缓存的 space
            }
            buttonHeight = MAX(buttonHeight, textSize.height);
            maxButtonHeight = MAX(maxButtonHeight, buttonHeight + space * 2);
            
            if (!weakSelf.autoLineBreak) {
                // 不自动换行，同一行布局
                button.frame = CGRectMake(x, y, buttonWidth, buttonHeight + space * 2);
                x += buttonWidth + buttonSpace; // 使用缓存的 buttonSpace
            } else {
                // 自动换行逻辑
                if (x + buttonWidth > totalWidth) {
                    x = 0;
                    y += maxButtonHeight + buttonSpace;
                    totalHeight += maxButtonHeight;
                    maxButtonHeight = 0;
                }
                button.frame = CGRectMake(x, y, buttonWidth, buttonHeight + space * 2);
                x += buttonWidth + buttonSpace;
            }
            
            if (button.imageView.image) {
                button.imageEdgeInsets = UIEdgeInsetsMake(space, 0, space, space);
            }
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
            button.contentEdgeInsets = UIEdgeInsetsMake(0, space, 0, space);
        }
        
        // 计算总高度（修复重复累加问题）
        if (x > 0) {
            totalHeight += maxButtonHeight;
        }
        // 此处无需单独计算 lastRowHeight，totalHeight 已包含最后一行高度
        CGFloat newRefreshHeight = weakSelf.buttons.count > 0
            ? (weakSelf.autoLineBreak ? CGRectGetMaxY(weakSelf.buttons.lastObject.frame) + space : CGRectGetHeight(weakSelf.frame))
            : 0;
        
        if (!weakSelf.autoLineBreak) {
            weakSelf.contentSize = CGSizeMake(x, newRefreshHeight);
        }
        weakSelf.showsHorizontalScrollIndicator = !weakSelf.hidesScrollIndicator;
        weakSelf.showsVerticalScrollIndicator = !weakSelf.hidesScrollIndicator;
        
        // 确保 weakSelf 非 nil 再比较
        if (weakSelf) {
            updated = (weakSelf.refreshHeight != newRefreshHeight);
            weakSelf.refreshHeight = newRefreshHeight;
        }
    }];
    
    return updated;
}

//任意随机色
- (UIColor *)randomColorWithAlpha:(CGFloat)alpha {
    CGFloat red = (CGFloat)arc4random_uniform(256) / 255.0;
    CGFloat green = (CGFloat)arc4random_uniform(256) / 255.0;
    CGFloat blue = (CGFloat)arc4random_uniform(256) / 255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

// 点击方法
- (void)buttonTapped:(UITapGestureRecognizer *)gestureRecognizer {
    UIButton *button = (UIButton *)gestureRecognizer.view;
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if ([self.buttonDelegate respondsToSelector:@selector(buttonTappedWithTag:title:button:)]) {
            [self.buttonDelegate buttonTappedWithTag:button.tag title:button.titleLabel.text button:button];
        }
    }
}

// 长按方法
- (void)buttonLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    UIButton *button = (UIButton *)gestureRecognizer.view;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.buttonDelegate respondsToSelector:@selector(buttonLongPressedWithTag:title:button:)]) {
            [self.buttonDelegate buttonLongPressedWithTag:button.tag title:button.titleLabel.text button:button];
        }
    }
}

// 双击方法
- (void)buttonDoubleTapped:(UITapGestureRecognizer *)gestureRecognizer {
    UIButton *button = (UIButton *)gestureRecognizer.view;
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if ([self.buttonDelegate respondsToSelector:@selector(buttonDoubleTappedWithTag:title:button:)]) {
            [self.buttonDelegate buttonDoubleTappedWithTag:button.tag title:button.titleLabel.text button:button];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
         NSLog(@"开始滑动");
    // 通知开始滑动
    if ([self.buttonDelegate respondsToSelector:@selector(miniButtonViewDidStartSliding)]) {
        [self.buttonDelegate miniButtonViewDidStartSliding];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        NSLog(@"结束滑动（无惯性滚动）");
        if ([self.buttonDelegate respondsToSelector:@selector(miniButtonViewDidStopSliding)]) {
            [self.buttonDelegate miniButtonViewDidStopSliding];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"结束滑动（惯性滚动结束）");
    if ([self.buttonDelegate respondsToSelector:@selector(miniButtonViewDidStopSliding)]) {
        [self.buttonDelegate miniButtonViewDidStopSliding];
    }
}
/// 外部调用以更新按钮并刷新视图
- (void)updateButtonsWithStrings:(NSArray<NSString *> *)newStrings icons:(NSArray<NSString *> * _Nullable)newIcons {
    NSLog(@"更新");
    self.titles = newStrings? [newStrings copy] : nil;
    self.icons = newIcons? [newIcons copy] : @[];
    
    // 移除旧的按钮
    for (UIButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    
    if (self.titles) {
        [self createButtons];
        [self refreshLayout];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 允许按钮的点击事件继续
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 根据需要决定是否同时响应多个手势识别器
    return YES;
}


- (void)setButtonBcornerRadius:(CGFloat)buttonBcornerRadius{
    _buttonBcornerRadius = buttonBcornerRadius;
    for (UIButton *button in self.buttons) {
        button.layer.cornerRadius = _buttonBcornerRadius;
    }

    [self refreshLayout];
}

@end
