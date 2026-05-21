//
//  AppIconCell.h
//  TrollApps
//
//  Created by 十三哥 on 2026/4/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppIconCell : UITableViewCell
@property (nonatomic, strong) UIImageView *appIconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@end

NS_ASSUME_NONNULL_END
