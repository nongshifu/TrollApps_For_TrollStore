//
//  PublishMoodViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "PublishMoodViewController.h"
#import "NetworkClient.h"
#import "NewProfileViewController.h"
#import "SVProgressHUD.h"
#import "Masonry.h"


@interface PublishMoodViewController ()<UITextViewDelegate>
// 输入框
@property (nonatomic, strong) UITextView *contentTextView;
// 字数统计标签
@property (nonatomic, strong) UILabel *wordCountLabel;
// 最大字数限制（与后端一致：2000字）
@property (nonatomic, assign) NSInteger maxWordCount;

@property (nonatomic, strong) UIButton *publishButton;

@property (nonatomic, strong) UIButton *cancelBtn;

@property (nonatomic, strong) UIView *bottomBar;

@property (nonatomic, strong) UILabel *hintLabel;
@end

@implementation PublishMoodViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxWordCount = 2000;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self setupNavigationBar];
    [self setupBottomButtonBar];
    [self setupSubviews];
    [self updateViewConstraints];
    
   
}

#pragma mark - 界面设置

// 导航栏设置
- (void)setupNavigationBar {
    self.navigationItem.title = @"发布心情";
    // 移除原有导航栏按钮（不再使用）
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
}

// 新增：设置底部按钮栏
- (void)setupBottomButtonBar {
    // 1. 底部容器视图（承载两个按钮）
    self.bottomBar = [UIView new];
    self.bottomBar.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.bottomBar];
    
    
    // 2. 取消按钮
    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelBtn setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    self.cancelBtn.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.cancelBtn.layer.cornerRadius = 8;
    [self.cancelBtn addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.cancelBtn];
    
    // 3. 发布按钮（默认禁用）
    self.publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.publishButton setTitle:@"发布" forState:UIControlStateNormal];
    [self.publishButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.publishButton.backgroundColor = [UIColor systemBlueColor];
    self.publishButton.layer.cornerRadius = 8;
    self.publishButton.enabled = YES;
    [self.publishButton addTarget:self action:@selector(publishButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.publishButton];
    
    
    
}

// 子视图设置
- (void)setupSubviews {
    // 1. 输入提示标签
    self.hintLabel = [UILabel new];
    self.hintLabel.text = @"分享你的动态心情吧...";
    self.hintLabel.textColor = [UIColor labelColor];
    self.hintLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:self.hintLabel];
    
    // 2. 内容输入框（初始约束：不依赖wordCountLabel，改用安全区域）
    self.contentTextView = [UITextView new];
    self.contentTextView.font = [UIFont systemFontOfSize:16];
    self.contentTextView.delegate = self;
    self.contentTextView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    self.contentTextView.returnKeyType = UIReturnKeyDone;
    self.contentTextView.layer.cornerRadius = 15;
    [self.view addSubview:self.contentTextView];
    
    // 3. 字数统计标签（固定在安全区域底部，与contentTextView分离）
    self.wordCountLabel = [UILabel new];
    self.wordCountLabel.text = @"0/1000";
    self.wordCountLabel.textColor = [UIColor secondaryLabelColor];
    self.wordCountLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.wordCountLabel];
        
    
    
    
}


#pragma mark - UITextViewDelegate（输入监听）

- (void)textViewDidChange:(UITextView *)textView {
    NSString *content = textView.text;
    NSInteger count = content.length;
    
    // 更新字数统计
    self.wordCountLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)count, (long)_maxWordCount];
    
    // 超过最大字数限制时截断
    if (count > _maxWordCount) {
        textView.text = [content substringToIndex:_maxWordCount];
        self.wordCountLabel.textColor = [UIColor systemRedColor];
    } else {
        self.wordCountLabel.textColor = [UIColor secondaryLabelColor];
    }
    
    // 启用/禁用发布按钮（内容不为空）
//    self.navigationItem.rightBarButtonItem.enabled = (count > 0 && count <= _maxWordCount);
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    return YES;
}

#pragma mark - 按钮点击事件

// 取消按钮
- (void)cancelButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

// 发布按钮（核心：对接后端接口）
- (void)publishButtonTapped {
    NSLog(@"准备发布");
    [self.contentTextView resignFirstResponder];
    NSString *content = [self.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // 再次验证内容
    if (content.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"内容不能为空"];
        return;
    }
    if (content.length > _maxWordCount) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"内容不能超过%ld字", (long)_maxWordCount]];
        return;
    }
    // 获取当前用户UDID
    NSString *myUdid = [NewProfileViewController sharedInstance].userInfo.udid;
    if (!myUdid || myUdid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"UDID获取失败"];
        return;
    }
    // 构建请求参数
    NSDictionary *params = @{
        @"action": @"createMood",
        @"udid": myUdid,
        @"content": content // 心情内容
    };
    NSLog(@"准备发布params:%@",params);
    // 接口地址（与列表接口一致）
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php", localURL];
    
    // 显示加载中
    [SVProgressHUD showWithStatus:@"发布中..."];
    
    // 发送请求
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                           urlString:url
                                          parameters:params
                                               udid:myUdid
                                             progress:nil
                                              success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (!jsonResult) {
                [SVProgressHUD showErrorWithStatus:@"发布失败，数据格式错误"];
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] integerValue];
            NSString *message = jsonResult[@"msg"] ?: @"发布失败，请重试";
            
            if (code == 200) {
                [SVProgressHUD showSuccessWithStatus:@"发布成功"];
                // 延迟返回，让用户看到成功提示
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 回调通知列表刷新
                    if (self.publishSuccessBlock) {
                        self.publishSuccessBlock();
                    }
                    [self dismiss];
                });
            } else {
                [SVProgressHUD showErrorWithStatus:message];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"发布失败：%@", error.localizedDescription]];
        });
    }];
}

#pragma mark - 内存管理

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    
    // 布局（关键修改）
    [self.hintLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(16);
        make.left.right.equalTo(self.view).inset(16);
        make.height.equalTo(@20);
    }];
    
    // 4. 布局底部栏和按钮
    [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight); // 贴安全区域底部（适配刘海屏）
        make.height.equalTo(@56); // 固定高度
    }];
    
    // 取消按钮：左半部分
    [self.cancelBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomBar).offset(16);
        make.centerY.equalTo(self.bottomBar);
        make.height.equalTo(@40);
        make.right.equalTo(self.bottomBar.mas_centerX).offset(-8); // 距离中线左8pt
    }];
    
    // 发布按钮：右半部分
    [self.publishButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomBar).offset(-16);
        make.centerY.equalTo(self.bottomBar);
        make.height.equalTo(@40);
        make.left.equalTo(self.bottomBar.mas_centerX).offset(8); // 距离中线右8pt
    }];
    
    
    
    // wordCountLabel约束：固定在contentTextView下方，安全区域底部上方
    [self.wordCountLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).inset(16);
        make.bottom.equalTo(self.bottomBar.mas_top).offset(-10);
        make.height.equalTo(@20);
    }];
    
    
    
    
    // contentTextView初始约束：顶部接hintLabel，底部距离安全区域底部有默认间距
    [self.contentTextView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hintLabel.mas_bottom).offset(16);
        make.left.right.equalTo(self.view).inset(16);
//        make.height.equalTo(@300);
        make.bottom.equalTo(self.wordCountLabel.mas_top).offset(-10);
    }];
    
}
#pragma mark - HWPanModalPresentable

- (PanModalHeight)longFormHeight {
    return PanModalHeightMake(PanModalHeightTypeContent, 500);
}
- (CGFloat)keyboardOffsetFromInputView{
    return 30;
}
@end
