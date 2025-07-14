//
//  TemplateSectionController.h
//  NewSoulChat
//  父类 SectionController 模版 - 基于 IGListKit
//  Created by 十三哥 on 2025/3/7.
//  Copyright © 2025 D-James. All rights reserved.
//

#import <IGListKit/IGListKit.h>
#import "TemplateCell.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - SectionController 代理协议
@class TemplateSectionController; // 向前声明类

@protocol TemplateSectionControllerDelegate <NSObject>

@optional
/// 刷新指定Cell
- (void)refreshCell:(UICollectionViewCell *)cell;


// 原始索引回调（保留 IGListKit 原生行为）
- (void)templateSectionController:(TemplateSectionController *)sectionController
              didSelectItemAtIndex:(NSInteger)index;

// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                            cell:(UICollectionViewCell *)cell;


@end

#pragma mark - SectionController 主类
@interface TemplateSectionController : IGListSectionController

#pragma mark - 属性声明
/// 关联的代理传递（弱引用）
@property (nonatomic, weak) id<TemplateSectionControllerDelegate> delegate; // 代理
/// 关联的CollectionView（弱引用）
@property (nonatomic, weak) UICollectionView *collectionView;

/// 当前数据模型（通过didUpdateToObject:自动设置）
@property (nonatomic, strong, readonly) id model;

/// 传递附加数据
@property (nonatomic, strong) id idObjc;

/// 是否使用缓存高度（默认YES）
@property (nonatomic, assign) BOOL UsingCacheHeight;

/// 预期的Model类型（可选，用于类型检查）
@property (nonatomic, assign) CGFloat cellHeight;

/// 注册的Cell类型（必需）
@property (nonatomic, strong, readonly) Class cellClass;

/// 预期的Model类型（可选，用于类型检查）
@property (nonatomic, strong, readonly) Class modelClass;

#pragma mark - 初始化方法
/// 基础初始化方法
- (instancetype)initWithCellClass:(Class)cellClass;

/// 指定是否使用高度缓存
- (instancetype)initWithCellClass:(Class)cellClass
                usingCacheHeight:(BOOL)usingCacheHeight;
/// 指定是高度
- (instancetype)initWithCellClass:(Class)cellClass
                       cellHeight:(BOOL)cellHeight;

/// 指定Cell类型和Model类型（用于类型安全）
- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class)modelClass;

/// 完整参数初始化方法
- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class _Nullable)modelClass
                        delegate:(id<TemplateSectionControllerDelegate> _Nullable)delegate
                      edgeInsets:(UIEdgeInsets)edgeInsets
                usingCacheHeight:(BOOL)usingCacheHeight;

/// 完整参数初始化方法
- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class _Nullable)modelClass
                        delegate:(id<TemplateSectionControllerDelegate> _Nullable)delegate
                      edgeInsets:(UIEdgeInsets)edgeInsets
                       cellHeight:(CGFloat)cellHeight;

/// 完整参数初始化方法
- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class _Nullable)modelClass
                        delegate:(id<TemplateSectionControllerDelegate> _Nullable)delegate
                      edgeInsets:(UIEdgeInsets)edgeInsets
                usingCacheHeight:(BOOL)usingCacheHeight
                       cellHeight:(CGFloat)cellHeight;



@end

NS_ASSUME_NONNULL_END
