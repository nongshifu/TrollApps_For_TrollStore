//
//  PostPublisher.h
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <YYModel/YYModel.h>
#import "PostModel.h"
#import "MediaItem.h"
#import "config.h"
NS_ASSUME_NONNULL_BEGIN

/// 帖子发布回调
typedef void(^PublishCompletionBlock)(BOOL success, NSString *message, PostModel * _Nullable postModel);
typedef void(^PublishProgressBlock)(CGFloat progress);


@interface PostPublisher : NSObject

@property (nonatomic, strong) NSMutableArray<MediaItem *> *mediaItems;

/// 单例（避免重复创建）
+ (instancetype)sharedInstance;


/// 发布帖子主方法
- (void)publishPost:(PostModel *)postModel
           progress:(PublishProgressBlock)progress
         completion:(PublishCompletionBlock)completion;



@end

NS_ASSUME_NONNULL_END
