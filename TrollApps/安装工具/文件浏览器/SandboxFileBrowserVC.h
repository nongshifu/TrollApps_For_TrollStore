//
//  SandboxFileBrowserVC.h
//  TrollApps
//
//  Created by 十三哥 on 2025/11/29.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import "NewAppFileModel.h"
#import "FileUtils.h"
#import "config.h"

NS_ASSUME_NONNULL_BEGIN
// 🔥 1. 定义代理协议
@class SandboxFileBrowserVC;
@protocol SandboxFileBrowserVCDelegate <NSObject>

@optional
/// 单选模式下点击文件时回调
/// @param browserVC 当前浏览器控制器
/// @param cell 被点击的表格 cell
/// @param fileModel 被点击的文件模型
- (void)sandboxFileBrowserVC:(SandboxFileBrowserVC *)browserVC
             didSelectFileCell:(UITableViewCell *)cell
                     fileModel:(NewAppFileModel *)fileModel;

@end

@interface SandboxFileBrowserVC : UITableViewController<UISearchBarDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>
+ (instancetype)sharedBrowser;
/// 快速创建浏览器（默认进入Documents目录）
+ (instancetype)browserWithDefaultPath;

/// 指定初始目录创建浏览器
+ (instancetype)browserWithInitialPath:(NSString *)initialPath;

/// 单选模式
@property (nonatomic, assign) BOOL singleSelectionMode;

// 🔥 2. 添加代理属性（weak 避免循环引用）
@property (nonatomic, weak) id<SandboxFileBrowserVCDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
