#import "UIResponder+DoneButton.h"
#import <objc/runtime.h>

@implementation UIResponder (DoneButton)

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
    // 获取原始方法
    SEL originalSelector = @selector(inputAccessoryView);
    SEL swizzledSelector = @selector(customInputAccessoryView);
    
    // 确保两个方法都存在
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    if (!originalMethod || !swizzledMethod) {
        NSLog(@"警告: %@ 类缺少 inputAccessoryView 或 customInputAccessoryView 方法", NSStringFromClass(cls));
        return;
    }
    
    // 如果类没有实现原始方法（从父类继承），需要先添加方法
    BOOL didAddMethod = class_addMethod(
        cls,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    );
    
    if (didAddMethod) {
        // 添加成功，替换父类实现
        class_replaceMethod(
            cls,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        );
    } else {
        // 类已实现该方法，直接交换
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (UIToolbar *)customInputAccessoryView {
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
