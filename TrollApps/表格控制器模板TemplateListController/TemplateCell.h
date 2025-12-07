//
//  TemplateCell.h
//  NewSoulChat
//  父类cell模版
//  Created by 十三哥 on 2025/3/7.
//  Copyright © 2025 D-James. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Config.h"
#import "CellHeightCache.h"
NS_ASSUME_NONNULL_BEGIN

// 前向声明
@class TemplateCell;

@protocol TemplateCellDelegate <NSObject>

- (void)refreshCell:(UICollectionViewCell *)cell;

@end

@interface TemplateCell : UICollectionViewCell<IGListBindable>


@property (nonatomic, weak) id<TemplateCellDelegate> delegate; // 代理
/**
 列表视图对象
 */
@property (nonatomic, weak) UICollectionView *collectionView;
/**
 弱引用数据源
 */
@property (nonatomic, weak) NSMutableArray *dataSource;
/**
 缓存高度
 */
@property (nonatomic, assign) CGFloat cachedHeight;
/**
 是否启用缓存高度
 */
@property (nonatomic, assign) BOOL UsingCacheHeight;
/**
 数据模型
 */
@property (nonatomic, strong) id model;
/**
 刷新当前行
 */
- (void)refreshCell;
/**
 传送数据
 */
@property (nonatomic, strong) id idObjc;

#pragma mark - 子类必须重写的方法
/**
 配置UI元素（必须由子类实现）
 */
- (void)setupUI;

/**
 配置布局约束（必须由子类实现）
 */
- (void)setupConstraints;

/**
 数据绑定方法（必须由子类实现）
 @param model 数据模型
 */
- (void)configureWithModel:(id)model;

@end

NS_ASSUME_NONNULL_END
