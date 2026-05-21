//
//  InjectMainController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface InjectMainController : DemoBaseViewController
@property (nonatomic, strong) NSURL *selectedDylibURL; // 从Dylib管理页面选择的Dylib
@end

NS_ASSUME_NONNULL_END
