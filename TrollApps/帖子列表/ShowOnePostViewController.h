//
//  ShowOnePostViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2026/3/23.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "TemplateListController.h"
#import "PostModel.h"
#import "PostCell.h"
#import "CommentModel.h"
#import "AppCommentCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowOnePostViewController : TemplateListController <TemplateSectionControllerDelegate>

/// 帖子ID（数据库主键，自增）
@property (nonatomic, assign) long long post_id;;

///排序
@property (nonatomic, assign) int sort_type;

@end

NS_ASSUME_NONNULL_END
