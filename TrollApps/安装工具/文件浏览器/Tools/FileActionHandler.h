//
//  FileActionHandler.h
//  SandboxFileManager
//
//  文件操作处理工具类
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FileModel;

#pragma mark - FileActionType

/// 文件操作类型
typedef NS_ENUM(NSInteger, FileActionType) {
    FileActionTypePlay,       ///< 播放视频/音频
    FileActionTypeShare,      ///< 分享文件
    FileActionTypeUnzip,      ///< 解压
    FileActionTypeZip,        ///< 压缩
    FileActionTypeRename,     ///< 重命名
    FileActionTypeDelete,     ///< 删除
    FileActionTypeCopyPath,   ///< 复制路径
    FileActionTypeInfo,       ///< 显示详情
    FileActionTypeOpenWith,   ///< 用其他应用打开
    FileActionTypeEditRemark, ///< 修改备注
};

#pragma mark - FileConflictOption

/// 文件冲突处理选项
typedef NS_ENUM(NSInteger, FileConflictOption) {
    FileConflictOptionCancel,    ///< 取消操作
    FileConflictOptionOverwrite, ///< 覆盖原文件
    FileConflictOptionRename     ///< 重命名文件
};

/// 文件冲突处理回调
/// @param model 当前操作的文件模型
/// @param conflictingPath 冲突的文件路径
/// @param suggestedName 建议的重命名文件名
/// @param completion 完成回调，传入用户选择的选项和新文件名（重命名时使用）
typedef void(^FileConflictHandler)(FileModel *model, NSString *conflictingPath, NSString *suggestedName, void(^completion)(FileConflictOption option, NSString * _Nullable newFileName));

#pragma mark - FileActionHandler

/// 文件操作处理单例类
/// 统一处理文件的各类操作：播放、分享、压缩、解压、重命名、删除等
@interface FileActionHandler : NSObject

/// 获取单例实例
+ (instancetype)sharedHandler;

#pragma mark - 执行操作

/// 执行文件操作
/// @param actionType 操作类型
/// @param models 文件模型数组
/// @param viewController 来源视图控制器
- (void)handleFileAction:(FileActionType)actionType
              withModels:(NSArray<FileModel *> *)models
        fromViewController:(UIViewController *)viewController;

/// 显示文件操作菜单
/// @param model 文件模型
/// @param viewController 来源视图控制器
/// @param delegate 代理
- (void)showActionSheetForModel:(FileModel *)model
            fromViewController:(UIViewController *)viewController
                      delegate:(id)delegate;

#pragma mark - 压缩解压

/// 压缩文件（直接压缩）
/// @param files 要压缩的文件数组
/// @param destinationDir 目标目录
/// @param viewController 来源视图控制器
- (void)compressFiles:(NSArray<FileModel *> *)files
         toDirectory:(NSString *)destinationDir
     fromViewController:(UIViewController *)viewController;

/// 压缩文件（弹出输入框让用户输入文件名）
/// @param files 要压缩的文件数组
/// @param destinationDir 目标目录
/// @param viewController 来源视图控制器
- (void)compressFilesWithInput:(NSArray<FileModel *> *)files
                  destinationDir:(NSString *)destinationDir
              fromViewController:(UIViewController *)viewController;

#pragma mark - 拷贝移动

/// 拷贝文件（单个，带冲突处理）
/// @param model 文件模型
/// @param destinationDir 目标目录
/// @param viewController 来源视图控制器
/// @param conflictHandler 冲突处理回调，如果为 nil 则直接覆盖
- (void)copyFile:(FileModel *)model
      toDirectory:(NSString *)destinationDir
fromViewController:(UIViewController *)viewController
    conflictHandler:(nullable FileConflictHandler)conflictHandler;

/// 移动文件（单个，带冲突处理）
/// @param model 文件模型
/// @param destinationDir 目标目录
/// @param viewController 来源视图控制器
/// @param conflictHandler 冲突处理回调，如果为 nil 则直接覆盖
- (void)moveFile:(FileModel *)model
      toDirectory:(NSString *)destinationDir
fromViewController:(UIViewController *)viewController
    conflictHandler:(nullable FileConflictHandler)conflictHandler;

/// 批量拷贝文件
/// @param models 文件模型数组
/// @param destinationDir 目标目录
/// @param viewController 来源视图控制器
/// @param conflictHandler 冲突处理回调，如果为 nil 则自动跳过已存在的文件
/// @param completion 完成回调，返回成功数量和成功操作的文件路径数组
- (void)copyFiles:(NSArray<FileModel *> *)models
      toDirectory:(NSString *)destinationDir
fromViewController:(UIViewController *)viewController
    conflictHandler:(nullable FileConflictHandler)conflictHandler
        completion:(void (^)(NSInteger successCount, NSArray<NSString *> *successFilePaths))completion;

/// 批量移动文件
/// @param models 文件模型数组
/// @param destinationDir 目标目录
/// @param viewController 来源视图控制器
/// @param conflictHandler 冲突处理回调，如果为 nil 则自动跳过已存在的文件
/// @param completion 完成回调，返回成功数量和成功操作的文件路径数组
- (void)moveFiles:(NSArray<FileModel *> *)models
      toDirectory:(NSString *)destinationDir
fromViewController:(UIViewController *)viewController
    conflictHandler:(nullable FileConflictHandler)conflictHandler
        completion:(void (^)(NSInteger successCount, NSArray<NSString *> *successFilePaths))completion;

#pragma mark - 查询

/// 获取文件支持的操作列表
/// @param model 文件模型
/// @return 支持的操作类型数组
- (NSArray<NSString *> *)supportedActionsForModel:(FileModel *)model;

/// 生成建议的重命名文件名
/// @param originalPath 原始文件路径
/// @return 建议的重命名文件名（格式：原名_1.扩展名）
- (NSString *)generateSuggestedFileNameForPath:(NSString *)originalPath;

@end
