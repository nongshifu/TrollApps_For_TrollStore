//
//  ExpandableIconButton.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/5.
//

#import "ExpandableIconButton.h"
#import <Masonry/Masonry.h>



@interface ExpandableIconButton ()<UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL isDragging;              // 是否正在拖动
@property (nonatomic, assign) CGPoint viewCenter;              // 记录拖动位置 以便恢复
@end

@implementation ExpandableIconButton

#pragma mark - 初始化方法

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupDefaultProperties];
        // 设置默认尺寸
        self.frame = CGRectMake(0, 100, _iconSize + _totalPadding * 2, _iconSize + _totalPadding * 2);
        
        // 强制更新布局
        [self layoutIfNeeded];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultProperties];
        // 如果传入的frame尺寸为0，设置默认尺寸
        if (CGRectIsEmpty(frame) || CGRectIsNull(frame)) {
            self.frame = CGRectMake(0, 0, _iconSize + _totalPadding * 2, _iconSize + _totalPadding * 2);
        }
        
        [self loadUI];
        
        // 强制更新布局
        [self layoutIfNeeded];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame icon:(UIImage *)icon title:(NSString *)title {
    self = [super init];
    if (self) {
        [self setupDefaultProperties];
        // 如果传入的frame尺寸为0，设置默认尺寸
        if (CGRectIsEmpty(frame) || CGRectIsNull(frame)) {
            self.frame = CGRectMake(0, 0, _iconSize + _totalPadding * 2, _iconSize + _totalPadding * 2);
        } else {
            self.frame = frame;
        }
        
        //传入参数属性
        _iconImage = icon;
        _title = title;
        
        [self loadUI];
        
        // 强制更新布局
        [self layoutIfNeeded];
    }
    return self;
}


- (void)setupDefaultProperties {
    _containerViewbackgroundColor = [UIColor systemBlueColor];
    _cornerRadius = 0; // 默认为高度的一半
    _animationDuration = 0.4;
    _expandedShowDuration = 3;
    _isExpanded = NO;
    _iconRadius = 0;
    // 设置固定尺寸属性
    _iconSize = 36.0;
    _titleMaxSize = CGSizeMake(300, 200); // 默认最大宽度 高度
    _totalPadding = 10.0;
    _rotatingAnimation =YES;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self loadUI];
}

- (void)loadUI{
    
    [self setupUI];
    [self setupConstraints];
    [self setupGestures];
    [self updateConstraints];
    
}

#pragma mark - UI设置

- (void)setupUI {
    // 创建容器视图
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = self.containerViewbackgroundColor;
    self.containerView.layer.cornerRadius = self.isCircle ? (self.iconSize + self.totalPadding *2) /2 :self.cornerRadius;
    self.containerView.layer.masksToBounds = YES;
    [self addSubview:self.containerView];
    
    // 创建图标视图
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.image = self.iconImage;
    self.iconImageView.contentMode = UIViewContentModeCenter;
    self.iconImageView.tintColor = [UIColor whiteColor];
    self.iconImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    self.iconImageView.layer.cornerRadius = self.isCircle?self.iconSize/2 :self.iconRadius;
    self.iconImageView.layer.masksToBounds = YES;
    [self.containerView addSubview:self.iconImageView];
    
    // 创建标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = self.title;
    self.titleLabel.font = [UIFont systemFontOfSize:14.0];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.numberOfLines = 0; // 支持多行
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.containerView addSubview:self.titleLabel];
    
    //标题下方的子视图容器
    self.subViewContainerView = [UIStackView new];
    self.subViewContainerView.backgroundColor = [UIColor greenColor];
    [self.containerView addSubview:self.subViewContainerView];
    
}

#pragma mark - 设置约束
//设置约束
- (void)setupConstraints {
    // 确保视图已添加到父视图
    [self addSubview:_containerView];
    [_containerView addSubview:_iconImageView];
    [_containerView addSubview:_titleLabel];

    // 容器视图约束 - 使用图标大小和内边距计算总高度
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(_iconSize + _totalPadding * 2);
    }];
    
    // 图标视图约束
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.mas_equalTo(_totalPadding);
        make.width.height.mas_equalTo(_iconSize);
    }];
    
    // 文字标签约束
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_totalPadding);
        make.left.mas_equalTo(_iconImageView.mas_right).offset(_totalPadding);
        make.width.mas_equalTo(0); // 初始宽度为0
    }];
    
    // 标题下方的子视图容器约束
    [self.subViewContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_titleLabel.mas_bottom).offset(_totalPadding);
        make.left.mas_equalTo(_iconImageView.mas_right).offset(_totalPadding);
        make.bottom.lessThanOrEqualTo(_containerView).offset(-_totalPadding);
        
    }];
}

//更新约束
- (void)updateConstraints {
    [super updateConstraints];
    
    
    // 计算安全的标题最大宽度
    CGFloat safeTitleMaxWidth = [self calculateSafeTitleMaxWidth];
    NSLog(@"计算安全的标题最大宽度:%f",safeTitleMaxWidth);
    // 计算标题实际需要的宽高度
    CGSize titleSize = [self sizeForText:_title maxWidth:safeTitleMaxWidth font:_titleLabel.font];
    NSLog(@"计算标题实际需要的宽度:%f 高度:%f",titleSize.width,titleSize.height);
    //取得最终文字宽度 最大屏幕右边距离 最小为实际文字宽度
    CGFloat actualTitleWidth = MIN(titleSize.width, safeTitleMaxWidth);
    NSLog(@"取得最终文字宽度 最大屏幕右边距离 最小为实际文字宽度:%f",actualTitleWidth);
    //取得最终文字高度 最大设置的最大值
    CGFloat actualTitleHeight = MIN(_titleMaxSize.height, titleSize.height);
    NSLog(@"取得最终文字高度 最大设置的最大值:%f",actualTitleHeight);
    //更新文字约束
    [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(actualTitleWidth);
        make.height.mas_equalTo(actualTitleHeight);
    }];
    
    
    
    //更新内容视图宽度 左间隔 +图标+间隔+文本宽度+右侧间隔+父视图和屏幕右侧间隔
    CGFloat containerViewWidth = _totalPadding + _iconSize + _totalPadding + actualTitleWidth + _totalPadding + _totalPadding ;
    
    
    //设置最大高度 更新内容视图高度 文本高度+上下间隔  如果效验头像 取 头像+上下间隔
    CGFloat containerViewMaxHeight = titleSize.height + _totalPadding*3;//最大高度 自适应文本高度+上下
    //如果文字为空 上下间隔就只保留一个顶部间隔 要减去 左右间隔也只保留一个
    if(_titleLabel.text.length == 0){
        containerViewWidth -=_totalPadding;
        containerViewMaxHeight -=_totalPadding;
    }
    //设置最小高度 头像加上下间隔
    CGFloat containerViewMinHeight = _iconSize + _totalPadding*2;//最小高度 头像高度+上下
    
    
    //取最小值
    CGFloat containerViewHeight = MAX(containerViewMaxHeight, containerViewMinHeight);
    
    //取子视图容器宽度
    CGFloat subMaxWidth = CGRectGetMaxX(self.subViewContainerView.frame);
    //取子视图容器高度
    CGFloat subMaxHeight = CGRectGetMaxX(self.subViewContainerView.frame);
    
    //展开状态下取最大值宽度
    containerViewWidth = MAX(subMaxWidth, containerViewWidth);
    //展开状态下取最大值高度
    containerViewHeight = MAX(subMaxHeight, containerViewHeight);
    //更新约束
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        
        if(_isExpanded){
            //如果展开 按以上实际尺寸
            make.width.mas_equalTo(containerViewWidth);
            make.height.mas_equalTo(containerViewHeight);
        }else{
            //如果关闭 使用 头像加上下间隔
            make.width.height.mas_equalTo(containerViewMinHeight);
            
        }
        
    }];
    
    //执行布局动画更新
    [UIView animateWithDuration:self.animationDuration animations:^{
        //设置内容视图圆角
        if(self.isExpanded){
            self.containerView.layer.cornerRadius = self.cornerRadius;
        }else{
            //关闭状态下 如果设置为圆形 就跟随图标圆形 否则为实际圆角
            self.containerView.layer.cornerRadius = self.isCircle ? (self.iconSize + self.totalPadding *2)/2 : self.cornerRadius;
        }
        
        // 旋转图标
        if(self.rotatingAnimation){
            self.iconImageView.transform = CGAffineTransformMakeRotation(M_PI);
        }
        
        
        // 代码强制立即布局
        [self layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        // 旋转图标回到初始状态
        if(self.rotatingAnimation){
            self.iconImageView.transform = CGAffineTransformIdentity;
        }
        
        
        // 更新完成 确保父视图尺寸跟随以上内容视图 动态包裹 才能点击
        CGRect rect = self.frame;
        rect.size.width = CGRectGetWidth(self.containerView.frame);
        rect.size.height = CGRectGetHeight(self.containerView.frame);
        
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = rect;
        } completion:^(BOOL finished) {
            //储存位置
             self.viewCenter = self.center;
        }];
        
        // 自动收缩（如果设置了动画时间 并且当前为展开 倒计时关闭）
        if (self.expandedShowDuration > 0 && self.isExpanded) {
            //执行倒计时
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.expandedShowDuration * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                //倒计时结束 再次判断状态 可能倒计时结束之前 人为点击关闭 避免重复操作发送回调
                if(self.isExpanded){
                    [self collapse];
                }
                
            });
        }
        
        
        
        
    }];
}

#pragma mark - 手势添加

- (void)setupGestures {
    
    
    // 拖动手势
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGesture.delegate = self;
    [self addGestureRecognizer:self.panGesture];
    
    // 点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapGesture];
    
    // 设置点击手势需要失败才能触发拖动手势
    [tapGesture requireGestureRecognizerToFail:self.panGesture];
}

#pragma mark - 手势处理

//拖动
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (!self.isDraggable) return;
    UIView *view = gesture.view;
    CGPoint location = [gesture locationInView:self.superview];
    CGPoint translation = [gesture translationInView:view];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            
            self.isDragging = NO;
            
            // 如果正在展开，先收起
            if (self.isExpanded) {
                [self collapse];
            }
            
            // 调用拖动开始回调
            if (self.dragBeganBlock) {
                self.dragBeganBlock(location);
            }
            break;
            
        case UIGestureRecognizerStateChanged: {
            // 超过阈值才开始拖动
            if (!self.isDragging) {
                self.isDragging = YES;
            }
            
            if (self.isDragging) {
                // 计算位移
                view.center = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
                
                [gesture setTranslation:CGPointZero inView:view];
                // 调用拖动中回调
                if (self.draggingBlock) {
                    self.draggingBlock(location);
                }
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:{
            NSLog(@"拖动结束:%@",self);
            CGPoint newCenter = CGPointMake(view.center.x,
                                            view.center.y);
            
            // 确保按钮在父视图范围内
            newCenter = [self constrainCenterToSuperviewBounds:newCenter];
            
            
            // 更新位置
            self.center = newCenter;
            
            //记录位置
            self.viewCenter = newCenter;
            
            self.isDragging = NO;
            
            [self updateConstraints];
            
            // 只有真正拖动了才调用拖动结束回调
            if (!self.isDragging && self.dragEndedBlock) {
                
                NSLog(@"真正拖动结束:%@",self);
                self.dragEndedBlock(location);
            }
            
            
        }
        case UIGestureRecognizerStateCancelled: {
            
            break;
        }
            
        default:
            break;
    }
}

// 限制按钮在父视图范围内
- (CGPoint)constrainCenterToSuperviewBounds:(CGPoint)center {
    if (!self.superview) return center;
    
    CGFloat halfWidth = self.bounds.size.width / 2.0;
    CGFloat halfHeight = self.bounds.size.height / 2.0;
    
    // 计算边界
    CGFloat minX = halfWidth;
    CGFloat maxX = self.superview.bounds.size.width - halfWidth;
    CGFloat minY = halfHeight;
    CGFloat maxY = self.superview.bounds.size.height - halfHeight;
    
    // 限制在边界内
    center.x = MAX(minX, MIN(maxX, center.x));
    center.y = MAX(minY, MIN(maxY, center.y));
    
    return center;
}

//点击
- (void)handleTap:(UITapGestureRecognizer *)gesture {
    NSLog(@"开始点击");
    if (gesture.state == UIGestureRecognizerStateEnded) {
        // 如果正在拖动，则忽略点击
//        if (self.panGesture.state != UIGestureRecognizerStatePossible) {
//            return;
//        }
        
        if (self.isExpanded) {
            // 展开状态下的点击 发送回调
            if (self.didTapInExpandedState) {
                self.didTapInExpandedState(YES);
            }
            //执行关闭
            [self collapse];
        } else {
            // 发送回调 非展开状态下的点击
            if (self.didTapInCollapsedState) {
                self.didTapInCollapsedState(NO);
            }
            //执行展开
            [self expand];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

// 允许多个手势共存
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 如果是拖动手势，只有在位移超过阈值后才允许与其他手势共存
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return self.isDragging;
    }
    return YES;
}



#pragma mark - 拖动回调设置

- (void)setDragBeganBlock:(void (^)(CGPoint))dragBeganBlock {
    _dragBeganBlock = [dragBeganBlock copy];
}

- (void)setDraggingBlock:(void (^)(CGPoint))draggingBlock {
    _draggingBlock = [draggingBlock copy];
}

- (void)setDragEndedBlock:(void (^)(CGPoint))dragEndedBlock {
    _dragEndedBlock = [dragEndedBlock copy];
}



#pragma mark - 属性设置

- (void)setContainerViewbackgroundColor:(UIColor *)backgroundColor {
    _containerViewbackgroundColor = backgroundColor;
    if (self.containerView) {
        self.containerView.backgroundColor = backgroundColor;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    //判断视图存在
    if (self.containerView) {
        self.containerView.layer.cornerRadius = cornerRadius;
        //判断展开状态 不展开并且圆形
        if(!_isExpanded && _isCircle){
            self.containerView.layer.cornerRadius = (_iconSize + _totalPadding *2) /2;
        }
    }
}

- (void)setIconRadius:(CGFloat)iconRadius {
    _iconRadius = iconRadius;
    if (self.iconImageView) {
        self.iconImageView.layer.cornerRadius = iconRadius;
    }
}

- (void)setIconImage:(UIImage *)iconImage {
    _iconImage = iconImage;
    if (self.iconImageView) {
        self.iconImageView.image = iconImage;
    }
}

- (void)setTitle:(NSString *)title {
    _title = title;
    if (self.titleLabel) {
        self.titleLabel.text = title;
    }
}

- (void)setIsDraggable:(BOOL)isDraggable {
    _isDraggable = isDraggable;
    self.panGesture.enabled = isDraggable;
    
    // 更新外观以提示可拖动状态
    self.containerView.layer.shadowOpacity = isDraggable ? 0.3 : 0.0;
    self.containerView.layer.shadowRadius = isDraggable ? 3.0 : 0.0;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 2);
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (void)setIsCircle:(BOOL)isCircle {
    _isCircle = isCircle;
    //判断视图存在
    if(self.iconImageView){
        self.iconImageView.layer.cornerRadius = _iconSize/2 ;
    }
    if(self.containerView){
        self.containerView.layer.cornerRadius = _cornerRadius;
        if(!_isExpanded){
            self.containerView.layer.cornerRadius = (_iconSize + _totalPadding *2) /2;
        }
    }
    
}

- (void)setTotalPadding:(CGFloat)totalPadding {
    _totalPadding = totalPadding;
    //判断存在
    if(!_iconImageView)return;
    //判断已经在父视图
    if(!_iconImageView.superview)return;
    //更新头像约束
    [_iconImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(_iconImageView.superview).offset(_totalPadding);
    }];
    //判断标题
    if(!_titleLabel)return;
    //判断标题父视图
    if(!_titleLabel.superview)return;
    //更新标题约束
    [_titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_iconImageView.superview.mas_top).offset(_totalPadding);
        make.left.equalTo(_iconImageView.mas_right).offset(_totalPadding);
    }];
    
}

- (void)setRotatingAnimation:(BOOL)rotatingAnimation{
    _rotatingAnimation = rotatingAnimation;
    if(!_iconImageView)return;
    if(rotatingAnimation)return;
    //恢复原始旋转
    _iconImageView.transform = CGAffineTransformIdentity;
}

- (void)setIconSize:(CGFloat)iconSize {
    _iconSize = iconSize;
    if(!_iconImageView)return;
    if(!_iconImageView.superview)return;
    [_iconImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(iconSize);
    }];
    
}


#pragma mark - 布局调整

- (void)layoutSubviews {
    [super layoutSubviews];

    //储存位置
     self.viewCenter = self.center;
    
}

#pragma mark - 辅助函数

// 计算安全的标题最大宽度（不超出屏幕）右侧
- (CGFloat)calculateSafeTitleMaxWidth {
    if (!self.superview) return _titleMaxSize.width;
    
    // 获取按钮在窗口中的位置
    CGRect buttonFrameInWindow = [self convertRect:self.bounds toView:nil];
    
    // 获取屏幕宽度
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    
    // 计算从按钮右侧到屏幕右侧的剩余空间
    CGFloat availableWidth = screenWidth - buttonFrameInWindow.origin.x - _iconSize - _totalPadding * 4;
    
    // 返回预设最大宽度和可用宽度中的较小值
    return MIN(_titleMaxSize.width, MAX(0, availableWidth));
}

//计算最大宽度下 得到的宽度高度尺寸
#pragma mark - 文本尺寸计算

- (CGSize)sizeForText:(NSString *)text
            maxWidth:(CGFloat)maxWidth
                font:(UIFont *)font {
    if (!text || text.length == 0) {
        return CGSizeZero;
    }
    
    // 创建段落样式
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    // 计算文本尺寸
    CGRect textRect = [text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:@{
                                         NSFontAttributeName: font,
                                         NSParagraphStyleAttributeName: paragraphStyle
                                     }
                                        context:nil];
    
    // 返回尺寸（向上取整以避免截断）
    return CGSizeMake(ceil(textRect.size.width), ceil(textRect.size.height));
}


#pragma mark - 展开/收缩方法

- (void)expand {
    if (_isExpanded) return;
    //标记为已经展开
    self.isExpanded = YES;
    //发送展开状态回调
    if (self.didExpand) {
        self.didExpand(YES);
    }
    // 更新约束
    [self updateConstraints];
    
    
    
}

- (void)collapse {
    if (!_isExpanded) return;
    // 旋转图标回到初始状态
    if(self.rotatingAnimation){
        self.iconImageView.transform = CGAffineTransformIdentity;
    }
    //标记为已经关闭
    self.isExpanded = NO;
    //发送关闭回调
    if (self.didCollapse) {
        self.didCollapse(NO);
    }
    // 更新约束
    [self updateConstraints];
   
}


@end
