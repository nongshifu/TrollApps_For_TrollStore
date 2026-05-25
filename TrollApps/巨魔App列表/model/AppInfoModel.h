//
//  AppInfoModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ITunesAppModel.h"
#import "config.h"
#import "UserModel.h"
#import <IGListKit/IGListKit.h>
#import "NewProfileViewController.h"
#import "DownloadRecordModel.h"

NS_ASSUME_NONNULL_BEGIN


#define MAIN_File_KEY @"_mainFile_"
#define ICON_KEY @"icon.png"

typedef NS_ENUM(NSInteger, AppStatus) {
    AppStatusNormal     = 0,    // 正常
    AppStatusInvalid    = 1,    // 失效
    AppStatusUpdating   = 2,    // 更新中
    AppStatusLocked     = 3,    // 锁定
    AppStatusUploading  = 4,    // 上传中
    AppStatusHidden     = 5,    // 隐藏
    AppStatusDeleted    = 6     // 删除
};

@interface AppInfoModel : NSObject<IGListDiffable,YYModel>
//OC属性
@property (nonatomic, strong, nullable) UIImage *appIcon; // 软件图标
@property (nonatomic, strong, nullable) NSString *iconBase64String;
@property (nonatomic, strong, nullable) NSString * icon_url;//软件图标URL
@property (nonatomic, strong, nullable) ITunesAppModel *iTunesAppModel;//商店数据字典
@property (nonatomic, strong, nullable) NSString *mainFileUrl;//主程序URL
@property (nonatomic, assign) BOOL is_cloud;//是否是云端URL
@property (nonatomic, strong, nullable) NSData *mainFileData;//主程序数据


@property (nonatomic, assign) BOOL isShowAll;////cell属性 是否显示全部 用于查看折叠软件

///数据库属性
@property (nonatomic, assign) NSInteger app_id;
@property (nonatomic, copy) NSString *bundle_id;
@property (nonatomic, copy) NSString *app_name;
@property (nonatomic, copy) NSString *track_id;
@property (nonatomic, copy) NSString *task_id;
@property (nonatomic, assign) NSInteger upload_status;
@property (nonatomic, copy) NSString *save_path;
@property (nonatomic, assign) NSInteger app_type;
@property (nonatomic, strong) NSString *add_date;
@property (nonatomic, strong) NSString *update_date;
@property (nonatomic, copy) NSString *udid;
@property (nonatomic, copy) NSString *idfv;
///点赞数量
@property (nonatomic, assign) NSInteger like_count;
/// 是否已经点赞
@property (nonatomic, assign) BOOL isLike;
/// 收藏数量
@property (nonatomic, assign) NSInteger collect_count;
/// 是否收藏
@property (nonatomic, assign) BOOL isCollect;
/// 踩一踩数量
@property (nonatomic, assign) NSInteger dislike_count;
/// 是否踩一踩
@property (nonatomic, assign) BOOL isDislike;
/// 评论数量
@property (nonatomic, assign) NSInteger comment_count;
/// 是否已经评论
@property (nonatomic, assign) BOOL isComment;
/// 分享数量
@property (nonatomic, assign) NSInteger share_count;
/// 是否已经分析
@property (nonatomic, assign) BOOL isShare;
/// 下载数量
@property (nonatomic, assign) NSInteger download_count;
/// 购买所需要的积分
@property (nonatomic, assign) NSInteger app_rmb;
/// 是否已经购买
@property (nonatomic, assign) BOOL hasPurchased;

@property (nonatomic, copy) NSString *app_remark;
@property (nonatomic, copy) NSString *app_description;
@property (nonatomic, assign) AppStatus app_status;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, assign) NSInteger current_version_code;
@property (nonatomic, copy) NSString *version_name;
@property (nonatomic, copy) NSString *release_notes;
@property (nonatomic, strong) NSMutableArray<NSString *> *fileNames;

@property (nonatomic, strong) UserModel*userModel;

/// 获取 App 下载链接（异步）
/// @param app_id App 的唯一标识
/// @param success 成功回调：返回下载链接 NSURL
/// @param failure 失败回调：返回错误信息 NSError
+ (void)getDownloadLinkWithAppId:(NSInteger)app_id
                         success:(void(^)(DownloadRecordModel *recordModel, NSURL *downloadURL, NSDictionary *json))success
                         failure:(void(^)(NSError *error))failure;

/// 获取 App 下载链接（异步）
/// @param app_id App 的唯一标识
/// @param success 成功回调：返回下载链接 NSURL
/// @param failure 失败回调：返回错误信息 NSError
+ (void)getDownloadLinkAndRecordHistoryWithAppId:(NSInteger)app_id
                                         success:(void(^)(DownloadRecordModel *recordModel, NSDictionary *json))success
                                         failure:(void(^)(NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
