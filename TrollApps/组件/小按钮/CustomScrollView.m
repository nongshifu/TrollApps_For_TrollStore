//
//  CustomScrollView.m
//  SoulChat
//
//  Created by 十三哥 on 2024/11/7.
//

#import "CustomScrollView.h"

@implementation CustomScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 初始化属性默认值
        self.buttonBcornerRadius = 0;
        self.space = 0;
        self.autoLineBreak = NO;
        
        self.refreshHeight = 0;
        self.hidesScrollIndicator = YES;
        self.subviewArray = [NSMutableArray array];
        
        // 设置滚动条隐藏
        self.showsHorizontalScrollIndicator =!self.hidesScrollIndicator;
        self.showsVerticalScrollIndicator =!self.hidesScrollIndicator;
        self.userInteractionEnabled =YES;
       
    }
    return self;
}

- (void)addSubview:(UIView *)view {
    [self.subviewArray addObject:view];
    // 将子视图添加到滚动视图中
    [super addSubview:view];
    
    
    // 设置子视图的圆角
    if(self.buttonBcornerRadius>0){
        view.layer.cornerRadius = self.buttonBcornerRadius;
        view.layer.masksToBounds = YES;
    }
    view.tag = self.subviewArray.count-1;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(Tapped:)];
    view.userInteractionEnabled = YES;
    tapGesture.delegate = self; // 设置代理
    [view addGestureRecognizer:tapGesture];
   
    // 调用刷新视图布局方法
    [self refreshViewLayout];
    
}
- (void)addSubview:(UIView *)view isTap:(BOOL)isTap{
    [self.subviewArray addObject:view];
    // 将子视图添加到滚动视图中
    [super addSubview:view];
    
    
    // 设置子视图的圆角
    if(self.buttonBcornerRadius>0){
        view.layer.cornerRadius = self.buttonBcornerRadius;
        view.layer.masksToBounds = YES;
    }
    view.tag = self.subviewArray.count;
    if(isTap){
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(Tapped:)];
        view.userInteractionEnabled = YES;
        tapGesture.delegate = self; // 设置代理
        [view addGestureRecognizer:tapGesture];
    }
    // 调用刷新视图布局方法
    [self refreshViewLayout];
    
}
- (void)Tapped:(UITapGestureRecognizer *)gestureRecognizer {
    NSInteger tag = gestureRecognizer.view.tag;
    // 在这里处理标签被点击的逻辑
    NSLog(@"滚动视图点击了下标: %ld  gestureRecognizers.count:%ld", tag,gestureRecognizer.view.gestureRecognizers.count);
    // 调用代理方法
    if ([self.MyScrollViewdelegate respondsToSelector:@selector(myScrollView:didTapAtIndex:)]) {
        [self.MyScrollViewdelegate myScrollView:gestureRecognizer.view didTapAtIndex:tag];
    }
    // 同时触发子视图的点击事件 双击 长安 拖动等
    
    
}
#pragma mark - UIGestureRecognizerDelegate

// 允许多个手势同时识别
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 在这里可以添加更多的逻辑来决定是否允许手势同时识别，例如根据 `otherGestureRecognizer` 的类型
    return YES;
}
- (void)removeSubview:(UIView *)view {
    [self.subviewArray addObject:view];
    [super removeFromSuperview];
    // 调用刷新视图布局方法
    [self refreshViewLayout];
}

- (void)refreshViewLayoutWithCompletion:(void (^)(CGFloat height))completion {
    [self refreshViewLayout];
    if (completion) {
        completion(self.refreshHeight);
    }

}

- (void)refreshViewLayout {
    CGFloat finalHeight = 0;
    CGFloat xOffset = 0;
    CGFloat yOffset = 0;
    CGFloat maxWidth = self.frame.size.width;
    CGFloat currentRowWidth = 0;
    CGFloat ErrorValue = 20; // 容错值

    for (int i = 0; i < self.subviewArray.count; i++) {
        UIView *subview = self.subviewArray[i];
        CGFloat subviewWidth = subview.frame.size.width;
        CGFloat subviewHeight = subview.frame.size.height;

        // 取最大的子视图高度为父视图高度
        if(!self.autoLineBreak){
            finalHeight = MAX(finalHeight, subviewHeight);
        }
        

        // 判断是否需要换行
        if (self.autoLineBreak && currentRowWidth + subviewWidth + self.space + ErrorValue > maxWidth ) {
            // 换行
            xOffset = 0;
            yOffset += finalHeight + self.space; // 使用 finalHeight 而非 subviewHeight
            currentRowWidth = 0;
            finalHeight = subviewHeight; // 更新为新行的子视图高度
        }

        // 设置子视图的位置
        subview.frame = CGRectMake(xOffset, yOffset, subviewWidth, subviewHeight);

        // 更新当前行的宽度
        currentRowWidth += subviewWidth + self.space;
        xOffset += subviewWidth + self.space;
    }

    // 更新滚动视图的内容大小
    if (self.autoLineBreak) {
        self.refreshHeight = yOffset + finalHeight; // 计算最终高度
        self.contentSize = CGSizeMake(maxWidth, self.refreshHeight);
    } else {
        self.refreshHeight = finalHeight;
        self.contentSize = CGSizeMake(xOffset, self.frame.size.height);
    }
}

- (CGFloat)getHeight {
    // 正确的做法是等待动画完成后返回获取到的最终高度值
    return self.refreshHeight;
}

@end
