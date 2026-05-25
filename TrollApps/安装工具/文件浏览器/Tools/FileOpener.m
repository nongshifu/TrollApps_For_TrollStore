//
//  FileOpener.m
//  SandboxFileManager
//
//  文件打开管理器实现
//

#import "FileOpener.h"
#import "FilePreviewViewController.h"
#import "PlistEditorViewController.h"
#import "FileEnum.h"

@interface FileOpener ()

@end

@implementation FileOpener

+ (instancetype)sharedOpener {
    static FileOpener *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)openFileWithModel:(FileModel *)model fromViewController:(UIViewController *)viewController {
    [self openFileWithModel:model fileList:nil currentIndex:0 currentDirPath:nil fromViewController:viewController];
}

- (void)openFileWithModel:(FileModel *)model
                fileList:(NSArray<FileModel *> *)fileList
             currentIndex:(NSInteger)currentIndex
          currentDirPath:(NSString *)currentDirPath
         fromViewController:(UIViewController *)viewController {
    
    // 如果是文件夹，不处理，由外部处理
    if (model.itemType == FileItemTypeFolder) {
        return;
    }
    
    NSString *extension = [model.filePath pathExtension].lowercaseString;
    
    // 根据文件扩展名处理不同类型
    if ([self shouldOpenWithPlistEditor:extension]) {
        [self openPlistEditorWithModel:model fromViewController:viewController];
        return;
    }
    
    // 默认使用文件预览控制器
    [self openFilePreviewWithModel:model
                           fileList:fileList
                        currentIndex:currentIndex
                     currentDirPath:currentDirPath
                  fromViewController:viewController];
}

#pragma mark - Private Methods

/**
 判断是否应该用 Plist 编辑器打开
 */
- (BOOL)shouldOpenWithPlistEditor:(NSString *)extension {
    NSArray *plistExtensions = @[@"plist", @"xml"];
    return [plistExtensions containsObject:extension];
}

/**
 打开 Plist 编辑器
 */
- (void)openPlistEditorWithModel:(FileModel *)model fromViewController:(UIViewController *)viewController {
    PlistEditorViewController *editorVC = [[PlistEditorViewController alloc] init];
    editorVC.fileModel = model;
    editorVC.filePath = model.filePath;
    [viewController.navigationController pushViewController:editorVC animated:YES];
}

/**
 打开文件预览控制器
 */
- (void)openFilePreviewWithModel:(FileModel *)model
                         fileList:(NSArray<FileModel *> *)fileList
                      currentIndex:(NSInteger)currentIndex
                   currentDirPath:(NSString *)currentDirPath
                fromViewController:(UIViewController *)viewController {
    
    FilePreviewViewController *previewVC = [[FilePreviewViewController alloc] init];
    previewVC.fileList = fileList ?: @[model];
    previewVC.currentIndex = fileList ? currentIndex : 0;
    previewVC.fromActionButton = NO;
    previewVC.currentDirPath = currentDirPath;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:previewVC];
//    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [viewController presentViewController:navController animated:YES completion:nil];
}

@end
