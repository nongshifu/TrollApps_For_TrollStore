//
//  HTMLCodeEditorView.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//

#import "HTMLCodeEditorView.h"
#import <Masonry/Masonry.h>

@interface HTMLCodeEditorView () <UITextViewDelegate>


@property (nonatomic, strong) UIView *toolbarView;

@end

@implementation HTMLCodeEditorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    
    self.layer.cornerRadius = 12.0;
    self.clipsToBounds = YES;
    
    // 顶部工具栏
    _toolbarView = [[UIView alloc] init];
    _toolbarView.backgroundColor = [UIColor systemBackgroundColor];
    [self addSubview:_toolbarView];
    
    // 复制按钮
    _cpHtmlButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cpHtmlButton setTitle:@"复制" forState:UIControlStateNormal];
    [_cpHtmlButton addTarget:self action:@selector(onCopyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_toolbarView addSubview:_cpHtmlButton];
    
    // 粘贴按钮
    _pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_pasteButton setTitle:@"粘贴" forState:UIControlStateNormal];
    [_pasteButton addTarget:self action:@selector(onPasteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_toolbarView addSubview:_pasteButton];
    
    // 清除按钮
    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_clearButton setTitle:@"清除" forState:UIControlStateNormal];
    [_clearButton addTarget:self action:@selector(onClearButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_toolbarView addSubview:_clearButton];
    
    //右上角提示
    
    _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_rightButton setTitle:@"HTML" forState:UIControlStateNormal];
    [_rightButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
    [_rightButton addTarget:self action:@selector(onRightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_toolbarView addSubview:_rightButton];
    
    // HTML代码文本框
    _codeTextView = [[UITextView alloc] init];
    _codeTextView.font = [UIFont fontWithName:@"Menlo" size:14];
    _codeTextView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    _codeTextView.delegate = self;
    _codeTextView.keyboardType = UIKeyboardTypeDefault;
    _codeTextView.returnKeyType = UIReturnKeyDefault;
    _codeTextView.scrollEnabled = YES;
    _codeTextView.editable = YES;
    _codeTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    _codeTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self addSubview:_codeTextView];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupConstraints {
    [self.toolbarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.equalTo(@44);
    }];
    
    [self.cpHtmlButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.toolbarView).offset(16);
        make.centerY.equalTo(self.toolbarView);
    }];
    
    [self.pasteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cpHtmlButton.mas_right).offset(20);
        make.centerY.equalTo(self.toolbarView);
    }];
    
    [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.pasteButton.mas_right).offset(20);
        make.centerY.equalTo(self.toolbarView);
    }];
    [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.toolbarView.mas_right).offset(-20);
        make.centerY.equalTo(self.toolbarView);
    }];
    
    [self.codeTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.toolbarView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    }];
}

- (void)setHTMLCode:(NSString *)htmlCode {
    self.codeTextView.text = htmlCode;
}

- (NSString *)getHTMLCode {
    return self.codeTextView.text;
}

#pragma mark - Actions

- (void)onCopyButtonTapped:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.codeTextView.text;
    
    if ([self.delegate respondsToSelector:@selector(htmlCodeEditorView:didTapCopyButton:)]) {
        [self.delegate htmlCodeEditorView:self didTapCopyButton:sender];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"已复制到剪贴板" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)onPasteButtonTapped:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.string) {
        self.codeTextView.text = pasteboard.string;
    }
    
    if ([self.delegate respondsToSelector:@selector(htmlCodeEditorView:didTapPasteButton:)]) {
        [self.delegate htmlCodeEditorView:self didTapPasteButton:sender];
    }
}

- (void)onClearButtonTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认" message:@"确定要清除所有代码吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        self.codeTextView.text = @"";
        
        if ([self.delegate respondsToSelector:@selector(htmlCodeEditorView:didTapClearButton:)]) {
            [self.delegate htmlCodeEditorView:self didTapClearButton:sender];
        }
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)onRightButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(htmlCodeEditorView:didTapRightButton:)]) {
        [self.delegate htmlCodeEditorView:self didTapRightButton:sender];
    }
}


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(htmlCodeEditorViewDidChangeContent:)]) {
        [self.delegate htmlCodeEditorViewDidChangeContent:self];
    }
}

#pragma mark - Helper

- (UIViewController *)viewController {
    for (UIView *next = self.superview; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

@end
