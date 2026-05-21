//
//  PrivacyPolicyViewController.h
//  NewSoulChat
//
//  Created by 十三哥 on 2025/4/3.
//  Copyright © 2025 D-James. All rights reserved.
//

#import "DemoBaseViewController.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^PrivacyPolicyAgreementHandler)(BOOL isAgreed);

@interface PrivacyPolicyViewController : DemoBaseViewController<WKUIDelegate>


@property (nonatomic, copy) PrivacyPolicyAgreementHandler agreementHandler;
@property (nonatomic, strong) WKWebView *webView;

@end

NS_ASSUME_NONNULL_END
