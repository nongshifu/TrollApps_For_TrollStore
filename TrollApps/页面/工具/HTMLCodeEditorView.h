//
//  HTMLCodeEditorView.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HTMLCodeEditorView;

@protocol HTMLCodeEditorViewDelegate <NSObject>

@optional
- (void)htmlCodeEditorViewDidChangeContent:(id)editorView;
- (void)htmlCodeEditorView:(HTMLCodeEditorView *)editorView didTapCopyButton:(UIButton *)button;
- (void)htmlCodeEditorView:(HTMLCodeEditorView *)editorView didTapPasteButton:(UIButton *)button;
- (void)htmlCodeEditorView:(HTMLCodeEditorView *)editorView didTapClearButton:(UIButton *)button;
- (void)htmlCodeEditorView:(HTMLCodeEditorView *)editorView didTapRightButton:(UIButton *)button;
@end

@interface HTMLCodeEditorView : UIView

@property (nonatomic, weak) id<HTMLCodeEditorViewDelegate> delegate;

- (void)setHTMLCode:(NSString *)htmlCode;
- (NSString *)getHTMLCode;

@property (nonatomic, strong) UIButton *pasteButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *cpHtmlButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UITextView *codeTextView;

@end

NS_ASSUME_NONNULL_END
