//
//  DownloadRecordModel.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/9.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IGListDiffable.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadRecordModel : NSObject<IGListDiffable, YYModel>

/// 主键ID（与数据库字段recordId完全一致，避免OC关键字冲突）
@property (nonatomic, assign) NSInteger recordId;
/// 应用ID（与数据库字段appId完全一致）
@property (nonatomic, assign) NSInteger appId;
/// 应用名称
@property (nonatomic, copy) NSString *appName;
/// 下载用户UDID（与数据库字段userUdid完全一致）
@property (nonatomic, copy) NSString *userUdid;
/// 下载地址（与数据库字段downloadUrl完全一致）
@property (nonatomic, strong) NSURL *downloadUrl;
/// 下载时间（与数据库字段downloadTime完全一致）
@property (nonatomic, copy) NSString *downloadTime;
/// 扣除的下载点数（与数据库字段downloadPoints完全一致）
@property (nonatomic, assign) NSInteger downloadPoints;
/// 下载状态：0=成功, 1=失败, 2=取消（与数据库字段status完全一致）
@property (nonatomic, assign) NSInteger status;
/// 下载IP地址（与数据库字段ipAddress完全一致）
@property (nonatomic, copy, nullable) NSString *ipAddress;
/// 设备信息（与数据库字段deviceInfo完全一致）
@property (nonatomic, copy, nullable) NSString *deviceInfo;
/// 应用版本号（与数据库字段versionName完全一致）
@property (nonatomic, copy, nullable) NSString *versionName;
/// 创建时间（与数据库字段createdAt完全一致）
@property (nonatomic, copy) NSString *createdAt;
/// 更新时间（与数据库字段updatedAt完全一致）
@property (nonatomic, copy) NSString *updatedAt;

@end

NS_ASSUME_NONNULL_END
