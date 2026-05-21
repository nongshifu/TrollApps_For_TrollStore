#import <UIKit/UIKit.h>

@interface ImageGridCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UIButton *selectButton;

- (void)configureWithImageUrl:(NSString *)imageUrl;
- (void)setSelectedState:(BOOL)selected;

@end
