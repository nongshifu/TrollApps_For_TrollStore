//
//  CommentInputView.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/15.
//

#import <UIKit/UIKit.h>

@protocol CommentInputViewDelegate <NSObject>
/// 发送评论回调
- (void)commentInputViewDidSendComment:(NSString *)content;
@end

@interface CommentInputView : UIView

/// 代理
@property (nonatomic, weak) id<CommentInputViewDelegate> delegate;
/// 输入框文本
@property (nonatomic, copy, readonly) NSString *inputText;
/// 键盘高度（外部可设置）
@property (nonatomic, assign) CGFloat keyboardHeight;
/// 键盘是否显示
@property (nonatomic, assign) BOOL keyboardIsShow;

/// 初始化方法
- (instancetype)initWithOriginalHeight:(CGFloat)originalHeight expandedHeight:(CGFloat)expandedHeight;

/// 清空输入框
- (void)clearInputText;


/// 输入框
@property (nonatomic, strong) UITextView *textView;
/// 提示文字
@property (nonatomic, strong) UILabel *textPromptLabel;
/// 发送按钮
@property (nonatomic, strong) UIButton *sendButton;
/// 背景装饰视图
@property (nonatomic, strong) UIView *backgroundView;

/// 原始高度
@property (nonatomic, assign) CGFloat originalHeight;
/// 展开高度
@property (nonatomic, assign) CGFloat expandedHeight;

@end
