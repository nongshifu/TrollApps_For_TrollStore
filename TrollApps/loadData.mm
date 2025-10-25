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
        [self fetchUserInfoFromServerWithUDID:udid];
    } else {
        [self fetchUserInfoFromServerWithIDFV:[self getIDFV]];
    }
}

- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid {
    
    NSDictionary *dic = @{
        @"action":@"getUserInfo",
        @"udid":udid,
        @"type":@"udid"
    };
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user/user/user_api.php",localURL]
                                             parameters:dic
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"请求udid用户数据:%@",stringResult);
            if (jsonResult &&
                [jsonResult[@"status"] isEqualToString:@"success"]) {
                self.userModel = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
                
            }
        });
    } failure:^(NSError *error) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        [self fetchUserInfoFromServerWithIDFV:[self getIDFV]];
    }];
}

- (void)fetchUserInfoFromServerWithIDFV:(NSString *)idfv {
    
    NSDictionary *dic = @{
        @"action":@"getUserInfo",
        @"udid":idfv,
        @"type":@"idfv"
    };
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user/user_api.php",localURL]
                                             parameters:dic
                                                   udid:idfv progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"请求idfv用户数据:%@",stringResult);
            if(!jsonResult){
               
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            
            if (code == 200) {
                
                self.userModel = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
                NSLog(@"请求idfv用户数据:%@",self.userModel);
                
            }
        });
    } failure:^(NSError *error) {
        NSLog(@"从服务器获取IDFV 读取资料失败：%@",error);
        
        
    }];
}

/// 获取本地存储的UDID
- (NSString *)getUDID {
    // 优先从本地存储获取（通过描述文件获取的UDID）
    NSUUID *vendorID = [UIDevice currentDevice].identifierForVendor;
    NSString *savedUDID = [[NSUserDefaults standardUserDefaults] stringForKey:[vendorID UUIDString]];
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
    // 应用唯一标识（bundle_id，如"com.example.TrollApps"）
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    // 当前应用版本号（current_version_code，对应Info.plist的CFBundleVersion）
    NSString *localVersionCodeStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSInteger currentVersionCode = [localVersionCodeStr integerValue];
    
    // 2. 校验必填参数
    if (!bundleId || bundleId.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"获取应用标识失败"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    if (currentVersionCode <= 0) {
        [SVProgressHUD showErrorWithStatus:@"获取本地版本号失败"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // 3. 构建请求参数（包含后端要求的所有必填字段）
    NSDictionary *params = @{
        @"udid": udid ?: @"",
        @"action": @"getVersionUpdateInfo",
        @"bundle_id": bundleId, // 后端必填：应用唯一标识
        @"current_version_code": @(currentVersionCode) // 后端必填：当前版本号
    };
    
    // 4. 接口地址
    NSString *url = [NSString stringWithFormat:@"%@/admin/app_version_api.php", localURL];
    
    // 5. 发送网络请求
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                            urlString:url
                                            parameters:params
                                                udid:udid
                                              progress:^(NSProgress *progress) {
        // 进度回调（可选，此处无需处理）
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult){
                NSLog(@"检查版本返回错误:%@",stringResult);
                return;
            }
            NSLog(@"检查版本返回:%@",jsonResult);
            // 6. 解析接口返回数据
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            
            if (code ==200) {
                // 成功：解析版本信息
                NSDictionary *data = jsonResult[@"data"];
                NSLog(@"need_update:%@",data[@"need_update"]);
                BOOL needUpdate = [data[@"need_update"] boolValue];
                
                
                // 可选：显示更新提示（如果需要）
                if (needUpdate) {
                    AppVersionHistoryViewController *vc = [AppVersionHistoryViewController new];
                    [[UIView getTopViewController] presentPanModal:vc];
                }
            }else{
                [SVProgressHUD showInfoWithStatus:msg];
                [SVProgressHUD dismissWithDelay:10];
            }
        });
    } failure:^(NSError *error) {
        
    }];
}

@end
