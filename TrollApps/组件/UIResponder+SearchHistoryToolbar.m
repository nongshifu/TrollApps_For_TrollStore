#import "UIResponder+SearchHistoryToolbar.h"
#import <objc/runtime.h>

@implementation UIResponder (SearchHistoryToolbar)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换 UITextField 的方法
        [self safeSwizzleMethodForClass:[UITextField class]];
        // 交换 UITextView 的方法（修复 iOS 16 崩溃）
        [self safeSwizzleMethodForClass:[UITextView class]];
    });
}

/// 安全的方法交换逻辑：只针对目标类，不影响父类
+ (void)safeSwizzleMethodForClass:(Class)cls {
    SEL originalSelector = @selector(inputAccessoryView);
    SEL swizzledSelector = @selector(customInputAccessoryView);
    
    // 获取交换方法的实现
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
    if (!swizzledMethod) {
        NSLog(@"警告: 交换方法 %@ 不存在", NSStringFromSelector(swizzledSelector));
        return;
    }
    
    // 核心逻辑：尝试为目标类添加自定义实现，避免影响父类
    BOOL didAddMethod = class_addMethod(cls, originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        // 添加成功：说明目标类原来没有该方法（继承自父类），直接用自定义实现覆盖
        NSLog(@"为 %@ 添加自定义 inputAccessoryView 方法", NSStringFromClass(cls));
    } else {
        // 添加失败：说明目标类已有该方法，安全交换
        Method originalMethod = class_getInstanceMethod(cls, originalSelector);
        if (originalMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
            NSLog(@"交换 %@ 的 inputAccessoryView 方法", NSStringFromClass(cls));
        }
    }
}

- (UIView *)customInputAccessoryView {
    // 1. 先调用原始方法（兼容系统原有实现）
    // 注意：方法交换后，customInputAccessoryView 实际指向原始实现
    UIView *originalAccessoryView = [self customInputAccessoryView];
    
    // 2. 如果系统已有 accessoryView，直接返回（避免覆盖系统或其他库的设置）
    if (originalAccessoryView) {
        return originalAccessoryView;
    }
    
    // 3. 仅对 UITextField 和 UITextView 返回自定义工具栏
    if (![self isKindOfClass:[UITextField class]] && ![self isKindOfClass:[UITextView class]]) {
        return nil; // 非目标控件，返回 nil
    }
    
    // 4. 创建自定义工具栏
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 44)];
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.translucent = YES;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(resignFirstResponder)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    
    toolbar.items = @[flexibleSpace, doneButton];
    [toolbar sizeToFit];
    
    return toolbar;
}

@end
