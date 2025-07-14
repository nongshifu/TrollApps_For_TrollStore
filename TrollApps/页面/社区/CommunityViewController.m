//
//  CommunityViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/6/30.
//

#import "CommunityViewController.h"
#import "NewProfileViewController.h"

@interface CommunityViewController ()

@end

@implementation CommunityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.zx_navBar.zx_lineViewHeight = 0;
    self.zx_navBarBackgroundColorAlpha = 0.5;
}


- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    
    
}


// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    [self setupNavigationBar];
    
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self updateViewConstraints];
    
    [self setupNavigationBar];
    
    
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 检查界面模式是否发生变化
    [self setupNavigationBar];
}

//更新UI颜色 底部顶部导航
- (void)setupNavigationBar {
    NSLog(@"监听主题变化updateTabBarColor");
//    self.zx_navTitleLabel.textAlignment = NSTextAlignmentLeft;
    //设置分割线
    self.zx_navBar.zx_lineViewHeight = 0.5;
    //分割线透明度
    self.zx_navBar.zx_lineView.alpha = 0.5;
    //移除渐变
    [self zx_removeNavGradientBac];
    //添加悬浮球
    [self.zx_navBar addColorBallsWithCount:10 ballradius:150 minDuration:30 maxDuration:60 UIBlurEffectStyle:UIBlurEffectStyleProminent UIBlurEffectAlpha:0.99 ballalpha:0.5];
    [self zx_setMultiTitle: @"社区广场" subTitle: @"有求必应，有需求 大牛帮你解决！" subTitleFont:[UIFont boldSystemFontOfSize:10] subTitleTextColor:[UIColor randomColorWithAlpha:1]];
    
    UIImage *image = [NewProfileViewController sharedInstance].userInfo.avatarImage;
    if(!image){
        image = [UIImage systemImageNamed:@"applelogo"];
    }
    CGFloat width = 30;
    image = [image resizedImageToSize:CGSizeMake(width, width) contentMode:UIViewContentModeScaleAspectFit];
    NSLog(@"读取头像:%@",image);
    [self zx_setLeftBtnWithImg:image clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        
        
    }];
   
    
    self.zx_navLeftBtn.zx_fixWidth = width;
    self.zx_navLeftBtn.zx_fixHeight = width;
    self.zx_navLeftBtn.zx_setCornerRadiusRounded = width/2;
    self.zx_navLeftBtn.imageView.image = image;
    
    [self zx_setRightBtnWithImg:[UIImage systemImageNamed:@"magnifyingglass.circle"] clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        
    }];
    
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    self.navigationController.navigationBarHidden = YES;
    
    // 显示 TabBar（带动画）
    [UIView transitionWithView:self.tabBarController.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.tabBarController.tabBar.hidden = NO;
    }completion:nil];
    
    
    
}
@end
