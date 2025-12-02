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

@end

@implementation CommentInputView

- (instancetype)initWithOriginalHeight:(CGFloat)originalHeight expandedHeight:(CGFloat)expandedHeight {
    self = [super init];
    if (self) {
        _originalHeight = originalHeight;
        _expandedHeight = expandedHeight;
        _keyboardIsShow = NO;
        _keyboardHeight = 0;
        
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
    
    // 2. 输入框
    self.textView = [[UITextView alloc] init];
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:15];
    self.textView.enablesReturnKeyAutomatically = YES;
    self.textView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.95];
    self.textView.layer.cornerRadius = 10;
    self.textView.clipsToBounds = YES;
    self.textView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
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

#pragma mark - 事件处理
- (void)sendButtonTapped {
    NSString *content = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
    self.textView.text = @"";
    self.textPromptLabel.alpha = 1;
}

#pragma mark - 布局刷新
- (void)layoutSubviews {
    [super layoutSubviews];
    // 确保高度正确
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.keyboardIsShow ? self.expandedHeight : self.originalHeight);
}

@end
