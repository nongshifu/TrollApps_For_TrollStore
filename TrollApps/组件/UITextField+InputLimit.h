//
//  UITextField+InputLimit.h
//  TrollApps
//
//  Created by 十三哥 on 2025/7/12.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN
@interface UITextField (InputLimit)
+ (instancetype)textFieldWithMaxLength:(NSInteger)maxLength;
/// 最大输入长度（0 = 不限制）
@property (nonatomic, assign) NSInteger maxInputLength;

@end

NS_ASSUME_NONNULL_END
