//
//  TipBarCell.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/2/24.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "TemplateCell.h"
#import "TipBarModel.h"

// TipBarCell 点击通知宏定义
#define kTipBarCellTappedNotification @"TipBarCellTappedNotification"

NS_ASSUME_NONNULL_BEGIN

@class TipBarCell;

@protocol TipBarCellDelegate <NSObject>

@optional
/**
 点击了提示栏中的元素
 @param cell 触发事件的单元格
 @param model 单元格的数据模型
 @param buttonType 按钮类型（0=图标，1=文本，2=左按钮，3=右按钮）
 @param sender 触发事件的视图对象（UIImageView/UIButton/UILabel）
 */
- (void)tipBarCell:(TipBarCell *)cell
       didTapElementWithModel:(TipBarModel *)model
                  buttonType:(NSInteger)buttonType
                    sender:(id)sender;
@end

@interface TipBarCell : TemplateCell

@property (nonatomic, weak, nullable) id<TipBarCellDelegate> tipBarDelegate;

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;


@end




NS_ASSUME_NONNULL_END
