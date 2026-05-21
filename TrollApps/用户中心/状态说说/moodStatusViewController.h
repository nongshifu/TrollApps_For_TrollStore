//
//  moodStatusViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TemplateListController.h"
#import "MoodStatusModel.h"
#import "moodStatusCell.h"
#import "CustomMoodStatusNavView.h"
#import "PublishMoodViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface moodStatusViewController : TemplateListController
@property (nonatomic, strong) NSString *udid;//查询的用户udid
@property (nonatomic, assign) BOOL sort;//排序  默认按最新时间
@property (nonatomic, strong) NSString *keyword;//搜索关键词
@property (nonatomic, strong) NSString *startTime;//搜索相关 按时间
@end

NS_ASSUME_NONNULL_END
