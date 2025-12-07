//
//  FindFriendsViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/11/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//


#import "FindFriendsViewController.h"
#import "UserModel.h"
#import "UserModelCell.h"
#import "loadData.h"
#import "NewProfileViewController.h"
#import "MiniButtonView.h"
#import "UserProfileViewController.h"
#import "TTCHATViewController.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

#define FIND_TITLES_SAVE_KEY @"FIND_TITLES_SAVE_KEY"
#define KEYWORD_SAVE_KEY @"keyword_SAVE_KEY"



@interface FindFriendsViewController ()<UISearchResultsUpdating,UISearchBarDelegate,TemplateSectionControllerDelegate, MiniButtonViewDelegate>
@property (nonatomic, strong) NSString *keyword;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) NSInteger sort;
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器

@property (nonatomic, strong) MiniButtonView *miniButtonView;//历史搜索标签
@property (nonatomic, strong) NSMutableArray *searchTitles;//搜索数组

@property (nonatomic, strong) NSMutableArray *search_fields;

@end

@implementation FindFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.search_fields = [NSMutableArray array];
    
    // Do any additional setup after loading the view.
    //导航搜索
    [self setupNavigationBarWithSearch];
    //其他UI
    [self setupViews];
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    //读取数据
    [self loadDataWithPage:1];
    
    
}

#pragma mark - 初始化UI

- (void)setupViews{
    
    //默认
    self.title = @"发现好友";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
//    self.edgesForExtendedLayout = UIRectEdgeBottom | UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeTop;
    
    self.view.backgroundColor = [UIColor clearColor];
    
    //设置历史搜索
    NSArray *titles = [[NSUserDefaults standardUserDefaults] arrayForKey:FIND_TITLES_SAVE_KEY];
    self.searchTitles = [NSMutableArray arrayWithArray:titles];
    if(self.searchTitles.count == 0){
        [self.searchTitles addObject:@"历史搜索"];
    }
    
    self.miniButtonView = [MiniButtonView new];
    self.miniButtonView.buttonDelegate = self;
    self.miniButtonView.buttonBcornerRadius = 5;
    self.miniButtonView.buttonSpace = 10;
    self.miniButtonView.hidden = YES; // 初始隐藏历史搜索视图
    [self.view addSubview:self.miniButtonView];
    
    
    
}

- (void)setupNavigationBarWithSearch {
    // 初始化搜索相关数组
    self.zx_hideBaseNavBar = YES;
    self.zx_showSystemNavBar = YES;
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = YES;
    // 创建搜索控制器
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"输入搜索内容";

    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.returnKeyType = UIReturnKeySearch;
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *reset = [[UIBarButtonItem alloc] initWithTitle:@"重置" style:UIBarButtonItemStylePlain target:self action:@selector(resetTap:)];
    reset.tintColor = [UIColor labelColor];
    self.navigationItem.rightBarButtonItem = reset;
    
    // 配置导航项
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框

}

- (void)resetTap:(UIBarButtonItem*)item{
    self.keyword = @"";
    self.page = 1;
    self.searchController.searchBar.text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEYWORD_SAVE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self loadDataWithPage:1];
    
}

#pragma mark - 约束相关

//设置约束
- (void)setupViewConstraints{
    // 子视图顶部对齐导航栏底部（自动适配所有设备和模式）
    [self.collectionView removeFromSuperview];
    [self.view addSubview:self.collectionView];
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat topOffset = statusBarHeight + navBarHeight + 44;
    NSLog(@"statusBarHeight:%f  navBarHeight:%f",navBarHeight,topOffset);
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0); // 顶部偏移量
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    [self.miniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.collectionView.mas_top).offset(5); // 顶部偏移量
        make.width.mas_equalTo(kWidth - 80);
        make.height.mas_equalTo(40);
        make.centerX.equalTo(self.view).offset(-20);
    }];


}

//更新约束
- (void)updateViewConstraints{
    [super updateViewConstraints];
    CGFloat topOffset = self.miniButtonView.hidden?0:40;
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(topOffset); // 顶部偏移量
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    [self.miniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.collectionView.mas_top).offset(0); // 顶部偏移量
        make.width.mas_equalTo(kWidth - 80);
        make.height.mas_equalTo(30);
        make.centerX.equalTo(self.view).offset(-20);
    }];

    
}


#pragma mark - 辅助函数

// 辅助方法：判断当前控制器是否是模态弹出
- (BOOL)isModal {
    // 情况1：直接被present（如：[vc presentViewController:self animated:YES completion:nil]）
    if (self.presentingViewController != nil) {
        return YES;
    }
    
    // 情况2：被导航控制器包裹后，导航控制器被present（如：[vc presentViewController:nav animated:YES completion:nil]，而self是nav的根控制器）
    if (self.navigationController != nil &&
        self.navigationController.presentingViewController.presentedViewController == self.navigationController &&
        self.navigationController.viewControllers.firstObject == self) {
        return YES;
    }
    
    // 情况3：被其他容器控制器（如UIPageViewController）包裹后被present
    if (self.parentViewController != nil && self.parentViewController.presentingViewController != nil) {
        return YES;
    }
    
    return NO;
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page {
    [SVProgressHUD showWithStatus:nil];
    NSString *udid = [loadData sharedInstance].userModel.udid ? [loadData sharedInstance].userModel.udid :[[NewProfileViewController sharedInstance] getIDFV];
    
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"searchUser",
        @"sort":@(self.sort),
        @"keyword":keyword,
        @"pageSize":@(10),
        
        @"search_fields":self.search_fields,
        
        @"page":@(self.page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self endRefreshing];
                if(self.page <=1){
                    [self.dataSource removeAllObjects];
                }
                if(!jsonResult) {
                    NSLog(@"返回数据类型错误: %@", jsonResult);
                    [SVProgressHUD showErrorWithStatus:@"返回数据类型错误"];
                    [SVProgressHUD dismissWithDelay:2 completion:nil];
                    return;
                }
                
                NSLog(@"读取数据jsonResult: %@", jsonResult);
                NSInteger  code = [jsonResult[@"code"] intValue];
                NSString *message = jsonResult[@"msg"];
                
                if(code == 200){
                    NSDictionary * data = jsonResult[@"data"];
                    NSLog(@"读取用户列表:%@",data);
                    NSArray * list = data[@"list"];
                    if(list.count>0){
                        self.page+=1;
                    }
                    for (NSDictionary *dic in list) {
                        UserModel *model = [UserModel yy_modelWithDictionary:dic];
                        NSLog(@"读取用户user_id:%ld nickname:%@ avatar:%@",model.user_id,model.nickname,model.avatar);
                        [UserModel cacheUserModel:model];
                        [self.dataSource addObject:model];
                    }
                    [self refreshTable];
                   
                    
                    NSDictionary * pagination = data[@"pagination"];
                    NSInteger total = [pagination[@"total"] intValue];
                    NSLog(@"共:%ld个APP",total);
                    BOOL hasMore = [pagination[@"hasMore"] boolValue];
                    NSLog(@"noMoreData:%d",hasMore);
                    if(list.count >0){
                        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"搜索到%ld个结果",list.count]];
                    }else{
                        [self handleNoMoreData];
                        [SVProgressHUD showImage:[UIImage systemImageNamed:@"smiley"] status:@"翻到底啦"];
                    }
                    
                    [SVProgressHUD dismissWithDelay:2];
                    
                    
                }else{
                    NSLog(@"数据搜索失败出错: %@", message);
                    [SVProgressHUD showErrorWithStatus:message];
                    [SVProgressHUD dismissWithDelay:2 completion:^{
                        return;
                    }];
                }
                
            });
        } failure:^(NSError *error) {
            NSLog(@"异步请求Error: %@", error);
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"请求错误\n%@",error]];
            [SVProgressHUD dismissWithDelay:2 completion:nil];
        }];
    
    
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[UserModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[UserModelCell class] modelClass:[UserModel class] delegate:self edgeInsets:UIEdgeInsetsMake(10, 10, 0, 10) usingCacheHeight:NO];
    }
    return nil;
}

#pragma mark - UISearchBarDelegate（补充状态监听）
// 1. 搜索框开始编辑（用户点击搜索框，进入编辑状态）→ 显示历史搜索视图
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // 显示历史搜索视图，并刷新历史搜索数据
    self.miniButtonView.hidden = NO;
    [self.miniButtonView updateButtonsWithStrings:self.searchTitles icons:nil];
    [self updateViewConstraints];
    // 刷新约束（确保视图位置正确）
    [self.view layoutIfNeeded];
}

// 2. 搜索框结束编辑（用户收起键盘、点击页面其他区域）→ 隐藏历史搜索视图
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.miniButtonView.hidden = NO;
    [self updateViewConstraints];
}

// 3. 点击搜索框“取消”按钮 → 隐藏历史搜索视图（原有逻辑基础上补充）
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder]; // 收起键盘
    searchBar.text = @""; // 清空输入框
    self.keyword = @"";   // 清空关键词
    self.page = 1;
    // 补充：隐藏历史搜索视图
    self.miniButtonView.hidden = YES;
    [self updateViewConstraints];
    // 恢复原始会话数据（原有逻辑保留）
    [self loadDataWithPage:1];
}

// 4. 点击搜索按钮（键盘Done键），执行搜索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self performSearchWithText:searchBar.text]; // 调用完善后的搜索方法
    [self updateViewConstraints];
}

#pragma mark - UISearchResultsUpdating 代理（搜索防抖）
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    NSLog(@"输入过程1：%@", searchText);
    if(![searchText isEqualToString:self.keyword]) return;
    
    // 停止之前的定时器，避免重复触发
    [self.searchTimer invalidate];
    
    // 0.5秒后执行搜索（防抖）
//    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
//                                                       target:self
//                                                     selector:@selector(executeDebounceSearch:)
//                                                     userInfo:searchText
//                                                      repeats:NO];
}

// 防抖搜索执行方法
- (void)executeDebounceSearch:(NSTimer *)timer {
    NSString *searchText = timer.userInfo;
    [self performSearchWithText:searchText];
}

#pragma mark - 执行搜索请求（表层+深层历史消息）

- (void)performSearchWithText:(NSString *)text {
    self.keyword = text;
    [[NSUserDefaults standardUserDefaults] setObject:text forKey:KEYWORD_SAVE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [SVProgressHUD showWithStatus:@"搜索中"];
    
    
    // 1. 关键词为空时，恢复原始数据并返回
    if (self.keyword.length == 0) {
        
        // 关键补充：关闭搜索框键盘（需在主线程执行）
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismissWithDelay:0.5];
            [self.searchController resignFirstResponder];
        });
        [self loadDataWithPage:1];
        return;
    }
    
    
    
    // 1. 判断关键词非空 + 未存在于数组中
    if (self.keyword && self.keyword.length > 0 ) {
        
        [self loadDataWithPage:self.page];
    }
    // 1. 判断关键词非空 + 未存在于数组中
    if (![self.searchTitles containsObject:self.keyword]) {
        // 2. 不存在则添加
        [self.searchTitles insertObject:self.keyword atIndex:1];
        [self.miniButtonView updateButtonsWithStrings:self.searchTitles icons:nil];
        // 3. 储存
        [[NSUserDefaults standardUserDefaults] setObject:self.searchTitles forKey:FIND_TITLES_SAVE_KEY];
        
    }
    
    [self updateViewConstraints];
   
    
    [SVProgressHUD dismissWithDelay:0.5];
}

// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    
    if([model isKindOfClass:[UserModel class]]){
        UserModel *user = (UserModel *)model;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"输入信息" message:@"请输入内容" preferredStyle:UIAlertControllerStyleActionSheet];
        
        // 添加确定按钮
        UIAlertAction *openShow = [UIAlertAction actionWithTitle:@"查看主页" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UserProfileViewController *vc = [UserProfileViewController new];
            vc.user_udid = user.udid;
            [self presentPanModal:vc];
           
        }];
        [alertController addAction:openShow];
        // 添加确定按钮
        UIAlertAction *chat = [UIAlertAction actionWithTitle:@"私信聊天" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            TTCHATViewController *conversationVC = [[TTCHATViewController alloc] initWithConversationType:ConversationType_PRIVATE targetId:user.udid];
            conversationVC.targetId = user.udid;
            conversationVC.title = user.nickname;
           
            conversationVC.modalPresentationStyle = UIModalPresentationFullScreen;
            
//            [self.navigationController pushViewController:conversationVC animated:YES];
            
            // 2. 为它创建一个新的 UINavigationController
            UINavigationController *chatNavController = [[UINavigationController alloc] initWithRootViewController:conversationVC];

            // 3. 将新的导航控制器推入当前导航栈
//            [self.navigationController pushViewController:chatNavController animated:YES];
            chatNavController.modalPresentationStyle = UIModalPresentationFullScreen; // 或其他你喜欢的样式
            [self presentViewController:chatNavController animated:YES completion:nil];
        }];
        [alertController addAction:chat];
        // 添加取消按钮
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            // 取消操作的处理
        }];
        
       
        
        [alertController addAction:cancelAction];
        
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    [self setTopView];
    [self setBackgroundUI];
    
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    //导航搜索

    if (self.navigationItem.searchController != self.searchController) {
        self.navigationItem.searchController = self.searchController;
    }
   
    [self updateViewConstraints];
    
    
}

#pragma mark - 历史搜索按钮点击
///点击代理
- (void)buttonTappedWithTag:(NSInteger)tag title:(NSString *)title button:(UIButton*)button{
    if(tag == 0) return;
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD dismissWithDelay:1];
    self.searchController.searchBar.text = title;
    [self.searchController resignFirstResponder];
    [self performSearchWithText:title];
}

///长按代理
- (void)buttonLongPressedWithTag:(NSInteger)tag title:(NSString *)title button:(UIButton*)button {
    if(tag == 0) return;
    [self.searchTitles removeObject:title];
    [[NSUserDefaults standardUserDefaults] setObject:self.searchTitles forKey:FIND_TITLES_SAVE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.miniButtonView updateButtonsWithStrings:self.searchTitles icons:nil];
}

- (void)setBackgroundUI {
    
    // 在其他类中
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIWindow *rootWindow = appDelegate.window;
    

    // 设置背景颜色和透明度
    
    rootWindow.backgroundColor = [UIColor systemBackgroundColor];
    
    // 添加浮动小球
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        NSLog(@"切换到暗色模式");
        rootWindow.backgroundColor = [UIColor systemBackgroundColor];
        [rootWindow setRandomGradientBackgroundWithColorCount:3 alpha:0.05];
        [rootWindow addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleDark UIBlurEffectAlpha:0.99 ballalpha:0.5];
    
        
    } else {
        NSLog(@"切换到亮色模式");
        rootWindow.backgroundColor = [UIColor systemBackgroundColor];
        [rootWindow setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
        [rootWindow addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleLight UIBlurEffectAlpha:0.99 ballalpha:0.3];
    
    }
    
    
    
}

- (void)setTopView{
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        
        // 1. 设置背景色为透明
        appearance.backgroundColor = [UIColor clearColor];
        
        // 2. 确保背景图片为空
        appearance.backgroundImage = [UIImage new];
        
        // 3. 移除阴影
        appearance.shadowImage = [UIImage new];
        // 或者通过 shadowColor 设置为 clearColor
        appearance.shadowColor = [UIColor clearColor];
        
        // 4. 确保导航栏不使用毛玻璃效果
        appearance.backgroundEffect = nil;
        
        // （可选）配置标题和按钮颜色
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor labelColor]};
        appearance.buttonAppearance.normal.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor labelColor]};
        
        // 应用 appearance
        UINavigationBar *navBar = self.navigationController.navigationBar;
        navBar.standardAppearance = appearance;
        navBar.scrollEdgeAppearance = appearance; // 滚动时也应用同样的外观
        navBar.shadowImage = [UIImage new];
        
    } else {
        
        // 1. 获取当前导航栏
        UINavigationBar *navBar = self.navigationController.navigationBar;
        
        // 2. 设置背景色为透明
        navBar.barTintColor = [UIColor clearColor];
        
        // 3. 设置背景图片为空图片
        [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        
        // 4. 设置阴影图片为空图片（移除底部的灰线）
        navBar.shadowImage = [UIImage new];
        
    }
    
    // 4. 强制刷新导航栏布局（解决高度计算异常）
    [self.navigationController.navigationBar layoutIfNeeded];
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    [self setTopView];
    [self setBackgroundUI];
  
}

@end
