//
//  FileInstallManager.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/17.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//


#import "FileInstallManager.h"
#import "NSTask.h"
#import <AFNetworking/AFNetworking.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface FileInstallManager ()

@property (nonatomic, strong) AFURLSessionManager *sessionManager;
@property (nonatomic, strong) NSString *tempDirectory;

@end

@implementation FileInstallManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static FileInstallManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化网络会话管理器
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        // 创建临时目录
        NSString *tempDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"InstallTemp"];
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:tempDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:&error];
        }
        self.tempDirectory = tempDir;
        
        if (error) {
            NSLog(@"创建临时目录失败: %@", error.localizedDescription);
        }
    }
    return self;
}

#pragma mark - Public Methods

- (void)installFileWithURL:(NSURL *)fileURL completion:(InstallCompletionHandler)completion {
    if (!fileURL) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"FileInstallManager" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"无效的文件URL"}]);
        }
        return;
    }
    
    // 判断是本地URL还是网络URL
    if ([self isLocalURL:fileURL]) {
        // 本地文件直接处理
        [self handleLocalFileWithURL:fileURL completion:completion];
    } else {
        // 网络文件先下载
        [self downloadFileWithURL:fileURL completion:^(NSURL * _Nullable localURL, NSError * _Nullable error) {
            if (error || !localURL) {
                if (completion) {
                    completion(NO, error ?: [NSError errorWithDomain:@"FileInstallManager" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"下载文件失败"}]);
                }
                return;
            }
            
            // 下载成功后处理本地文件
            [self handleLocalFileWithURL:localURL completion:completion];
        }];
    }
}

- (void)installFileWithURLString:(NSString *)urlString completion:(InstallCompletionHandler)completion {
    if (!urlString || urlString.length == 0) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"FileInstallManager" code:1003 userInfo:@{NSLocalizedDescriptionKey: @"无效的URL字符串"}]);
        }
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"FileInstallManager" code:1004 userInfo:@{NSLocalizedDescriptionKey: @"无法解析URL"}]);
        }
        return;
    }
    
    [self installFileWithURL:url completion:completion];
}

- (void)installFileWithType:(FileType)fileType fileData:(NSData *)fileData fileName:(NSString *)fileName completion:(InstallCompletionHandler)completion {
    if (!fileData || fileData.length == 0) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"FileInstallManager" code:1005 userInfo:@{NSLocalizedDescriptionKey: @"无效的文件数据"}]);
        }
        return;
    }
    
    if (!fileName || fileName.length == 0) {
        // 生成默认文件名
        fileName = [NSString stringWithFormat:@"temp_file_%ld.%@", (long)NSDate.date.timeIntervalSince1970, [self fileExtensionForType:fileType]];
    }
    
    // 保存文件到临时目录
    NSString *filePath = [self.tempDirectory stringByAppendingPathComponent:fileName];
    NSError *error;
    [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    
    if (error) {
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    NSURL *localURL = [NSURL fileURLWithPath:filePath];
    [self handleLocalFileWithURL:localURL completion:completion];
}

- (BOOL)isLocalURL:(NSURL *)url {
    return [url.scheme isEqualToString:@"file"];
}

- (FileType)fileTypeForPath:(NSString *)filePath {
    if (!filePath || filePath.length == 0) {
        return FileTypeUnknown;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    
    // 安装包类型
    if ([extension isEqualToString:@"ipa"]) return FileTypeIPA;
    if ([extension isEqualToString:@"ipas"]) return FileTypeIPAS;
    if ([extension isEqualToString:@"deb"]) return FileTypeDEB;
    
    // 脚本/配置类型
    if ([extension isEqualToString:@"js"]) return FileTypeJS;
    if ([extension isEqualToString:@"html"]) return FileTypeHTML;
    if ([extension isEqualToString:@"json"]) return FileTypeJSON;
    if ([extension isEqualToString:@"sh"]) return FileTypeSH;
    if ([extension isEqualToString:@"plist"]) return FileTypePLIST;
    
    // 二进制类型
    if ([extension isEqualToString:@"dylib"]) return FileTypeDYLIB;
    
    // 压缩包类型
    if ([extension isEqualToString:@"zip"]) return FileTypeZIP;
    
    return FileTypeUnknown;
}

#pragma mark - Private Methods

- (void)downloadFileWithURL:(NSURL *)url completion:(void(^)(NSURL * _Nullable localURL, NSError * _Nullable error))completion {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 创建下载任务
    NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 更新下载进度
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showProgress:downloadProgress.fractionCompleted status:@"下载中..."];
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        // 确定下载文件的保存位置
        NSString *fileName = response.suggestedFilename ?: [NSString stringWithFormat:@"downloaded_file_%ld", (long)NSDate.date.timeIntervalSince1970];
        NSString *filePath = [self.tempDirectory stringByAppendingPathComponent:fileName];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (error || !filePath) {
                if (completion) {
                    completion(nil, error ?: [NSError errorWithDomain:@"FileInstallManager" code:1006 userInfo:@{NSLocalizedDescriptionKey: @"下载失败"}]);
                }
                return;
            }
            
            NSLog(@"文件下载成功: %@", filePath);
            if (completion) {
                completion(filePath, nil);
            }
        });
    }];
    
    [downloadTask resume];
}

- (void)handleLocalFileWithURL:(NSURL *)localURL completion:(InstallCompletionHandler)completion {
    if (!localURL) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"FileInstallManager" code:1007 userInfo:@{NSLocalizedDescriptionKey: @"无效的本地文件URL"}]);
        }
        return;
    }
    
    // 获取文件名和文件类型
    NSString *fileName = [localURL lastPathComponent];
    FileType fileType = [self fileTypeForPath:fileName];
    
    if (fileType == FileTypeUnknown) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"FileInstallManager" code:1008 userInfo:@{NSLocalizedDescriptionKey: @"未知的文件类型"}]);
        }
        return;
    }
    
    // 根据文件类型执行不同的安装逻辑
    [self installFileWithType:fileType fileURL:localURL fileName:fileName completion:completion];
}

- (void)installFileWithType:(FileType)fileType fileURL:(NSURL *)fileURL fileName:(NSString *)fileName completion:(InstallCompletionHandler)completion {
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"准备安装 %@...", fileName]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = NO;
        NSError *error = nil;
        
        switch (fileType) {
            case FileTypeIPA:
                success = [self installIPAFileWithURL:fileURL error:&error];
                break;
                
            case FileTypeDEB:
                success = [self installDEBFileWithURL:fileURL error:&error];
                break;
                
            case FileTypeZIP:
                success = [self unzipFileWithURL:fileURL error:&error];
                break;
                
            case FileTypePLIST:
                success = [self processPLISTFileWithURL:fileURL error:&error];
                break;
                
            default:
                error = [NSError errorWithDomain:@"FileInstallManager" code:1009 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"不支持安装 %@ 类型的文件", [self stringForFileType:fileType]]}];
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (success) {
                [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"%@ 安装成功", fileName]];
            } else {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ 安装失败: %@", fileName, error.localizedDescription]];
            }
            
            if (completion) {
                completion(success, error);
            }
        });
    });
}

- (BOOL)installIPAFileWithURL:(NSURL *)ipaURL error:(NSError **)error {
    // 检查文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:[ipaURL path]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager" code:1010 userInfo:@{NSLocalizedDescriptionKey: @"IPA文件不存在"}];
        }
        return NO;
    }
    
    // 使用itms-services协议安装IPA
    NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", [ipaURL absoluteString]]];
    
    if ([[UIApplication sharedApplication] canOpenURL:installURL]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:installURL options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:installURL];
        }
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager" code:1011 userInfo:@{NSLocalizedDescriptionKey: @"无法打开安装链接，可能是系统限制"}];
        }
        return NO;
    }
}

- (BOOL)installDEBFileWithURL:(NSURL *)debURL error:(NSError **)error {
    // 检查设备是否越狱
    BOOL isJailbroken = [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"];
    
    if (!isJailbroken) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager" code:1012 userInfo:@{NSLocalizedDescriptionKey: @"设备未越狱，无法安装DEB插件"}];
        }
        return NO;
    }
    
    // 检查文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:[debURL path]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager" code:1013 userInfo:@{NSLocalizedDescriptionKey: @"DEB文件不存在"}];
        }
        return NO;
    }
    
    // 模拟使用dpkg安装DEB包（实际需要通过SSH或其他越狱通道执行）
    // 注意：此代码仅为示例，实际越狱环境需要适当的权限和工具
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/dpkg";
    task.arguments = @[@"-i", [debURL path]];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    
    [task launch];
    [task waitUntilExit];
    
    int returnCode = [task terminationStatus];
    if (returnCode != 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager" code:1014 userInfo:@{NSLocalizedDescriptionKey: @"DEB安装失败"}];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)unzipFileWithURL:(NSURL *)zipURL error:(NSError **)error {
    // 此方法需要引入ZipArchive或SSZipArchive等库
    // 这里仅为示例，实际实现需要适当的解压缩库
    NSLog(@"解压ZIP文件: %@", zipURL);
    
    // 创建解压目录
    NSString *fileName = [[zipURL lastPathComponent] stringByDeletingPathExtension];
    NSString *destinationPath = [self.tempDirectory stringByAppendingPathComponent:fileName];
    
    NSError *unzipError;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:&unzipError]) {
        if (error) {
            *error = unzipError;
        }
        return NO;
    }
    
    // 模拟解压过程（实际需要使用解压缩库）
    // 例如使用SSZipArchive:
    // [SSZipArchive unzipFileAtPath:[zipURL path] toDestination:destinationPath error:error];
    
    return YES;
}

- (BOOL)processPLISTFileWithURL:(NSURL *)plistURL error:(NSError **)error {
    // 处理PLIST文件（读取或写入配置）
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfURL:plistURL];
    
    if (!plistDict) {
        if (error) {
            *error = [NSError errorWithDomain:@"FileInstallManager" code:1015 userInfo:@{NSLocalizedDescriptionKey: @"无法解析PLIST文件"}];
        }
        return NO;
    }
    
    NSLog(@"成功解析PLIST文件: %@", plistDict);
    return YES;
}

#pragma mark - Helper Methods

- (NSString *)stringForFileType:(FileType)fileType {
    switch (fileType) {
        case FileTypeIPA: return @"IPA应用";
        case FileTypeIPAS: return @"IPAS多应用包";
        case FileTypeDEB: return @"DEB插件";
        case FileTypeJS: return @"JS脚本";
        case FileTypeHTML: return @"HTML文件";
        case FileTypeJSON: return @"JSON数据";
        case FileTypeSH: return @"Shell脚本";
        case FileTypePLIST: return @"PLIST配置";
        case FileTypeDYLIB: return @"动态链接库";
        case FileTypeZIP: return @"ZIP压缩包";
        case FileTypeUnknown: default: return @"未知类型";
    }
}

- (NSString *)fileExtensionForType:(FileType)fileType {
    switch (fileType) {
        case FileTypeIPA: return @"ipa";
        case FileTypeIPAS: return @"ipas";
        case FileTypeDEB: return @"deb";
        case FileTypeJS: return @"js";
        case FileTypeHTML: return @"html";
        case FileTypeJSON: return @"json";
        case FileTypeSH: return @"sh";
        case FileTypePLIST: return @"plist";
        case FileTypeDYLIB: return @"dylib";
        case FileTypeZIP: return @"zip";
        case FileTypeUnknown: default: return @"unknown";
    }
}

@end
