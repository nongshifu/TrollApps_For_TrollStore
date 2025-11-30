//
//  loadData.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//

#import "loadData.h"
#include <sys/sysctl.h>
#include <dlfcn.h>
#import "AppVersionHistoryViewController.h"
#import "AppVersionHistoryModel.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@implementation loadData

+ (instancetype)sharedInstance {
    static loadData *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        // 在这里进行初始化设置（如果需要的话）
        
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadUserInfo];
        [self loadLocalTags];
        [self loadTagsFromRemote];
        [self loadVIPPackagesFromRemote];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getVersionUpdateInfo];
        });
    }
    return self;
}

#pragma mark - 用户数据加载与处理
- (void)loadUserInfo {
    NSString *udid = [self getUDID];
    if (udid.length > 0) {
        if(self.userModel.udid.length>5){
            [KeychainTool saveString:self.userModel.udid forKey:TROLLAPPS_SAVE_UDID_KEY];
        }
        [self fetchUserInfoFromServerWithUDID:udid];
    } else {
        [self fetchUserInfoFromServerWithIDFV:[self getIDFV]];
    }
}


- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid {
    [UserModel getUserInfoWithUdid:udid success:^(UserModel * _Nonnull userModel) {
        self.userModel = userModel;
        [self refreshUserInfoCache:userModel];
    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        [self fetchUserInfoFromServerWithIDFV:[self getIDFV]];
    }];
    
}



- (void)fetchUserInfoFromServerWithIDFV:(NSString *)idfv {
    [UserModel getUserInfoWithIDFV:[self getIDFV] success:^(UserModel * _Nonnull userModel) {
        self.userModel = userModel;
        [self refreshUserInfoCache:userModel];
        if(self.userModel.udid.length>5){
            [KeychainTool saveString:self.userModel.udid forKey:TROLLAPPS_SAVE_UDID_KEY];
        }
        
    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        
    }];
    
}
//刷新融云
- (void)refreshUserInfoCache:(UserModel *)userModel{
    NSString *avaurl = userModel.avatar;
    if(![avaurl containsString:@"http"]){
        avaurl = [NSString stringWithFormat:@"%@/%@",localURL,userModel.avatar];
    }
    NSLog(@"刷新融云 读取用户信息avaurl：%@",avaurl);
    RCUserInfo *userInfo = [[RCUserInfo alloc] initWithUserId:userModel.udid name:userModel.nickname portrait:avaurl];
    [[RCIM sharedRCIM] refreshUserInfoCache:userInfo withUserId:userModel.udid];
    
}
/// 获取本地存储的UDID
- (NSString *)getUDID {
    // 优先从本地存储获取（通过描述文件获取的UDID）
   
    NSString *savedUDID = [KeychainTool readStringForKey:TROLLAPPS_SAVE_UDID_KEY];
    NSLog(@"优先从本地存储获取savedUDID:%@",savedUDID);
    if (savedUDID.length > 0) {
        return savedUDID;
    }
    NSLog(@"否则尝试通过系统接口获取（可能失败，仅作为备用）savedUDID:%@",savedUDID);
    // 否则尝试通过系统接口获取（可能失败，仅作为备用）
    static CFStringRef (*$MGCopyAnswer)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    if (!gestalt) {
        NSLog(@"无法加载libMobileGestalt.dylib");
        return nil;
    }
    
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
    if (!$MGCopyAnswer) {
        NSLog(@"找不到MGCopyAnswer函数");
        dlclose(gestalt);
        return nil;
    }
    
    CFStringRef udidRef = $MGCopyAnswer(CFSTR("UniqueDeviceID"));
    NSString *udid = (__bridge_transfer NSString *)udidRef;
    NSLog(@"读取的UDID:%@",udid);
    dlclose(gestalt);
    return udid;
}

/// 获取本机IDFV
- (NSString *)getIDFV {
    return [KeychainTool readAndSaveIDFV];
}

#pragma mark - 分类标签处理

/// 加载本地缓存的tag数据
- (void)loadLocalTags {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:SAVE_SERVER_TAGS_KEY];
    if (data) {
        NSArray *dictArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (dictArray) {
            self.tags= [NSMutableArray arrayWithArray:dictArray];
        }
    }else{
        self.tags = [NSMutableArray arrayWithArray:@[@"最新",@"最火",@"推荐",@"巨魔IPA", @"游戏辅助", @"多开软件", @"Dylib", @"定位", @"脚本",
                                                                          @"有根越狱插件", @"无根插件", @"影音", @"工具",
                                                                          @"系统增强", @"其他"]];
        [[NSUserDefaults standardUserDefaults] setObject:self.tags forKey:SAVE_LOCAL_TAGS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
   
}

/// 从远程加载tag数据
- (void)loadTagsFromRemote {
    // 格式化日期为时间戳或ISO格式
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSString *remoteDataURL = [NSString stringWithFormat:@"%@/tags.json?time=%@",localURL,timestamp];
    
    
    NSDictionary *dictionary = @{
        @"action":@"getTags"
    };
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodGET
                                              urlString:remoteDataURL
                                             parameters:dictionary
                                                   udid:[self getIDFV]
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"jsonResult:%@",jsonResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            if (jsonResult && [jsonResult isKindOfClass:[NSArray class]]) {
                NSArray *array = (NSArray *)jsonResult;
                self.tags= [NSMutableArray arrayWithArray:array];
                if(self.tags.count>0){
                    // 缓存到本地
                    NSData *cacheData = [NSJSONSerialization dataWithJSONObject:self.tags options:0 error:nil];
                    if (cacheData) {
                        [[NSUserDefaults standardUserDefaults] setObject:cacheData forKey:SAVE_SERVER_TAGS_KEY];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
                
                
            }
        });
    } failure:^(NSError *error) {
        
    }];
}


/// 从远程加载套餐数据
- (void)loadVIPPackagesFromRemote {
    // 格式化日期为时间戳或ISO格式
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSString *remoteDataURL = [NSString stringWithFormat:@"%@/vip.json?time=%@",localURL,timestamp];
    
    
    NSDictionary *dictionary = @{
        @"action":@"loadVIPPackages"
    };
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodGET
                                              urlString:remoteDataURL
                                             parameters:dictionary
                                                   udid:[self getIDFV]
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
           
            
            if (jsonResult &&
                [jsonResult[@"status"] isEqualToString:@"success"] &&
                [jsonResult[@"data"] isKindOfClass:[NSArray class]]) {
                
                NSArray *packagesArray = jsonResult[@"data"];
               
                // 缓存到本地
                NSData *cacheData = [NSJSONSerialization dataWithJSONObject:packagesArray options:0 error:nil];
                if (cacheData) {
                    [[NSUserDefaults standardUserDefaults] setObject:cacheData forKey:@"VIPPackagesCache"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
        });
    } failure:^(NSError *error) {
       
    }];
}


- (void)getVersionUpdateInfo {
    
    // 设备UDID/IDFV
    NSString *udid = [self getUDID] ?: [self getIDFV];
    // 应用唯一标识（bundle_id）
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    // --------------------------
    // 关键修改1：同时获取两个版本号
    // --------------------------
    // 1. 完整版本号（CFBundleVersion，如 123，对应后端 version_code）
    NSString *localVersionCodeStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSInteger currentVersionCode = [localVersionCodeStr integerValue];
    
    // 2. 短版本号（CFBundleShortVersionString，如 1.2.3，对应后端 short_version）
    NSString *localShortVersionStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (!localShortVersionStr || localShortVersionStr.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"获取本地短版本号失败"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // --------------------------
    // 关键修改2：校验短版本号（可选，确保参数有效）
    // --------------------------
    if (!bundleId || bundleId.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"获取应用标识失败"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    if (currentVersionCode <= 0) {
        [SVProgressHUD showErrorWithStatus:@"获取本地完整版本号失败"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // --------------------------
    // 关键修改3：请求参数中添加短版本号
    // --------------------------
    NSDictionary *params = @{
        @"udid": udid ?: @"",
        @"action": @"getVersionUpdateInfo",
        @"bundle_id": bundleId,
        @"current_version_code": @(currentVersionCode), // 完整版本号（数字）
        @"version_name": localShortVersionStr  // 短版本号（字符串，如 @"1.2.3"）
    };
    NSLog(@"请求查询版本:%@",params);
    
    // 接口地址（不变）
    NSString *url = [NSString stringWithFormat:@"%@/admin/app_version_api.php", localURL];
    
    // 发送网络请求（不变，仅参数新增）
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                            urlString:url
                                            parameters:params
                                                udid:udid
                                              progress:^(NSProgress *progress) {
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult){
                NSLog(@"检查版本返回错误:%@",stringResult);
                return;
            }
            NSLog(@"检查版本返回:%@",jsonResult);
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            
            if (code == 200) {
                NSDictionary *data = jsonResult[@"data"];
                NSLog(@"成功：解析版本信息:%@",data);
                AppVersionHistoryModel *appVersionHistoryModel = [AppVersionHistoryModel yy_modelWithDictionary:data];
                [self updateLatestAppVersionUI:appVersionHistoryModel];
            }else{
                [SVProgressHUD showInfoWithStatus:msg];
                [SVProgressHUD dismissWithDelay:10];
            }
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"检查更新失败"];
        [SVProgressHUD dismissWithDelay:2];
    }];
}


- (void)updateLatestAppVersionUI:(AppVersionHistoryModel*)appVersionHistoryModel {
    // 1. 读取服务端版本信息（确保非空，避免崩溃）
    NSInteger latestVersionCode = appVersionHistoryModel.version_code; // 服务器版本号（整数）
    NSString *latestVersionName = appVersionHistoryModel.version_name ?: @""; // 服务器版本名称（如"10.0.5"）
    NSLog(@"服务器版本 - code:%ld, name:%@", latestVersionCode, latestVersionName);
    
    // 2. 读取本地版本信息（从Info.plist，确保非空处理）
    NSString *localVersionCodeStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"0";
    NSInteger localVersionCode = [localVersionCodeStr integerValue]; // 本地版本号（整数）
    NSString *localVersionName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @""; // 本地版本名称（如"10.0.6"）
    NSLog(@"本地版本 - code:%ld, name:%@", localVersionCode, localVersionName);
    
    // 3. 版本号判断：服务器版本号 > 本地版本号 → 需要更新
    BOOL isCodeNeedUpdate = (latestVersionCode > localVersionCode);
    
    // 4. 版本名称判断：服务器版本名称 > 本地版本名称 → 需要更新（用语义化比较）
    BOOL isNameNeedUpdate = NO;
    if (latestVersionName.length > 0 && localVersionName.length > 0) {
        // 调用工具方法：比较服务器版本名和本地版本名
        NSComparisonResult result = [self compareSemanticVersion:latestVersionName withVersion2:localVersionName];
        isNameNeedUpdate = (result == NSOrderedDescending); // 服务器版本名 > 本地 → 需要更新
    }
    
    // 5. 最终需要更新的条件：版本号 或 版本名称 满足更新（两者任一满足即可）
    BOOL needUpdate = isCodeNeedUpdate || isNameNeedUpdate;
    
    // 6. 更新按钮UI
    if (needUpdate) {
        NSLog(@"发现新版：服务器版本高于本地");
        AppVersionHistoryViewController *vc = [AppVersionHistoryViewController new];
        [[UIView getTopViewController] presentPanModal:vc];
    } else {
        NSLog(@"无需更新：本地版本已是最新（或高于服务器）");
        
    }
}
- (NSComparisonResult)compareSemanticVersion:(NSString *)version1 withVersion2:(NSString *)version2 {
    // 分割版本号为数组（如 "10.0.6" → @[@10, @0, @6]）
    NSArray *parts1 = [version1 componentsSeparatedByString:@"."];
    NSArray *parts2 = [version2 componentsSeparatedByString:@"."];
    
    // 取最长数组长度，补0对齐（如 "10.0" 和 "10.0.1" → 补为 @[@10,@0,@0] 和 @[@10,@0,@1]）
    NSUInteger maxCount = MAX(parts1.count, parts2.count);
    
    for (NSUInteger i = 0; i < maxCount; i++) {
        NSInteger num1 = (i < parts1.count) ? [parts1[i] integerValue] : 0;
        NSInteger num2 = (i < parts2.count) ? [parts2[i] integerValue] : 0;
        
        if (num1 > num2) {
            return NSOrderedDescending; // version1 > version2
        } else if (num1 < num2) {
            return NSOrderedAscending;  // version1 < version2
        }
    }
    return NSOrderedSame; // 版本相等
}


@end
