//
//  FeedbackCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//

#import "TemplateCell.h"
#import <YYModel/YYModel.h>
#import "config.h"
#import "UserFeedbackModel.h"

NS_ASSUME_NONNULL_BEGIN

@class FeedbackCell;

@protocol UserFeedbackCellDelegate <NSObject>

@optional
- (void)feedbackCell:(FeedbackCell *)cell didUpdateStatus:(NSInteger)status forFeedback:(UserFeedbackModel *)feedback;
- (void)feedbackCell:(FeedbackCell *)cell didSubmitReply:(NSString *)reply forFeedback:(UserFeedbackModel *)feedback;
@end

@interface FeedbackCell : TemplateCell

@property (nonatomic, weak) id<UserFeedbackCellDelegate> feedbackDelegate;

@end

NS_ASSUME_NONNULL_END
