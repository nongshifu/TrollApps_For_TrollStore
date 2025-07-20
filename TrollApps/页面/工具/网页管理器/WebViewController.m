//
//  WebViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "WebViewController.h"
#import "WebToolManager.h"

@interface WebViewController () <WKUIDelegate, WKNavigationDelegate>


@end

@implementation WebViewController

#pragma mark - Lifecycle
- (instancetype)initWithToolModel:(WebToolModel *)toolModel {
    self = [super init];
    if (self) {
        _toolModel = toolModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadWebContent];
    
    // 添加到WebToolManager
    [[WebToolManager sharedManager] addWebToolWithModel:self.toolModel controller:self];
}

#pragma mark - WebView Loading

- (void)loadWebContent {
    if (!self.toolModel || !self.toolModel.tool_path) {
        NSLog(@"WebToolModel or tool_path is nil");
        [self showErrorWithMessage:@"工具信息不完整，无法加载"];
        return;
    }
    
    // 构建完整的URL
//    NSString *localURL = [self getLocalBaseURL];
    NSString *fullURLString = [NSString stringWithFormat:@"%@/%@/%@", localURL, self.toolModel.tool_path, self.toolModel.html_file ?: @"index.html"];
    
    // 处理特殊字符
    fullURLString = [fullURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:fullURLString];
    
    if (url) {
        NSLog(@"Loading URL: %@", fullURLString);
        
        // 创建SFSafariViewController
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
        safariVC.delegate = self;
        safariVC.preferredControlTintColor = [UIColor systemBlueColor]; // 设置控制按钮颜色
        
        self.safariVC = safariVC;
        [self addChildViewController:safariVC];
        [self.view addSubview:safariVC.view];
        [safariVC didMoveToParentViewController:self];
        
        // 设置约束
        [safariVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    } else {
        NSLog(@"Invalid URL: %@", fullURLString);
        [self showErrorWithMessage:@"无效的URL"];
    }
}

- (NSString *)getLocalBaseURL {
    // 返回应用文档目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
}

#pragma mark - Error Handling

- (void)showErrorWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加载失败" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // 用户点击完成按钮
    [self closeWebView];
}

- (void)closeWebView {
    // 从导航栈中移除
    [self.navigationController popViewControllerAnimated:YES];
}

@end
