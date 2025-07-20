//
//  loadData.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "loadData.h"
#include <sys/sysctl.h>
#include <dlfcn.h>

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
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
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
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
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

/// 加载本地缓存的套餐数据
- (void)loadLocalTags {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"tags"];
    if (data) {
        NSArray *dictArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (dictArray) {
            self.tags= [NSMutableArray arrayWithArray:dictArray];
        }
    }else{
        self.tags = [NSMutableArray arrayWithArray:@[@"巨魔IPA", @"游戏辅助", @"多开软件", @"定位", @"脚本",
                                                                          @"有根越狱插件", @"无根插件", @"影音", @"工具",
                                                                          @"系统增强", @"其他"]];
    }
}

/// 从远程加载套餐数据
- (void)loadTagsFromRemote {
    // 格式化日期为时间戳或ISO格式
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSString *remoteDataURL = [NSString stringWithFormat:@"%@/tags.json?time=%@",localURL,timestamp];
    
    [SVProgressHUD showWithStatus:@"加载系统分类中..."];
    
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
            [SVProgressHUD dismiss];
            
            if (jsonResult && [jsonResult isKindOfClass:[NSArray class]]) {
                NSArray *array = (NSArray *)jsonResult;
                self.tags= [NSMutableArray arrayWithArray:array];
                if(self.tags.count>0){
                    // 缓存到本地
                    NSData *cacheData = [NSJSONSerialization dataWithJSONObject:self.tags options:0 error:nil];
                    if (cacheData) {
                        [[NSUserDefaults standardUserDefaults] setObject:cacheData forKey:@"tags"];
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
    
    [SVProgressHUD showWithStatus:@"加载套餐中..."];
    
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
@end
