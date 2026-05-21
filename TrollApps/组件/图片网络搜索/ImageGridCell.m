#import "ImageGridCell.h"
#import <SDWebImage/SDWebImage.h>

@interface ImageGridCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *selectButton;

@end

@implementation ImageGridCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.layer.cornerRadius = 4;
    self.clipsToBounds = YES;
    
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_imageView];
    
    [_imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [_imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
    [_imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [_imageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    
    _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _selectButton.tag = 100;
    [_selectButton setTintColor:[UIColor greenColor]];
    [_selectButton setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateNormal];
    _selectButton.hidden = YES;
    [_selectButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateSelected];
    
    _selectButton.userInteractionEnabled = NO;
    _selectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_selectButton];
    
    [_selectButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5].active = YES;
    [_selectButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-5].active = YES;
    [_selectButton.widthAnchor constraintEqualToConstant:20].active = YES;
    [_selectButton.heightAnchor constraintEqualToConstant:20].active = YES;
}

- (void)configureWithImageUrl:(NSString *)imageUrl {
    NSString *secureUrl = [imageUrl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:secureUrl]
                       placeholderImage:[UIImage imageNamed:@"placeholder"]
                                options:SDWebImageRetryFailed | SDWebImageLowPriority
                              progress:nil
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            self.imageView.image = [UIImage imageNamed:@"error"];
        }
    }];
}

- (void)setSelectedState:(BOOL)selected {
    self.selectButton.selected = selected;
    self.selectButton.hidden = !selected;
    if (selected) {
        
        self.contentView.layer.borderWidth = 3;
        self.contentView.layer.borderColor = [UIColor greenColor].CGColor;
    } else {
        
        self.contentView.layer.borderWidth = 0;
        self.contentView.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    [self setSelectedState:NO];
}

@end
