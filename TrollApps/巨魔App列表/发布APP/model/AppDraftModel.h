//
//  AppDraftModel.h
//  TrollApps
//
//  草稿模型 - 用于保存和加载发布草稿
//

#import <Foundation/Foundation.h>
#import "config.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDraftModel : NSObject<YYModel>

@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *bundleId;
@property (nonatomic, copy) NSString *trackId;
@property (nonatomic, copy) NSString *versionName;
@property (nonatomic, assign) NSInteger appType;
@property (nonatomic, copy) NSString *appDescription;
@property (nonatomic, copy) NSString *releaseNotes;
@property (nonatomic, copy) NSString *appRmb;
@property (nonatomic, assign) NSInteger appStatus;
@property (nonatomic, strong) NSArray<NSString *> *selectedTags;
@property (nonatomic, assign) BOOL isCloudMode;
@property (nonatomic, copy, nullable) NSString *mainFileCloudURL;
@property (nonatomic, strong, nullable) NSNumber *editingAppId;
@property (nonatomic, assign) NSInteger currentVersionCode;
@property (nonatomic, assign) NSTimeInterval saveTime;

@end

NS_ASSUME_NONNULL_END
