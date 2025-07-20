//
//  AppCommentCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "TemplateCell.h"
#import "CommentModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface AppCommentCell : TemplateCell
@property (nonatomic, strong) CommentModel *appComment;
@end

NS_ASSUME_NONNULL_END
