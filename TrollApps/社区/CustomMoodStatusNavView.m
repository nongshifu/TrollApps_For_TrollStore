//
//  CustomMoodStatusNavView.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "CustomMoodStatusNavView.h"
#import "Masonry.h"

@implementation CustomMoodStatusNavView


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemBackgroundColor];
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    // 1. 左侧排序按钮
    UIButton *sortBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    sortBtn.tag = 100;
    [sortBtn setTitle:@"排序" forState:UIControlStateNormal];
    [sortBtn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:sortBtn];
    
    // 2. 中间标题
    UILabel *titleLabel = [UILabel new];
    titleLabel.tag = 101;
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:titleLabel];
    
    // 3. 右侧发布按钮
    UIButton *publishBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    publishBtn.tag = 102;
    [publishBtn setTitle:@"发布" forState:UIControlStateNormal];
    [publishBtn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:publishBtn];
    
    // 4. 分割线
    UIView *line = [UIView new];
    line.backgroundColor = [UIColor systemGrayColor];
    [self addSubview:line];
    
    // 5. 时间选择行
    UIView *timeContainer = [UIView new];
    timeContainer.tag = 103;
    timeContainer.userInteractionEnabled = YES;
    [timeContainer addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(timeTapped)]];
    [self addSubview:timeContainer];
    
    // 时间标签
    UILabel *timeLabel = [UILabel new];
    timeLabel.text = @"时间筛选:";
    timeLabel.font = [UIFont systemFontOfSize:14];
    timeLabel.textColor = [UIColor secondaryLabelColor];
    [timeContainer addSubview:timeLabel];
    
    // 时间值
    UILabel *timeValueLabel = [UILabel new];
    timeValueLabel.tag = 104;
    timeValueLabel.font = [UIFont systemFontOfSize:14];
    timeValueLabel.textColor = [UIColor labelColor];
    [timeContainer addSubview:timeValueLabel];
    
    // 箭头图标
    UIImageView *arrowImgV = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
    arrowImgV.tintColor = [UIColor secondaryLabelColor];
    arrowImgV.contentMode = UIViewContentModeScaleAspectFit;
    [timeContainer addSubview:arrowImgV];
    
    // 布局
    [sortBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.centerY.equalTo(self.mas_top).offset(44/2); // 导航栏高度的一半
        make.width.lessThanOrEqualTo(@80);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(sortBtn);
        make.left.greaterThanOrEqualTo(sortBtn.mas_right).offset(8);
        make.right.lessThanOrEqualTo(publishBtn.mas_left).offset(-8);
    }];
    
    [publishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(sortBtn);
        make.width.lessThanOrEqualTo(@80);
    }];
    
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(sortBtn.mas_bottom).offset(12);
        make.height.equalTo(@0.5);
    }];
    
    [timeContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self).inset(16);
        make.top.equalTo(line.mas_bottom).offset(8);
        make.bottom.equalTo(self).offset(-8);
        make.height.equalTo(@30);
    }];
    
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(timeContainer);
    }];
    
    [timeValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(timeLabel.mas_right).offset(8);
        make.centerY.equalTo(timeContainer);
    }];
    
    [arrowImgV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(timeValueLabel.mas_right).offset(4);
        make.centerY.equalTo(timeContainer);
        make.width.height.equalTo(@16);
    }];
}

// 按钮点击事件
- (void)buttonTapped:(UIButton *)btn {
    if (btn.tag == 100) { // 排序按钮
        if ([self.delegate respondsToSelector:@selector(sortButtonTapped)]) {
            [self.delegate sortButtonTapped];
        }
    } else if (btn.tag == 102) { // 发布按钮
        if ([self.delegate respondsToSelector:@selector(publishButtonTapped)]) {
            [self.delegate publishButtonTapped];
        }
    }
}

// 时间选择点击
- (void)timeTapped {
    if ([self.delegate respondsToSelector:@selector(timeSelectorTapped)]) {
        [self.delegate timeSelectorTapped];
    }
}

// 更新排序状态文本
- (void)setIsSorted:(BOOL)isSorted {
    _isSorted = isSorted;
    UIButton *sortBtn = [self viewWithTag:100];
    [sortBtn setTitle:isSorted ? @"排序 ▲" : @"排序 ▼" forState:UIControlStateNormal];
}

// 更新标题
- (void)setTitleText:(NSString *)titleText {
    _titleText = titleText;
    UILabel *titleLabel = [self viewWithTag:101];
    titleLabel.text = titleText;
}

// 更新时间文本
- (void)setTimeText:(NSString *)timeText {
    _timeText = timeText;
    UILabel *timeValueLabel = [self viewWithTag:104];
    timeValueLabel.text = timeText;
}


@end
