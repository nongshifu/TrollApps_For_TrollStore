//
//  moodStatusCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TemplateCell.h"
#import "MoodStatusModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface moodStatusCell : TemplateCell
@property (nonatomic, strong) MoodStatusModel *moodStatusModel;
@property (nonatomic, strong) UITextView *moodStatusTextView;
@property (nonatomic, strong) UILabel *moodStatusTime;

@end

NS_ASSUME_NONNULL_END
