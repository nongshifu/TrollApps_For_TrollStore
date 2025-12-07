//
//  CustomMoodStatusNavView.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol CustomMoodStatusNavViewDelegate <NSObject>
// 排序按钮点击
- (void)sortButtonTapped;
// 发布按钮点击
- (void)publishButtonTapped;
// 时间选择点击
- (void)timeSelectorTapped;
@end

@interface CustomMoodStatusNavView : UIView
// 当前排序状态（YES/NO）
@property (nonatomic, assign) BOOL isSorted;
// 当前选中的时间文本
@property (nonatomic, copy) NSString *timeText;
// 标题文本
@property (nonatomic, copy) NSString *titleText;
// 代理
@property (nonatomic, weak) id<CustomMoodStatusNavViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
