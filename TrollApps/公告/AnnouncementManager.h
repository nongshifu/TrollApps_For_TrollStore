//
//  AnnouncementManager.h
//  TrollApps
//
//  Created by 十三哥 on 2026/5/14.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnnouncementModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AnnouncementDisplayState) {
    AnnouncementDisplayStateNone = 0,      // 不显示
    AnnouncementDisplayStateOnce = 1,      // 显示一次（已显示过不再显示）
    AnnouncementDisplayStateEveryTime = 2  // 每次启动都显示
};

@interface AnnouncementManager : NSObject

// 单例
+ (instancetype)sharedManager;

// 最新公告
@property (nonatomic, strong, nullable) AnnouncementModel *latestAnnouncement;

// 是否已显示过最新公告
- (BOOL)hasShownAnnouncement:(AnnouncementModel *)announcement;

// 检查是否应该显示公告
- (AnnouncementDisplayState)shouldDisplayAnnouncement:(AnnouncementModel *)announcement;

// 记录已显示公告
- (void)markAnnouncementAsShown:(AnnouncementModel *)announcement;

// 刷新最新公告
- (void)fetchLatestAnnouncementWithCompletion:(void(^_Nullable)(AnnouncementModel * _Nullable announcement, NSError * _Nullable error))completion;

// 显示最新公告（如果符合条件）
- (void)showAnnouncementIfNeededFromViewController:(UIViewController *)viewController;

// 手动显示特定公告
- (void)showAnnouncement:(AnnouncementModel *)announcement fromViewController:(UIViewController *)viewController;

// 清除所有显示历史
- (void)clearDisplayHistory;

@end

NS_ASSUME_NONNULL_END
