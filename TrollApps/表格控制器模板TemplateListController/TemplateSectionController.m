//
//  TemplateSectionController.m
//  NewSoulChat
//  父类 SectionController 模版实现
//  Created by 十三哥 on 2025/3/7.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "TemplateSectionController.h"
#import "TemplateCell.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

#pragma mark - 类扩展
@interface TemplateSectionController () <TemplateCellDelegate>
// 私有属性（已在头文件声明）
@end

#pragma mark - 实现部分
@implementation TemplateSectionController

#pragma mark - 生命周期方法
// MARK: 初始化方法群
/// 主初始化方法（设计ated initializer）
- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class)modelClass
                        delegate:(id<TemplateSectionControllerDelegate>)delegate
                      edgeInsets:(UIEdgeInsets)edgeInsets
                usingCacheHeight:(BOOL)usingCacheHeight
                       cellHeight:(CGFloat)cellHeight{
    self = [super init];
    if (self) {
        _cellClass = cellClass;
        _modelClass = modelClass;
        _delegate = delegate;
        self.inset = edgeInsets;
        _UsingCacheHeight = usingCacheHeight;
        _cellHeight = cellHeight;
    }
    return self;
}

- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class)modelClass
                        delegate:(id<TemplateSectionControllerDelegate>)delegate
                      edgeInsets:(UIEdgeInsets)edgeInsets
                usingCacheHeight:(BOOL)usingCacheHeight {
    return [self initWithCellClass:cellClass
                        modelClass:modelClass
                          delegate:delegate
                        edgeInsets:edgeInsets
                  usingCacheHeight:usingCacheHeight
                        cellHeight:0];
}

- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class)modelClass
                        delegate:(id<TemplateSectionControllerDelegate>)delegate
                      edgeInsets:(UIEdgeInsets)edgeInsets
                cellHeight:(CGFloat)cellHeigh {
    return [self initWithCellClass:cellClass
                        modelClass:modelClass
                          delegate:delegate
                        edgeInsets:edgeInsets
                  usingCacheHeight:NO
                        cellHeight:cellHeigh];
}

/// 基础初始化
- (instancetype)initWithCellClass:(Class)cellClass {
    return [self initWithCellClass:cellClass
                       modelClass:nil
                        delegate:nil
                      edgeInsets:UIEdgeInsetsMake(0, 0, 0.5, 0)
                usingCacheHeight:YES];
}

/// 带缓存配置的初始化
- (instancetype)initWithCellClass:(Class)cellClass
                usingCacheHeight:(BOOL)usingCacheHeight {
    return [self initWithCellClass:cellClass
                       modelClass:nil
                        delegate:nil
                      edgeInsets:UIEdgeInsetsMake(0, 0, 0.5, 0)
                usingCacheHeight:usingCacheHeight];
}
- (instancetype)initWithCellClass:(Class)cellClass
                cellHeight:(BOOL)cellHeight {
    return [self initWithCellClass:cellClass
                       modelClass:nil
                        delegate:nil
                      edgeInsets:UIEdgeInsetsMake(0, 0, 0.5, 0)
                usingCacheHeight:NO
                        cellHeight:cellHeight];
}

/// 带Model类型检查的初始化
- (instancetype)initWithCellClass:(Class)cellClass
                       modelClass:(Class)modelClass {
    return [self initWithCellClass:cellClass
                       modelClass:modelClass
                        delegate:nil
                      edgeInsets:UIEdgeInsetsMake(0, 0, 0.5, 0)
                usingCacheHeight:YES];
}

#pragma mark - IGListKit 数据源方法
// MARK: 数据更新
/// 数据模型更新（IGListKit自动调用）
- (void)didUpdateToObject:(id)object {
    _model = object;
}

// MARK: 单元格尺寸计算
/// 返回单元格尺寸
- (CGSize)sizeForItemAtIndex:(NSInteger)index {
    // 创建临时cell并绑定数据
    UICollectionViewCell *tempCell = [[_cellClass alloc] initWithFrame:CGRectZero];
    CGFloat width = self.collectionContext.containerSize.width - self.inset.left - self.inset.right;
    if(_UsingCacheHeight){
        if(_cellHeight == 0){
            _cellHeight = [CellHeightCache getCachedHeightForModel:_model];
        }
        return CGSizeMake(width,_cellHeight);
    }
    
    CGFloat height = [tempCell systemLayoutSizeFittingSize:CGSizeMake(width, 0)
             withHorizontalFittingPriority:UILayoutPriorityRequired
                   verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    return CGSizeMake(width, height);
}

// MARK: 单元格配置
/// 返回配置好的单元格
- (UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index {
    UICollectionViewCell *cell = [self.collectionContext
        dequeueReusableCellOfClass:_cellClass
             forSectionController:self
                          atIndex:index];
    
    // 配置TemplateCell特有属性
    TemplateCell *templateCell = (TemplateCell *)cell;
    templateCell.delegate = self;
    templateCell.collectionView = self.collectionView;
    templateCell.tag = self.section;
    templateCell.idObjc = self.idObjc;
    templateCell.dataSource = self.dataSource;
    
    // 绑定数据（如果cell实现了bindViewModel:方法）
    [cell performSelector:@selector(bindViewModel:) withObject:_model];
    return cell;
}

#pragma mark - TemplateCellDelegate
// MARK: 单元格事件处理
/// 处理单元格刷新请求
- (void)refreshCell:(UICollectionViewCell *)cell {
    // 更新高度缓存
    TemplateCell *templateCell = (TemplateCell *)cell;
    [templateCell layoutIfNeeded];
    CGFloat height = CGRectGetHeight(templateCell.contentView.frame);
    [CellHeightCache cacheHeightForModel:templateCell.model height:height];
    
    // 通知代理
    if ([_delegate respondsToSelector:@selector(refreshCell:)]) {
        [_delegate refreshCell:cell];
    }
    
    // 执行局部刷新
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

/// 处理单元格点击事件


#pragma mark - IGListKit 点击事件处理
- (void)didSelectItemAtIndex:(NSInteger)index {
    // 1. 调用原始代理（可选）
    if ([_delegate respondsToSelector:@selector(templateSectionController:didSelectItemAtIndex:)]) {
        [_delegate templateSectionController:self didSelectItemAtIndex:index];
    }
    
    // 2. 扩展：获取模型和 Cell 并传递
    UICollectionViewCell *cell = [self cellForItemAtIndex:index];
    
    if ([_delegate respondsToSelector:@selector(templateSectionController:didSelectItem:atIndex:cell:)]) {
        [_delegate templateSectionController:self
                                   didSelectItem:self.model
                                         atIndex:index
                                           cell:cell];
    }
}


@end
