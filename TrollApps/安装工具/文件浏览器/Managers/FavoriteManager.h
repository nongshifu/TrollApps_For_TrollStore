//
//  FavoriteManager.h
//  SandboxFileManager
//
//  收藏管理器
//

#import <Foundation/Foundation.h>
#import "FileModel.h"

#pragma mark - FavoriteManager

/// 收藏管理器单例类
/// 管理文件的收藏功能，数据持久化存储到UserDefaults
@interface FavoriteManager : NSObject

/// 获取单例实例
+ (instancetype)sharedManager;

#pragma mark - 收藏操作

/// 添加收藏
/// @param model 文件模型
- (void)addFavorite:(FileModel *)model;

/// 通过路径和备注添加收藏（自动创建FileModel）
/// @param path 文件路径
/// @param remark 备注（可为空）
- (void)addFavoriteWithPath:(NSString *)path remark:(NSString *)remark;

/// 移除收藏
/// @param model 文件模型
- (void)removeFavorite:(FileModel *)model;

/// 通过路径移除收藏
/// @param path 文件路径
- (void)removeFavoriteWithPath:(NSString *)path;

/// 判断文件是否已收藏
/// @param path 文件路径
/// @return YES表示已收藏
- (BOOL)isFavorite:(NSString *)path;

/// 获取所有收藏的文件
/// @return 收藏文件模型数组
- (NSArray<FileModel *> *)getAllFavorites;

#pragma mark - 数据持久化

/// 保存收藏数据到UserDefaults
- (void)saveFavorites;

/// 从UserDefaults加载收藏数据
- (void)loadFavorites;

@end
