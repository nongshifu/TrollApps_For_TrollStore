//
//  EmptyView.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/4/5.
//  Copyright © 2025 D-James. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmptyView : UIView
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *actionButton;

- (void)configureWithImage:(UIImage *)image title:(NSString *)title buttonTitle:(NSString *)buttonTitle;
@end

NS_ASSUME_NONNULL_END
