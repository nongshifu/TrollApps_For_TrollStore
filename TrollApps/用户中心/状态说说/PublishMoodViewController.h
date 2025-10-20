//
//  PublishMoodViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
// 发布成功的回调
typedef void(^PublishSuccessBlock)(void);

@interface PublishMoodViewController : DemoBaseViewController

// 发布成功后回调（用于刷新列表）
@property (nonatomic, copy) PublishSuccessBlock publishSuccessBlock;

@end

NS_ASSUME_NONNULL_END
