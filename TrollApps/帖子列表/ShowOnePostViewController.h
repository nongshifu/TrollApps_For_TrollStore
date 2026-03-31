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
/// 数据模型
@property (nonatomic, strong) PostModel *postModel;
/// 帖子UUID
@property (nonatomic, strong) NSString *post_uuid;
/// 帖子ID（数据库主键，自增）
@property (nonatomic, assign) long long post_id;;

///排序
@property (nonatomic, assign) int sort_type;

@end

NS_ASSUME_NONNULL_END
