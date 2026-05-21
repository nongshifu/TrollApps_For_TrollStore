//
//  PostPublishViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/31.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"
#import "PostPublisher.h"
#import "PostModel.h"
#import "MediaItem.h"
#import "ImageSelectCell.h"

NS_ASSUME_NONNULL_BEGIN

/// 发帖完成回调
typedef void(^PostPublishCompletionBlock)(PostModel *post, NSError * _Nullable error);


@interface PostPublishViewController : DemoBaseViewController<HXPhotoViewDelegate>

/// 发帖完成回调
@property (nonatomic, copy) PostPublishCompletionBlock publishCompletion;

/// 初始化方法（可传入草稿模型）
- (instancetype)initWithDraftPost:(nullable PostModel *)draftPost;

/// 核心模型
@property (nonatomic, strong) PostModel *postModel;

@end

NS_ASSUME_NONNULL_END
