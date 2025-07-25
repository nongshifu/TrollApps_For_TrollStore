//
//  InjectMainController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//

#import "InjectMainController.h"

#import "AppListController.h"
#import "InjectionHistoryController.h"
#import "DylibHistoryController.h"


@interface InjectMainController ()
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *refreshBtn;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tabButtons;
@property (nonatomic, strong) AppListController *appListVC;
@property (nonatomic, strong) InjectionHistoryController *historyVC;
@property (nonatomic, strong) DylibHistoryController *dylibVC;
@end

@implementation InjectMainController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.tabButtons = [NSMutableArray array];
    [self setupNavBar];
    [self setupTabBar];
    [self setupChildControllers];
    [self switchToController:0]; // 默认显示APP列表
}

#pragma mark - 导航栏
- (void)setupNavBar {
    self.navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
    self.navBar.backgroundColor = [UIColor systemBlueColor];
    [self.view addSubview:self.navBar];
    
    // 标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 20, self.view.bounds.size.width - 160, 44)];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.text = @"动态库注入工具";
    [self.navBar addSubview:self.titleLabel];
    
    // 刷新按钮
    self.refreshBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshBtn.frame = CGRectMake(15, 20, 44, 44);
    [self.refreshBtn setImage:[UIImage systemImageNamed:@"arrow.clockwise"] forState:UIControlStateNormal];
    self.refreshBtn.tintColor = [UIColor whiteColor];
    [self.refreshBtn addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:self.refreshBtn];
    
    // 关闭按钮
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeBtn.frame = CGRectMake(self.view.bounds.size.width - 59, 20, 44, 44);
    [self.closeBtn setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    self.closeBtn.tintColor = [UIColor whiteColor];
    [self.closeBtn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.navBar addSubview:self.closeBtn];
}

#pragma mark - 底部标签栏
- (void)setupTabBar {
    self.tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 50)];
    self.tabBar.backgroundColor = [UIColor whiteColor];
    self.tabBar.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.tabBar.layer.borderWidth = 0.5;
    [self.view addSubview:self.tabBar];
    
    NSArray *titles = @[@"应用列表", @"注入历史", @"Dylib管理"];
    self.tabButtons = [NSMutableArray array];
    
    CGFloat btnWidth = self.view.bounds.size.width / 3;
    for (int i = 0; i < 3; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(i * btnWidth, 0, btnWidth, 50);
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateSelected];
        btn.tag = i;
        [btn addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabBar addSubview:btn];
        [self.tabButtons addObject:btn];
    }
}

#pragma mark - 子控制器
- (void)setupChildControllers {
    self.appListVC = [[AppListController alloc] init];
    self.appListVC.selectedDylibURL =self.selectedDylibURL;
    
    self.historyVC = [[InjectionHistoryController alloc] init];
    self.dylibVC = [[DylibHistoryController alloc] init];
    
    
    // 传递Dylib选择回调（从Dylib列表选择后返回APP列表注入）
    __weak typeof(self) weakSelf = self;
    self.dylibVC.onDylibSelected = ^(NSURL *dylibURL) {
        weakSelf.appListVC.selectedDylibURL = dylibURL;
        [weakSelf switchToController:0]; // 切回APP列表
    };
    
    [self addChildViewController:self.appListVC];
    [self addChildViewController:self.historyVC];
    [self addChildViewController:self.dylibVC];
}

- (void)switchToController:(NSInteger)index {
    // 更新按钮状态
    for (UIButton *btn in self.tabButtons) {
        btn.selected = (btn.tag == index);
    }
    
    // 切换显示的控制器
    UIViewController *targetVC = nil;
    switch (index) {
        case 0: targetVC = self.appListVC; break;
        case 1: targetVC = self.historyVC; break;
        case 2: targetVC = self.dylibVC; break;
    }
    
    for (UIViewController *child in self.childViewControllers) {
        child.view.hidden = (child != targetVC);
    }
    
    if (!targetVC.view.superview) {
        targetVC.view.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64 - 50);
        [self.view insertSubview:targetVC.view belowSubview:self.tabBar];
    }
}

#pragma mark - 事件处理
- (void)tabButtonTapped:(UIButton *)btn {
    [self switchToController:btn.tag];
}

- (void)refreshAction {
    // 刷新当前页面（根据当前显示的控制器刷新）
    if (self.tabButtons[0].selected) {
        [self.appListVC refreshAppList];
    } else if (self.tabButtons[1].selected) {
        [self.historyVC refreshHistory];
    } else if (self.tabButtons[2].selected) {
        [self.dylibVC refreshDylibList];
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取手势的位置
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    if (CGRectContainsPoint(self.appListVC.view.frame, loc) || CGRectContainsPoint(self.historyVC.view.frame, loc) || CGRectContainsPoint(self.dylibVC.view.frame, loc)) {
        return NO;
    }
    

    // 默认返回 YES，允许拖拽
    return YES;
}

@end
