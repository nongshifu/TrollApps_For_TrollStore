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

#pragma mark - 查询

/// 获取文件支持的操作列表
/// @param model 文件模型
/// @return 支持的操作类型数组
- (NSArray<NSString *> *)supportedActionsForModel:(FileModel *)model;

@end
