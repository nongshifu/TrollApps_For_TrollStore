//
//  HTMLCodeEditorView.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol HTMLCodeEditorViewDelegate <NSObject>
@optional
- (void)htmlCodeEditorViewDidChangeContent:(id)editorView;
@end

@interface HTMLCodeEditorView : UIView

@property (nonatomic, weak) id<HTMLCodeEditorViewDelegate> delegate;

- (void)setHTMLCode:(NSString *)htmlCode;
- (NSString *)getHTMLCode;
@property (nonatomic, strong) UITextView *codeTextView;

@end

NS_ASSUME_NONNULL_END
