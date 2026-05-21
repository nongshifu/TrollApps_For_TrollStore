//
//  AppPublishEditViewModel.h
//  TrollApps
//
//  发布/编辑视图模型 - 单例模式，支持草稿保存
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppInfoModel.h"
#import "MediaItemModel.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kAppPublishDraftKey; // 草稿存储Key

@interface AppPublishEditViewModel : NSObject

/// 单例访问
+ (instancetype)sharedInstance;

/// 是否是编辑模式
@property (nonatomic, assign) BOOL isEditMode;

/// 当前编辑的应用ID (nil表示新建)
@property (nonatomic, strong, nullable) NSNumber *editingAppId;

/// 当前版本号 (编辑模式才有值)
@property (nonatomic, assign) NSInteger currentVersionCode;



/// ==================== 应用基本信息 ====================
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *bundleId;
@property (nonatomic, copy) NSString *trackId;
@property (nonatomic, copy) NSString *versionName;
@property (nonatomic, assign) NSInteger appType;
@property (nonatomic, copy) NSString *appDescription;
@property (nonatomic, copy) NSString *releaseNotes;
@property (nonatomic, copy) NSString *appRmb;
@property (nonatomic, assign) NSInteger appStatus;

/// ==================== 图标相关 ====================
/// 图标本地数据(新上传)
@property (nonatomic, strong, nullable) UIImage *iconImage;
@property (nonatomic, strong, nullable) NSData *iconData;
/// 现有图标URL
@property (nonatomic, copy, nullable) NSString *existingIconURL;

/// ==================== 主文件相关 ====================
/// 主文件云端URL (云端模式)
@property (nonatomic, copy, nullable) NSString *mainFileCloudURL;
/// 主文件本地数据 (本地上传模式)
@property (nonatomic, strong, nullable) NSData *mainFileData;
@property (nonatomic, copy, nullable) NSString *mainFileName;
/// 是否云端模式
@property (nonatomic, assign) BOOL isCloudMode;

/// ==================== 标签 ====================
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedTags;

/// ==================== 媒体文件 (截图和视频) ====================
@property (nonatomic, strong) NSMutableArray<MediaItemModel *> *mediaItems;

/// ==================== 商店数据 (可选) ====================
@property (nonatomic, strong, nullable) ITunesAppModel *iTunesAppModel;

/// ==================== 方法 ====================

/// 初始化为新建模式
- (void)setupForNewApp;

/// 初始化为编辑模式 (加载现有数据)
/// @param appId 应用ID
/// @param completion 加载完成回调
- (void)setupForEditWithAppId:(NSInteger)appId completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

/// 保存草稿
- (void)saveDraft;

/// 加载草稿
/// @return 是否有保存的草稿
- (BOOL)loadDraft;

/// 清除草稿
- (void)clearDraft;

/// 重置所有数据
- (void)resetAllData;

/// 获取待删除的现有媒体文件列表
- (NSArray<NSString *> *)pendingDeleteMediaFiles;

/// 获取所有新上传的媒体文件
- (NSArray<MediaItemModel *> *)newMediaItems;

/// 获取所有现有媒体文件
- (NSArray<MediaItemModel *> *)existingMediaItems;

/// 检查是否有未保存的更改
- (BOOL)hasUnsavedChanges;

/// 验证数据是否完整
/// @param error 错误信息
/// @return 是否通过验证
- (BOOL)validateDataWithError:(NSError * _Nullable * _Nullable)error;

/// 显示错误提示
- (void)showValidationError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
