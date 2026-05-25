//
//  DockFlowLayout.m
//  SandboxFileManager
//
//  类似Mac程序坞的卡片布局 - 中心卡片放大
//
//

#import "DockFlowLayout.h"

@implementation DockFlowLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        _activeZoneRatio = 0.4;
        _maxScale = 1.25;
        _cardWidth = 280;
        _cardBottomHeight = 80;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 24;
        self.minimumInteritemSpacing = 24;
        self.sectionInset = UIEdgeInsetsMake(40, 40, 100, 40);
    }
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *newAttributes = [NSMutableArray array];
    
    CGRect visibleRect = (CGRect){self.collectionView.contentOffset, self.collectionView.bounds.size};
    CGFloat centerX = visibleRect.origin.x + CGRectGetWidth(visibleRect) / 2;
    CGFloat activeWidth = CGRectGetWidth(visibleRect) * self.activeZoneRatio;
    
    for (UICollectionViewLayoutAttributes *attr in attributes) {
        UICollectionViewLayoutAttributes *attrCopy = [attr copy];
        
        // 计算缩放
        CGFloat distanceFromCenter = fabs(attrCopy.center.x - centerX);
        CGFloat scale;
        
        if (distanceFromCenter < activeWidth / 2) {
            CGFloat progress = 1 - (distanceFromCenter / (activeWidth / 2));
            scale = 1 + (self.maxScale - 1) * progress;
        } else {
            scale = 1.0;
        }
        
        attrCopy.transform = CGAffineTransformMakeScale(scale, scale);
        attrCopy.zIndex = (NSInteger)(scale * 10);
        
        [newAttributes addObject:attrCopy];
    }
    
    return newAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attr = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    CGRect visibleRect = (CGRect){self.collectionView.contentOffset, self.collectionView.bounds.size};
    CGFloat centerX = visibleRect.origin.x + CGRectGetWidth(visibleRect) / 2;
    CGFloat activeWidth = CGRectGetWidth(visibleRect) * self.activeZoneRatio;
    
    // 计算缩放
    CGFloat distanceFromCenter = fabs(attr.center.x - centerX);
    CGFloat scale;
    
    if (distanceFromCenter < activeWidth / 2) {
        CGFloat progress = 1 - (distanceFromCenter / (activeWidth / 2));
        scale = 1 + (self.maxScale - 1) * progress;
    } else {
        scale = 1.0;
    }
    
    attr.transform = CGAffineTransformMakeScale(scale, scale);
    attr.zIndex = (NSInteger)(scale * 10);
    
    return attr;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 检查是否有代理提供截图
    if (self.delegate && [self.delegate respondsToSelector:@selector(dockFlowLayout:snapshotForItemAtIndexPath:)]) {
        UIImage *snapshot = [self.delegate dockFlowLayout:self snapshotForItemAtIndexPath:indexPath];
        
        if (snapshot) {
            // 根据截图宽高比计算高度
            CGFloat imageWidth = snapshot.size.width;
            CGFloat imageHeight = snapshot.size.height;
            CGFloat scaleFactor = self.cardWidth / imageWidth;
            CGFloat scaledImageHeight = imageHeight * scaleFactor;
            
            // 总高度 = 图片高度 + 底部区域
            CGFloat totalHeight = scaledImageHeight + self.cardBottomHeight;
            
            return CGSizeMake(self.cardWidth, totalHeight);
        }
    }
    
    // 默认尺寸
    CGFloat defaultHeight = self.cardWidth * 1.4;
    return CGSizeMake(self.cardWidth, defaultHeight);
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGPoint result = [super targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:velocity];
    
    CGFloat offsetAdjustment = CGFLOAT_MAX;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2);
    
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in array) {
        CGFloat itemHorizontalCenter = layoutAttributes.center.x;
        if (fabs(itemHorizontalCenter - horizontalCenter) < fabs(offsetAdjustment)) {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
        }
    }
    
    result.x += offsetAdjustment;
    
    return result;
}

@end
