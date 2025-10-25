//
//  MyTabBarController.m
//  CustomTabbarViewController
//
//  Created by duanshengwu on 2019/7/11.
//  Copyright © 2019 D-James. All rights reserved.
//


#import "MyTabBarController.h"
#import "AppsViewController.h"
#import "ToolStoreListViewController.h"
#import "CommunityViewController.h"
#import "PublishAppViewController.h"
#import "DemoBaseNavigationController.h"
#import "NewToolViewController.h"
#import "HelpViewController.h"
#import "EditUserProfileViewController.h"
#import "config.h"
#import "NewProfileViewController.h"
#import "ChatListViewController.h"
#import "UserProfileViewController.h"
#import "loadData.h"

@interface MyTabBarController ()<UITabBarControllerDelegate>
@property (nonatomic, strong) UIView *backageView;
@property (nonatomic, strong) UIImageView *circleView;
@property (nonatomic, strong) UIButton *centerButton; // 添加中间按钮
@property (nonatomic, assign) CGFloat yOffset; // Y偏移
@property (nonatomic, assign) NSInteger vCselectedIndex;
@end

@implementation MyTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self; // 设置代理
    // Do any additional setup after loading the view.
    [self setupTabBarItems];
    // 创建中间凸起按钮
    [self createCenterButton];
    // 创建并添加渐变色视图
    self.backageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWidth, 200)];
    self.backageView.backgroundColor = [UIColor systemBackgroundColor];
    self.backageView.userInteractionEnabled = YES;
    [self.tabBar insertSubview:self.backageView atIndex:0];
    
    
    self.circleView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -10, kWidth, 300)];
    
    [self.tabBar insertSubview:self.circleView atIndex:0];
    
    // 加载图片
    UIImage *image = [UIImage imageNamed:@"tabBar_background"];
    UIImage *newImage = [image imageWithTintColor:[UIColor systemBackgroundColor]];
    // 设置不拉伸区域
    CGFloat top = 20;
    CGFloat left = 0;
    CGFloat bottom = 0;
    CGFloat right = 0;
    
    // 拉伸图片
    UIImage *bgImage = [newImage resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right) resizingMode:UIImageResizingModeStretch];
    self.circleView.image =bgImage;
    [self updateTabBarColor];
    
    
}

// 创建中间按钮
- (void)createCenterButton {
    self.yOffset = 20;
    CGFloat buttonWidth = 45; // 增大按钮尺寸
    
    // 1. 计算位置（第三个按钮位置）
    NSInteger itemCount = self.viewControllers.count;
    CGFloat itemWidth = self.tabBar.frame.size.width / itemCount;
    CGFloat centerX = itemWidth * 2 + itemWidth / 2; // 第三个位置的中心
    
    // 2. 屏蔽中间位置的默认按钮
    [self disableMiddleTabBarButton];
    
    // 3. 创建凸起按钮
    self.centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.centerButton.frame = CGRectMake(0, 0, buttonWidth, buttonWidth);
    self.centerButton.center = CGPointMake(centerX, self.tabBar.frame.size.height/2 - self.yOffset); // 上移20点
    
    // 4. 按钮样式（圆形+阴影）
    self.centerButton.backgroundColor = [UIColor colorWithHexString:@"#a6b3f2"];
    self.centerButton.layer.cornerRadius = buttonWidth/2;
    self.centerButton.layer.shadowColor = [UIColor labelColor].CGColor;
    self.centerButton.layer.shadowOffset = CGSizeMake(0, -0.1);
    self.centerButton.layer.shadowOpacity = 0.5;
    self.centerButton.layer.shadowRadius = 0.5;
    
    // 5. 添加图标 - 使用模板模式并调整图标大小
    UIImage *icon = [UIImage systemImageNamed:@"plus"];
    icon = [icon imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightBold]];
    [self.centerButton setImage:icon forState:UIControlStateNormal];
    self.centerButton.tintColor = [UIColor whiteColor];
    
    // 6. 添加点击事件
    [self.centerButton addTarget:self action:@selector(centerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 7. 添加到tabBar
    [self.tabBar addSubview:self.centerButton];
    
    
    // 8. 添加心跳动画
    [self addHeartbeatAnimationToButton:self.centerButton];
}

// 禁用中间的TabBar按钮
- (void)disableMiddleTabBarButton {
    // 找出所有UITabBarButton类型的子视图
    NSMutableArray<UIView *> *tabBarButtons = [NSMutableArray array];
    for (UIView *view in self.tabBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            [tabBarButtons addObject:view];
        }
    }
    
    // 禁用中间的按钮（索引为2）
    if (tabBarButtons.count > 2) {
        UIView *middleButton = tabBarButtons[2];
        middleButton.userInteractionEnabled = NO;
        
        // 隐藏中间按钮的内容
        for (UIView *subview in middleButton.subviews) {
            subview.alpha = 0;
        }
    }
}

// 为按钮添加心跳动画
- (void)addHeartbeatAnimationToButton:(UIButton *)button {
    // 优化图标渲染质量
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerTopEdge | kCALayerBottomEdge;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    animation.values = @[@1.0, @1.05, @1.0];
    animation.keyTimes = @[@0.0, @0.5, @1.0];
    animation.duration = 1.0; // 动画持续时间
    animation.repeatCount = HUGE_VALF; // 无限循环
    
    // 设置动画的时间函数，使动画更自然
    animation.timingFunctions = @[
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
    ];
    
    [button.layer addAnimation:animation forKey:@"heartbeatAnimation"];
}

// 中间按钮点击事件
- (void)centerButtonTapped:(UIButton *)sender {
    NSLog(@"点击了发帖按钮");
    switch (self.vCselectedIndex) {
        case 0:{
            // 创建发帖视图控制器
            PublishAppViewController *publishVC = [[PublishAppViewController alloc] init];
            publishVC.title = @"发布内容";
            [self presentPanModal:publishVC];
            
        }
            return;
        case 1:{
            NewToolViewController *publishVC = [[NewToolViewController alloc] init];
            publishVC.title = @"发布工具";
            [self presentPanModal:publishVC];
        }
            return;
        case 2:{
            
        }
            
            return;
        case 3:{
            NSString *udid = [loadData sharedInstance].userModel.udid;
            if(!udid || udid.length<5)return;
            UserProfileViewController *publishVC = [[UserProfileViewController alloc] init];
            publishVC.user_udid = [loadData sharedInstance].userModel.udid;
            publishVC.title = @"我的关注";
            [self presentPanModal:publishVC];
        }
            
            return;
        case 4:{
            EditUserProfileViewController *publishVC = [[EditUserProfileViewController alloc] init];
            publishVC.title = @"修改用户资料";
            [self presentPanModal:publishVC];
        }
            
            return;
            
        default:
            break;
    }
    
    
    
}

// 调整布局方法（确保旋转屏幕后位置正确）
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 更新按钮位置
    [self updateCenterButtonPosition];
}

- (void)updateCenterButtonPosition {
    if (self.centerButton) {
        NSInteger itemCount = self.viewControllers.count;
        CGFloat itemWidth = self.tabBar.frame.size.width / itemCount;
        CGFloat centerX = itemWidth * 2 + itemWidth / 2;
        self.centerButton.center = CGPointMake(centerX, self.tabBar.frame.size.height/2 - self.yOffset);
    }
}

- (void)setupTabBarItems {
    // 创建三个内容控制器
    
    NSMutableArray *sideMenuControllers = [NSMutableArray array];
    [sideMenuControllers addObject:[self createSideMenuControllerWithVC:[AppsViewController new]
                                                                  title:@"Apps"
                                                              imageName:@"music.house"
                                                          selectedImage:@"music.house.fill"]
    ];
    [sideMenuControllers addObject:[self createSideMenuControllerWithVC:[ToolStoreListViewController new]
                                                                  title:@"工具"
                                                              imageName:@"t.circle"
                                                          selectedImage:@"t.circle.fill"]
    ];
    [sideMenuControllers addObject:[self createSideMenuControllerWithVC:[DemoBaseViewController new]
                                                                  title:@""
                                                              imageName:@""
                                                          selectedImage:@""]
    ];
    [sideMenuControllers addObject:[self createSideMenuControllerWithVC:[CommunityViewController new]
                                                                  title:@"广场"
                                                              imageName:@"message"
                                                          selectedImage:@"message.fill"]
    ];
    
    [sideMenuControllers addObject:[self createSideMenuControllerWithVC:[NewProfileViewController sharedInstance]
                                                                  title:@"我"
                                                              imageName:@"person.circle"
                                                          selectedImage:@"person.circle.fill"]
    ];
    
    self.viewControllers = sideMenuControllers;
}

- (LGSideMenuController *)createSideMenuControllerWithVC:(UIViewController *)vc
                                                   title:(NSString *)title
                                               imageName:(NSString *)imageName
                                           selectedImage:(NSString *)selectedImage{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    LGSideMenuController *sideMenuController = [[LGSideMenuController alloc] initWithRootViewController:nav leftViewController:nil rightViewController:nil];
    
    sideMenuController.tabBarItem.title = title;
    sideMenuController.tabBarItem.image = [UIImage systemImageNamed:imageName];
    sideMenuController.tabBarItem.selectedImage = [UIImage systemImageNamed:selectedImage];
    
    return sideMenuController;
}

// 实现代理方法
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    // 在这里处理点击事件
    self.vCselectedIndex = [tabBarController.viewControllers indexOfObject:viewController];
    NSLog(@"点击了VCselectedIndex: %ld", self.vCselectedIndex);
    // 添加图标 - 使用模板模式并调整图标大小
    NSArray *icons = @[
        @"plus",
        @"t.circle",
        @"plus",
        @"lightbulb",
        @"lasso",
    ];
    UIImage *icon = [UIImage systemImageNamed:icons[self.vCselectedIndex]];
    icon = [icon imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightBold]];
    [self.centerButton setImage:icon forState:UIControlStateNormal];
    
    
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 检查界面模式是否发生变化
    [self updateTabBarColor];
}

- (void)updateTabBarColor{
    NSArray *colos = @[
        [UIColor randomColorWithAlpha:1],
        [UIColor randomColorWithAlpha:0],
        [UIColor randomColorWithAlpha:1],
    ];
    [self.backageView setGradientBackgroundWithColors:colos alpha:0.2];
    
//    [self.backageView addColorBallsWithCount:5 ballradius:100 minDuration:50 maxDuration:100 UIBlurEffectStyle:UIBlurEffectStyleProminent UIBlurEffectAlpha:0.98 ballalpha:0.2];
    [self.tabBar addGlowEffectWithColor:[UIColor secondaryLabelColor] shadowOffset:CGSizeMake(0, -0.5) shadowOpacity:1 shadowRadius:2];
}
@end    
