//
//  AppDowngradeModel.h
//  TrollApps
//
//  Created by 十三哥 on 2026/3/26.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppStoreAuth.h"
NS_ASSUME_NONNULL_BEGIN

@interface AppDowngradeModel : NSObject
@property (nonatomic, copy) NSString *appName;        // 应用显示名
@property (nonatomic, copy) NSString *bundleId;       // 应用包ID（核心，用于查历史版本）
@property (nonatomic, copy) NSString *currentVersion; // 当前安装版本
@property (nonatomic, copy) NSString *appPath;        // 包体路径
@property (nonatomic, strong) UIImage *appIcon;       // 应用图标
+ (NSArray<AppDowngradeModel *> *)getInstalledApps ;
+ (void)getAppTrackIdWithBundleId:(NSString *)bundleId completion:(void(^)(NSString *trackId, NSError *error))completion;
+ (void)getAppHistoryVersionsWithTrackId:(NSString *)trackId completion:(void(^)(NSArray *versionList, NSError *error))completion ;
+ (void)searchAppsWithTerm:(NSString *)term completion:(void(^)(NSArray *apps, NSError *error))completion ;
@end

NS_ASSUME_NONNULL_END
