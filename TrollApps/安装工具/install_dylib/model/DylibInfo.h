//
//  DylibInfo.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface DylibInfo : NSObject <YYModel>
@property (nonatomic, copy) NSString *name;        // 动态库名称（如 libtest.dylib）
@property (nonatomic, copy) NSString *filePath;    // 本地存储路径
@property (nonatomic, strong) NSDate *downloadTime;// 下载/添加时间
@property (nonatomic, assign) BOOL isSelected;     // 是否被选中（用于注入时标记）
@end

NS_ASSUME_NONNULL_END
