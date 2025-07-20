//
//  WebViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DemoBaseViewController.h"
#import "WebToolModel.h"
#import <WebKit/WebKit.h>
#import <SafariServices/SafariServices.h>
NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : DemoBaseViewController<SFSafariViewControllerDelegate>
// 使用WebToolModel初始化
- (instancetype)initWithToolModel:(WebToolModel *)toolModel;

@property (nonatomic, strong) WebToolModel *toolModel;
@property (nonatomic, strong) SFSafariViewController *safariVC;


@end

NS_ASSUME_NONNULL_END
