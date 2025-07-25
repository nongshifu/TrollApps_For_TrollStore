//
//  AppVersionHistoryModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListKit.h>
#import "YYModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppVersionHistoryModel : NSObject<YYModel, IGListDiffable>

/// 自增主键ID（数据库字段：app_id）
@property (nonatomic, assign) NSUInteger app_id;

/// 应用唯一标识（如com.example.app，数据库字段：bundle_id）
@property (nonatomic, copy) NSString *bundle_id;

/// 应用名称（数据库字段：app_name）
@property (nonatomic, copy) NSString *app_name;

/// 版本号（内部标识，如1001，数据库字段：version_code）
@property (nonatomic, assign) NSInteger version_code;

/// 版本名称（显示给用户，如v1.0.1，数据库字段：version_name）
@property (nonatomic, copy) NSString *version_name;

/// 构建号（区分同一版本的不同构建，数据库字段：build_number）
@property (nonatomic, assign) NSInteger build_number;

/// 更新说明/变更日志（数据库字段：release_notes）
@property (nonatomic, copy) NSString *release_notes;

/// 发布时间（数据库字段：release_date）
@property (nonatomic, copy) NSString *release_date;

/// 支持的最低操作系统版本（数据库字段：min_supported_os）
@property (nonatomic, copy) NSString *min_supported_os;

/// 支持的最高操作系统版本（数据库字段：max_supported_os）
@property (nonatomic, copy) NSString *max_supported_os;

/// 下载链接（数据库字段：download_url）
@property (nonatomic, copy) NSString *download_url;

/// 安装包大小（字节，数据库字段：file_size）
@property (nonatomic, assign) long long file_size;

/// 安装包MD5校验值（数据库字段：md5_checksum）
@property (nonatomic, copy) NSString *md5_checksum;

/// 是否强制更新（0=否，1=是，数据库字段：is_mandatory）
@property (nonatomic, assign) BOOL is_mandatory;

/// 状态（0=草稿，1=已发布，2=已撤回，数据库字段：status）
@property (nonatomic, assign) NSInteger status;

/// 创建人（数据库字段：created_by）
@property (nonatomic, copy) NSString *created_by;

/// 创建时间（数据库字段：created_at）
@property (nonatomic, copy) NSString *created_at;

/// 最后更新时间（数据库字段：updated_at）
@property (nonatomic, copy) NSString *updated_at;

@end

NS_ASSUME_NONNULL_END
