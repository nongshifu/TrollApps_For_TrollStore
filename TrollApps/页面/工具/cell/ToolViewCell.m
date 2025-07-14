//
//  ToolViewCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "ToolViewCell.h"
#import "config.h"

@implementation ToolViewCell

#pragma mark - 布局方法

- (void)setupUI {
    
    // 设置背景色
    self.backgroundColor = [UIColor clearColor];
    
    self.contentView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.8]
                                                          darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3]
    ];
    self.contentView.layer.cornerRadius = 15;
    
    
    
    [self setupConstraints];
}

- (void)setupConstraints {
    // 应用图标约束
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(self);
    }];
    
   
}

#pragma mark - 数据绑定

- (void)bindViewModel:(id)viewModel {
    if ([viewModel isKindOfClass:[ToolModel class]]) {
        self.toolModel = (ToolModel*)viewModel;
        //布局数据更新UI
    }
        
}

@end
