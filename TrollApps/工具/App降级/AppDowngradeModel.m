//
//  AppDowngradeModel.m
//  TrollApps
//
//  Created by 十三哥 on 2026/3/26.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//


#import "AppDowngradeModel.h"
#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@implementation AppDowngradeModel

+ (NSArray<AppDowngradeModel *> *)getInstalledApps {
    NSMutableArray *result = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    // 巨魔权限可直接访问的系统应用安装目录
    NSString *appRootPath = @"/var/containers/Bundle/Application";
    NSArray *appUUIDDirs = [fm contentsOfDirectoryAtPath:appRootPath error:nil];
    NSLog(@"读取appUUIDDirs 长度：%ld：%@",appUUIDDirs.count,appUUIDDirs);
    for (NSString *uuidDir in appUUIDDirs) {
        NSString *fullDir = [appRootPath stringByAppendingPathComponent:uuidDir];
        NSArray *subFiles = [fm contentsOfDirectoryAtPath:fullDir error:nil];
        NSLog(@"读取subFiles 长度：%ld：%@",subFiles.count,subFiles);
        // 查找.app包体
        for (NSString *subFile in subFiles) {
            if (![subFile hasSuffix:@".app"]) continue;
            
            NSString *appPath = [fullDir stringByAppendingPathComponent:subFile];
            NSString *infoPlistPath = [appPath stringByAppendingPathComponent:@"Info.plist"];
            NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
            NSLog(@"读取infoDict：%@",infoDict);
            if (!infoDict) continue;
            
            // 过滤系统应用
            NSString *bundleId = infoDict[@"CFBundleIdentifier"];
            if ([bundleId hasPrefix:@"com.apple"]) continue;
            NSLog(@"读取bundleId：%@",bundleId);
            // 封装应用信息
            AppDowngradeModel *model = [AppDowngradeModel new];
            model.bundleId = bundleId;
            model.appName = infoDict[@"CFBundleDisplayName"] ?: infoDict[@"CFBundleName"];
            model.currentVersion = infoDict[@"CFBundleShortVersionString"] ?: @"未知版本";
            model.appPath = appPath;
            
            // 读取应用图标
            NSString *iconName = infoDict[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconName"];
            NSLog(@"读取iconName：%@",iconName);
            if (iconName) {
                NSString *iconPath = [appPath stringByAppendingPathComponent:iconName];
                model.appIcon = [UIImage imageWithContentsOfFile:iconPath];
            }
            
            [result addObject:model];
        }
    }
    return result;
}

#pragma mark - 降级管理
// 第一步：通过bundleId获取APP的trackId
+ (void)getAppTrackIdWithBundleId:(NSString *)bundleId completion:(void(^)(NSString *trackId, NSError *error))completion {
    NSString *urlStr = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?bundleId=%@&entity=software", bundleId];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSError *jsonError;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || [result[@"resultCount"] intValue] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, jsonError ?: [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未找到该应用"}]);
            });
            return;
        }
        
        NSString *trackId = result[@"results"][0][@"trackId"];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(trackId, nil);
        });
    }];
    [task resume];
}

// 第二步：通过trackId获取历史版本列表（开源ipatool核心私有API）
+ (void)getAppHistoryVersionsWithTrackId:(NSString *)trackId completion:(void(^)(NSArray *versionList, NSError *error))completion {
    // 检查是否已登录
    if (![[AppStoreAuth sharedInstance] isLoggedIn]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"请先登录App Store"}]);
        });
        return;
    }
    
    // 苹果私有API，用于查询应用历史版本
    NSString *urlStr = [NSString stringWithFormat:@"https://uclient-api.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%@&mt=8", trackId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"iTunes/12.6.5 (Windows; Microsoft Windows 7 x64 Business Edition Build 7601) AppleWebKit/536.30.2" forHTTPHeaderField:@"User-Agent"];
    
    // 添加认证信息
    AppStoreAccount *account = [[AppStoreAuth sharedInstance] getCurrentAccount];
    if (account.storeFront) {
        [request setValue:account.storeFront forHTTPHeaderField:@"X-Apple-Store-Front"];
    }
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        // 解析历史版本列表，返回格式包含：版本号、externalVersionId、发布时间
        NSError *jsonError;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSArray *versions = result[@"platformMetadata"][@"ios"][@"historyVersions"];
        
        if (!versions) {
            // 如果第一个API失败，尝试使用第二个API
            [self getAppHistoryVersionsWithAlternativeAPI:trackId completion:completion];
            return;
        }
        
        // 格式化版本列表
        NSMutableArray *formattedVersions = [NSMutableArray array];
        for (NSDictionary *version in versions) {
            NSMutableDictionary *formattedVersion = [NSMutableDictionary dictionary];
            formattedVersion[@"version"] = version[@"version"];
            formattedVersion[@"buildId"] = version[@"externalVersionId"];
            formattedVersion[@"releaseDate"] = version[@"releaseDate"];
            [formattedVersions addObject:formattedVersion];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(formattedVersions, jsonError);
        });
    }];
    [task resume];
}

// 备用API：使用ipatool的核心API获取版本信息
+ (void)getAppHistoryVersionsWithAlternativeAPI:(NSString *)trackId completion:(void(^)(NSArray *versionList, NSError *error))completion {
    // 获取账户信息
    AppStoreAccount *account = [[AppStoreAuth sharedInstance] getCurrentAccount];
    if (!account.directoryServicesID) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"账户信息不完整"}]);
        });
        return;
    }
    
    // 生成设备GUID
    NSString *guid = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    // 构建请求URL
    NSString *podPrefix = account.pod ? [NSString stringWithFormat:@"p%@-", account.pod] : @"";
    NSString *urlStr = [NSString stringWithFormat:@"https://%@buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=%@", podPrefix, guid];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-apple-plist" forHTTPHeaderField:@"Content-Type"];
    [request setValue:account.directoryServicesID forHTTPHeaderField:@"iCloud-DSID"];
    [request setValue:account.directoryServicesID forHTTPHeaderField:@"X-Dsid"];
    
    // 构建请求体
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"creditDisplay"] = @"";
    payload[@"guid"] = guid;
    payload[@"salableAdamId"] = trackId;
    
    // 转换为plist数据
    NSError *plistError;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:payload format:NSPropertyListXMLFormat_v1_0 options:0 error:&plistError];
    if (plistError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, plistError);
        });
        return;
    }
    [request setHTTPBody:plistData];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        // 解析plist响应
        NSError *plistError;
        NSDictionary *result = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&plistError];
        if (plistError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, plistError);
            });
            return;
        }
        
        // 检查错误
        NSString *failureType = result[@"failureType"];
        if (failureType) {
            NSString *customerMessage = result[@"customerMessage"];
            NSString *errorMessage = customerMessage ?: failureType;
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:errorMessage}]);
            });
            return;
        }
        
        // 提取版本信息
        NSArray *items = result[@"items"];
        if (!items || items.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"无效的响应"}]);
            });
            return;
        }
        
        NSDictionary *item = items[0];
        NSDictionary *metadata = item[@"metadata"];
        NSArray *versionIdentifiers = metadata[@"softwareVersionExternalIdentifiers"];
        
        if (!versionIdentifiers) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"无法获取版本信息"}]);
            });
            return;
        }
        
        // 格式化版本列表
        NSMutableArray *formattedVersions = [NSMutableArray array];
        for (id versionId in versionIdentifiers) {
            NSMutableDictionary *versionInfo = [NSMutableDictionary dictionary];
            versionInfo[@"buildId"] = [versionId stringValue];
            versionInfo[@"version"] = [versionId stringValue]; // 使用版本ID作为版本号
            [formattedVersions addObject:versionInfo];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(formattedVersions, nil);
        });
    }];
    [task resume];
}

// 搜索应用
+ (void)searchAppsWithTerm:(NSString *)term completion:(void(^)(NSArray *apps, NSError *error))completion {
    // 检查是否已登录
    if (![[AppStoreAuth sharedInstance] isLoggedIn]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"请先登录App Store"}]);
        });
        return;
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"https://itunes.apple.com/search?term=%@&entity=software&limit=20", [self urlEncode:term]];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // 添加认证信息
    AppStoreAccount *account = [[AppStoreAuth sharedInstance] getCurrentAccount];
    if (account.storeFront) {
        [request setValue:account.storeFront forHTTPHeaderField:@"X-Apple-Store-Front"];
    }
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSError *jsonError;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || [result[@"resultCount"] intValue] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, jsonError ?: [NSError errorWithDomain:@"AppDowngrade" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未找到相关应用"}]);
            });
            return;
        }
        
        NSArray *results = result[@"results"];
        NSMutableArray *apps = [NSMutableArray array];
        
        for (NSDictionary *appInfo in results) {
            NSMutableDictionary *app = [NSMutableDictionary dictionary];
            app[@"trackId"] = appInfo[@"trackId"];
            app[@"bundleId"] = appInfo[@"bundleId"];
            app[@"appName"] = appInfo[@"trackName"];
            app[@"version"] = appInfo[@"version"];
            app[@"artistName"] = appInfo[@"artistName"];
            app[@"iconUrl"] = appInfo[@"artworkUrl512"];
            [apps addObject:app];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(apps, nil);
        });
    }];
    [task resume];
}

+ (NSString *)urlEncode:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
