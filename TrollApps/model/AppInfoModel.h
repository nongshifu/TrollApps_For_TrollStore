//
//  AppInfoModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ITunesAppModel.h"
#import <IGListKit/IGListKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface AppInfoModel : NSObject<IGListDiffable>
//OC属性
@property (nonatomic, strong, nullable) UIImage *appIcon; // 软件图标
@property (nonatomic, strong, nullable) NSString *iconBase64String;
@property (nonatomic, strong, nullable) NSString * icon_url;//软件图标URL
@property (nonatomic, strong, nullable) ITunesAppModel *iTunesAppModel;//商店数据字典
@property (nonatomic, strong, nullable) NSString *mainFileUrl;//主程序URL
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
@property (nonatomic, assign) NSInteger like_count;
@property (nonatomic, assign) BOOL isLike;
@property (nonatomic, assign) NSInteger collect_count;
@property (nonatomic, assign) BOOL isCollect;
@property (nonatomic, assign) NSInteger dislike_count;
@property (nonatomic, assign) BOOL isDislike;
@property (nonatomic, assign) NSInteger comment_count;
@property (nonatomic, assign) BOOL isComment;
@property (nonatomic, assign) NSInteger share_count;
@property (nonatomic, assign) BOOL isShare;
@property (nonatomic, assign) NSInteger download_count;
@property (nonatomic, copy) NSString *app_remark;
@property (nonatomic, copy) NSString *app_description;
@property (nonatomic, assign) NSInteger app_status;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, assign) NSInteger current_version_code;
@property (nonatomic, copy) NSString *version_name;
@property (nonatomic, copy) NSString *release_notes;
@property (nonatomic, strong) NSMutableArray<NSString *> *fileNames;

@end

NS_ASSUME_NONNULL_END
