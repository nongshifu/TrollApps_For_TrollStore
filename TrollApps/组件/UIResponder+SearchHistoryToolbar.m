#import "UIResponder+SearchHistoryToolbar.h"
#import <objc/runtime.h>


@implementation UIResponder (SearchHistoryToolbar)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换UITextField的方法
        [self swizzleMethodForClass:[UITextField class]];
        
        // 交换UITextView的方法
        [self swizzleMethodForClass:[UITextView class]];
    });
}

+ (void)swizzleMethodForClass:(Class)cls {
    SEL originalSelector = @selector(inputAccessoryView);
    SEL swizzledSelector = @selector(customInputAccessoryView);
    
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
    
    if (!originalMethod || !swizzledMethod) {
        NSLog(@"警告: %@ 类缺少 inputAccessoryView 方法", NSStringFromClass(cls));
        return;
    }
    
    // 关键：检查 originalMethod 是否属于 cls 自身（而非父类继承）
    if (class_getInstanceMethod(object_getClass(cls), originalSelector) != originalMethod) {
        NSLog(@"跳过 %@：inputAccessoryView 方法来自父类", NSStringFromClass(cls));
        return;
    }
    
    // 直接交换（仅当 cls 自身实现了该方法时）
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (UIToolbar *)customInputAccessoryView {
    // 仅对 UITextField 和 UITextView 返回自定义工具栏，其他控件返回原始实现
    if (![self isKindOfClass:[UITextField class]] && ![self isKindOfClass:[UITextView class]]) {
        // 调用原始方法（注意：方法交换后，customInputAccessoryView 实际指向原始实现）
        return [self customInputAccessoryView];
    }
    // 获取屏幕宽度（适配不同设备）
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    // 使用屏幕宽度创建工具条
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
