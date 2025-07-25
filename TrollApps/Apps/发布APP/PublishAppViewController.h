//
//  PublishAppViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import "DemoBaseViewController.h"
#import "config.h"
#import "AppInfoModel.h"
#import "AppVersionModel.h"
#import "NewAppFileModel.h"
#import "UploadManager.h"
#import "UploadTask.h"
#import "UserModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, NewCategoryType) {
    CategoryTypePublish = 0,  // 发布新软件
    CategoryTypeUpdate = 1    // 更新软件
};
@interface PublishAppViewController : DemoBaseViewController
@property (nonatomic, strong) AppInfoModel *app_info; // 应用信息模型
@property (nonatomic, strong) ITunesAppModel *iTunesAppModel;//应用商店模型
///0发布新软件 1 更新软件 （更新时候务必带上appId）
@property (nonatomic, assign) NewCategoryType category;
@end

NS_ASSUME_NONNULL_END
