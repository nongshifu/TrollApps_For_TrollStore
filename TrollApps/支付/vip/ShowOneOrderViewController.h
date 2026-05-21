//
//  ShowOneOrderViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowOneOrderViewController : DemoBaseViewController

/// 目标订单号（外部传入）
@property (nonatomic, copy) NSString *targetOrderNo;

@end

NS_ASSUME_NONNULL_END
