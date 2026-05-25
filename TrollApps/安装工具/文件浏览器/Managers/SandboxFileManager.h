//
//  SandboxFileManager.h
//  SandboxFileManager
//
//  沙盒文件管理器 - 统一入口
//  提供多种使用方式
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SandboxFileManagerStyle) {
    SandboxFileManagerStyleFull,           // 完整模式（带底部导航）
    SandboxFileManagerStyleFileBrowserOnly,// 仅文件浏览器
    SandboxFileManagerStyleFilePicker      // 文件选择器（选择文件后返回）
};

@class SandboxFileManager;
@class FileModel;

@protocol SandboxFileManagerDelegate <NSObject>
@optional
- (void)fileManager:(SandboxFileManager *)manager didSelectFiles:(NSArray<FileModel *> *)files;
- (void)fileManagerDidClose:(SandboxFileManager *)manager;
@end

@interface SandboxFileManager : NSObject

@property (nonatomic, weak) id<SandboxFileManagerDelegate> delegate;
@property (nonatomic, assign) SandboxFileManagerStyle style;
@property (nonatomic, copy, nullable) NSString *initialPath;
@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) BOOL showsBottomToolbar; // 是否显示底部工具栏

/// 获取单例
+ (instancetype)sharedManager;

/// 创建完整文件管理器（带底部导航）
+ (UIViewController *)fullFileManager;

/// 创建文件浏览器（仅文件列表，可自定义底部工具栏）
+ (UIViewController *)fileBrowserWithPath:(nullable NSString *)path;

/// 创建文件选择器
+ (UIViewController *)filePickerWithInitialPath:(nullable NSString *)path
                           allowsMultipleSelection:(BOOL)allowsMultiple
                                       completion:(void(^)(NSArray<FileModel *> * _Nullable selectedFiles))completion;

/// 以 present 方式显示完整文件管理器
+ (void)presentFullFileManagerFrom:(UIViewController *)fromVC;

/// 以 present 方式显示文件浏览器
+ (void)presentFileBrowserFrom:(UIViewController *)fromVC path:(nullable NSString *)path;

/// 以 present 方式显示文件选择器
+ (void)presentFilePickerFrom:(UIViewController *)fromVC
                    initialPath:(nullable NSString *)path
           allowsMultipleSelection:(BOOL)allowsMultiple
                     completion:(void(^)(NSArray<FileModel *> * _Nullable selectedFiles))completion;

@end

NS_ASSUME_NONNULL_END
