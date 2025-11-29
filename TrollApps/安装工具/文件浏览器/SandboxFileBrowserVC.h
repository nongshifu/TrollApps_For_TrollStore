//
//  SandboxFileBrowserVC.h
//  TrollApps
//
//  Created by 十三哥 on 2025/11/29.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

NS_ASSUME_NONNULL_BEGIN

@interface SandboxFileBrowserVC : UITableViewController<UISearchBarDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>
+ (instancetype)sharedBrowser;
/// 快速创建浏览器（默认进入Documents目录）
+ (instancetype)browserWithDefaultPath;

/// 指定初始目录创建浏览器
+ (instancetype)browserWithInitialPath:(NSString *)initialPath;


@end

NS_ASSUME_NONNULL_END
