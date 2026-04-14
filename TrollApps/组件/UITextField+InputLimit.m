//
//  UIImage+Extensions.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/12.
//
#import "UITextField+InputLimit.h"
#import <objc/runtime.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation UITextField (InputLimit)

static const char *kMaxInputLengthKey = "maxInputLength";

// 在分类里加一个工厂方法
+ (instancetype)textFieldWithMaxLength:(NSInteger)maxLength {
    UITextField *tf = [[UITextField alloc] init];
    tf.maxInputLength = maxLength;
    return tf;
}
- (void)setMaxInputLength:(NSInteger)maxInputLength {
    objc_setAssociatedObject(self, kMaxInputLengthKey, @(maxInputLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 监听输入变化
    if (maxInputLength > 0) {
        [self addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    } else {
        [self removeTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
}

- (NSInteger)maxInputLength {
    return [objc_getAssociatedObject(self, kMaxInputLengthKey) integerValue];
}

/// 输入框文字变化监听（自动限制长度，完美支持中文输入）
- (void)textFieldTextDidChange:(UITextField *)textField {
    NSInteger maxLength = self.maxInputLength;
    if (maxLength <= 0) return;
    
    // 处理中文输入法（未确认的拼音不计算长度）
    UITextRange *selectedRange = textField.markedTextRange;
    if (selectedRange && selectedRange.start != selectedRange.end) {
        return;
    }
    
    // 截取文字
    NSString *text = textField.text;
    if (text.length >= maxLength) {
        textField.text = [text substringToIndex:maxLength];
        // 2. ✅ 触发系统轻振动反馈（核心新增）
//        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        // 创建UIImpactFeedbackGenerator对象
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
        // 准备触发震动
        [generator prepare];
        
        // 触发震动
        [generator impactOccurred];
        // 释放UIImpactFeedbackGenerator对象
        generator = nil;
    }
}

@end
