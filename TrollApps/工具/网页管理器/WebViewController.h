//
//  WebViewController.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
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
@property (nonatomic, copy) void(^onClose)(void); // 关闭回调（用于通知父控制器）


@end

NS_ASSUME_NONNULL_END
