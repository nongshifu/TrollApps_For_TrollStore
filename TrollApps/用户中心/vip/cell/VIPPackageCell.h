//
//  VIPPackageCell.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/3.
//

#import <UIKit/UIKit.h>
#import "VIPPackage.h"
#import "config.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "TemplateCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPPackageCell : TemplateCell

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UIButton *recommendedLabel;
@property (nonatomic, strong) VIPPackage *vipPackage;
- (void)configureWithPackage:(VIPPackage *)package;
@end

NS_ASSUME_NONNULL_END
