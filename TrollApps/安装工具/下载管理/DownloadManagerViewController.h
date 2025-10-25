//
//  DownloadManagerViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/18.

//

#import "DemoBaseViewController.h"
#import "DownloadTaskModel.h"

// 新增筛选类型枚举
typedef NS_ENUM(NSInteger, FilterType) {
    FilterTypeDownloading = 0,  // 下载中
    FilterTypeAll,              // 全部
    FilterTypeFileTypes         // 文件类型起始值
};

NS_ASSUME_NONNULL_BEGIN

@interface DownloadManagerViewController : DemoBaseViewController
// 1. 外部可访问的下载目录属性（核心修改：从私有改为public）
@property (nonatomic, strong) NSString *downloadDir;

// 2. 手动切换目录的方法（外部调用此方法切换）
- (void)switchToDirectory:(NSString *)directoryPath;

// 3. 保留原单例方法（外部通过单例访问）
+ (instancetype)sharedInstance;

- (void)handleTaskStatusChanged;

@property (nonatomic, assign) FilterType currentFilterType;      // 当前筛选类型
@end

NS_ASSUME_NONNULL_END
