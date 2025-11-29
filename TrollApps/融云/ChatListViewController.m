//
//  ChatListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/20.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "ChatListViewController.h"
#import "config.h"
#import "UserModel.h"
#import "MyTabBarController.h"
#import "MiniButtonView.h"

//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface ChatListViewController ()<RCIMClientReceiveMessageDelegate,RCIMConnectionStatusDelegate,UISearchResultsUpdating,UISearchBarDelegate,RCTypingStatusDelegate,RCMessageDestructDelegate>
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, strong) NSString *keyword;
// 新增搜索相关属性
@property (nonatomic, strong) NSMutableArray *backupsArray; // 原始会话数据源备份
@property (nonatomic, strong) NSMutableArray *searchArray;  // 搜索结果存储数组

// 新增：存储搜索框引用，用于后续关闭键盘
@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) MiniButtonView *miniButtonView;

@property (nonatomic, strong) NSMutableArray *searchTitles;

///导航的渐变视图
@property (nonatomic, strong) UIView * gradientNavigationView;
@end

@implementation ChatListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    
    //导航搜索
    [self setupNavigationBarWithSearch];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addColorBallsWithCount:20 ballradius:200 minDuration:30 maxDuration:50 UIBlurEffectStyle:UIBlurEffectStyleRegular UIBlurEffectAlpha:1 ballalpha:0.5];
    self.conversationListTableView.backgroundColor =[UIColor clearColor];
    
    // 初始化搜索相关数组
    self.backupsArray = [NSMutableArray array];
    self.searchArray = [NSMutableArray array];
    
    // 首次加载时备份原始会话数据
    if (self.conversationListDataSource.count > 0) {
        self.backupsArray = [NSMutableArray arrayWithArray:self.conversationListDataSource];
    }
    
}

- (void)setupNavigationBarWithSearch {
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    
    // 创建搜索控制器
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = YES;
    self.searchController.searchBar.placeholder = @"输入搜索内容";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.returnKeyType = UIReturnKeySearch;
    
    // 配置导航项
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *countryItem = [[UIBarButtonItem alloc] initWithTitle:@"关于" style:UIBarButtonItemStylePlain target:self action:@selector(myToolTapped:)];
    countryItem.tintColor = [UIColor labelColor];
    self.navigationItem.rightBarButtonItem = countryItem;
    
    // 关闭按钮
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"最近"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(recently)];
    closeButton.tintColor = [UIColor labelColor];
    
    // 关键：禁用系统默认的返回按钮
    self.navigationItem.leftItemsSupplementBackButton = NO; // 禁用补充模式
    self.navigationItem.hidesBackButton = NO; // 隐藏系统返回按钮
    
    // 设置自定义左侧按钮
    self.navigationItem.leftBarButtonItem = closeButton;
    
    self.searchTitles = [NSMutableArray array];
    self.miniButtonView = [[MiniButtonView alloc] initWithFrame:CGRectMake(0, 0, kWidth, 40)];
    [self.view addSubview:self.miniButtonView];
}


- (void)onRCIMConnectionStatusChanged:(RCConnectionStatus)status {
    
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    // 用 Masonry 约束表格，顶部紧贴安全区域顶部（导航栏下方），左右和底部充满屏幕
    // 计算顶部偏移量：状态栏高度 + 导航栏高度
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat topOffset = statusBarHeight + navBarHeight;
    
    [self.conversationListTableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(topOffset); // 顶部偏移量
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    [self.miniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.conversationListTableView.mas_top).offset(5); // 顶部偏移量
        make.width.mas_equalTo(kWidth);
        make.centerX.equalTo(self.view);
    }];
}

#pragma mark - action 函数

//查看我的发布工具
- (void)myToolTapped:(UIBarButtonItem*)item {
    
}

//最近使用
- (void)recently {
    
}



#pragma mark - 执行搜索请求（表层+深层历史消息）

- (void)performSearchWithText:(NSString *)text {
    self.keyword = text;
    // 2. 备份原始数据（避免多次搜索篡改原始数据）
    if (self.backupsArray.count == 0) {
        self.backupsArray = [NSMutableArray arrayWithArray:self.conversationListDataSource];
    }
    // 1. 关键词为空时，恢复原始数据并返回
    if (self.keyword.length == 0) {
        
        // 关键补充：关闭搜索框键盘（需在主线程执行）
        dispatch_async(dispatch_get_main_queue(), ^{
            self.miniButtonView.alpha = 1;
            [self.searchController resignFirstResponder];
        });
        self.conversationListDataSource = [NSMutableArray arrayWithArray:self.backupsArray];
        [self.conversationListTableView reloadData];
        return;
    }
    
    
    
    // 1. 判断关键词非空 + 未存在于数组中
    if (self.keyword && self.keyword.length > 0 && ![self.searchTitles containsObject:self.keyword]) {
        // 2. 不存在则添加
        [self.searchTitles addObject:self.keyword];
        [self.miniButtonView updateButtonsWithStrings:self.searchTitles icons:nil];
        self.miniButtonView.alpha = 1;
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
        [self.conversationListTableView reloadData];
    }
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

#pragma mark - UISearchBarDelegate
// 点击搜索框“取消”按钮，恢复原始数据
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder]; // 收起键盘
    searchBar.text = @""; // 清空输入框
    self.keyword = @"";   // 清空关键词
    
    // 恢复原始会话数据
    if (self.backupsArray.count > 0) {
        self.conversationListDataSource = [NSMutableArray arrayWithArray:self.backupsArray];
        [self.conversationListTableView reloadData];
    }
}

// 点击搜索按钮（键盘Done键），执行搜索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self performSearchWithText:searchBar.text]; // 调用完善后的搜索方法
}


#pragma mark - 接收消息后
- (void)onReceived:(RCMessage *)message left:(int)left object:(id)object {
    NSLog(@"列表界面onReceived收到消息extra:%@",message.content.senderUserInfo.extra);
    if(left ==0){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self refreshConversationTableViewIfNeeded];
//            [self.conversationListTableView reloadData];
        });
        
    }
    
    
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
    mycel.conversationTitle.font = [UIFont boldSystemFontOfSize:18];
    
    //置顶的颜色
    mycel.topCellBackgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.2];
    if(model.isTop){
        mycel.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.2];
    }
    //非置顶的颜色
    mycel.cellBackgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.05];
    //会话有新消息通知的时候显示数字提醒，设置为NO,不显示数字只显示红点
    mycel.isShowNotificationNumber = YES;
    
    //显示最后一条内容的Label
    mycel.messageContentLabel.textColor = [UIColor secondaryLabelColor];
//    mycel.messageContentLabel.text = [self truncateString:model.lastestMessage.conversationDigest];
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
    //得到每个用户的userId
    NSString *targetId = model.targetId;
    
    


//
//    [UserModel getUserInfoWithUdid:targetId success:^(UserModel * _Nonnull userModel) {
//        [self updateCellUIWithUserId:userModel cell:mycel];
//    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
//
//    }];
//    
    
}

- (NSString *)truncateString:(NSString *)inputString {
    if ([inputString length] <= 20) {
        return inputString;
    } else {
        return [inputString substringToIndex:20];
    }
}

- (void)updateCellUIWithUserId:(UserModel *)userModel cell:(RCConversationCell *)mycel {
    //设置头像
    UIImageView * avaView = (UIImageView *)mycel.headerImageView;
    //设置头像
    NSString *avaurl = [NSString stringWithFormat:@"%@/%@",localURL,userModel.avatar];
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
    
    /*!
     显示内容区的view
     */
    mycel.detailContentView.hidden = NO;
    
    /*!
     显示会话状态的view
     */
    mycel.statusView.hidden = NO;
    
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




#pragma mark - 点击列表 跳转聊天页面

- (void)onSelectedTableRow:(RCConversationModelType)conversationModelType
         conversationModel:(RCConversationModel *)model
               atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"点击列表 跳转聊天页面");
    
    TTCHATViewController *conversationVC = [[TTCHATViewController alloc] initWithConversationType:model.conversationType targetId:model.targetId];
    conversationVC.targetId = model.targetId;
    conversationVC.title = model.conversationTitle;
    conversationVC.message = model.lastestMessage;
    conversationVC.locatedMessageSentTime = model.sentTime;
    conversationVC.keyword = self.keyword;
    
    conversationVC.modalPresentationStyle = UIModalPresentationFullScreen;
    

    [self.navigationController pushViewController:conversationVC animated:YES];
}
//点击头像
- (void)didTapCellPortrait:(RCConversationModel *)model{
    
    
}




// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.navigationController setNavigationBarHidden:YES];
    self.tabBarController.tabBar.hidden = YES;
    
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    //储存正在聊天的ID 用来判断是否显示通知 离开控制器后要删除
    
    
    [self.navigationController setNavigationBarHidden:NO];
   
    self.tabBarController.tabBar.hidden = NO;
    
    //链接超时 重连
    
    [self refreshConversationTableViewIfNeeded];
    [self updateViewConstraints];
    
    //监听消息
    [[RCCoreClient sharedCoreClient] addReceiveMessageDelegate:self];
    //输入状态监听
    [[RCCoreClient sharedCoreClient] setRCTypingStatusDelegate:self];
    //阅后既焚监听器
    [[RCCoreClient sharedCoreClient] setRCMessageDestructDelegate:self];
    // 获取总未读数量，计算左侧按钮的未读数量
    // 1. 获取AppDelegate实例
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    // 2. 读取未读消息
    [appDelegate getTotalUnreadCount];
    
    
    //如果没登录 就清空数据源 刷新表格
    [self topBackageView];
    
}

// 消失之前
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 在这里可以进行一些在视图消失之前的清理工作，比如停止动画、保存数据等。
    //储存正在聊天的ID 用来判断是否显示通知 离开控制器后要删除

}

//消失后
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];


    [[RCCoreClient sharedCoreClient] removeReceiveMessageDelegate:self];

    
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
        self.view.backgroundColor = [UIColor systemBackgroundColor];
        [self.view setRandomGradientBackgroundWithColorCount:3 alpha:0.05];
        [self.view addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleDark UIBlurEffectAlpha:0.99 ballalpha:0.5];
    
        
    } else {
        NSLog(@"切换到亮色模式");
        self.view.backgroundColor = [UIColor systemBackgroundColor];
        [self.view setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
        [self.view addColorBallsWithCount:15 ballradius:200 minDuration:50 maxDuration:150 UIBlurEffectStyle:UIBlurEffectStyleLight UIBlurEffectAlpha:0.99 ballalpha:0.3];
    
    }
    
    
    
}


- (void)topBackageView{
    NSLog(@"11111111111111");
    //先判断下系统
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        appearance.backgroundImage = [UIImage new];;
        appearance.shadowImage = [UIImage new];
        appearance.shadowColor = nil;
        
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;
        
    }else{
        //顶部背景图
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        //清除分割线
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    }


}

- (BOOL)isDarkMode {
    return self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self topBackageView];
    [self setBackgroundUI];
}

@end
