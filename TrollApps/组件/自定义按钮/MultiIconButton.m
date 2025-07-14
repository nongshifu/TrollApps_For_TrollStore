#import "MultiIconButton.h"

@interface MultiIconButton ()

// 存储不同状态下的字体
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIFont *> *titleFontsForStates;
// 存储不同状态下的左侧图标
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *leftImagesForStates;
// 存储不同状态下的右侧图标
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *rightImagesForStates;
// 存储不同状态下的顶部图标
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *topImagesForStates;
// 存储不同状态下的底部图标
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *bottomImagesForStates;

@end


@implementation MultiIconButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
        self.imageTextSpacing = 5;
        self.titleFontsForStates = [NSMutableDictionary dictionary];
        self.leftImagesForStates = [NSMutableDictionary dictionary];
        self.rightImagesForStates = [NSMutableDictionary dictionary];
        self.topImagesForStates = [NSMutableDictionary dictionary];
        self.bottomImagesForStates = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setupSubviews {
    
    self.backgroundColorView = [[UIView alloc] init];
    [self addSubview:self.backgroundColorView];
    
    self.rightImageView = [[UIImageView alloc] init];
    self.rightImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.rightImageView];

    self.topImageView = [[UIImageView alloc] init];
    self.topImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.topImageView];

    self.bottomImageView = [[UIImageView alloc] init];
    self.bottomImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.bottomImageView];

    self.leftImageView = [[UIImageView alloc] init];
    self.leftImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.leftImageView];
}

- (void)setLeftImage:(UIImage *)image forState:(UIControlState)state {
    if (image) {
        _leftImage = image;
        self.leftImagesForStates[@(state)] = image;
        if (self.state == state) {
            self.leftImageView.image = image;
        }
    }
    [self setNeedsLayout];
}

- (void)setRightImage:(UIImage *)image forState:(UIControlState)state {
    if (image) {
        _rightImage = image;
        self.rightImagesForStates[@(state)] = image;
        if (self.state == state) {
            self.rightImageView.image = image;
        }
    }
    [self setNeedsLayout];
}

- (void)setTopImage:(UIImage *)image forState:(UIControlState)state {
    if (image) {
        self.topImagesForStates[@(state)] = image;
        if (self.state == state) {
            self.topImageView.image = image;
            
        }
    }
    [self setNeedsLayout];
}

- (void)setBottomImage:(UIImage *)image forState:(UIControlState)state {
    if (image) {
        self.bottomImagesForStates[@(state)] = image;
        if (self.state == state) {
            self.bottomImageView.image = image;
        }
    }
    [self setNeedsLayout];
}

- (void)setTitleFont:(UIFont *)font forState:(UIControlState)state {
    if (font) {
        self.titleFontsForStates[@(state)] = font;
        if (self.state == state) {
            self.titleLabel.font = font;
        }
    }
    [self setNeedsLayout];
}

- (void)setState:(UIControlState)state {
    UIFont *font = self.titleFontsForStates[@(state)];
    if (font) {
        self.titleLabel.font = font;
    }

    UIImage *leftImage = self.leftImagesForStates[@(state)];
    if (leftImage) {
        self.leftImageView.image = leftImage;
    }

    UIImage *rightImage = self.rightImagesForStates[@(state)];
    if (rightImage) {
        self.rightImageView.image = rightImage;
    }

    UIImage *topImage = self.topImagesForStates[@(state)];
    if (topImage) {
        self.topImageView.image = topImage;
    }

    UIImage *bottomImage = self.bottomImagesForStates[@(state)];
    if (bottomImage) {
        self.bottomImageView.image = bottomImage;
    }

    [self setNeedsLayout];
}
- (void)setBackgroundColor:(UIColor *)backgroundColor{
    
    self.backgroundColorView.backgroundColor = backgroundColor;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    
    CGRect titleRect = [self titleRectForContentRect:self.bounds];
    

    UIEdgeInsets insets = UIEdgeInsetsZero;

    // 获取当前文字的字体大小
    CGFloat fontSize = self.titleLabel.font.pointSize;
    // 计算图标大小，这里的 1.2 可以根据需要调整
    CGFloat iconSize = fontSize;
    
    
    
    // 处理顶部图标
    CGRect topImageRect = self.topImageView.frame;
    CGFloat topImageWidth = topImageRect.size.width;
    CGFloat topImageHeight = topImageRect.size.height;
    self.topImageView.frame = CGRectMake(topImageRect.origin.x, 0, topImageWidth, topImageHeight);
    insets.top = topImageHeight + self.topImageTextSpacing;
    
    
    // 处理底部图标
    CGRect bottomImageRect = self.bottomImageView.frame;
    CGFloat bottomImageWidth = bottomImageRect.size.width;
    CGFloat bottomImageHeight = bottomImageRect.size.height;
    self.bottomImageView.frame = CGRectMake(bottomImageRect.origin.x, CGRectGetMaxY(titleRect) + self.bottomImageTextSpacing, bottomImageWidth, bottomImageHeight);
    insets.bottom = bottomImageHeight + self.bottomImageTextSpacing;
    
    // 处理左侧图标 - 修改部分
    [self.leftImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(self.imageTextSpacing);
        make.width.height.mas_equalTo(iconSize);
        make.centerY.equalTo(self.titleLabel);
        
    }];
    // 文字和左侧图标之间的间距设为5
    insets.left = (_leftImage ? iconSize+self.imageTextSpacing :0) + self.imageTextSpacing; // 图标宽度 + 图标左侧间距5 + 图标文字间距5

    // 处理右侧图标
    [self.rightImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self);
        make.width.height.mas_equalTo(iconSize);
        make.centerY.equalTo(self.titleLabel);
        
    }];
    insets.right = (_rightImage?iconSize:0) + self.imageTextSpacing;
    
    // 最后拉伸
    self.contentEdgeInsets = insets;
    
    [self.backgroundColorView mas_updateConstraints:^(MASConstraintMaker *make) {
       
        make.width.equalTo(self);
        if (self.heightIncludesTopImages) {
            make.top.equalTo(self.mas_top);
        }else{
            make.top.equalTo(self.titleLabel.mas_top).offset(- self.topImageTextSpacing );
        }
        if (self.heightIncludesBottomImages) {
            make.bottom.equalTo(self.mas_bottom);
        }else{
            make.bottom.equalTo(self.titleLabel.mas_bottom ).offset(self.bottomImageTextSpacing);
        }
    }];
    
    self.backgroundColorView.layer.cornerRadius = self.layer.cornerRadius;
    self.backgroundColorView.layer.masksToBounds = self.layer.masksToBounds;

    
   

    
}

@end
