//
//  QRCodeGeneratorViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/26.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"
#import <ZXingObjC/ZXingObjC.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <Masonry/Masonry.h>
NS_ASSUME_NONNULL_BEGIN

@interface QRCodeGeneratorViewController : DemoBaseViewController
/**
 *  初始化方法
 *
 *  @param urlString 二维码链接
 *  @param title     二维码标题（可为空）
 *
 *  @return 控制器实例
 */
- (instancetype)initWithURLString:(NSString *)urlString title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
