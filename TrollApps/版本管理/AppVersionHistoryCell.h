//
//  AppVersionHistoryCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TemplateCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppVersionHistoryCell : TemplateCell

// 基本UI元素
@property (nonatomic, strong) UIButton *downloadButton ;      // 下载按钮
@property (nonatomic, strong) UILabel *versionNameLabel;      // 版本名称
@property (nonatomic, strong) UILabel *releaseDateLabel;      // 发布日期
@property (nonatomic, strong) UILabel *sizeLabel;             // 安装包大小
@property (nonatomic, strong) UILabel *releaseNotesLabel;     // 更新说明
@property (nonatomic, strong) UIView *separatorView;          // 分隔线
@property (nonatomic, strong) UIButton *mandatoryButton;        // 强制更新标签

@end

NS_ASSUME_NONNULL_END
