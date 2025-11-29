#import "BubbleTipManager.h"
#import <Masonry/Masonry.h>

// 气泡内部的提示视图（仅显示文本）
@interface BubbleContentViewController : UIViewController
@property (nonatomic, copy) NSString *tipText;
@end

@implementation BubbleContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.view.layer.cornerRadius = 3; // 气泡圆角（系统默认也有，可自定义）
    self.view.clipsToBounds = YES;
    
    // 提示文本label
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = self.tipText;
    textLabel.font = [UIFont systemFontOfSize:14];
    textLabel.textColor = [UIColor labelColor];
    textLabel.numberOfLines = 0; // 支持多行文本
    textLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:textLabel];
    
    // 文本约束（内边距10）
    [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(0, 0, 10, 0));
    }];
    
    // 禁止点击气泡内部关闭（仅自动隐藏）
    self.view.userInteractionEnabled = NO;
}

// 自适应气泡大小（根据文本长度）
- (CGSize)preferredContentSize {
    CGSize maxSize = CGSizeMake(300, CGFLOAT_MAX); // 最大宽度200，高度自适应
    CGRect textRect = [self.tipText boundingRectWithSize:maxSize
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}
                                                context:nil];
    // 加上内边距（10*2）
    return CGSizeMake(MIN(textRect.size.width + 20, 300), textRect.size.height+20);
}

@end

@implementation BubbleTipManager

#pragma mark - 公开方法（原有）
+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC {
    // 调用新增方法，传入默认参数（3秒隐藏+自动方向）
    [self showBubbleTipWithText:text
                      targetView:targetView
                         superVC:superVC
                    dismissDelay:3.0
                   arrowDirection:UIPopoverArrowDirectionAny];
}

+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC
                 dismissDelay:(NSTimeInterval)dismissDelay {
    // 调用新增方法，传入默认方向
    [self showBubbleTipWithText:text
                      targetView:targetView
                         superVC:superVC
                    dismissDelay:dismissDelay
                   arrowDirection:UIPopoverArrowDirectionAny];
}

#pragma mark - 公开方法（新增：带箭头方向）
+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC
                arrowDirection:(UIPopoverArrowDirection)arrowDirection {
    // 调用核心方法，3秒隐藏
    [self showBubbleTipWithText:text
                      targetView:targetView
                         superVC:superVC
                    dismissDelay:3.0
                   arrowDirection:arrowDirection];
}

+ (void)showBubbleTipWithText:(NSString *)text
                   targetView:(UIView *)targetView
                      superVC:(UIViewController *)superVC
                 dismissDelay:(NSTimeInterval)dismissDelay
                arrowDirection:(UIPopoverArrowDirection)arrowDirection {
    // 合法性校验
    if (!text || !targetView || !superVC) return;
    
    // 处理无效方向（默认转为自动适配）
    UIPopoverArrowDirection validDirection = arrowDirection;
    if (validDirection == UIPopoverArrowDirectionUnknown || validDirection > UIPopoverArrowDirectionAny) {
        validDirection = UIPopoverArrowDirectionAny;
    }
    
    // 调用核心私有方法
    [self _showBubbleTipWithText:text
                        targetView:targetView
                           superVC:superVC
                      dismissDelay:dismissDelay
                     arrowDirection:validDirection];
}

#pragma mark - 核心私有方法（统一处理所有逻辑）
+ (void)_showBubbleTipWithText:(NSString *)text
                     targetView:(UIView *)targetView
                        superVC:(UIViewController *)superVC
                   dismissDelay:(NSTimeInterval)dismissDelay
                  arrowDirection:(UIPopoverArrowDirection)arrowDirection {
    // 1. 创建气泡内容控制器（仅显示文本）
    BubbleContentViewController *contentVC = [[BubbleContentViewController alloc] init];
    contentVC.tipText = text;
    
    // 2. 配置气泡样式（核心：UIPopoverPresentationController）
    contentVC.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popoverVC = contentVC.popoverPresentationController;
    popoverVC.sourceView = targetView; // 气泡箭头指向的目标视图
    // 优化：箭头精准指向目标视图中心（而非整个bounds）
    popoverVC.sourceRect = CGRectMake(targetView.bounds.size.width/2, 0, 1, 1);
    popoverVC.permittedArrowDirections = arrowDirection; // 自定义箭头方向
    popoverVC.backgroundColor = [UIColor systemBackgroundColor]; // 气泡背景色（与内容视图一致）
    popoverVC.delegate = (id<UIPopoverPresentationControllerDelegate>)superVC;
    
    // 3. 禁止点击气泡外部关闭（仅自动隐藏）
    popoverVC.passthroughViews = [NSArray arrayWithObjects:superVC.view, nil];
    
    // 4. 弹出气泡
    [superVC presentViewController:contentVC animated:YES completion:nil];
    
    // 5. 延时自动隐藏
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dismissDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (contentVC.presentedViewController == nil && contentVC.isBeingPresented == NO) {
            [contentVC dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

@end

// 适配iPhone：确保UIPopover以气泡形式显示（而非全屏）
@implementation UIViewController (BubblePopoverDelegate)

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    // 强制iPhone上也以Popover形式显示（默认iPhone会变成全屏）
    return UIModalPresentationNone;
}

@end
