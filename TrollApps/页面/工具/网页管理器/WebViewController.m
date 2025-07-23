//
//  WebViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//

#import "WebViewController.h"
#import "WebToolManager.h"
#import "NewAppFileModel.h"
#import <Masonry/Masonry.h>
@interface WebViewController () <WKUIDelegate, WKNavigationDelegate>


@end

@implementation WebViewController

#pragma mark - Lifecycle
// WebViewController.m
- (instancetype)initWithToolModel:(WebToolModel *)toolModel {
    // 第一步：查询单例中是否已存在该工具的控制器
    WebToolManager *manager = [WebToolManager sharedManager];
    WebViewController *existingVC = (WebViewController *)[manager getControllerForToolId:toolModel.tool_id];
    
    // 如果存在，直接返回已有实例（不创建新对象）
    if (existingVC) {
        // 更新打开时间（可选，根据需求决定是否在初始化时更新）
        [manager updateOpenTimeForToolId:toolModel.tool_id];
        return existingVC;
    }
    
    // 如果不存在，继续初始化新实例
    self = [super init];
    if (self) {
        _toolModel = toolModel;
        
        // 初始化时自动添加到单例（关键：新实例才会执行这步）
        [manager addWebToolWithModel:toolModel controller:self];
        
        // 设置关闭回调（隐藏而非销毁）
        __weak typeof(manager) weakSelf = manager;
        self.onClose = ^{
            [weakSelf hideWebToolWithId:toolModel.tool_id];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 自定义导航栏（覆盖系统默认关闭按钮）
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(customCloseAction)];
    
    // 首次加载时创建SFSafariViewController
    if (!self.safariVC) {
        [self loadWebContent];
    }
    
    
    
    // 添加到WebToolManager
    [[WebToolManager sharedManager] addWebToolWithModel:self.toolModel controller:self];
    
    
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self.safariVC.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        make.width.equalTo(self.view);
    }];
    [UIView animateWithDuration:0.4 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - WebView Loading

- (void)loadWebContent {
    if (!self.toolModel || !self.toolModel.tool_path) {
        NSLog(@"WebToolModel or tool_path is nil");
        [self showErrorWithMessage:@"工具信息不完整，无法加载"];
        return;
    }
    
    // 构建完整的URL
    NSString *fullURLString = [NSString stringWithFormat:@"%@/%@/%@", localURL, self.toolModel.tool_path, self.toolModel.html_file ?: @"index.html"];
    if(self.toolModel.tool_type == 1 && self.toolModel.html_content.length>0 && [NewAppFileModel isValidURL:self.toolModel.html_content]){
        //URL模式下
        fullURLString = self.toolModel.html_content;
    }
    
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

// 自定义关闭：仅隐藏，不销毁
- (void)customCloseAction {
    if (self.onClose) {
        self.onClose(); // 通知父控制器处理隐藏逻辑
    }
}

// 阻止系统默认的关闭行为（关键）
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // 不调用dismiss，改为触发自定义关闭
    [self customCloseAction];
}

#pragma mark - Error Handling

- (void)showErrorWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加载失败" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - SFSafariViewControllerDelegate

//- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
//    // 用户点击完成按钮
//    [self closeWebView];
//}

- (void)closeWebView {
    // 从导航栈中移除
    [self.navigationController popViewControllerAnimated:YES];
}

@end
