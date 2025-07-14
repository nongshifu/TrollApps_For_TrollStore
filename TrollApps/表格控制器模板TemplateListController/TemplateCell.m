//
//  TemplateCell.m
//  NewSoulChat
//  父类cell模版
//  Created by 十三哥 on 2025/3/7.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "TemplateCell.h"

@implementation TemplateCell


#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

#pragma mark - 布局方法（空实现，强制子类重写）
- (void)setupUI {
    NSAssert(NO, @"子类必须重写 %@ 方法", NSStringFromSelector(_cmd));
}

- (void)setupConstraints {
    NSAssert(NO, @"子类必须重写 %@ 方法", NSStringFromSelector(_cmd));
}

#pragma mark - 数据绑定
- (void)configureWithModel:(id)model {
    NSAssert(NO, @"子类必须重写 %@ 方法", NSStringFromSelector(_cmd));
}

#pragma mark - 布局更新后缓存cell高度
- (void)layoutSubviews {
    [super layoutSubviews];

    // 获取 Cell 的最终高度
    CGFloat height = CGRectGetHeight(self.contentView.frame);
    

    // 缓存高度
    self.cachedHeight = height;
    
    // 缓存高度
    [CellHeightCache cacheHeightForModel:_model height:height];
    


}

#pragma mark - IGListBindable协议
- (void)bindViewModel:(id)viewModel {
    _model = viewModel;
    // 将绑定逻辑统一到 configureWithModel: 方法
    [self configureWithModel:viewModel];
    
    
    
}

#pragma mark - 重用准备
- (void)prepareForReuse {
    [super prepareForReuse];
    // 重置视图状态（子类可按需重写）
}
#pragma mark - 刷新当前行
- (void)refreshCell {
    self.cachedHeight = 0;
    // 强制布局更新
    [self setNeedsLayout];
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
    }];
    
    if (self.delegate) {
        [self.delegate refreshCell:self];
    }
}

@end
