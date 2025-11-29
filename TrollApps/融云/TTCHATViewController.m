//
//  TTCHATViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TTCHATViewController.h"
#import "UserProfileViewController.h"
#import "ToolMessage.h"
#import "ToolMessageCell.h"
#import "UIView.h"
#import "ContactHelper.h"
#import "DemoBaseViewController.h"
//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface TTCHATViewController ()<RCIMClientReceiveMessageDelegate,RCTypingStatusDelegate,RCMessageDestructDelegate,UISearchResultsUpdating,UISearchBarDelegate>
@property (nonatomic, strong) NSTimer *searchTimer; // 搜索防抖定时器
@property (nonatomic, assign) long long startTime; // 开始时间
@property (nonatomic, strong) UIDatePicker *datePicker; // 时间选择器

@property (nonatomic, strong) UIView *headerView; // 时间选择器父视图
@property (nonatomic, assign) BOOL isRefresh; // 是否搜索总

@property (nonatomic, strong) NSMutableArray<RCMessage *> *messages;//搜索的数据数组
// 用于保存上一个页面的搜索控制器（退出时恢复）
@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) UIView *shareView;
@end

@implementation TTCHATViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    //消息列表表格
    self.conversationMessageCollectionView.backgroundColor = [UIColor clearColor];
    self.conversationMessageCollectionView.delegate = self;
    self.conversationMessageCollectionView.dataSource = self;
    
    //添加返回手势
    UIPanGestureRecognizer *g = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:g];
    
    //默认时间
    self.startTime = 0;
    // 默认读取 30 条
    self.defaultHistoryMessageCountOfChatRoom = 30;
    // 初始化数据
    self.messages = [NSMutableArray array];
    // 下拉刷新 30
    self.defaultMessageCount = 30;
    self.enableContinuousReadUnreadVoice = YES; // 语音连续播放
    self.enableUnreadMentionedIcon = YES; // @消息气泡
    self.enableUnreadMessageIcon = YES; // 未读消息气泡提示
    self.enableNewComingMessageIcon = YES; // 右下角新未读消息数量
    self.displayUserNameInCell = NO; // 隐藏用户昵称
    
    //输入区域背景图
    UIView *backview = [[UIView alloc] init];
    backview.frame = CGRectMake(0, 0, kWidth, kHeight);
    backview.backgroundColor = [UIColor systemBackgroundColor];
    [self.chatSessionInputBarControl addSubview:backview];
    [self.chatSessionInputBarControl sendSubviewToBack:backview];
    
    [UIColor setColor:3 desiredAlpha:0.3 uiview:backview ColorType:WarmColor];
    self.chatSessionInputBarControl.backgroundColor = [self.chatSessionInputBarControl.backgroundColor colorWithAlphaComponent:0.5];
    
    self.chatSessionInputBarControl.backgroundColor = [UIColor clearColor];
    self.chatSessionInputBarControl.pluginBoardView.backgroundColor = [UIColor clearColor];
    self.chatSessionInputBarControl.safeAreaView.backgroundColor =[UIColor clearColor];
    
    [self.chatSessionInputBarControl setCommonPhrasesList:@[@"你好,认识一下", @"看了你的动态很不错哦", @"啾咪，我来打招呼了！", @"哈喽,在干嘛呢", @"你好,我在的."]];
    self.chatSessionInputBarControl.backgroundColor = [UIColor secondarySystemBackgroundColor];
    
    [self registerClass:[ToolMessageCell class] forMessageClass:[ToolMessage class]];
    
    
    // 创建顶部容器视图
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    self.headerView.backgroundColor = [UIColor clearColor];
    self.headerView.hidden = YES;
    [self.view addSubview:self.headerView];
    // 设置时间选择器
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [self.datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.headerView addSubview:self.datePicker];
    
    [self setupNavigationBarWithSearch];
    

}


- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    
    [self.headerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.conversationMessageCollectionView.mas_top).offset(-5); // 顶部偏移量
        make.width.mas_equalTo(kWidth - 40);
        make.height.mas_equalTo(40);
        make.left.equalTo(self.view).offset(20);
    }];



}

- (void)setupNavigationBarWithSearch {
   
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
    
    // 配置导航项
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 滚动时不隐藏搜索框
    
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    closeItem.tintColor = [UIColor labelColor];
    
    // 地区选择按钮（移至右侧）
    UIBarButtonItem *chatItem = [[UIBarButtonItem alloc] initWithTitle:@"@ Ta" style:UIBarButtonItemStylePlain target:self action:@selector(contactButtonTap:)];
    chatItem.tintColor = [UIColor labelColor];
    
    // 1. 判断是否是模态弹出
    BOOL isModal = [self isModalPresented];
    //设置背景色
    self.view.backgroundColor = isModal?[UIColor systemBackgroundColor]:[UIColor clearColor];
    // 仅在模态时设置右侧关闭按钮，否则隐藏
    self.navigationItem.rightBarButtonItem = isModal ? closeItem : chatItem;
   
    
}

- (void)setupShareView{
    NSLog(@"设置分享页面 isShare:%d model:%@",self.isShare,self.shareModel);
    
    
    if(!self.isShare || !self.shareModel)return;
    self.shareView = [[UIView alloc] initWithFrame:CGRectMake(10, 200, 150, 200)];
    self.shareView.backgroundColor = [UIColor systemGrayColor];
    self.shareView.layer.cornerRadius = 15;
    [self.view addSubview:self.shareView];
    UIImageView *avaImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 130, 130)];
    avaImageView.backgroundColor = [UIColor systemBackgroundColor];
    avaImageView.layer.cornerRadius = 15;
    avaImageView.layer.masksToBounds = YES;
    avaImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.shareView addSubview:avaImageView];
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 145, 130, 50)];
    nameLabel.numberOfLines = 0;
    nameLabel.textColor = [UIColor labelColor];
    [self.shareView addSubview:nameLabel];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(35, 5, 80, 30)];
    [button setTitle:@"点击分享" forState:UIControlStateNormal];
    button.layer.cornerRadius = 15;
    button.backgroundColor = [UIColor systemOrangeColor];
    [button setTintColor:[UIColor whiteColor]];
    [button addTarget:self action:@selector(shareActio:) forControlEvents:UIControlEventTouchUpInside];
    [self.shareView addSubview:button];
    
    //赋值内容
    switch (self.messageForType) {
        case MessageForTypeTool:{
            WebToolModel *webToolModel = (WebToolModel *)self.shareModel;
            NSString *iconURL = [NSString stringWithFormat:@"%@/%@/icon.png", localURL,webToolModel.tool_path];
            NSLog(@"设置分享页面 iconURL:%@",iconURL);
            NSLog(@"设置分享页面 icon_url:%@",webToolModel.icon_url);
            [avaImageView sd_setImageWithURL:[NSURL URLWithString:webToolModel.icon_url]];
            nameLabel.text = webToolModel.tool_name;
            
        }
            
            break;
        case MessageForTypeApp:{
            AppInfoModel *appInfoModel = (AppInfoModel *)self.shareModel;
            [avaImageView sd_setImageWithURL:[NSURL URLWithString:appInfoModel.icon_url]];
            nameLabel.text = appInfoModel.app_name;
        }
            
            break;
        case MessageForTypeUser:{
            UserModel *userModel = (UserModel *)self.shareModel;
            [avaImageView sd_setImageWithURL:[NSURL URLWithString:userModel.avatar]];
            nameLabel.text = userModel.nickname;
        }
            
            break;
            
        default:
            break;
    }
    
    
}

/// 判断当前控制器是否是模态弹出
- (BOOL)isModalPresented {
    // 情况1：当前控制器直接被模态弹出（未包装在导航控制器中）
    if (self.presentingViewController != nil) {
        return YES;
    }
    
    // 情况2：当前控制器在导航控制器中，且导航控制器被模态弹出
    if (self.navigationController != nil && self.navigationController.presentingViewController != nil) {
        // 排除导航控制器被push的情况（仅判断被present的情况）
        if ([self.navigationController.presentingViewController isKindOfClass:[UINavigationController class]] ||
            [self.navigationController.presentingViewController isKindOfClass:[UITabBarController class]]) {
            return YES;
        }
    }
    
    // 情况3：当前控制器在标签控制器中，且标签控制器被模态弹出
    if (self.tabBarController != nil && self.tabBarController.presentingViewController != nil) {
        return YES;
    }
    
    return NO;
}

//点击关闭
- (void)back{
    BOOL isModal = [self isModalPresented];
    if(isModal){
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    
}

#pragma mark - action 函数

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

- (void)contactButtonTap:(UIBarButtonItem*)Item{
    [SVProgressHUD showWithStatus:nil];
    [UserModel getUserInfoWithUdid:self.targetId success:^(UserModel * _Nonnull userModel) {
        
        [SVProgressHUD dismiss];
        [[ContactHelper shared] showContactActionSheetWithUserInfo:userModel];
    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        [SVProgressHUD dismiss];
    }];
    
    
}

//最近使用
- (void)recently {
    
}

- (void)shareActio:(UIButton*)button {
    [self sendRcimMessage];
}

#pragma mark -监听主题

///视图转PNG图片对象
- (UIImage *)convertViewToPNG:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    
    if (self.navigationController.viewControllers.count > 1) {
        CGPoint translation = [gesture translationInView:self.view];
        if (translation.x > 60 && fabs(translation.y) < fabs(translation.x)) {  // 增加垂直方向的限制
            [self back];
        }
    }
}


#pragma mark -消息代理
- (void)onReceived:(RCMessage *)message left:(int)left object:(id)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"会话界面搜到消息message:%@ content:%@",message.objectName ,message.content);
        NSLog(@"会话界面搜到消息messageuser:%@ content:%@",message.content.extra ,message.content);
        if([message.targetId isEqualToString:self.targetId]){
            //插入当前会话
            [self appendAndDisplayMessage:message];
            UserModel *sendUserInfo =[UserModel yy_modelWithJSON:message.content.extra];
            if(sendUserInfo){
               
                [UserModel updateCloudUserInfoWithUserModel:sendUserInfo];
            }
            
            //如果在表格最下面 证明查看了最新消息 更新右下角红点为0
            BOOL AtBottom = [self checkIfTableViewAtBottom:self.conversationMessageCollectionView];
            NSLog(@"如果在：%@",self.unReadNewMessageLabel.superview);
            if(AtBottom){
                
                NSLog(@"如果在最底部 证明查看了最新消息 更新右下角红点为0");
                
                [[RCCoreClient sharedCoreClient] clearMessages:message.conversationType targetId:self.targetId completion:^(BOOL ret) {
                    if(ret){
                        //更新完成
                        
                    }
                }];
                
                
            }
            //如果是私聊 还要更新已读状态
            if(message.conversationType == ConversationType_PRIVATE){
                //发送已读
                [[RCCoreClient sharedCoreClient]
                 sendReadReceiptMessage:message.conversationType
                 targetId:message.targetId
                 time:message.sentTime
                 success:^{
                    
                } error:nil];
                
            }
        }
        if(left == 0){
            [self UpdateTheNumberOfUnreadMessages];
        }
    });
    
    
}

//更新未读消息
- (void)UpdateTheNumberOfUnreadMessages {
    __block int myCount = 0;
    [[RCCoreClient sharedCoreClient] getUnreadCount:self.conversationType targetId:self.targetId completion:^(int count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            myCount = count;
            // 更新当前会话未读标签（保留原有逻辑）
            if (myCount > 0) {
                self.unReadNewMessageLabel.text = [NSString stringWithFormat:@" %d ", count];
                self.unReadNewMessageLabel.superview.hidden = (count == 0);
            }
            
            // 获取总未读数量，计算左侧按钮的未读数量
            [[RCCoreClient sharedCoreClient] getTotalUnreadCountWith:^(int unreadCount) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    int newCount = unreadCount - myCount;
                    if(newCount >0){
                        // 1. 创建按钮（自定义类型，避免系统样式干扰）
                        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
                        backButton.backgroundColor = [UIColor redColor];
                        backButton.layer.cornerRadius = 10;
                        [backButton setTitle:[NSString stringWithFormat:@"%d",newCount] forState:UIControlStateNormal];
                        [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
                        backButton.layer.masksToBounds = YES;
                        backButton.contentEdgeInsets = UIEdgeInsetsMake(2, 10, 2, 10); // 左侧留边，避免贴边
                        [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
                        
                        self.navigationItem.leftBarButtonItem = leftItem;
                        
                    }
                   
                });
            }];
        });
    }];
}

//撤回提示
- (void)messageDidRecall:(RCMessage *)message{
    NSLog(@"聊天界面消息被撤回:%ld",message.messageId);
    for (RCMessageModel *model in self.conversationDataRepository) {
        if(model.messageId == message.messageId){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self deleteMessage:model];
                [SVProgressHUD showInfoWithStatus:@"对方撤回了消息"];
                [SVProgressHUD dismissWithDelay:0.3];
            });
        }
    }
    
}

//阅读后焚烧消息
- (void)onMessageDestructing:(nonnull RCMessage *)message remainDuration:(long long)remainDuration {
    NSLog(@"剩余时间:%lld",remainDuration);
    if(remainDuration>0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.conversationMessageCollectionView reloadData];
        });
    }else{
        for (RCMessageModel *model in self.conversationDataRepository) {
            if(model.messageId == message.messageId){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self deleteMessage:model];
                    [SVProgressHUD showInfoWithStatus:@"消息已焚烧"];
                    [SVProgressHUD dismissWithDelay:0.3];
                });
            }
        }
    }
    
}

//输入状态
- (void)onTypingStatusChanged:(RCConversationType)conversationType targetId:(nonnull NSString *)targetId status:(nullable NSArray<RCUserTypingStatus *> *)userTypingStatusList {
    NSLog(@"对方正在输入 类型：%ld  targetId:%@  userTypingStatusList:%ld",conversationType,targetId,userTypingStatusList.count);
    //获取导航栏文字
    
    //判断输入状态
    if(userTypingStatusList.count>0){
        RCUserTypingStatus *userTypingStatus =userTypingStatusList.firstObject;
        //获取消息类型
        NSString *contentType = userTypingStatus.contentType;
        NSLog(@"对方正在输入 消息类型：%@",contentType);
        
        if([contentType isEqualToString:@"RC:TxtMsg"]){
            self.title = @"对方正在输入中";
        }else if([contentType isEqualToString:@"RC:VcMsg"]){
            self.title = @"对方正在说话中";
        }
        
    }else{
        self.title = self.user.nickname;
    }
}


//头像点击
- (void)didTapCellPortrait:(NSString *)userId{
    
    NSLog(@"点击了私聊消息头像ID:%@",userId);

    UserProfileViewController *vc = [UserProfileViewController new];
    vc.user_udid = userId;
    [[self.view getTopViewController] presentPanModal:vc];
   

}

//检查显示位置
- (BOOL)checkIfTableViewAtBottom:(RCBaseCollectionView *)tableView {
    CGFloat contentHeight = tableView.contentSize.height;
    CGFloat tableViewHeight = tableView.frame.size.height;
    CGFloat currentOffset = tableView.contentOffset.y;
    
    if (currentOffset + tableViewHeight >= contentHeight) {
        // 表格在最底部
        NSLog(@"表格在最底部");
        return YES;
    }
    return NO;
}

#pragma mark - 主题变化

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

- (BOOL)isDarkMode {
    return self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
   
    
    [self setBackgroundUI];
}

#pragma mark - 控制器代理

// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO];
    self.tabBarController.tabBar.hidden = YES;
    
    //监听消息
    [[RCCoreClient sharedCoreClient] addReceiveMessageDelegate:self];
    //输入状态监听
    [[RCCoreClient sharedCoreClient] setRCTypingStatusDelegate:self];
    //阅后既焚监听器
    [[RCCoreClient sharedCoreClient] setRCMessageDestructDelegate:self];
    
    [self UpdateTheNumberOfUnreadMessages];
    [self updateViewConstraints];
    [self setBackgroundUI];
    
    // 1. 保存上一个页面的搜索控制器（用于返回时恢复）
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索聊天记录";
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    // 2. 清除当前导航栏的搜索控制器（核心：移除搜索框）
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = YES; // 确保搜索框不残留
    
    // 3. 重置导航栏样式（可选，确保高度正常）
    self.navigationController.navigationBar.translucent = YES; // 恢复默认半透明
    self.navigationController.navigationBar.barTintColor = [UIColor systemBackgroundColor]; // 重置背景色
    self.navigationController.navigationBar.shadowImage = [UIImage new]; // 移除底部阴影（若有）
    
    // 4. 强制刷新导航栏布局（解决高度计算异常）
    [self.navigationController.navigationBar layoutIfNeeded];
    
    // 5. 判断是否是模态弹出
    BOOL isModal = [self isModalPresented];
    //设置背景色
    self.view.backgroundColor = isModal?[UIColor systemBackgroundColor]:[UIColor clearColor];
    
    
   
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    //储存正在聊天的ID 用来判断是否显示通知 离开控制器后要删除
    [self setupShareView];
    
   
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 退出时恢复上一个页面的搜索控制器（确保返回社区页后搜索框正常显示）
    if (self.searchController) {
        self.navigationController.topViewController.navigationItem.searchController = self.searchController;
        self.navigationController.topViewController.navigationItem.hidesSearchBarWhenScrolling = NO; // 恢复社区页的搜索框配置
    }
}


#pragma mark - UISearchBarDelegate（补充状态监听）

// 1. 搜索框开始编辑（用户点击搜索框，进入编辑状态）→ 显示历史搜索视图
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // 显示历史搜索视图，并刷新历史搜索数据
    self.headerView.hidden = NO;
    // 刷新约束（确保视图位置正确）
    [self.view layoutIfNeeded];
}

// 2. 搜索框结束编辑（用户收起键盘、点击页面其他区域）→ 隐藏历史搜索视图
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.headerView.hidden = NO;
}

// 3. 点击搜索框“取消”按钮 → 重新初始化控制器
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // 1. 基础操作：收起键盘、清空输入框
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    self.keyword = @"";   // 清空关键词（关键：重置搜索标记）
    
    // 2. 重置搜索相关状态变量
    self.isRefresh = NO;  // 重置搜索刷新标记
    self.startTime = 0;   // 重置时间选择器初始值（对应“从最早开始”）
    [self.messages removeAllObjects]; // 清空搜索结果数组（关键：避免残留搜索数据）
    
    // 3. 隐藏搜索相关视图（时间选择器）
    self.headerView.hidden = YES;
    
    // 4. 核心：重新加载当前会话的原始历史消息（恢复非搜索状态的消息列表）
    [self reloadOriginalConversationMessages];
    
    // 5. 刷新未读消息计数（确保显示正确的未读状态）
    [self UpdateTheNumberOfUnreadMessages];
}

// 4. 点击搜索按钮（键盘Done键），执行搜索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self performSearchWithText:searchBar.text]; // 调用完善后的搜索方法
}

#pragma mark - UISearchResultsUpdating 代理（搜索防抖）
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    NSLog(@"输入过程2：%@", searchText);
    
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

// 辅助方法：重新加载当前会话的原始历史消息（从SDK获取，覆盖搜索结果）
- (void)reloadOriginalConversationMessages {
    // 显示加载提示（可选，提升用户体验）
    [SVProgressHUD showWithStatus:@"加载中..."];
    

    [[RCCoreClient sharedCoreClient] searchMessages:self.conversationType
                                           targetId:self.targetId
                                             userId:self.targetId
                                              count:100
                                          startTime:0
                                         completion:^(NSArray<RCMessage *> * _Nullable messages) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (RCMessage * message in messages) {
                RCMessageModel *rCMessageModel = [[RCMessageModel alloc] initWithMessage:message];
                [self.conversationDataRepository addObject:rCMessageModel];
                [SVProgressHUD dismissWithDelay:0.5];
            }
            [self.conversationMessageCollectionView reloadData];
        });
    }];
    
}

#pragma mark - 执行搜索请求（表层+深层历史消息）

- (void)performSearchWithText:(NSString *)text {
    self.keyword = text;
    NSLog(@"搜索：%@",self.keyword);
    [SVProgressHUD showWithStatus:@"搜索中"];
    self.startTime = (long long)([self.datePicker.date timeIntervalSince1970] * 1000);
    // 1. 关键词为空时，恢复原始数据并返回
    if (self.keyword.length == 0) {
        [SVProgressHUD dismissWithDelay:0.5];
        // 关键补充：关闭搜索框键盘（需在主线程执行）
        self.startTime = 0;
        return;

    }
    self.isRefresh = YES;
    [[RCCoreClient sharedCoreClient] searchMessages:ConversationType_PRIVATE
                                           targetId:self.targetId
                                            keyword:self.keyword
                                              count:100
                                          startTime:self.startTime
                                         completion:^(NSArray<RCMessage *> * _Nullable messages) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"搜索结果:%ld self.keyword：%@",messages.count,self.keyword);
            [SVProgressHUD dismissWithDelay:0.5];
            if (messages.count > 0) {
                if(self.isRefresh){
                    [self.messages removeAllObjects];
                    [self.conversationDataRepository removeAllObjects];
                }
                [self.messages addObjectsFromArray:messages];
                for (RCMessage * message in messages) {
                    RCMessageModel *rCMessageModel = [[RCMessageModel alloc] initWithMessage:message];
                    [self.conversationDataRepository addObject:rCMessageModel];
                }
                
                self.isRefresh = NO;
            }else{
                [SVProgressHUD showInfoWithStatus:@"搜索到 0 条"];
                [SVProgressHUD dismissWithDelay:1];
            }
            [self.conversationMessageCollectionView reloadData];
        });
    }];
}

#pragma mark - 时间选择器 UIDatePicker Action

- (void)datePickerValueChanged:(UIDatePicker *)datePicker {
    self.startTime = (long long)([datePicker.date timeIntervalSince1970] * 1000);
}

#pragma mark - 重写cell显示

- (void)willDisplayMessageCell:(RCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [super willDisplayMessageCell:cell atIndexPath:indexPath];
    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];
    if ([cell isKindOfClass:[RCTextMessageCell class]] && model.conversationType == ConversationType_PRIVATE) {
        // 转为对应的cell
        RCTextMessageCell *c =  (RCTextMessageCell *)cell;
        // 设置文字颜色
        [self setupLabel:c.textLabel withKey:self.keyword];
        
        //设置未读
        if (model.content && (model.sentStatus == SentStatus_READ ||model.sentStatus == SentStatus_SENT) && model.messageDirection == MessageDirection_SEND) {
            for (UIView *view in [((RCMessageCell *)cell).statusContentView subviews]) {
                if (view == ((RCMessageCell *)cell).messageFailedStatusView){
                    continue;
                }
                [view removeFromSuperview];
            }
            CGRect statusContentViewFrame = ((RCMessageCell *)cell).statusContentView.frame;
            UILabel *hasReadView = [[UILabel alloc] initWithFrame:CGRectMake(statusContentViewFrame.size.width-30,statusContentViewFrame.size.height-16, 30, 16)];
            hasReadView.textAlignment = NSTextAlignmentRight;
            hasReadView.font = [UIFont systemFontOfSize:10];
            hasReadView.textColor = [UIColor tertiaryLabelColor];
            hasReadView.tag = 1001;
            ((RCMessageCell *)cell).statusContentView.hidden = NO;
            if (model.sentStatus == SentStatus_READ) {
                hasReadView.text = @"已读";
                [((RCMessageCell *)cell).statusContentView addSubview:hasReadView];
            } else if (model.sentStatus == SentStatus_SENT) {
                hasReadView.text = @"未读";
                [((RCMessageCell *)cell).statusContentView addSubview:hasReadView];
            }
        }else{
            UIView *tagView = [((RCMessageCell *)cell).statusContentView viewWithTag:1001];
            if (tagView) {
                [tagView removeFromSuperview];
            }
        }
    }
    
}

//搜索状态下的帖子正文获取标签变色
- (void)setupLabel:(UILabel *)label withKey:(NSString *)key {
    if(label.text.length == 0 || key.length == 0)return;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label.text];

    NSRange range = [label.text rangeOfString:key];
    if (range.location!= NSNotFound) {
        UIColor *tagColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
        [attributedString addAttribute:NSForegroundColorAttributeName value:tagColor range:range];
    }
    label.attributedText = attributedString;
}

- (RCMessage *)willAppendAndDisplayMessage:(RCMessage *)message {
    if(self.keyword.length > 0 ){
        if(![message.content.conversationDigest containsString:self.keyword]) return nil;
    }
    return message;
}

- (void)sendRcimMessage{
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
    
    [[RCIM sharedRCIM] sendMessage:ConversationType_PRIVATE targetId:self.targetId content:message pushContent:message.content pushData:message.content success:^(long messageId) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.shareView.hidden = YES;
            self.isShare = NO;
            [self.conversationMessageCollectionView reloadData];
        });
    } error:^(RCErrorCode nErrorCode, long messageId) {
        
        
    }];
}

@end
