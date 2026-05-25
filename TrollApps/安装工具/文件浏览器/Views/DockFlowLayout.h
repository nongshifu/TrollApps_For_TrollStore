//
//  DockFlowLayout.h
//  SandboxFileManager
//
//  类似Mac程序坞的卡片布局 - 中心卡片放大
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DockFlowLayout;

@protocol DockFlowLayoutDelegate <NSObject>

@optional

/// 获取指定索引的截图
/// @param layout 布局对象
/// @param indexPath 索引
- (UIImage *)dockFlowLayout:(DockFlowLayout *)layout snapshotForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface DockFlowLayout : UICollectionViewFlowLayout

/// 代理
@property (nonatomic, weak) id<DockFlowLayoutDelegate> delegate;

/// 激活区域比例（占屏幕宽度的比例，比如0.5表示中间50%区域）
@property (nonatomic, assign) CGFloat activeZoneRatio;

/// 最大缩放比例
@property (nonatomic, assign) CGFloat maxScale;

/// 固定卡片宽度
@property (nonatomic, assign) CGFloat cardWidth;

/// 固定卡片底部高度（标题+路径区域）
@property (nonatomic, assign) CGFloat cardBottomHeight;

/// 获取指定索引的卡片尺寸
/// @param indexPath 索引
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
