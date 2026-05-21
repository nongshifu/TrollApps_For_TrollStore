#import "FileActionHandler.h"
#import "FileModel.h"
#import "FileNotification.h"
#import "FileListViewController.h"
#import "RemarkManager.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SSZipArchive.h"

@interface FileActionHandler () <UIDocumentInteractionControllerDelegate, SSZipArchiveDelegate>

@property (nonatomic, weak) UIViewController *currentViewController;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@end

@implementation FileActionHandler

+ (instancetype)sharedHandler {
    static FileActionHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [[FileActionHandler alloc] init];
    });
    return handler;
}

- (void)showActionSheetForModel:(FileModel *)model
            fromViewController:(UIViewController *)viewController
                      delegate:(id)delegate {
    self.currentViewController = viewController;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:model.fileName
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *supportedActions = [self supportedActionsForModel:model];

    for (NSNumber *actionNumber in supportedActions) {
        FileActionType fileActionType = (FileActionType)[actionNumber integerValue];
        NSString *title = [self titleForAction:fileActionType];
        UIImage *icon = [self iconForAction:fileActionType];

        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
            
            [self handleFileAction:fileActionType withModels:@[model] fromViewController:viewController];
        }];

        if (icon) {
            [alertAction setValue:icon forKey:@"image"];
        }

        [alert addAction:alertAction];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = viewController.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(viewController.view.bounds.size.width / 2,
                                                                    viewController.view.bounds.size.height / 2,
                                                                    0, 0);
    }

    [viewController presentViewController:alert animated:YES completion:nil];
}

- (NSArray<NSString *> *)supportedActionsForModel:(FileModel *)model {
    NSMutableArray *actions = [NSMutableArray array];

    [actions addObject:@(FileActionTypeInfo)];
    

    NSString *extension = model.filePath.pathExtension.lowercaseString;

    if (model.itemType == FileItemTypeFolder) {
        [actions addObject:@(FileActionTypeZip)];
        [actions addObject:@(FileActionTypeShare)];
        [actions addObject:@(FileActionTypeCopyPath)];
        [actions addObject:@(FileActionTypeRename)];
        [actions addObject:@(FileActionTypeDelete)];
    } else {
        if ([@[@"mp4", @"mov", @"avi", @"mkv", @"m4v", @"wmv"] containsObject:extension] ||
            [@[@"mp3", @"wav", @"aac", @"m4a", @"flac", @"ogg", @"wma"] containsObject:extension]) {
            [actions addObject:@(FileActionTypePlay)];
        }

        if ([@[@"zip", @"rar", @"7z", @"tar", @"gz", @"bz2"] containsObject:extension]) {
            [actions addObject:@(FileActionTypeUnzip)];
        }

        [actions addObject:@(FileActionTypeShare)];
        [actions addObject:@(FileActionTypeOpenWith)];
        [actions addObject:@(FileActionTypeCopyPath)];
        [actions addObject:@(FileActionTypeRename)];
        [actions addObject:@(FileActionTypeDelete)];
    }
    [actions addObject:@(FileActionTypeEditRemark)];
    return actions;
}

- (NSString *)titleForAction:(FileActionType)action {
    switch (action) {
        case FileActionTypePlay: return @"播放";
        case FileActionTypeShare: return @"分享";
        case FileActionTypeUnzip: return @"解压";
        case FileActionTypeZip: return @"压缩";
        case FileActionTypeRename: return @"重命名";
        case FileActionTypeDelete: return @"删除";
        case FileActionTypeCopyPath: return @"复制路径";
        case FileActionTypeInfo: return @"详情";
        case FileActionTypeOpenWith: return @"用其他应用打开";
        case FileActionTypeEditRemark: return @"修改备注";
            
        default: return @"未知";
    }
}

- (UIImage *)iconForAction:(FileActionType)action {
    switch (action) {
        case FileActionTypePlay: return [UIImage systemImageNamed:@"play.circle"];
        case FileActionTypeShare: return [UIImage systemImageNamed:@"square.and.arrow.up"];
        case FileActionTypeUnzip: return [UIImage systemImageNamed:@"archivebox"];
        case FileActionTypeZip: return [UIImage systemImageNamed:@"folder.badge.plus"];
        case FileActionTypeRename: return [UIImage systemImageNamed:@"pencil"];
        case FileActionTypeEditRemark: return [UIImage systemImageNamed:@"pencil"];
        case FileActionTypeDelete: return [UIImage systemImageNamed:@"trash"];
        case FileActionTypeCopyPath: return [UIImage systemImageNamed:@"doc.on.doc"];
        case FileActionTypeInfo: return [UIImage systemImageNamed:@"info.circle"];
        case FileActionTypeOpenWith: return [UIImage systemImageNamed:@"square.and.arrow.up"];
        default: return nil;
    }
}

- (void)handleFileAction:(FileActionType)actionType
              withModels:(NSArray<FileModel *> *)models
        fromViewController:(UIViewController *)viewController {
    self.currentViewController = viewController;

    switch (actionType) {
        case FileActionTypePlay:
            [self playMediaForModels:models];
            break;
        case FileActionTypeShare:
            [self shareFiles:models fromViewController:viewController];
            break;
        case FileActionTypeUnzip:
            [self unzipFiles:models fromViewController:viewController];
            break;
        case FileActionTypeZip:
            if (models.count == 1 && models.firstObject.itemType == FileItemTypeFolder) {
                [self compressFiles:@[models.firstObject] toDirectory:nil fromViewController:viewController];
            }
            break;
        case FileActionTypeRename:
            [self renameFile:models.firstObject fromViewController:viewController];
            break;
        case FileActionTypeDelete:
            [self deleteFiles:models fromViewController:viewController];
            break;
        case FileActionTypeCopyPath:
            [self copyPathForFiles:models];
            break;
        case FileActionTypeInfo:
            [self showFileInfo:models.firstObject fromViewController:viewController];
            break;
        case FileActionTypeOpenWith:
            [self openWithFiles:models fromViewController:viewController];
            break;
        case FileActionTypeEditRemark:
            [self editRemarkWithFiles:models.firstObject fromViewController:viewController];
            break;
        default:
            break;
    }
}

- (void)playMediaForModels:(NSArray<FileModel *> *)models {
    if (models.count == 0) return;

    FileModel *model = models.firstObject;
    NSURL *url = [NSURL fileURLWithPath:model.filePath];

    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    playerVC.player = [AVPlayer playerWithURL:url];

    UIViewController *topVC = [self topViewController];
    [topVC presentViewController:playerVC animated:YES completion:^{
        [playerVC.player play];
    }];
}

- (void)shareFiles:(NSArray<FileModel *> *)models fromViewController:(UIViewController *)viewController {
    if (models.count == 0) return;

    NSMutableArray *urls = [NSMutableArray array];
    for (FileModel *model in models) {
        [urls addObject:[NSURL fileURLWithPath:model.filePath]];
    }

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:urls applicationActivities:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = viewController.view;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(viewController.view.bounds.size.width / 2,
                                                                           viewController.view.bounds.size.height / 2,
                                                                           0, 0);
    }

    [viewController presentViewController:activityVC animated:YES completion:nil];
}

- (void)unzipFiles:(NSArray<FileModel *> *)models fromViewController:(UIViewController *)viewController {
    if (models.count == 0) return;

    FileModel *model = models.firstObject;
    NSString *destinationDir = [model.filePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:
                                [model.fileName stringByDeletingPathExtension]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:destinationDir withIntermediateDirectories:YES attributes:nil error:nil];

    [SSZipArchive unzipFileAtPath:model.filePath toDestination:destinationDir delegate:self];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
        [self showAlertWithTitle:@"解压成功" message:[NSString stringWithFormat:@"已解压到: %@", destinationDir.lastPathComponent] fromViewController:viewController];
    });
}

- (void)compressFiles:(NSArray<FileModel *> *)files
         toDirectory:(NSString *)destinationDir
     fromViewController:(UIViewController *)viewController {
    if (files.count == 0) return;

    NSString *basePath = [files.firstObject filePath];
    NSString *baseName = [files.firstObject fileName];
    NSString *parentDir = [basePath stringByDeletingLastPathComponent];

    if (!destinationDir) {
        NSString *zipName = [baseName stringByAppendingPathExtension:@"zip"];
        destinationDir = [parentDir stringByAppendingPathComponent:zipName];
    }

    if (![destinationDir.pathExtension isEqualToString:@"zip"]) {
        destinationDir = [destinationDir stringByAppendingPathExtension:@"zip"];
    }

    if ([destinationDir containsString:@".zip.zip"]) {
        destinationDir = [destinationDir stringByReplacingOccurrencesOfString:@".zip.zip" withString:@".zip"];
    }

    NSMutableArray *pathsToZip = [NSMutableArray array];
    for (FileModel *fileModel in files) {
        [pathsToZip addObject:fileModel.filePath];
    }

    
    [SSZipArchive createZipFileAtPath:destinationDir withFilesAtPaths:pathsToZip];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
        [self showCompressSuccessAlertWithPath:destinationDir fromViewController:viewController];
    });
}

// 显示压缩文件名输入框
- (void)compressFilesWithInput:(NSArray<FileModel *> *)files
                destinationDir:(NSString *)destinationDir
            fromViewController:(UIViewController *)viewController {
    if (files.count == 0) return;

    // 生成默认文件名：当前日期时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
    NSString *defaultFileName = [formatter stringFromDate:[NSDate date]];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"压缩文件"
                                                                   message:@"请输入压缩文件名"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultFileName;
        textField.placeholder = @"请输入压缩文件名";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];

    UIAlertAction *compressAction = [UIAlertAction actionWithTitle:@"压缩" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *fileName = alert.textFields.firstObject.text;
        if (fileName.length == 0) {
            fileName = defaultFileName;
        }

        // 确保文件名以 .zip 结尾
        if (![fileName.pathExtension isEqualToString:@"zip"]) {
            fileName = [fileName stringByAppendingPathExtension:@"zip"];
        }

        // 目标路径
        NSString *zipPath = [destinationDir stringByAppendingPathComponent:fileName];

        // 如果文件已存在，自动重命名
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:zipPath]) {
            [formatter setDateFormat:@"yyyyMMdd_HHmmss_SSS"];
            NSString *newFileName = [NSString stringWithFormat:@"%@_%@.zip", [fileName stringByDeletingPathExtension], @((NSInteger)([NSDate date].timeIntervalSince1970 * 1000))];
            zipPath = [destinationDir stringByAppendingPathComponent:newFileName];
        }

        // 执行压缩
        [self doCompressFiles:files toPath:zipPath fromViewController:viewController];
    }];

    [alert addAction:cancelAction];
    [alert addAction:compressAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}

// 执行压缩操作
- (void)doCompressFiles:(NSArray<FileModel *> *)files
                  toPath:(NSString *)zipPath
        fromViewController:(UIViewController *)viewController {
    NSMutableArray *pathsToZip = [NSMutableArray array];
    for (FileModel *fileModel in files) {
        [pathsToZip addObject:fileModel.filePath];
    }

    [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:pathsToZip];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
        [self showCompressSuccessAlertWithPath:zipPath fromViewController:viewController];
    });
}

// 显示压缩成功提示并提供查看按钮
- (void)showCompressSuccessAlertWithPath:(NSString *)zipPath fromViewController:(UIViewController *)viewController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"压缩成功"
                                                                   message:[NSString stringWithFormat:@"已压缩为: %@", zipPath.lastPathComponent]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *viewAction = [UIAlertAction actionWithTitle:@"查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 延迟导航到压缩文件所在目录，确保 alert 先 dismiss
        NSString *zipDir = [zipPath stringByDeletingLastPathComponent];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([viewController isKindOfClass:[FileListViewController class]]) {
                FileListViewController *fileListVC = (FileListViewController *)viewController;
                [fileListVC navigateToDirectory:zipDir];
            }
        });
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];

    [alert addAction:viewAction];
    [alert addAction:confirmAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)renameFile:(FileModel *)model fromViewController:(UIViewController *)viewController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = model.fileName;
        textField.placeholder = @"请输入新名称";
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newName = alert.textFields.firstObject.text;
        if (newName.length > 0 && ![newName isEqualToString:model.fileName]) {
            NSString *parentPath = [model.filePath stringByDeletingLastPathComponent];
            NSString *newPath = [parentPath stringByAppendingPathComponent:newName];

            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:model.filePath toPath:newPath error:&error];

            if (error) {
                [self showAlertWithTitle:@"重命名失败" message:error.localizedDescription fromViewController:viewController];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
            }
        }
    }]];

    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)deleteFiles:(NSArray<FileModel *> *)models fromViewController:(UIViewController *)viewController {
    NSString *message = models.count == 1 ?
        [NSString stringWithFormat:@"确定要删除 \"%@\" 吗？", models.firstObject.fileName] :
        [NSString stringWithFormat:@"确定要删除 %lu 个项目吗？", (unsigned long)models.count];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSMutableArray *pathsToDelete = [NSMutableArray array];
        for (FileModel *model in models) {
            [pathsToDelete addObject:model.filePath];
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            for (NSString *path in pathsToDelete) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
            });
        });
    }]];

    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)copyPathForFiles:(NSArray<FileModel *> *)models {
    if (models.count == 0) return;

    NSMutableString *paths = [NSMutableString string];
    for (FileModel *model in models) {
        if (paths.length > 0) {
            [paths appendString:@"\n"];
        }
        [paths appendString:model.filePath];
    }

    [UIPasteboard generalPasteboard].string = paths;

    UIViewController *topVC = [self topViewController];
    [self showAlertWithTitle:@"已复制" message:@"路径已复制到剪贴板" fromViewController:topVC];
}

- (void)showFileInfo:(FileModel *)model fromViewController:(UIViewController *)viewController {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attributes = [fm attributesOfItemAtPath:model.filePath error:nil];

    NSMutableString *info = [NSMutableString string];
    [info appendFormat:@"名称: %@\n", model.fileName];
    [info appendFormat:@"类型: %@\n", model.itemType == FileItemTypeFolder ? @"文件夹" : @"文件"];
    [info appendFormat:@"大小: %@\n", [model formattedFileSize]];

    if (attributes) {
        NSDate *creationDate = attributes[NSFileCreationDate];
        NSDate *modificationDate = attributes[NSFileModificationDate];

        if (creationDate) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterMediumStyle;
            [info appendFormat:@"创建时间: %@\n", [formatter stringFromDate:creationDate]];
            [info appendFormat:@"修改时间: %@", [formatter stringFromDate:modificationDate]];
        }
    }

    [info appendFormat:@"\n路径: %@", model.filePath];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"文件信息"
                                                                   message:info
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];

    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)openWithFiles:(NSArray<FileModel *> *)models fromViewController:(UIViewController *)viewController {
    if (models.count == 0) return;

    FileModel *model = models.firstObject;
    NSURL *url = [NSURL fileURLWithPath:model.filePath];

    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:url];
    self.documentController.delegate = self;

    [self.documentController presentOpenInMenuFromRect:viewController.view.bounds
                                                inView:viewController.view
                                              animated:YES];
}

- (void)editRemarkWithFiles:(FileModel *)model fromViewController:(UIViewController *)viewController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改备注" message:@"请输入备注" preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加输入框，默认显示当前 remark
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入备注";
        textField.text = model.remark; // 默认值
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 获取输入的备注
        UITextField *textField = alert.textFields.firstObject;
        NSString *remark = textField.text ?: @"";
        // 赋值给 model
        model.remark = remark;
        // 保存到本地
        [[RemarkManager sharedManager] saveRemark:remark forFilePath:model.filePath];
        if([viewController isKindOfClass:[FileListViewController class]]){
            FileListViewController * vc = (FileListViewController*)viewController;
            [vc.tableView reloadData];
        }
        
    }]];
    
    [viewController presentViewController:alert animated:YES completion:nil];
    
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message fromViewController:(UIViewController *)viewController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (UIViewController *)topViewController {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return [self topViewController];
}

@end
