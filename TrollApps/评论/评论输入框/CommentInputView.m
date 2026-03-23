//
//  CommentInputView.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/15.
//

#import "CommentInputView.h"
#import "config.h"
#import <Masonry/Masonry.h>

@interface CommentInputView () <UITextViewDelegate>
// 新增：记录原始文本（用于恢复）
@property (nonatomic, copy) NSString *originalText;
// 新增：@用户名的高亮颜色
@property (nonatomic, strong) UIColor *atUserHighlightColor;
@end

@implementation CommentInputView

- (instancetype)initWithOriginalHeight:(CGFloat)originalHeight expandedHeight:(CGFloat)expandedHeight {
    self = [super init];
    if (self) {
        _originalHeight = originalHeight;
        _expandedHeight = expandedHeight;
        _keyboardIsShow = NO;
        _keyboardHeight = 0;
        // 初始化高亮颜色（可自定义）
        _atUserHighlightColor = [UIColor systemBlueColor];
        
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

#pragma mark - UI搭建
- (void)setupUI {
    // 1. 背景装饰
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200)];
    self.backgroundView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    [self addSubview:self.backgroundView];
    
    // 添加背景效果（保留原逻辑）
    [self.backgroundView addColorBallsWithCount:10
                                     ballradius:100
                                     minDuration:60
                                     maxDuration:200
                               UIBlurEffectStyle:UIBlurEffectStyleSystemMaterial
                               UIBlurEffectAlpha:0.95
                                       ballalpha:0.5];
    [self.backgroundView setRandomGradientBackgroundWithColorCount:2 alpha:0.1];
    
    // 2. 输入框 - 关键修改：支持富文本
    self.textView = [[UITextView alloc] init];
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:15];
    self.textView.enablesReturnKeyAutomatically = YES;
    self.textView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.95];
    self.textView.layer.cornerRadius = 10;
    self.textView.clipsToBounds = YES;
    self.textView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    // 关闭文本选择的菜单（可选）
    self.textView.editable = YES;
    self.textView.selectable = YES;
    [self addSubview:self.textView];
    
    // 3. 提示文字
    self.textPromptLabel = [[UILabel alloc] init];
    self.textPromptLabel.text = @"发表评论 - 参与讨论";
    self.textPromptLabel.textColor = [UIColor tertiaryLabelColor];
    self.textPromptLabel.font = [UIFont systemFontOfSize:15];
    [self.textView addSubview:self.textPromptLabel];
    
    // 4. 发送按钮
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.sendButton.tintColor = [UIColor systemBlueColor];
    self.sendButton.layer.cornerRadius = 10;
    self.sendButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.95];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.sendButton];
    
    // 阴影效果
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.1;
    self.layer.shadowOffset = CGSizeMake(0, -2);
}

#pragma mark - 约束布局
- (void)setupConstraints {
    // 背景视图
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.width.equalTo(self);
        make.height.equalTo(@200);
    }];
    
    // 输入框
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(10);
        make.top.equalTo(self).offset(8);
        make.bottom.equalTo(self).offset(-8);
        make.right.equalTo(self.sendButton.mas_left).offset(-10);
    }];
    
    // 提示文字
    [self.textPromptLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textView).offset(8);
        make.top.equalTo(self.textView).offset(8);
    }];
    
    // 发送按钮
    [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-10);
        make.width.equalTo(@60);
        make.top.equalTo(self.textView);
        make.bottom.equalTo(self.textView);
    }];
}

#pragma mark - 外部属性监听
- (void)setKeyboardIsShow:(BOOL)keyboardIsShow {
    _keyboardIsShow = keyboardIsShow;
    [self updateInputHeight];
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight {
    _keyboardHeight = keyboardHeight;
    [self updateInputHeight];
}

/// 更新输入框高度
- (void)updateInputHeight {
    [UIView animateWithDuration:0.3 animations:^{
        // 调整自身高度
        CGFloat targetHeight = self.keyboardIsShow ? self.expandedHeight : self.originalHeight;
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, targetHeight);
        
        [self.sendButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-10);
            make.width.equalTo(@60);
            make.top.equalTo(self.textView);
            make.bottom.equalTo(self.textView);
        }];
        
        // 刷新布局
        [self layoutIfNeeded];
    }];
}

#pragma mark - 核心功能：@用户名高亮
/// 处理@用户名的富文本高亮
- (void)highlightAtUserInTextView:(UITextView *)textView {
    if (textView.text.length == 0) {
        self.originalText = @"";
        return;
    }
    
    // 保存原始文本（用于发送时恢复）
    self.originalText = textView.text;
    
    // 创建富文本
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:textView.text];
    // 设置默认字体和颜色
    [attributedText addAttribute:NSFontAttributeName value:textView.font range:NSMakeRange(0, textView.text.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName value:textView.textColor range:NSMakeRange(0, textView.text.length)];
    
    // 正则匹配：@用户名 + 空格（匹配规则：@开头，后面跟非空字符，直到空格结束）
    NSString *pattern = @"@[^\\s]+\\s";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    // 遍历所有匹配结果
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:textView.text
                                                               options:0
                                                                 range:NSMakeRange(0, textView.text.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange range = match.range;
        if (range.location != NSNotFound && range.length > 0) {
            // 设置@用户名的高亮颜色
            [attributedText addAttribute:NSForegroundColorAttributeName
                                   value:self.atUserHighlightColor
                                   range:range];
            // 可选：设置粗体
            [attributedText addAttribute:NSFontAttributeName
                                   value:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium]
                                   range:range];
        }
    }
    
    // 关闭代理避免循环调用
    textView.delegate = nil;
    // 设置富文本
    textView.attributedText = attributedText;
    // 恢复代理
    textView.delegate = self;
    
    // 恢复光标位置（避免光标跳到开头）
    NSRange selectedRange = textView.selectedRange;
    textView.selectedRange = selectedRange;
}

#pragma mark - 事件处理
- (void)sendButtonTapped {
    // 发送时使用原始文本（去掉富文本格式）
    NSString *content = [self.originalText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (content.length == 0) {
        // 可替换为自定义提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"评论内容不能为空"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 通知代理发送评论
    if ([self.delegate respondsToSelector:@selector(commentInputViewDidSendComment:)]) {
        [self.delegate commentInputViewDidSendComment:content];
    }
    
    // 清空输入框
    [self clearInputText];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    // 显示/隐藏提示文字
    self.textPromptLabel.alpha = textView.text.length > 0 ? 0 : 1;
    
    // 限制文本长度
    if (textView.text.length > 200) {
        textView.text = [textView.text substringToIndex:200];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"最多输入200个字"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [[self getTopViewController] presentViewController:alert animated:YES completion:nil];
    }
    
    // 处理换行
    [self processNewlinesInTextView:textView];
    
    // 核心新增：实时高亮@用户名
    [self highlightAtUserInTextView:textView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // 禁止连续换行
    if ([text isEqualToString:@"\n"] && [textView.text hasSuffix:@"\n"]) {
        return NO;
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.textPromptLabel.alpha = 0;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        self.textPromptLabel.alpha = 1;
    }
}

#pragma mark - 工具方法
/// 清理连续换行
- (void)processNewlinesInTextView:(UITextView *)textView {
    NSString *text = textView.text;
    NSString *processedText = [text stringByReplacingOccurrencesOfString:@"\n{2,}"
                                                              withString:@"\n"
                                                                 options:NSRegularExpressionSearch
                                                                   range:NSMakeRange(0, text.length)];
    
    if (![processedText isEqualToString:text]) {
        textView.text = processedText;
        [textView setSelectedRange:NSMakeRange(processedText.length, 0)];
    }
}

/// 清空输入框
- (void)clearInputText {
    // 清空富文本和原始文本
    self.textView.text = @"";
    self.originalText = @"";
    self.textPromptLabel.alpha = 1;
}

#pragma mark - 布局刷新
- (void)layoutSubviews {
    [super layoutSubviews];
    // 确保高度正确
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.keyboardIsShow ? self.expandedHeight : self.originalHeight);
}

/// 获取顶层控制器（原逻辑，补充实现）
- (UIViewController *)getTopViewController {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

@end
