//
//  CommunityViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/6/30.
//

#import "ChatListViewController.h"
#import "NewProfileViewController.h"
#import "WebToolModel.h"
#import "ToolViewCell.h"
#import "MiniButtonView.h"
#import "TTCHATViewController.h"
#import "UserProfileViewController.h"
#import "MyCollectionViewController.h"
#import "UserCardViewController.h"
#import "loadData.h"
#import "ArrowheadMenu.h"
#import "QRCodeScannerViewController.h"
#import "FindFriendsViewController.h"
#import "NewToolViewController.h"

#define TITLES_SAVE_KEY @"TITLES_SAVE_KEY"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@interface ChatListViewController ()<UISearchResultsUpdating,UISearchBarDelegate,TemplateSectionControllerDelegate,RCIMConnectionStatusDelegate,RCIMClientReceiveMessageDelegate,MiniButtonViewDelegate,MenuViewControllerDelegate>

@property (nonatomic, strong)  NSString *keyword;
@property (nonatomic, strong)  UIView *gradientNavigationView;
@property (nonatomic, strong) MiniButtonView *miniButtonView;
@property (nonatomic, strong) NSMutableArray *searchTitles;

@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, strong) NSMutableArray *backupsArray; // 原始会话数据源备份
@property (nonatomic, strong) NSMutableArray *searchArray;  // 搜索结果存储数组

@property (nonatomic, strong) UISearchController *searchController;
@end

@implementation ChatListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self setupViews];
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    
}


#pragma mark - 初始化UI

- (void)setupViews{
    
    //默认
    self.title = @"聊天";
    
    // Do any additional setup after loading the view.
    self.displayConversationTypeArray = @[
        @(ConversationType_PRIVATE),
        @(ConversationType_DISCUSSION),
        @(ConversationType_GROUP),
        @(ConversationType_CHATROOM),
        @(ConversationType_CUSTOMERSERVICE),
        @(ConversationType_SYSTEM),
        @(ConversationType_APPSERVICE),
        @(ConversationType_PUBLICSERVICE),
        @(ConversationType_PUSHSERVICE),
        @(ConversationType_ULTRAGROUP),
        @(ConversationType_Encrypted),
        @(ConversationType_RTC)
        
    ];
    self.collectionConversationTypeArray = nil;
    /// 添加代理委托
    [[RCIM sharedRCIM] addConnectionStatusDelegate:self];
    //注册消息接收代理
    [[RCCoreClient sharedCoreClient] addReceiveMessageDelegate:self];
    
//    self.edgesForExtendedLayout = UIRectEdgeBottom | UIRectEdgeLeft | UIRectEdgeRight ;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.conversationListTableView.backgroundColor =[UIColor clearColor];
    
    //导航搜索
    [self setupNavigationBarWithSearch];
    
    //设置历史搜索
    NSArray *titles = [[NSUserDefaults standardUserDefaults] arrayForKey:TITLES_SAVE_KEY];
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
    
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    
    
}

- (void)setupNavigationBarWithSearch {
    // 初始化搜索相关数组
    self.backupsArray = [NSMutableArray array];
    self.searchArray = [NSMutableArray array];
    
    // 首次加载时备份原始会话数据
    if (self.conversationListDataSource.count > 0) {
        self.backupsArray = [NSMutableArray arrayWithArray:self.conversationListDataSource];
    }
    
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    // 创建搜索控制器
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"输入搜索内容";

    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.returnKeyType = UIReturnKeySearch;
    
    // 配置导航项
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    closeItem.tintColor = [UIColor labelColor];
    
    // 判断是否是模态弹出
    BOOL isPresentedModally = [self isModal];
    
    UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"qrcode"] style:UIBarButtonItemStylePlain target:self action:@selector(camera:)];
    camera.tintColor = [UIColor labelColor];
    
    // 仅在模态时设置右侧关闭按钮，否则隐藏
    self.navigationItem.rightBarButtonItem = isPresentedModally ? closeItem : camera;
    
    // 关闭按钮
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"heart"] style:UIBarButtonItemStylePlain target:self action:@selector(heart:)];
    leftButton.tintColor = [UIColor labelColor];
    
    // 关键：禁用系统默认的返回按钮
    self.navigationItem.leftItemsSupplementBackButton = NO; // 禁用补充模式
    self.navigationItem.hidesBackButton = YES; // 隐藏系统返回按钮
    
    // 设置自定义左侧按钮
    self.navigationItem.leftBarButtonItem = leftButton;
}



#pragma mark - 约束相关

//设置约束
-(void)setupViewConstraints{
    // 子视图顶部对齐导航栏底部（自动适配所有设备和模式）
    
    // 用 Masonry 约束表格，顶部紧贴安全区域顶部（导航栏下方），左右和底部充满屏幕
    // 计算顶部偏移量：状态栏高度 + 导航栏高度
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat topOffset = statusBarHeight + navBarHeight + 44;
    NSLog(@"statusBarHeight:%f  navBarHeight:%f",navBarHeight,topOffset);
    
    [self.conversationListTableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0); // 顶部偏移量
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    [self.miniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.conversationListTableView.mas_top).offset(0); // 顶部偏移量
        make.width.mas_equalTo(kWidth - 80);
        make.height.mas_equalTo(40);
        make.centerX.equalTo(self.view).offset(-20);
    }];


}

//更新约束
-(void)updateViewConstraints{
    [super updateViewConstraints];
    
    
    CGFloat newtopOffset = self.miniButtonView.hidden ? 0 : 40;
    
    [self.conversationListTableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(newtopOffset); // 顶部偏移量
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    [self.miniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.conversationListTableView.mas_top).offset(0); // 顶部偏移量
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

#pragma mark - action 函数

// 关闭按钮的点击事件（模态弹出时，通过dismiss关闭）
- (void)close:(UIBarButtonItem *)item {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//显示好友
- (void)heart:(UIBarButtonItem *)item {
    MyCollectionViewController *vc = [MyCollectionViewController new];
    vc.selectedIndex = 3;
    vc.showFollowList = YES;
    vc.target_udid = [loadData sharedInstance].userModel.udid;
    [self presentPanModal:vc];
}

//显示好友
- (void)camera:(UIBarButtonItem *)item {
    
    
    NSArray *title = @[@"我的名片", @"扫一扫", @"发现好友"];
    NSArray *icon = @[@"person.crop.square", @"qrcode", @"magnifyingglass"];
    CGSize menuUnitSize = CGSizeMake(130, 50);
    CGFloat distanceFromTriggerSwitch = 10;
    UIFont * font = [UIFont boldSystemFontOfSize:15];
    UIColor * menuFontColor = [UIColor labelColor];
    UIColor * menuBackColor = [[UIColor tertiarySystemBackgroundColor] colorWithAlphaComponent:0.95];
    UIColor * menuSegmentingLineColor = [UIColor labelColor];
    
    ArrowheadMenu *VC = [[ArrowheadMenu alloc] initCustomArrowheadMenuWithTitle:title
                                                                           icon:icon
                                                                   menuUnitSize:menuUnitSize
                                                                       menuFont:font
                                                                  menuFontColor:menuFontColor
                                                                  menuBackColor:menuBackColor
                                                        menuSegmentingLineColor:menuSegmentingLineColor
                                                      distanceFromTriggerSwitch:distanceFromTriggerSwitch
                                                                 menuArrowStyle:MenuArrowStyleRound
                                                                 menuPlacements:ShowAtBottom
                                                           showAnimationEffects:ShowAnimationZoom
    ];
    VC.iconSize = CGSizeMake(27, 25);
    
    VC.delegate = self;
    [VC presentMenuView:item];
}

#pragma mark - 菜单代理方法
- (void)menu:(BaseMenuViewController *)menu didClickedItemUnitWithTag:(NSInteger)tag andItemUnitTitle:(NSString *)title {
    NSLog(@"\n\n\n\n点击了第%lu项名字为%@的菜单项", tag, title);
    
    if (tag ==0) {
        UserCardViewController *vc = [UserCardViewController new];
        vc.userID = [loadData sharedInstance].userModel.user_id;
        vc.nickname = [loadData sharedInstance].userModel.nickname;
        vc.avatarImage = [loadData sharedInstance].userModel.avatarImage;
        [self presentPanModal:vc];
    } else if (tag ==1) {
        // 初始化扫码器
        QRCodeScannerViewController *scannerVC = [[QRCodeScannerViewController alloc] init];
        [self.navigationController pushViewController:scannerVC animated:YES];
    }else if(tag == 2){
        FindFriendsViewController *vc = [FindFriendsViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - UISearchBarDelegate（补充状态监听）
// 1. 搜索框开始编辑（用户点击搜索框，进入编辑状态）→ 显示历史搜索视图
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // 显示历史搜索视图，并刷新历史搜索数据
    self.miniButtonView.hidden = NO;
    [self.miniButtonView updateButtonsWithStrings:self.searchTitles icons:nil];
    // 刷新约束（确保视图位置正确）
    [self updateViewConstraints];
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
    
    // 补充：隐藏历史搜索视图
    self.miniButtonView.hidden = YES;
    
    // 恢复原始会话数据（原有逻辑保留）
    if (self.backupsArray.count > 0) {
        self.conversationListDataSource = [NSMutableArray arrayWithArray:self.backupsArray];
        [self refreshConversationTableViewIfNeeded];
    }
    [self updateViewConstraints];
}

// 4. 点击搜索按钮（键盘Done键），执行搜索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self performSearchWithText:searchBar.text]; // 调用完善后的搜索方法
    
}

#pragma mark - UISearchResultsUpdating 代理（搜索防抖）
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    NSLog(@"输入过程1：%@", searchText);
    
    // 停止之前的定时器，避免重复触发
    [self.searchTimer invalidate];
    
    // 0.5秒后执行搜索（防抖）
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                       target:self
                                                     selector:@selector(executeDebounceSearch:)
                                                     userInfo:searchText
                                                      repeats:NO];
}

// 防抖搜索执行方法
- (void)executeDebounceSearch:(NSTimer *)timer {
    NSString *searchText = timer.userInfo;
    [self performSearchWithText:searchText];
}

#pragma mark - 执行搜索请求（表层+深层历史消息）

- (void)performSearchWithText:(NSString *)text {
    self.keyword = text;
    [self updateViewConstraints];
    [SVProgressHUD showWithStatus:@"搜索中"];
    // 2. 备份原始数据（避免多次搜索篡改原始数据）
    if (self.backupsArray.count == 0) {
        self.backupsArray = [NSMutableArray arrayWithArray:self.conversationListDataSource];
    }
    // 1. 关键词为空时，恢复原始数据并返回
    if (self.keyword.length == 0) {
        
        // 关键补充：关闭搜索框键盘（需在主线程执行）
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismissWithDelay:0.5];
            [self.searchController resignFirstResponder];
        });
        self.conversationListDataSource = [NSMutableArray arrayWithArray:self.backupsArray];
        [self refreshConversationTableViewIfNeeded];
        return;
    }
    
    
    
    // 1. 判断关键词非空 + 未存在于数组中
    if (self.keyword && self.keyword.length > 0 && ![self.searchTitles containsObject:self.keyword]) {
        // 2. 不存在则添加
        [self.searchTitles insertObject:self.keyword atIndex:1];
        [self.miniButtonView updateButtonsWithStrings:self.searchTitles icons:nil];
        // 3. 储存
        [[NSUserDefaults standardUserDefaults] setObject:self.searchTitles forKey:TITLES_SAVE_KEY];
        
        [self updateViewConstraints];
    }
    
    
    
    
    // 3. 清空上次搜索结果
    [self.searchArray removeAllObjects];
    
    // 4. 遍历原始备份数据，先做“会话表层”搜索（标题/最后一条消息）
    for (RCConversationModel *model in self.backupsArray) {
        BOOL isMatchSurface = [model.conversationTitle containsString:text]
                          || (model.lastestMessage.conversationDigest.length > 0
                              && [model.lastestMessage.conversationDigest containsString:text]);
        
        if (isMatchSurface) {
            [self.searchArray addObject:model];
            continue;
        }
       
    }
    
    // 5. 若仅表层有匹配结果，直接刷新（避免深层搜索无结果时表格不更新）
    if (self.searchArray.count > 0) {
        self.conversationListDataSource = [NSMutableArray arrayWithArray:self.searchArray];
        [self refreshConversationTableViewIfNeeded];
    }
    [SVProgressHUD dismissWithDelay:0.5];
}


#pragma mark - 接收消息后
- (void)onReceived:(RCMessage *)message left:(int)left object:(id)object {
    NSLog(@"列表界面onReceived收到消息extra:%@",message.content.senderUserInfo.extra);
    if(left ==0){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self refreshConversationTableViewIfNeeded];

        });
        
    }
    
    
}


#pragma mark - 控制器函数
// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    self.tabBarController.tabBar.hidden = NO;
    self.miniButtonView.hidden = YES;
    [self setTopView];
    [self setBackgroundUI];
    [self setupNavigationBarWithSearch];
    
    [self updateViewConstraints];
    
    
    
    
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    // 1. 获取AppDelegate实例
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    // 2. 读取未读消息
    [appDelegate getTotalUnreadCount];
    
    
}

//消失后
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 在这里可以进行一些清理工作，比如停止动画、取消定时器、保存数据等。
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 在这里进行与布局完成后相关的操作，比如获取子视图的最终尺寸等

}

- (void)dealloc {
    // 移除通知观察者
   
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

- (void)setBackgroundUI {
    
    // 在其他类中
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIWindow *rootWindow = appDelegate.window;
    self.view.backgroundColor = [UIColor clearColor];

    // 设置背景颜色和透明度
    
    rootWindow.backgroundColor = [UIColor systemBackgroundColor];
    
    // 添加浮动小球
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        NSLog(@"切换到暗色模式");
       
        [rootWindow setRandomGradientBackgroundWithColorCount:3 alpha:0.05];
        [rootWindow addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleDark UIBlurEffectAlpha:0.90 ballalpha:0.5];
    
        
    } else {
        NSLog(@"切换到亮色模式");
       
        [rootWindow setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
        [rootWindow addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleLight UIBlurEffectAlpha:0.90 ballalpha:0.3];
    
    }
    
    
    
}

- (BOOL)isDarkMode {
    return self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
   
    [self setTopView];
    [self setBackgroundUI];
}


#pragma mark - 表格代理

// 自定义 cell
- (void)willDisplayConversationTableCell:(RCConversationBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [super willDisplayConversationTableCell:cell atIndexPath:indexPath];
    
    RCConversationCell *mycel = (RCConversationCell *)cell;
    mycel.backgroundColor = [UIColor clearColor];
    mycel.selectionStyle = UITableViewCellSelectionStyleNone;  // 禁用 cell 的点击效果
    //解析会话列表的数据源的模型
    RCConversationModel *model = self.conversationListDataSource[indexPath.row];
    
    //昵称
    mycel.conversationTitle.font = [UIFont boldSystemFontOfSize:16];
    
    //置顶的颜色
    mycel.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.05];
   
    if(model.isTop){
        mycel.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3];
       
    }
    //非置顶的颜色
    
    //会话有新消息通知的时候显示数字提醒，设置为NO,不显示数字只显示红点
    mycel.isShowNotificationNumber = YES;
    
    //显示最后一条内容的Label
    mycel.messageContentLabel.textColor = [UIColor secondaryLabelColor];

    mycel.messageContentLabel.layer.masksToBounds = YES;
    
    //显示最后一条内容的时间
    mycel.messageCreatedTimeLabel.textColor = [UIColor secondaryLabelColor];

    
    
    //是否进行新消息提醒
    mycel.enableNotification = YES;
    //搜索相关
    if(self.keyword.length>0){
        [self setupLabel:mycel.conversationTitle withKey:self.keyword];
        [self setupLabel:mycel.messageContentLabel withKey:self.keyword];
    }
    
    NSString *targetId = model.targetId;
    //设置免打扰
    [[RCChannelClient sharedChannelManager] getConversationNotificationLevel:mycel.model.conversationType
                                                                    targetId:targetId
                                                                     success:^(RCPushNotificationLevel level) {
        NSLog(@"列表查询免打扰状态:%ld",level);
        dispatch_async(dispatch_get_main_queue(), ^{
            //全部接受通知
            if(level == RCPushNotificationLevelAllMessage || RCPushNotificationLevelDefault){
                mycel.conversationStatusImageView.hidden = YES;
            }
            //免打扰单聊
            else if(level == RCPushNotificationLevelMentionAll){
                mycel.conversationStatusImageView.hidden = NO;
                mycel.conversationStatusImageView.backgroundColor = [UIColor clearColor];
            }
            //屏蔽
            else if(level == RCPushNotificationLevelBlocked){
                mycel.conversationStatusImageView.hidden = NO;
                mycel.conversationStatusImageView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
                mycel.conversationStatusImageView.layer.cornerRadius = mycel.conversationStatusImageView.frame.size.width/2;
                
            }
            
        });
        
    }error:^(RCErrorCode status) {
        NSLog(@"查询免打扰状态RCErrorCode:%ld",status);
    }];
    __block UserModel *user = [UserModel cachedUserModelWithUdid:targetId];
    NSLog(@"打印user：%@",user);
    if(!user) {
        
        [UserModel getUserInfoWithUdidCacheFirst:targetId success:^(UserModel * _Nonnull userModel) {
            user = userModel;
            [self updateCellUIWithUserId:user cell:mycel];
        } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        }];
    }else{
        [self updateCellUIWithUserId:user cell:mycel];
    }
    
    
    
   
    
}


//搜索状态下的帖子正文获取标签变色
- (void)setupLabel:(UILabel *)label withKey:(NSString *)key {
    if(label.text.length==0)return;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label.text];

    NSRange range = [label.text rangeOfString:key];
    if (range.location!= NSNotFound) {
        UIColor *tagColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
        [attributedString addAttribute:NSForegroundColorAttributeName value:tagColor range:range];
    }
    label.attributedText = attributedString;
}

- (void)updateCellUIWithUserId:(UserModel *)userModel cell:(RCConversationCell *)mycel {
    //设置头像
    UIImageView * avaView = (UIImageView *)mycel.headerImageView;
    //设置头像
    NSString *avaurl = [NSString stringWithFormat:@"%@",userModel.avatar];
    NSLog(@"更新头像地址:%@",avaurl);
    [avaView sd_setImageWithURL:[NSURL URLWithString:avaurl]];
    
   
    if(mycel.model.conversationType == ConversationType_SYSTEM){
        mycel.conversationTitle.text = @"互动消息";
        avaView.image = [UIImage imageNamed:@"xingqiu99"];
    }
    
    
    mycel.conversationTagView.layer.masksToBounds =NO;
   
    
    
    /*!
     会话标题右侧的标签view
     */
    mycel.conversationTagView.hidden = NO;
    
    UIButton *button = [mycel viewWithTag:1001];
    if(!button){
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 60, 18); // 或根据文字长度调整宽度
        button.layer.cornerRadius = 9;
        button.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
        button.tag = 1001;
        
        // 核心优化：1. 减小字体 2. 简化边距设置
        button.titleLabel.font = [UIFont systemFontOfSize:11]; // 关键：设置合适字体大小
        button.contentEdgeInsets = UIEdgeInsetsMake(3, 1, 3, 1); // 仅保留 contentEdgeInsets
        // 移除 titleEdgeInsets，避免重复压缩
        
        [mycel.conversationTagView addSubview:button];
    }
    NSLog(@"自定义标签:%@  mutualFollowStatus:%ld",button,userModel.mutualFollowStatus);
    switch (userModel.mutualFollowStatus) {
        case UserFollowMutualStatus_None:
            mycel.conversationTagView.hidden = YES;
            break;
        case UserFollowMutualStatus_HimFollowMe:
            mycel.conversationTagView.hidden = NO;
            [button setTitle:@"粉丝" forState:UIControlStateNormal];
            break;
            
        case UserFollowMutualStatus_IFollowHim:
            mycel.conversationTagView.hidden = NO;
            [button setTitle:@"已关注" forState:UIControlStateNormal];
            button.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
            break;
            
        case UserFollowMutualStatus_Mutual:
            mycel.conversationTagView.hidden = NO;
            [button setTitle:@"互关密友" forState:UIControlStateNormal];
            button.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
            break;
            
        default:
            break;
    }
    UIButton *zxButton = [mycel viewWithTag:1002];
    if(!zxButton){
        CGFloat width = 8;
        zxButton = [UIButton buttonWithType:UIButtonTypeCustom];
        zxButton.frame = CGRectMake(width/2, mycel.headerImageViewBackgroundView.frame.size.height - width, width, width); // 或根据文字长度调整宽度
        zxButton.layer.cornerRadius = width/2;
        zxButton.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.8];
        zxButton.tag = 1002;
        [mycel.headerImageViewBackgroundView addSubview:zxButton];
    }
    zxButton.hidden = userModel.is_online;
    
    UIButton *vipButton = [mycel viewWithTag:1003];
    if(!vipButton){
        CGFloat width = 20;
        CGFloat size = 8;
        vipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        vipButton.frame = CGRectMake(0, 0, width, size + 3);
        vipButton.layer.cornerRadius = 5;
        vipButton.backgroundColor = [UIColor purpleColor];
        vipButton.tag = 1003;
        [vipButton setTitle:@"vip" forState:UIControlStateNormal];
        vipButton.titleLabel.font = [UIFont boldSystemFontOfSize:size];
        vipButton.contentEdgeInsets = UIEdgeInsetsMake(1, 2, 1, 2);
        [mycel.headerImageViewBackgroundView addSubview:vipButton];
        [vipButton addGlowEffectWithColor:[UIColor labelColor] shadowOpacity:1 shadowRadius:2];
        
    }
    vipButton.hidden = userModel.vip_level == 0;
    
}

#pragma mark - 表格代理

//表格左滑
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    RCConversationModel *model = self.conversationListDataSource[indexPath.row];
    //得到每个用户的userId
    NSString *userId = model.targetId;
    NSLog(@"得到每个用户的userId:%@",userId);
    
    BOOL isTop = model.isTop;
    
    
    
    //提示
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"删除" handler:^(UIContextualAction *action, __kindof UIView *sourceView, void (^completionHandler)(BOOL)) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"删除提示" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        // 添加取消按钮
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            // 取消操作的处理
            
        }];
        
        // 添加确定按钮
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"单删除会话窗口" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
   
            [[RCCoreClient sharedCoreClient] removeConversation:model.conversationType targetId:userId isDeleteRemote:NO success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conversationListDataSource removeObject:model];
                    [SVProgressHUD showSuccessWithStatus:@"删除完成"];
                    [SVProgressHUD dismissWithDelay:0.5 completion:^{
                        
                    }];
                    [self refreshConversationTableViewIfNeeded];
                });
                
            } error:^(RCErrorCode errorCode) {
                
            }];
            
        }];
        
        // 添加确定按钮
        UIAlertAction *okAction2 = [UIAlertAction actionWithTitle:@"删除本地聊天记录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [[RCCoreClient sharedCoreClient] clearHistoryMessages:model.conversationType
                                                         targetId:userId
                                                       recordTime:0
                                                      clearRemote:NO
                                                          success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshConversationTableViewIfNeeded];
                    // 删除成功
                    [SVProgressHUD showSuccessWithStatus:@"删除完成"];
                    [SVProgressHUD dismissWithDelay:0.5 completion:^{
                        
                    }];
                });
                
            } error:^(RCErrorCode status) {
                
            }];
            
           
            
        }];
        // 添加确定按钮
        UIAlertAction *okAction3 = [UIAlertAction actionWithTitle:@"删除本地+云端聊天记录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            //删除本地和云端历史记录
            [[RCCoreClient sharedCoreClient] clearHistoryMessages:model.conversationType
                                                         targetId:userId
                                                       recordTime:0
                                                      clearRemote:YES
                                                          success:^{
                
            } error:^(RCErrorCode status) {
                
            }];
        }];
        // 添加确定按钮
        UIAlertAction *okAction4 = [UIAlertAction actionWithTitle:@"删除/本地/云端/会话窗" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            //删除本地和云端历史记录
            [[RCCoreClient sharedCoreClient] clearHistoryMessages:model.conversationType
                                                         targetId:userId
                                                       recordTime:0
                                                      clearRemote:YES
                                                          success:^{
                
            } error:^(RCErrorCode status) {
                
            }];
            //删除会话
            [[RCCoreClient sharedCoreClient] removeConversation:model.conversationType targetId:userId isDeleteRemote:NO success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conversationListDataSource removeObject:model];
                    [SVProgressHUD showSuccessWithStatus:@"删除完成"];
                    [SVProgressHUD dismissWithDelay:0.5 completion:^{
                        
                    }];
                    [self refreshConversationTableViewIfNeeded];
                });
                
            } error:^(RCErrorCode errorCode) {
                
            }];
            
        }];
        
        
        [alertController addAction:okAction];
        [alertController addAction:okAction2];
        [alertController addAction:okAction3];
        [alertController addAction:okAction4];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        
        
        
        
        
    }];
    UIContextualAction *disturb = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"免打扰" handler:^(UIContextualAction *action, __kindof UIView *sourceView, void (^completionHandler)(BOOL)) {
        
        [[RCChannelClient sharedChannelManager] getConversationNotificationLevel:model.conversationType targetId:userId success:^(RCPushNotificationLevel level) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *actionTitle = @"接收消息-不提醒";
                NSString *action2Title = @"屏蔽-不接收消息";
                

                // 全部接受通知
                if (level == RCPushNotificationLevelAllMessage) {
                    
                }
                // 免打扰单聊
                else if (level == RCPushNotificationLevelMentionAll) {
                    actionTitle = @"取消免打扰-恢复消息提示";
                }
                // 屏蔽
                else if (level == RCPushNotificationLevelBlocked) {
                    
                    action2Title = @"取消屏蔽-恢复接收消息";
                }

                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置免打扰" message:nil preferredStyle:UIAlertControllerStyleAlert];

                // 添加取消按钮
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    // 取消操作的处理
                }];

                // 添加确定按钮
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    
                    //私聊 就按用户设置免打扰
                    [[RCChannelClient sharedChannelManager] setConversationNotificationLevel:model.conversationType
                                                                                       targetId:userId
                                                                                      level:level == RCPushNotificationLevelAllMessage? RCPushNotificationLevelMentionAll : RCPushNotificationLevelAllMessage
                                                                                        success:^() {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self refreshConversationTableViewIfNeeded];
                            [SVProgressHUD showSuccessWithStatus:@"设置完成"];
                            [SVProgressHUD dismissWithDelay:0.5 completion:^{
                                
                            }];
                        });
                        
                        NSLog(@"设置免打扰成功");
                    } error:^(RCErrorCode status) {
                        NSLog(@"设置免打扰失败");
                    }];
                }];

                // 添加确定按钮
                UIAlertAction *okAction2 = [UIAlertAction actionWithTitle:action2Title style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                    [[RCChannelClient sharedChannelManager] setConversationNotificationLevel:model.conversationType
                                                                                       targetId:userId
                                                                                      level:level == RCPushNotificationLevelBlocked? RCPushNotificationLevelAllMessage : RCPushNotificationLevelBlocked
                                                                                        success:^() {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"设置屏蔽成功");
                            [self refreshConversationTableViewIfNeeded];
                            [SVProgressHUD showSuccessWithStatus:@"设置完成"];
                            [SVProgressHUD dismissWithDelay:0.5 completion:^{
                               
                            }];
                        });
                        
                    } error:^(RCErrorCode status) {
                        NSLog(@"设置屏蔽失败");
                    }];
                }];

                [alertController addAction:okAction];
                [alertController addAction:okAction2];

                [alertController addAction:cancelAction];

                [self presentViewController:alertController animated:YES completion:nil];
               
            });
            
        } error:^(RCErrorCode status) {
            
        }];
        
        
    }];
    
    // 自定义颜色
    deleteAction.backgroundColor = [UIColor colorWithRed:1 green:0.1 blue:0.1 alpha:1.0];
    UIContextualAction *chatTop = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:isTop?@"取消置顶":@"置顶" handler:^(UIContextualAction *action, __kindof UIView *sourceView, void (^completionHandler)(BOOL)){
        // 创建弱引用
        __weak typeof(self) weakSelf = self;
        [[RCCoreClient sharedCoreClient] setConversationToTop:model.conversationType
                                                     targetId:userId
                                                        isTop:!isTop
                                                   completion:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"操作完成"];
                [SVProgressHUD dismissWithDelay:0.5 completion:^{
                    
                    [weakSelf refreshConversationTableViewIfNeeded];
                    
                }];
            });
        }];
        
        
        
    }];
    chatTop.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1.0];
    
    
    UISwipeActionsConfiguration *actionsConfiguration = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction,chatTop,disturb]];
    return actionsConfiguration;
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
    [[NSUserDefaults standardUserDefaults] setObject:self.searchTitles forKey:TITLES_SAVE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.miniButtonView updateButtonsWithStrings:self.searchTitles icons:nil];
}

#pragma mark - 点击列表 跳转聊天页面

- (void)onSelectedTableRow:(RCConversationModelType)conversationModelType
         conversationModel:(RCConversationModel *)model
               atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"点击列表 跳转聊天页面");
    if(!self.isShare){
        [self openChat:model];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"分享" message:nil preferredStyle:UIAlertControllerStyleAlert];
        // 添加取消按钮
        UIAlertAction*isShareAction = [UIAlertAction actionWithTitle:@"直接分享" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self sendRcimMessage:model];
            
        }];
        [alert addAction:isShareAction];
        UIAlertAction*openShareActionAction = [UIAlertAction actionWithTitle:@"打开聊天" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self openChat:model];
        }];
        [alert addAction:openShareActionAction];
        UIAlertAction*cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    
    
    
}

- (void)openChat:(RCConversationModel *)model{
    // 1. 初始化聊天页，保留原有参数配置
    TTCHATViewController *conversationVC = [[TTCHATViewController alloc] initWithConversationType:model.conversationType
                                                                                          targetId:model.targetId];
    conversationVC.shareModel = self.shareModel;
    conversationVC.messageForType = self.messageForType;
    conversationVC.isShare = self.isShare;
    conversationVC.targetId = model.targetId;
    conversationVC.title = model.conversationTitle;
    conversationVC.message = model.lastestMessage;
    conversationVC.locatedMessageSentTime = model.sentTime;
   
    [self.navigationController pushViewController:conversationVC animated:YES];
}

//点击头像
- (void)didTapCellPortrait:(RCConversationModel *)model{
    // 1. 互动消息会话
    UserProfileViewController *vc = [[UserProfileViewController alloc] init];
    vc.user_udid = model.targetId;
    [self presentPanModal:vc];
}

- (void)sendRcimMessage:(RCConversationModel *)rcModel{
    ToolMessage *message = [[ToolMessage alloc] init];
    NSString * content = @"分享个好东西给你:";
    if(self.messageForType == MessageForTypeTool){
        WebToolModel *webToolModel = (WebToolModel *)self.shareModel;
        content = [NSString stringWithFormat:@"%@\n%@",content,webToolModel.tool_name];
        message.messageForType = MessageForTypeTool;
    }
    else if(self.messageForType == MessageForTypeApp){
        AppInfoModel *appInfoModel = (AppInfoModel *)self.shareModel;
        content = [NSString stringWithFormat:@"%@\n%@",content,appInfoModel.app_name];
        message.messageForType = MessageForTypeApp;
    }
    else if(self.messageForType == MessageForTypeUser){
        UserModel *userModel = (UserModel *)self.shareModel;
        content = [NSString stringWithFormat:@"分享个用户给你:\n%@",userModel.nickname];
        message.messageForType = MessageForTypeUser;
    }
    
    message.content = content;
    
    message.extra = [self.shareModel yy_modelToJSONString];
    
    [[RCIM sharedRCIM] sendMessage:ConversationType_PRIVATE targetId:rcModel.targetId content:message pushContent:message.content pushData:message.content success:^(long messageId) {
        
    } error:^(RCErrorCode nErrorCode, long messageId) {
        
        
    }];
}

@end
