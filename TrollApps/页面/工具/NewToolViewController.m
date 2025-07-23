//
//  NewToolViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "NewToolViewController.h"
#import "WebToolModel.h"
#import "ToolTagsView.h"
#import "HTMLCodeEditorView.h"
#import "loadData.h"
#import "AppSearchViewController.h"
#import "NewAppFileModel.h"
#import "ImageGridSearchViewController.h"

#define kTool_Draft_KEY @"kTool_Draft_KEY"

//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface NewToolViewController () <UITextFieldDelegate, UITextViewDelegate, ToolTagsViewDelegate, HTMLCodeEditorViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,AppSearchViewControllerDelegate,ImageGridSearchViewControllerDelegate>

@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) UIButton *draftButton;
@property (nonatomic, strong) UIButton *closeButton;
// 基本信息输入
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIImage *iconImage;

@property (nonatomic, strong) UITextField *toolNameField;

@property (nonatomic, strong) UITextField *versionField;
@property (nonatomic, strong) UIButton *incrementButton; // 版本号增加按钮

@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UITextView *descriptionView;
@property (nonatomic, strong) UILabel *tagsLabel;
@property (nonatomic, strong) ToolTagsView *tagsView;

@property (nonatomic, strong) UISegmentedControl *switchInput;
// HTML代码编辑
@property (nonatomic, strong) HTMLCodeEditorView *codeEditorView;

// 底部按钮
@property (nonatomic, strong) UIButton *actionButton;

@property (nonatomic, strong) UIScrollView *infoContainer;

@property (nonatomic, assign) BOOL isRuning;//防止重复提交

@end

@implementation NewToolViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isTapViewToHideKeyboard = YES;
    
    [self setupUI];
    [self setupConstraints];
    [self setupNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self.isUpdating){
        [self setupInitialValues];
    }else{
        [self loadDraft];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 在这里进行与布局完成后相关的操作，比如获取子视图的最终尺寸等
    NSLog(@"视图布局完成");
    self.infoContainer.contentSize = CGSizeMake(self.infoContainer.bounds.size.width, CGRectGetMaxY(self.codeEditorView.frame)+20);
    
}


#pragma mark - Setup

- (void)setupUI {
    self.view.backgroundColor = [UIColor clearColor];
    //顶头标题
    _titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_titleButton setTitle:@"发布工具" forState:UIControlStateNormal];
    _titleButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    _titleButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    [_titleButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    [self.view addSubview:_titleButton];
    
    _draftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_draftButton setTitle:@"草稿" forState:UIControlStateNormal];
    [_titleButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_draftButton addTarget:self action:@selector(draftButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_draftButton];
    
    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(onBackButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_closeButton];
    
    
    
    // 基本信息区域
    self.infoContainer = [[UIScrollView alloc] init];
    self.infoContainer.backgroundColor = [UIColor clearColor];
    self.infoContainer.layer.cornerRadius = 12.0;
    self.infoContainer.clipsToBounds = YES;
    [self.view addSubview:self.infoContainer];
    
    //图标
    _iconView = [UIImageView new];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.image = [UIImage systemImageNamed:@"photo.fill"];
    _iconView.userInteractionEnabled = YES;
    _iconView.layer.cornerRadius = 22;
    _iconView.layer.borderWidth = 1;
    _iconView.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.3].CGColor;
    _iconView.layer.masksToBounds = YES;
    [_iconView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeAvatar:)]];
    [self.infoContainer addSubview:_iconView];
    
    
    // 工具名称
    _toolNameField = [[UITextField alloc] init];
    _toolNameField.placeholder = @"请输入工具名称";
    _toolNameField.borderStyle = UITextBorderStyleRoundedRect;
    _toolNameField.delegate = self;
    [self.infoContainer addSubview:_toolNameField];
    
    // 版本号
    _versionField = [[UITextField alloc] init];
    _versionField.placeholder = @"版本号";
    _versionField.text = @"1.0.0";
    _versionField.borderStyle = UITextBorderStyleRoundedRect;
    _versionField.delegate = self;
    [self.infoContainer addSubview:_versionField];
    // 递增按钮
    self.incrementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.incrementButton setTitle:@"+" forState:UIControlStateNormal];
    [self.incrementButton.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [self.incrementButton addTarget:self action:@selector(incrementVersion) forControlEvents:UIControlEventTouchUpInside];
    [self.infoContainer addSubview:self.incrementButton];

    
    // 工具描述
    _descLabel = [[UILabel alloc] init];
    _descLabel.text = @"工具简介:";
    _descLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.infoContainer addSubview:_descLabel];
    
    _descriptionView = [[UITextView alloc] init];
    _descriptionView.font = [UIFont systemFontOfSize:15];
    _descriptionView.layer.borderColor = [UIColor systemGray3Color].CGColor;
    _descriptionView.layer.borderWidth = 1.0;
    _descriptionView.layer.cornerRadius = 6.0;
    _descriptionView.delegate = self;
    _descriptionView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    [self.infoContainer addSubview:_descriptionView];
    
    // 标签
    _tagsLabel = [[UILabel alloc] init];
    _tagsLabel.text = @"标签:";
    _tagsLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.infoContainer addSubview:_tagsLabel];
    
    _tagsView = [[ToolTagsView alloc] init];
    _tagsView.toolTagsDelegate = self;
    [self.infoContainer addSubview:_tagsView];
    
    //切换选项卡
    _switchInput = [[UISegmentedControl alloc] initWithItems:@[@"HTML",@"URL"]];
    _switchInput.selectedSegmentIndex = 0;
    [_switchInput addTarget:self action:@selector(switchInputTap) forControlEvents:UIControlEventValueChanged];
    
    [self.infoContainer addSubview:_switchInput];
    
    // HTML代码编辑器
    _codeEditorView = [[HTMLCodeEditorView alloc] init];
    _codeEditorView.delegate = self;
    [self.infoContainer addSubview:_codeEditorView];
    
    // 底部按钮
    _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _actionButton.backgroundColor = [UIColor systemBlueColor];
    _actionButton.tintColor = [UIColor whiteColor];
    [_actionButton setTitle:@"发布工具" forState:UIControlStateNormal];
    _actionButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    [_actionButton addTarget:self action:@selector(onActionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_actionButton];
    
    
}

- (void)setupConstraints {
    CGFloat maxWidth = kWidth;
    [self.titleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(0); // 顶部对齐安全区
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.equalTo(@45);
        
    }];
    [self.draftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(0); // 顶部对齐安全区
        make.width.equalTo(@50);
        make.right.equalTo(self.view).offset(-16);
        make.height.equalTo(@45);
        
    }];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(0); // 顶部对齐安全区
        make.width.equalTo(@50);
        make.left.equalTo(self.view).offset(16);
        make.height.equalTo(@45);
        
    }];
    
    // 使用Masonry设置约束
    [self.infoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleButton.mas_bottom).offset(0); // 顶部对齐安全区
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight -70);
    }];
    
    
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.infoContainer).offset(16);
        make.width.height.equalTo(@100);
        
    }];
    
    // 1. 工具名称相关
    [self.toolNameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.infoContainer.mas_top).offset(16); // 与名称标签间距8
        make.left.equalTo(self.iconView.mas_right).offset(16);
        make.height.equalTo(@40);
        make.width.equalTo(@(maxWidth - 148));
    }];
    
    // 2. 版本号相关（与上方视图衔接）
    [self.versionField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.toolNameField.mas_bottom).offset(16);
        make.left.equalTo(self.iconView.mas_right).offset(16);
        make.height.equalTo(@40);
        make.width.equalTo(@120);
    }];
    //版本号修改
    [self.incrementButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.versionField);
        make.left.equalTo(self.versionField.mas_right).offset(10);
        make.width.equalTo(@50);
        make.height.equalTo(self.versionField);
    }];
    
    // 3. 描述相关
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconView.mas_bottom).offset(16);
        make.left.equalTo(self.infoContainer).offset(16);
        
    }];
    //描述
    [self.descriptionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descLabel.mas_bottom).offset(8);
        make.width.equalTo(@(maxWidth - 32));
        make.centerX.equalTo(self.infoContainer);
        make.height.equalTo(@80);
    }];
    
    // 4. 标签相关
    [self.tagsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionView.mas_bottom).offset(16);
        make.left.equalTo(self.infoContainer).offset(16);
    }];
    
    [self.tagsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsLabel.mas_bottom).offset(8);
        make.width.equalTo(@(maxWidth - 32));
        make.centerX.equalTo(self.infoContainer);
        make.height.greaterThanOrEqualTo(@40); // 标签高度动态适应内容
    }];
    
    //选项卡
    [self.switchInput mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsView.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(16);
        make.width.equalTo(@110);
        make.height.equalTo(@35); // 固定高度，或根据需求调整
    }];
    
    // 5. 代码编辑器（最后一个子视图，需关联ScrollView底部）
    [self.codeEditorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.switchInput.mas_bottom).offset(10);
        make.width.equalTo(@(maxWidth - 32));
        make.centerX.equalTo(self.infoContainer);
        make.height.equalTo(@300); // 固定高度，或根据需求调整
        make.bottom.equalTo(self.infoContainer).offset(-20); // 与ScrollView底部间距20（关键！）
    }];
    
    [self.actionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(32);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight); // 关联安全区底部
        make.height.equalTo(@50);
    }];
    
    self.infoContainer.contentSize = CGSizeMake(self.infoContainer.bounds.size.width, 500.0);
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    
    [self.infoContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight -70);
    }];
    // 5. 代码编辑器（最后一个子视图，需关联ScrollView底部）
    [self.codeEditorView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.switchInput.mas_bottom).offset(10);
        if(self.switchInput.selectedSegmentIndex == 0){
            make.height.equalTo(@300);
        }else{
            make.height.equalTo(@100);
        }
    }];
    
    
    [self.actionButton mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        
    }];
}

- (void)setupNavigationBar {
    self.title = @"发布工具";
    
    // 返回按钮
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onBackButtonTapped)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)setupInitialValues {
    
    self.toolNameField.text = self.webToolModel.tool_name;
    self.versionField.text = self.webToolModel.version;
    self.descriptionView.text = self.webToolModel.tool_description;
    [self.tagsView setTags:self.webToolModel.tags];
    [self.codeEditorView setHTMLCode:self.webToolModel.html_content];
    self.switchInput.selectedSegmentIndex = self.webToolModel.tool_type;
    [self switchInputTap];
    NSString *url = [NSString stringWithFormat:@"%@/%@/icon.png",localURL,self.webToolModel.tool_path];
    [self.iconView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage systemImageNamed:@"photo.fill"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if(image){
            self.iconView.image =  image;
            
        }
    }];
    
    if (self.isUpdating && self.webToolModel ) {
        // 更新模式
       
        [_titleButton setTitle:@"更新工具" forState:UIControlStateNormal];
        [_actionButton setTitle:@"提交更新" forState:UIControlStateNormal];
        
        [self fetchHtmlFromServerWithToolId:self.webToolModel.tool_id];
        
    } else {
        // 发布模式
        
        [_titleButton setTitle:@"发布工具" forState:UIControlStateNormal];
        [_actionButton setTitle:@"提交发布" forState:UIControlStateNormal];
        self.versionField.text = @"1.0.0"; // 默认版本号
    }
}

- (void)fetchHtmlFromServerWithToolId:(NSInteger )tool_id {
    NSString *udid = [loadData sharedInstance].userModel.udid;
    if(tool_id ==0){
        return;
    }
    if(!udid || udid.length<5){
        [SVProgressHUD showErrorWithStatus:@"请先获取UDID绑定设备登录"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    NSDictionary *dic = @{
        @"action":@"getToolHtmlContent",
        @"tool_id":@(tool_id),
        @"udid":udid,
    };
    NSString *url = [NSString stringWithFormat:@"%@/tool_api.php",localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"stringResult:%@",stringResult);
            if(jsonResult){
                NSInteger code = [jsonResult[@"code"] intValue];
                if (code == 200) {
                    NSDictionary *data = jsonResult[@"data"];
                    NSString *html_content_base64 = data[@"html_content_base64"];
                    
                    // 将 Base64 字符串解码为 NSData
                    NSData *htmlData = [[NSData alloc] initWithBase64EncodedString:html_content_base64 options:0];
                    
                    if (htmlData) {
                        // 将 NSData 转换为 UTF-8 字符串
                        NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
                        
                        if (htmlString) {
                            // 设置到代码编辑器
                            self.codeEditorView.codeTextView.text = htmlString;
                        } else {
                            NSLog(@"警告: 无法将 HTML 数据转换为字符串");
                        }
                    } else {
                        NSLog(@"警告: 无法解码 Base64 字符串");
                    }
                }
                
            }
        });
        
    } failure:^(NSError *error) {
        
    }];
}

#pragma mark - Actions

- (void)onBackButtonTapped {
    [self dismiss];
}

//提交
- (void)onActionButtonTapped {
    [self.view endEditing:YES];
    
    if (![self validateInputs]) {
        return;
    }
    if(self.isRuning){
        [SVProgressHUD showInfoWithStatus:@"任务已提交-等待结果后操作"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    [SVProgressHUD showWithStatus:@"提交进行中。。。"];
    
    // 准备请求参数
    NSMutableDictionary *params = [self uiContentToDictionary].copy;
    
    [self requestsToolWithParams:params];
    
    
}

- (void)draftButtonTap:(UIButton*)button {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"草稿" message:nil preferredStyle:UIAlertControllerStyleAlert];
    // 添加取消按钮
    UIAlertAction*deleteAction = [UIAlertAction actionWithTitle:@"删除草稿" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteDraft];
        
        [SVProgressHUD showSuccessWithStatus:@"删除成功"];
        
        [SVProgressHUD dismissWithDelay:1];
    }];
    [alert addAction:deleteAction];
    UIAlertAction*confirmAction = [UIAlertAction actionWithTitle:@"保存草稿" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self saveDraft];
        
        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
        
        [SVProgressHUD dismissWithDelay:1];
    }];
    [alert addAction:confirmAction];
    UIAlertAction*loadAction = [UIAlertAction actionWithTitle:@"加载草稿" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if(![self loadDraft]){
            [SVProgressHUD showInfoWithStatus:@"读取失败 草稿为空"];
            
            [SVProgressHUD dismissWithDelay:1];
        };
        
        
    }];
    [alert addAction:loadAction];
    
    UIAlertAction*cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)switchInputTap {
    NSInteger index = self.switchInput.selectedSegmentIndex;
    if(index ==0){
        [self.codeEditorView.rightButton setTitle:@"HTML" forState:UIControlStateNormal];
    }else{
        [self.codeEditorView.rightButton setTitle:@"URL" forState:UIControlStateNormal];
        NSString * text = self.codeEditorView.codeTextView.text;
        //检测输入是否是URL
        BOOL isURL = [NewAppFileModel isValidURL:text];
        if(!isURL && text.length>0){
            
            [self showAlertWithConfirmationFromViewController:self title:@"URL不合法" message:@"URL模式下仅支持http或https开头URL网址" confirmTitle:@"清除输入" cancelTitle:@"取消" onConfirmed:^{
                self.codeEditorView.codeTextView.text = @"";
            } onCancelled:^{
                self.switchInput.selectedSegmentIndex = 0;
            }];
            [self updateViewConstraints];
        }
    }
    
  
    [self updateViewConstraints];
}

//修改版本号
- (void)incrementVersion {
    NSString *currentVersion = self.versionField.text;
    
    // 检查版本号格式是否合法（至少包含一个点号）
    if (![currentVersion containsString:@"."]) {
        [self showAlertFromViewController:self title:@"格式错误" message:@"版本号格式错误，应为小写 X.Y.Z \n如 1.1.3"];
        return;
    }
    
    // 分割版本号为数组
    NSArray *components = [currentVersion componentsSeparatedByString:@"."];
    NSMutableArray *versionParts = [components mutableCopy];
    
    // 确保有三个部分（X.Y.Z），不足则补0
    while (versionParts.count < 3) {
        [versionParts addObject:@"0"];
    }
    
    // 从末尾开始递增
    BOOL incremented = NO;
    for (NSInteger i = versionParts.count - 1; i >= 0; i--) {
        NSInteger part = [versionParts[i] integerValue];
        part++; // 递增当前部分
        
        // 如果递增后超过9，进位并将当前部分置0
        if (part > 9) {
            versionParts[i] = @"0";
            // 如果不是第一部分，继续进位
            if (i > 0) {
                continue;
            } else {
                // 第一部分进位（如9.9.9 → 10.0.0）
                versionParts[i] = [NSString stringWithFormat:@"%ld", (long)part];
                incremented = YES;
                break;
            }
        } else {
            // 正常递增，无需进位
            versionParts[i] = [NSString stringWithFormat:@"%ld", (long)part];
            incremented = YES;
            break;
        }
    }
    
    if (incremented) {
        // 生成新的版本号字符串
        NSString *newVersion = [versionParts componentsJoinedByString:@"."];
        self.versionField.text = newVersion;
    } else {
        
        [self showAlertFromViewController:self title:@"错误" message:@"版本号递增失败"];
    }
}

#pragma mark - 草稿功能

//保存
- (void)saveDraft{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
    NSDictionary *params = [self uiContentToDictionary];
    
    [defaults setValue:params forKey:kTool_Draft_KEY];
    
    [defaults synchronize];
   
    
}

//删除
- (void)deleteDraft{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kTool_Draft_KEY];
    [defaults synchronize];
}

//加载
- (BOOL)loadDraft{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [defaults objectForKey:kTool_Draft_KEY];
    if(!dic){
        return NO;
    }
    [self dictionaryContentToUI:dic];
    return YES;
}

#pragma mark - 辅助函数

//UI转字典
- (NSDictionary*)uiContentToDictionary{
    // 准备请求参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"tool_name"] = self.toolNameField.text;
    params[@"tool_description"] = self.descriptionView.text;
    params[@"tags"] = [self.tagsView getTags];
    params[@"version"] = self.versionField.text;
    params[@"tool_type"] = @(self.switchInput.selectedSegmentIndex);
    params[@"is_public"] = @YES;
    // 获取HTML代码
    NSString *htmlCode = [self.codeEditorView getHTMLCode];
    
    // 处理HTML代码（使用Base64编码防止JSON解析问题）
    NSData *htmlData = [htmlCode dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64EncodedHTML = [htmlData base64EncodedStringWithOptions:0];
    params[@"html_content"] = base64EncodedHTML;
    

    if(self.iconImage){
        if(self.iconImage.size.width >100 || self.iconImage.size.height >100){
            self.iconImage = [self.iconImage resizedImageToSize:CGSizeMake(100, 100) contentMode:UIViewContentModeScaleAspectFit];
        }
        NSData *iconData = UIImagePNGRepresentation(self.iconImage);
        NSString *base64Encoded = [iconData base64EncodedStringWithOptions:0];
        NSLog(@"base64Encoded:%@",base64Encoded);
        params[@"icon_content"] = base64Encoded;
    }
    return params;
}

- (void)dictionaryContentToUI:(NSDictionary*)dictionary {
    // 使用YYModel将字典转换为模型对象
    self.webToolModel = [WebToolModel yy_modelWithDictionary:dictionary];
    
    // 设置初始值
    [self setupInitialValues];
    
    // 处理HTML内容
    NSString *htmlContentBase64 = dictionary[@"html_content"];
    if (htmlContentBase64 && [htmlContentBase64 length] > 0) {
        // 将Base64字符串解码为NSData
        NSData *htmlData = [[NSData alloc] initWithBase64EncodedString:htmlContentBase64 options:0];
        if (htmlData) {
            // 将NSData转换为NSString
            NSString *htmlContent = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
            self.codeEditorView.codeTextView.text = htmlContent;
        } else {
            NSLog(@"HTML内容Base64解码失败");
            self.codeEditorView.codeTextView.text = @"";
        }
    } else {
        self.codeEditorView.codeTextView.text = @"";
    }
    
    // 处理图标图片
    NSString *iconBase64 = dictionary[@"icon_content"];
    if (iconBase64 && [iconBase64 length] > 0) {
        // 将Base64字符串解码为NSData
        NSData *iconData = [[NSData alloc] initWithBase64EncodedString:iconBase64 options:0];
        if (iconData) {
            // 将NSData转换为UIImage
            UIImage *iconImage = [UIImage imageWithData:iconData];
            if (iconImage) {
                self.iconView.image = iconImage;
                self.iconImage = iconImage;
            } else {
                NSLog(@"图标图片转换失败");
            }
        } else {
            NSLog(@"图标Base64解码失败");
        }
    }
}

#pragma mark - 头像与昵称修改

- (void)changeAvatar:(UITapGestureRecognizer *)gesture {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置图标"
                                                                   message:@"请选择图片来源"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"网络搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        ImageGridSearchViewController *vc = [ImageGridSearchViewController new];
        vc.delegate = self;
        vc.maxiMum = 1;
        vc.searchKeyword = self.toolNameField.text;
        
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navVC animated:YES completion:nil];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"商店搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        AppSearchViewController * appSaearchViewController = [AppSearchViewController new];
        appSaearchViewController.delegate = self;
        if(self.toolNameField.text.length>0){
            appSaearchViewController.keyword = self.toolNameField.text;
        }
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:appSaearchViewController];
        [self presentViewController:navVC animated:YES completion:nil];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openCamera];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openPhotoLibrary];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [self showAlertWithTitle:@"提示" message:@"相机不可用"];
    }
}

- (void)openPhotoLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [self showAlertWithTitle:@"提示" message:@"相册不可用"];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    
    if (selectedImage) {
        self.iconImage = selectedImage;
        self.iconView.image = selectedImage;
        
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Validation

//表单验证
- (BOOL)validateInputs {
    if (self.toolNameField.text.length == 0) {
        [self showAlertWithTitle:@"提示" message:@"请输入工具名称"];
        return NO;
    }
    
    if (self.descriptionView.text.length == 0) {
        [self showAlertWithTitle:@"提示" message:@"请输入工具简介"];
        return NO;
    }
    
    if (!self.isUpdating && self.codeEditorView.getHTMLCode.length == 0) {
        [self showAlertWithTitle:@"提示" message:@"请输入HTML代码"];
        return NO;
    }
    
    // 验证版本号格式
    if (![self validateVersionFormat:self.versionField.text]) {
        [self showAlertWithTitle:@"提示" message:@"版本号格式不正确，应为X.Y.Z格式"];
        return NO;
    }
    if(!self.isUpdating && !self.iconImage){
        [self showAlertWithTitle:@"提示" message:@"请选择头像"];
        return NO;
    }
    if(self.codeEditorView.codeTextView.text.length ==0){
        [self showAlertWithTitle:@"提示" message:@"请输入工具 代码 或 URL"];
        return NO;
    }
    if(self.switchInput.selectedSegmentIndex == 0){
        if(self.codeEditorView.codeTextView.text.length <100){
            [self showAlertWithTitle:@"提示" message:@"请输入工完整标准HTML代码"];
            return NO;
        }
    }else{
        BOOL isURL = [NewAppFileModel isValidURL:self.codeEditorView.codeTextView.text];
        if(!isURL){
            [self showAlertWithConfirmationFromViewController:self title:@"URL不合法" message:@"URL模式下仅支持http或https开头URL网址" confirmTitle:@"清除输入" cancelTitle:@"取消" onConfirmed:^{
                self.codeEditorView.codeTextView.text = @"";
            } onCancelled:^{
                self.switchInput.selectedSegmentIndex = 0;
            }];
            [self updateViewConstraints];
            return NO;
        }
            
    }
    
    return YES;
}

// 简单验证版本号格式 X.Y.Z
- (BOOL)validateVersionFormat:(NSString *)version {
    // 简单验证版本号格式 X.Y.Z
    NSArray *components = [version componentsSeparatedByString:@"."];
    if (components.count != 3) {
        return NO;
    }
    
    for (NSString *component in components) {
        if (![self isNumericString:component]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)isNumericString:(NSString *)string {
    NSCharacterSet *nonNumberSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return ([string rangeOfCharacterFromSet:nonNumberSet].location == NSNotFound);
}

#pragma mark - 发布 API Requests

- (void)requestsToolWithParams:(NSDictionary *)params {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    //标记为开始提交
    self.isRuning = YES;
    
    NSString *action = @"updateTool";
    if (self.isUpdating && self.webToolModel && self.webToolModel.tool_id > 0){
        [dic setValue:@(self.webToolModel.tool_id) forKey:@"tool_id"];
    }else{
        action = @"publishTool";
    }
    [dic setValue:action forKey:@"action"];
    
    NSString *udid = [loadData sharedInstance].userModel.udid;
    if(!udid || udid.length<5){
        [SVProgressHUD showErrorWithStatus:@"请先获取UDID绑定设备登录"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/tool_api.php",localURL];
    
    
    NSLog(@"请求字典:%@",dic);
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"stringResult:%@",stringResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            //标记为请求完成
            self.isRuning = NO;
            
            if(!jsonResult){
                [self showAlertWithTitle:@"返回数据错误" message:stringResult completion:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                return;
            }
            NSString *msg = jsonResult[@"msg"];
            if ([jsonResult[@"code"] integerValue] == 200) {
                
                [self showAlertWithTitle:@"操作成功" message:msg completion:^{
                    [self deleteDraft];
                    [self dismiss];
                }];
            } else {
                [self showAlertWithTitle:@"操作失败" message:msg];
            }
        });
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:@"网络错误" message:[error localizedDescription]];
        });
    }];
}

#pragma mark - Helpers

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showAlertWithTitle:title message:message completion:nil];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message completion:(void (^)(void))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // 可以添加滚动调整，避免键盘遮挡
}

#pragma mark - Setters

- (void)setWebToolModel:(WebToolModel *)editingTool {
    _webToolModel = editingTool;
    
}

#pragma mark - ToolTagsViewDelegate

- (void)toolTagsViewDidChangeTags:(id)tagsView {
    NSLog(@"添加了按钮:%@",tagsView);
    [self updateViewConstraints];
}


//侧滑手势
- (BOOL)allowScreenEdgeInteractive{
    return NO;
}

//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return YES;
}

- (CGFloat)keyboardOffsetFromInputView {
    return 50;
}

#pragma mark - 商店搜索点击后回调

- (void)didSelectAppModel:(ITunesAppModel *)model {
    if(!model)return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"使用此App数据填充"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"仅使用图标" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if(model.artworkUrl512.length > 0 ){
            [self.iconView sd_setImageWithURL:[NSURL URLWithString:model.artworkUrl512] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if(image){
                    //赋值给头像上传
                    self.iconImage = image;
                    self.iconView.image =  image;
                    
                    
                }
            }];
        }
        [self dismiss];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"覆盖 图标,应用名" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if(model.trackName.length > 0){
            self.toolNameField.text = model.trackName;
        }
        
        if(model.artworkUrl512.length > 0 ){
            [self.iconView sd_setImageWithURL:[NSURL URLWithString:model.artworkUrl512] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if(image){
                    //赋值给头像上传
                    self.iconImage = image;
                    self.iconView.image =  image;
                    
                }
            }];
        }
        [self dismiss];
    }]];
    
    
    [[self.view getTopViewController] presentViewController:alert animated:YES completion:nil];
    
    
}

#pragma mark - ImageGridSearchViewControllerDelegate 图片搜索返回

// 点击图片回调（返回图片对象和URL）
- (void)imageGridSearch:(ImageGridSearchViewController *)controller didSelectImage:(ImageModel *)imageModel cell:(UICollectionViewCell*)cell{
    NSLog(@"图片搜索返回:%@",imageModel.image);
    NSLog(@"图片搜索返回imageUrl:%@",imageModel.url);
    if(imageModel.image && imageModel.isSelected){
        
        [self showIconAlert:imageModel.image controller:controller];
        
    }
}
/// 确认按钮点击后调用代理
- (void)imageGridSearch:(ImageGridSearchViewController *)controller didSelectImages:(NSArray<ImageModel *> *)imageModels{
    NSLog(@"多选择模式下返回数组:%@",imageModels);
    if(imageModels.count>0){
        ImageModel *model = imageModels.firstObject;
        UIImage *image = model.image;
        [self showIconAlert:image controller:controller];
    }
}
#pragma mark - 保存图片到相册
-(void)showIconAlert:(UIImage*)image controller:(ImageGridSearchViewController*)vc{
    // 创建弹窗控制器
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 1. 选择此图（触发代理）
    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:@"选择此图"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        self.iconView.image = image;
        self.iconImage = image;
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        
        [SVProgressHUD showSuccessWithStatus:@"图片已替换"];
        [SVProgressHUD dismissWithDelay:1];
        //读取顶层控制器
        //如果是 转为基类VC 关闭
        
        [vc dismissViewControllerAnimated:YES completion:nil];
        
    }];
    [alert addAction:selectAction];
    
    // 2. 保存相册
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存相册"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
        [self saveImageToAlbum:image];
    }];
    [alert addAction:saveAction];
    
    // 3. 剪切（调用系统裁剪工具）
    UIAlertAction *cropAction = [UIAlertAction actionWithTitle:@"剪切尺寸"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [self presentEditViewControllerWithImage:image];
    }];
    [alert addAction:cropAction];
    
    // 取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    
    [[self.view getTopViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)saveImageToAlbum:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

// 保存相册回调
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        [self showAlertFromViewController:self title:@"保存失败" message:@"无法保存，请检查相册权限"];
       
    } else {
        [SVProgressHUD showSuccessWithStatus:@"已保存到相册"];
        [SVProgressHUD dismissWithDelay:1];
    }
}

#pragma mark - 调用系统裁剪工具
- (void)presentEditViewControllerWithImage:(UIImage *)image{
    __weak typeof(self) weakSelf = self;
    
    HXPhotoManager *manager = [[HXPhotoManager alloc] init];
    HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:image];
    
    [[self.view getTopViewController] hx_presentPhotoEditViewControllerWithManager:manager photoModel:photoModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXPhotoEditViewController *viewController) {
        // 获取编辑后的图片
        UIImage *editedImage = afterModel.thumbPhoto ?: afterModel.thumbPhoto;
        weakSelf.iconView.image = editedImage;
        weakSelf.iconImage = editedImage;
        weakSelf.iconView.contentMode = UIViewContentModeScaleAspectFit;

        
        // 关闭编辑器
        [viewController dismissViewControllerAnimated:YES completion:^{
            [SVProgressHUD showSuccessWithStatus:@"图片已替换"];
            [SVProgressHUD dismissWithDelay:1];
            
            // 直接 dismiss 当前控制器（ImageGridSearchViewController）
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    } cancel:^(HXPhotoEditViewController *viewController) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }];
}



@end
