//
//  SandboxFileManager.m
//  SandboxFileManager
//
//  沙盒文件管理器 - 统一入口实现
//
//

#import "SandboxFileManager.h"
#import "RootViewController.h"
#import "FileListViewController.h"
#import "FileModel.h"

@interface SandboxFileManager ()
@property (nonatomic, copy) void(^filePickerCompletion)(NSArray<FileModel *> * _Nullable);
@end

@implementation SandboxFileManager

+ (instancetype)sharedManager {
    static SandboxFileManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

#pragma mark - 创建方法

+ (UIViewController *)fullFileManager {
    return [RootViewController rootController];
}

+ (UIViewController *)fileBrowserWithPath:(nullable NSString *)path {
    FileListViewController *fileListVC = nil;
    if (path) {
        fileListVC = [[FileListViewController alloc] initWithFullPath:path];
    } else {
        fileListVC = [[FileListViewController alloc] init];
    }
    
    // 创建导航控制器包裹
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fileListVC];
    navController.navigationBar.prefersLargeTitles = NO;
    
    return navController;
}

+ (UIViewController *)filePickerWithInitialPath:(nullable NSString *)path
                           allowsMultipleSelection:(BOOL)allowsMultiple
                                       completion:(void(^)(NSArray<FileModel *> * _Nullable selectedFiles))completion {
    SandboxFileManager *manager = [SandboxFileManager sharedManager];
    manager.filePickerCompletion = completion;
    
    FileListViewController *fileListVC = nil;
    if (path) {
        fileListVC = [[FileListViewController alloc] initWithFullPath:path];
    } else {
        fileListVC = [[FileListViewController alloc] init];
    }
    
    fileListVC.isFilePickerMode = YES;
    fileListVC.allowsMultipleSelection = allowsMultiple;
    fileListVC.delegate = (id)manager;
    
    // 添加取消按钮
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:manager
                                                                                    action:@selector(filePickerCancel)];
    fileListVC.navigationItem.leftBarButtonItem = cancelButton;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fileListVC];
    navController.navigationBar.prefersLargeTitles = NO;
    
    return navController;
}

#pragma mark - Present 方法

+ (void)presentFullFileManagerFrom:(UIViewController *)fromVC {
    UIViewController *fileManager = [self fullFileManager];
    [fromVC presentViewController:fileManager animated:YES completion:nil];
}

+ (void)presentFileBrowserFrom:(UIViewController *)fromVC path:(nullable NSString *)path {
    UIViewController *fileBrowser = [self fileBrowserWithPath:path];
    [fromVC presentViewController:fileBrowser animated:YES completion:nil];
}

+ (void)presentFilePickerFrom:(UIViewController *)fromVC
                    initialPath:(nullable NSString *)path
           allowsMultipleSelection:(BOOL)allowsMultiple
                     completion:(void(^)(NSArray<FileModel *> * _Nullable selectedFiles))completion {
    UIViewController *filePicker = [self filePickerWithInitialPath:path
                                               allowsMultipleSelection:allowsMultiple
                                                           completion:completion];
    [fromVC presentViewController:filePicker animated:YES completion:nil];
}

#pragma mark - 文件选择器回调

- (void)filePickerCancel {
    if (self.filePickerCompletion) {
        self.filePickerCompletion(nil);
    }
}

#pragma mark - FileListViewControllerDelegate (适配)

- (void)fileManagerDidCloseWithSelectedFiles:(NSArray<FileModel *> *)selectedFiles
                              currentDirPath:(NSString *)currentDirPath
                                  controller:(UIViewController *)controller {
    if (self.filePickerCompletion) {
        self.filePickerCompletion(selectedFiles);
    }
    
    if ([self.delegate respondsToSelector:@selector(fileManager:didSelectFiles:)]) {
        [self.delegate fileManager:self didSelectFiles:selectedFiles];
    }
    
    if ([self.delegate respondsToSelector:@selector(fileManagerDidClose:)]) {
        [self.delegate fileManagerDidClose:self];
    }
}

@end
