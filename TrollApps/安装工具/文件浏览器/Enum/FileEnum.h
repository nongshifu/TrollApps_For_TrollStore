//
//  FileEnum.h
//  SandboxFileManager
//
//  文件管理器相关枚举定义
//

#import <Foundation/Foundation.h>

#ifndef FileEnum_h
#define FileEnum_h

#pragma mark - SandboxDirectoryType

/// 沙盒目录类型
typedef NS_ENUM(NSInteger, SandboxDirectoryType) {
    SandboxDirectoryTypeHome = 0,         ///< 主目录(沙盒根目录)
    SandboxDirectoryTypeDocuments,          ///< Documents目录
    SandboxDirectoryTypeLibrary,           ///< Library目录
    SandboxDirectoryTypeCaches,            ///< Caches目录
    SandboxDirectoryTypeTmp                ///< Tmp目录
};

#pragma mark - FileItemType

/// 文件项类型
typedef NS_ENUM(NSInteger, FileItemType) {
    FileItemTypeFolder = 0,  ///< 文件夹
    FileItemTypeFile         ///< 文件
};

#pragma mark - DisplayType

/// 显示类型（用于筛选）
typedef NS_ENUM(NSInteger, DisplayType) {
    DisplayTypeAll = 0,         ///< 显示全部
    DisplayTypeFolderOnly        ///< 仅显示文件夹
};

#pragma mark - CellSwipeActionType

/// 单元格滑动操作类型
typedef NS_ENUM(NSInteger, CellSwipeActionType) {
    CellSwipeActionTypeDelete = 0,    ///< 删除
    CellSwipeActionTypeRename,        ///< 重命名
    CellSwipeActionTypeFavorite       ///< 收藏/取消收藏
};

#pragma mark - BatchEditActionType

/// 批量编辑操作类型
typedef NS_ENUM(NSInteger, BatchEditActionType) {
    BatchEditActionTypeModifyExtension = 0,  ///< 批量修改扩展名
    BatchEditActionTypeDeleteByExtension     ///< 批量删除指定扩展名
};

#pragma mark - SortType

/// 排序类型
typedef NS_ENUM(NSInteger, SortType) {
    SortTypeName = 0,    ///< 按名称排序
    SortTypeDate,        ///< 按日期排序
    SortTypeSize,        ///< 按大小排序
    SortTypeType         ///< 按类型排序
};

#pragma mark - SortOrder

/// 排序顺序
typedef NS_ENUM(NSInteger, SortOrder) {
    SortOrderAscending = 0,    ///< 升序
    SortOrderDescending        ///< 降序
};

#pragma mark - CreateItemType

/// 创建项目类型
typedef NS_ENUM(NSInteger, CreateItemType) {
    CreateItemTypeFolder = 0,    ///< 文件夹
    CreateItemTypeFile           ///< 文件
};

#endif /* FileEnum_h */
