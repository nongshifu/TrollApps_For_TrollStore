//
//  ImageSelectCell.h
//  TrollApps
//
//  Created by 十三哥 on 2026/1/1.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageSelectCell : UICollectionViewCell
/// 显示的图片视图
@property (nonatomic, strong) UIImageView *imageView;
/// 删除按钮
@property (nonatomic, strong) UIButton *deleteButton;
@end

NS_ASSUME_NONNULL_END
