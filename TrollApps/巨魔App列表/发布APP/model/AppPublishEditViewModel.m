//
//  AppPublishEditViewModel.m
//  TrollApps
//
//  发布/编辑视图模型 - 单例模式，支持草稿保存
//

#import "AppPublishEditViewModel.h"
#import "config.h"
#import "AppInfoModel.h"
#import "AppDraftModel.h"
#import "NetworkClient.h"
#import <AVFoundation/AVFoundation.h>
#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用
NSString * const kAppPublishDraftKey = @"AppPublishDraft_v4";

@interface AppPublishEditViewModel ()

@end

@implementation AppPublishEditViewModel

+ (instancetype)sharedInstance {
    static AppPublishEditViewModel *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppPublishEditViewModel alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        [self resetAllData];
    }
    return self;
}

- (void)resetAllData {
    _isEditMode = NO;
    _editingAppId = nil;
    _currentVersionCode = 1;
    _draftModel = [[AppDraftModel alloc] init];
    
    _appName = @"";
    _bundleId = @"";
    _trackId = @"";
    _versionName = @"1.0.0";
    _appType = 1; // 默认IPA
    _appDescription = @"";
    _releaseNotes = @"";
    _appRmb = @"0";
    _appStatus = 0;
    
    _iconImage = nil;
    _iconData = nil;
    _existingIconURL = nil;
    
    _mainFileCloudURL = nil;
    _mainFileData = nil;
    _mainFileName = nil;
    _isCloudMode = YES;
    
    _selectedTags = [NSMutableArray array];
    _mediaItems = [NSMutableArray array];
    _iTunesAppModel = nil;
}

#pragma mark - 模式设置

- (void)setupForNewApp {
    [self resetAllData];
    self.isEditMode = NO;
    self.currentVersionCode = 1;
}

- (void)setupForEditWithAppId:(NSInteger)appId completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    [self resetAllData];
    self.isEditMode = YES;
    self.editingAppId = @(appId);
    
    // 请求应用详情数据
    NSDictionary *params = @{
        @"action": @"getAppDetail",
        @"app_id": @(appId),
        @"data": @{
            @"app_id": @(appId)
        }
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                modules:@"app" parameters:params
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult){
                NSLog(@"\n发布软件返回失败stringResult:%@",stringResult);
                
                NSError *error = [NSError errorWithDomain:@"setupForEditWithAppId" code:413 userInfo:@{NSLocalizedDescriptionKey: stringResult ?: @"加载失败"}];
                if (completion) completion(NO, error);
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if (code !=200) {
                NSLog(@"\n发布软件返回失败stringResult:%@",stringResult);
                NSError *error = [NSError errorWithDomain:@"setupForEditWithAppId" code:414 userInfo:@{NSLocalizedDescriptionKey: msg ?: @"加载失败"}];
                if (completion) completion(NO, error);
                return;
            }
            NSLog(@"\n发布软件jsonResult:%@",jsonResult);
            NSDictionary *appInfo = jsonResult[@"data"][@"appInfo"];
            NSLog(@"\n发布软件appInfo:%@",appInfo);
            if (appInfo) {
                [self parseAppInfoData:appInfo];
                if (completion) completion(YES, nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"AppPublishEditViewModel" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"应用不存在"}];
                if (completion) completion(NO, error);
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(NO, error);
        });
    }];
}

- (void)parseAppInfoData:(NSDictionary *)appInfo {
    NSLog(@"appInfo:%@",appInfo);
    AppInfoModel *model = [AppInfoModel yy_modelWithDictionary:appInfo];
    // 基本信息
    self.appName = model.app_name ?: @"";
    self.bundleId = model.bundle_id ?: @"";
    self.trackId = model.track_id ?: @"0";
    self.versionName = model.version_name ?: @"1.0.0";
    self.appType = model.app_type;
    self.appDescription = model.app_description ?: @"";
    self.releaseNotes = model.release_notes ?: @"";
    self.appRmb = [NSString stringWithFormat:@"%ld", (long)(model.app_rmb ?:0)];
    self.appStatus = model.app_status;
    self.currentVersionCode = model.current_version_code;
    
    // 图标
    NSString *iconURL = model.icon_url;
    NSLog(@"iconURL:%@",iconURL);
    if (iconURL && iconURL.length > 0) {
        self.existingIconURL = [self fullURLWithPath:iconURL];
    }
    NSLog(@"self.existingIconURL:%@",self.existingIconURL);
    // 主文件
    NSString *mainFileUrl = model.mainFileUrl;
    NSLog(@"mainFileUrl:%@",mainFileUrl);
    if (mainFileUrl && mainFileUrl.length > 10) {
        self.mainFileCloudURL = [self fullURLWithPath:mainFileUrl]?:@"";
        NSLog(@"self.mainFileCloudURL:%@",self.mainFileCloudURL);
        // 从 AppInfo 中读取 is_cloud 属性
        if (appInfo[@"is_cloud"] != nil) {
            self.isCloudMode = model.is_cloud;
        } else {
            // 如果没有 is_cloud 属性，默认是服务器文件 (非云端)
            self.isCloudMode = NO;
        }
    }
    
    // 标签
    NSArray *tags = model.tags;
    if (tags) {
        [self.selectedTags removeAllObjects];
        [self.selectedTags addObjectsFromArray:tags];
    }
    
    // 媒体文件 (截图和视频)
    [self.mediaItems removeAllObjects];
    for (NSString *fileURL in model.fileNames) {
        // 先提取文件名
        NSString *fileName = [fileURL lastPathComponent];
        NSLog(@"fileName:%@",fileName);
        // 跳过主文件和图标
        if ([fileName containsString:MAIN_File_KEY] || [fileName containsString:ICON_KEY]) {
            continue;
        }
        // 跳过视频缩略图(会在显示时单独处理)
        if ([fileName containsString:@"_thumbnail_"]) {
            continue;
        }
        
        // 判断是图片还是视频
        NSString *ext = [[fileName pathExtension] lowercaseString];
        
        NSLog(@"判断是图片还是视频ext:%@",ext);
        NSArray *videoExts = @[@"mp4", @"mov", @"m4v", @"avi", @"mkv"];
        BOOL isVideo = [videoExts containsObject:ext];
        
        // 查找对应的缩略图
        NSString *thumbnailURL = nil;
        if (isVideo) {
            // 查找缩略图文件
            NSString *baseName = [fileName stringByDeletingPathExtension];
            for (NSString *fnURL in model.fileNames) {
                NSString *fn = [fnURL lastPathComponent];
                if ([fn containsString:baseName] && [fn containsString:@"_thumbnail_"]) {
                    thumbnailURL = fnURL;
                    break;
                }
            }
        }
        NSLog(@"thumbnailURL:%@",thumbnailURL);
        MediaItemModel *item = [MediaItemModel itemWithFileName:fileName fileURL:fileURL thumbnailURL:thumbnailURL isVideo:isVideo];
        [self.mediaItems addObject:item];
    }
}

- (NSString *)fullURLWithPath:(NSString *)path {
    if ([path hasPrefix:@"http"]) {
        return path;
    }
    return [NSString stringWithFormat:@"%@/uploads/%@", localURL, path];
}

#pragma mark - 草稿管理

- (void)saveDraft {
    if (!self.hasUnsavedChanges) {
        return;
    }
    
    self.draftModel.appName = self.appName ?: @"";
    self.draftModel.bundleId = self.bundleId ?: @"";
    self.draftModel.trackId = self.trackId ?: @"";
    self.draftModel.versionName = self.versionName ?: @"1.0.0";
    self.draftModel.appType = self.appType;
    self.draftModel.appDescription = self.appDescription ?: @"";
    self.draftModel.releaseNotes = self.releaseNotes ?: @"";
    self.draftModel.appRmb = self.appRmb ?: @"0";
    self.draftModel.appStatus = self.appStatus;
    self.draftModel.selectedTags = [self.selectedTags copy];
    self.draftModel.isCloudMode = self.isCloudMode;
    self.draftModel.mainFileCloudURL = self.mainFileCloudURL;
    self.draftModel.editingAppId = self.editingAppId;
    self.draftModel.currentVersionCode = self.currentVersionCode;
    self.draftModel.saveTime = [[NSDate date] timeIntervalSince1970];
    
    NSDictionary *draft = [self.draftModel yy_modelToJSONObject];
    [[NSUserDefaults standardUserDefaults] setObject:draft forKey:kAppPublishDraftKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)loadDraft {
    NSDictionary *draft = [[NSUserDefaults standardUserDefaults] objectForKey:kAppPublishDraftKey];
    if (!draft) {
        return NO;
    }
    
    self.draftModel = [AppDraftModel yy_modelWithDictionary:draft];
    
    self.appName = self.draftModel.appName ?: @"";
    self.bundleId = self.draftModel.bundleId ?: @"";
    self.trackId = self.draftModel.trackId ?: @"";
    self.versionName = self.draftModel.versionName ?: @"1.0.0";
    self.appType = self.draftModel.appType;
    self.appDescription = self.draftModel.appDescription ?: @"";
    self.releaseNotes = self.draftModel.releaseNotes ?: @"";
    self.appRmb = self.draftModel.appRmb ?: @"0";
    self.appStatus = self.draftModel.appStatus;
    self.isCloudMode = self.draftModel.isCloudMode;
    self.mainFileCloudURL = self.draftModel.mainFileCloudURL;
    
    if (self.draftModel.editingAppId) {
        self.editingAppId = self.draftModel.editingAppId;
        self.isEditMode = YES;
    } else {
        self.isEditMode = NO;
    }
    self.currentVersionCode = self.draftModel.currentVersionCode;
    
    [self.selectedTags removeAllObjects];
    [self.selectedTags addObjectsFromArray:self.draftModel.selectedTags ?: @[]];
    
    return YES;
}

- (void)clearDraft {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAppPublishDraftKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.iconImage = nil;
    self.iconData = nil;
    self.mainFileData = nil;
    self.mainFileName = nil;
    
    NSMutableArray *toRemove = [NSMutableArray array];
    for (MediaItemModel *item in self.mediaItems) {
        if (item.source == MediaSourceNew) {
            [toRemove addObject:item];
        } else if (item.source == MediaSourceExisting) {
            item.pendingDelete = NO;
        }
    }
    [self.mediaItems removeObjectsInArray:toRemove];
}

#pragma mark - 媒体文件管理

- (void)addMediaItem:(MediaItemModel *)item {
    [self.mediaItems addObject:item];
}

- (void)removeMediaItem:(MediaItemModel *)item {
    if (item.source == MediaSourceExisting) {
        item.pendingDelete = YES;
    } else {
        [self.mediaItems removeObject:item];
    }
}

- (void)undoDeleteMediaItem:(MediaItemModel *)item {
    if (item.source == MediaSourceExisting) {
        item.pendingDelete = NO;
    }
}

- (NSArray<NSString *> *)pendingDeleteMediaFiles {
    NSMutableArray *result = [NSMutableArray array];
    for (MediaItemModel *item in self.mediaItems) {
        if (item.source == MediaSourceExisting && item.pendingDelete) {
            [result addObject:item.fileName];
        }
    }
    return result;
}

- (NSArray<MediaItemModel *> *)newMediaItems {
    NSMutableArray *result = [NSMutableArray array];
    for (MediaItemModel *item in self.mediaItems) {
        if (item.source == MediaSourceNew) {
            [result addObject:item];
        }
    }
    return result;
}

- (NSArray<MediaItemModel *> *)existingMediaItems {
    NSMutableArray *result = [NSMutableArray array];
    for (MediaItemModel *item in self.mediaItems) {
        if (item.source == MediaSourceExisting && !item.pendingDelete) {
            [result addObject:item];
        }
    }
    return result;
}

#pragma mark - 数据验证

- (BOOL)hasUnsavedChanges {
    // 检查是否有新上传的文件或图标
    if (self.iconImage || self.iconData) {
        return YES;
    }
    if (self.mainFileData) {
        return YES;
    }
    for (MediaItemModel *item in self.mediaItems) {
        if (item.source == MediaSourceNew) {
            return YES;
        }
        if (item.source == MediaSourceExisting && item.pendingDelete) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)validateDataWithError:(NSError * _Nullable *)error {
    if (self.appName.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"AppPublishEditViewModel" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"请输入应用名称"}];
        }
        return NO;
    }
    
//    if (self.bundleId.length == 0) {
//        if (error) {
//            *error = [NSError errorWithDomain:@"AppPublishEditViewModel" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"请输入Bundle ID"}];
//        }
//        return NO;
//    }
    
    // 至少需要一个图标
    if (!self.iconImage && !self.existingIconURL) {
        if (error) {
            *error = [NSError errorWithDomain:@"AppPublishEditViewModel" code:1003 userInfo:@{NSLocalizedDescriptionKey: @"请上传应用图标"}];
        }
        return NO;
    }
    
    // 检查主文件
    if (self.isCloudMode) {
        if (self.mainFileCloudURL.length == 0) {
            if (error) {
                *error = [NSError errorWithDomain:@"AppPublishEditViewModel" code:1004 userInfo:@{NSLocalizedDescriptionKey: @"请输入云端主文件URL"}];
            }
            return NO;
        }
    } else {
        // 编辑模式下，如果已有云端主文件且没有选择新的本地文件，无需重新上传
        if (!self.mainFileData) {
            if (!self.isEditMode || self.mainFileCloudURL.length == 0) {
                // 只有非编辑模式，或者编辑模式但没有云端主文件时，才要求上传
                if (error) {
                    *error = [NSError errorWithDomain:@"AppPublishEditViewModel" code:1005 userInfo:@{NSLocalizedDescriptionKey: @"请上传主文件"}];
                }
                return NO;
            }
        }
    }
    // 至少分类
    if (!self.selectedTags || self.selectedTags.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"AppPublishEditViewModel" code:1003 userInfo:@{NSLocalizedDescriptionKey: @"至少选一个分类"}];
        }
        return NO;
    }
    
    return YES;
}

- (void)showValidationError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootVC = [(UINavigationController *)rootVC topViewController];
    }
    [rootVC presentViewController:alert animated:YES completion:nil];
}

@end
