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
@interface ChatListViewController ()<RCIMClientReceiveMessageDelegate,RCIMConnectionStatusDelegate,UISearchResultsUpdating,UISearchBarDelegate,RCTypingStatusDelegate,RCMessageDestructDelegate>
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, strong)  NSString *keyword;
@end

@implementation ChatListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    
    self.view.backgroundColor = [UIColor clearColor];
    self.conversationListTableView.backgroundColor =[UIColor clearColor];
    
}

- (void)setupNavigationBarWithSearch {
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    
    // 1. 创建搜索框（直接用 UISearchBar，而非依赖 UISearchController 的默认布局）
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.placeholder = @"输入搜索内容";
    searchBar.delegate = self; // 关联搜索代理（与之前的 UISearchController 共用代理方法）
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.returnKeyType = UIReturnKeyDone;
    searchBar.tintColor = [UIColor labelColor]; // 光标和按钮颜色
    
    // 2. 调整搜索框尺寸（使其在导航栏中居中显示，适应不同屏幕）
    searchBar.frame = CGRectMake(0, 0, 100, 44); // 宽度可根据需求调整（如 200~300）
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [searchBar.widthAnchor constraintLessThanOrEqualToConstant:300].active = YES; // 最大宽度限制（避免过宽）
    
    // 3. 将搜索框设置为导航栏的 titleView（核心：嵌入导航栏）
    self.navigationItem.titleView = searchBar;
    
    // 4. 右侧按钮（保持不变）
    UIBarButtonItem *countryItem = [[UIBarButtonItem alloc] initWithTitle:@"关于"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(myToolTapped:)];
    countryItem.tintColor = [UIColor labelColor];
    self.navigationItem.rightBarButtonItem = countryItem;
    
    // 5. 左侧按钮（保持不变）
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"最近"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(recently)];
    closeButton.tintColor = [UIColor labelColor];
    self.navigationItem.leftItemsSupplementBackButton = NO;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = closeButton;
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
}

#pragma mark - action 函数

//查看我的发布工具
- (void)myToolTapped:(UIBarButtonItem*)item {
    
}
//最近使用
- (void)recently {
    
}


#pragma mark - UISearchResultsUpdating 代理

//输入过程 防抖0.5 执行关键词搜索
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    
    [self.searchTimer invalidate];
    
    
    self.keyword = searchText;
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                       target:self
                                                     selector:@selector(refreshData)
                                                     userInfo:searchText
                                                      repeats:NO];
}


//点击取消时 执行默认搜索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    
    [self performSearchWithText:@""];
}

// 执行搜索请求
#pragma mark - 执行搜索请求（添加分页参数）

- (void)performSearchWithText:(NSString*)text {
    //关键词判断
    
    //赋值属性
    self.keyword = text;
    //执行搜索
    
}

- (void)refreshData{
    
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
    mycel.messageContentLabel.text = [self truncateString:model.lastestMessage.conversationDigest];
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
//
//    [UserModel getUserInfoWithUdid:targetId success:^(UserModel * _Nonnull userModel) {
//        [self updateCellUIWithUserId:userModel cell:mycel];
//    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
//
//    }];
    
    
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
    conversationVC.SearchKey = self.keyword;
    
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
    //如果没登录 就清空数据源 刷新表格
    
    //链接超时 重连
    
    [self refreshConversationTableViewIfNeeded];
    [self updateViewConstraints];
    
    //监听消息
    [[RCCoreClient sharedCoreClient] addReceiveMessageDelegate:self];
    //输入状态监听
    [[RCCoreClient sharedCoreClient] setRCTypingStatusDelegate:self];
    //阅后既焚监听器
    [[RCCoreClient sharedCoreClient] setRCMessageDestructDelegate:self];
    
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


@end
