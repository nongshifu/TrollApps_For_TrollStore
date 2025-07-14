//
//  AppSearchCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/4.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>
#import "config.h"
#import "ITunesAppModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface AppSearchCell : UITableViewCell
// 图标
@property (nonatomic, strong) UIImageView *iconView;
/// 应用名称
@property (nonatomic, strong) UILabel *nameLabel;
/// 开发者
@property (nonatomic, strong) UILabel *developerLabel;
/// 评分星星容器
@property (nonatomic, strong) UIView *ratingContainer;
/// 评分标签
@property (nonatomic, strong) UILabel *ratingLabel;
/// 分类标签
@property (nonatomic, strong) UILabel *categoryLabel;
/// 价格标签（突出显示）
@property (nonatomic, strong) UILabel *priceLabel;
/// 简介（多行）
@property (nonatomic, strong) UILabel *summaryLabel;
//安装
@property (nonatomic, strong) UIButton *installButton;

@property (nonatomic, strong) ITunesAppModel *model;

/// 配置 cell 数据
- (void)configureWithModel:(ITunesAppModel *)model;

@end

NS_ASSUME_NONNULL_END
