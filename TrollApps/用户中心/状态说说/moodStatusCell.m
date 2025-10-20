//
//  moodStatusCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "moodStatusCell.h"
#import "MoodStatusModel.h"
#import "Masonry.h"

@implementation moodStatusCell
#pragma mark - 子类必须重写的方法
/**
 配置UI元素（必须由子类实现）
 */
- (void)setupUI{
    // 1. 内容文本框（不可编辑，自适应高度）
    self.moodStatusTextView = [[UITextView alloc] init];
    self.moodStatusTextView.editable = NO; // 禁止编辑
    self.moodStatusTextView.scrollEnabled = NO; // 禁止滚动（内容自适应高度）
    self.moodStatusTextView.font = [UIFont systemFontOfSize:16];
    self.moodStatusTextView.textColor = [UIColor labelColor]; // 适配深色模式
    self.moodStatusTextView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.moodStatusTextView]; // 添加到contentView
    
    // 2. 时间标签
    self.moodStatusTime = [[UILabel alloc] init];
    self.moodStatusTime.font = [UIFont systemFontOfSize:12];
    self.moodStatusTime.textColor = [UIColor secondaryLabelColor]; // 次要文本颜色
    self.moodStatusTime.textAlignment = NSTextAlignmentRight; // 右对齐
    [self.contentView addSubview:self.moodStatusTime];
}

/**
 配置布局约束（必须由子类实现）
 */
- (void)setupConstraints{
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(kWidth - 40));
        
    }];
    
    // 内容文本框约束（上下左右留边距，宽度适应cell）
    [self.moodStatusTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(12);
        make.left.equalTo(self.contentView).offset(0);
        make.right.equalTo(self.contentView).offset(0);
        // 高度不固定，由内容决定（最低高度40）
        make.height.greaterThanOrEqualTo(@40);
    }];
    
    // 时间标签约束（在文本框下方，右对齐）
    [self.moodStatusTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.moodStatusTextView.mas_bottom).offset(8);
        make.right.equalTo(self.moodStatusTextView); // 与文本框右对齐
        make.bottom.equalTo(self.contentView).offset(-12); // 底部留边
        make.left.greaterThanOrEqualTo(self.contentView).offset(16); // 左边界限制
        make.height.equalTo(@20); // 固定高度
    }];
}


#pragma mark - 数据绑定

- (void)configureWithModel:(id)model {
    
    
    if ([model isKindOfClass:[MoodStatusModel class]]) {
        self.moodStatusModel = (MoodStatusModel *)model;
        
        // 绑定内容
        self.moodStatusTextView.text = self.moodStatusModel.content ?: @"暂无内容";
        
        // 绑定时间（可格式化处理，例如简化为"10-21 15:30"）
        NSString *time = [self formatTime:self.moodStatusModel.publish_time] ?: @"未知时间";
        self.moodStatusTime.text = [NSString stringWithFormat:@"发布于:%@   -删除",time];
    }
}

#pragma mark - 辅助方法（时间格式化）

/// 简化时间显示（例如："2025-10-21 15:30:00" → "10-21 15:30"）
- (NSString *)formatTime:(NSString *)originalTime {
    if (!originalTime.length) return nil;
    
    // 原始时间格式：yyyy-MM-dd HH:mm:ss
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    inputFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [inputFormatter dateFromString:originalTime];
    if (!date) return originalTime;
    
    // 目标格式：MM-dd HH:mm
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    outputFormatter.dateFormat = @"MM-dd HH:mm";
    return [outputFormatter stringFromDate:date];
}

@end
