//
//  TTCHATViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "TTCHATViewController.h"
#import "UserProfileViewController.h"

#import "UIView.h"
//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface TTCHATViewController ()<RCIMClientReceiveMessageDelegate,RCTypingStatusDelegate,RCMessageDestructDelegate>

@end

@implementation TTCHATViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    //消息列表表格
    self.conversationMessageCollectionView.backgroundColor = [UIColor clearColor];
    self.conversationMessageCollectionView.delegate = self;
    self.conversationMessageCollectionView.dataSource = self;
    
    
    // 默认读取 30 条
    self.defaultHistoryMessageCountOfChatRoom = 30;
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
    self.tabBarController.tabBar.hidden = YES;
    
    //监听消息
    [[RCCoreClient sharedCoreClient] addReceiveMessageDelegate:self];
    //输入状态监听
    [[RCCoreClient sharedCoreClient] setRCTypingStatusDelegate:self];
    //阅后既焚监听器
    [[RCCoreClient sharedCoreClient] setRCMessageDestructDelegate:self];
    
    [self UpdateTheNumberOfUnreadMessages];
    [self updateViewConstraints];
    
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    // 1. 判断是否是模态弹出
    BOOL isModal = [self isModalPresented];
    if(isModal){
        self.view.backgroundColor = [UIColor systemBackgroundColor];

        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
        
        self.navigationItem.leftBarButtonItem = leftItem;
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

#pragma mark -监听主题
- (void)topBackageView{
    //创建一个空视图渐变色
    UIView * navigationControllerBackageView =[[UIView alloc] initWithFrame:CGRectMake(0,-( 100-self.navigationController.navigationBar.bounds.size.height), self.view.frame.size.width, 100)];
    navigationControllerBackageView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.95];
    NSUInteger gradientSize = 3; // 渐变色数组的大小
    CGFloat desiredAlpha = 0.3; // 设置透明度，范围为0到1之间
    [UIColor setColor:gradientSize desiredAlpha:desiredAlpha uiview:navigationControllerBackageView ColorType:WarmColor];
    
    //视图转图片
    UIImage *image =[self convertViewToPNG:navigationControllerBackageView];
    //顶部背景图
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    //清除分割线
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        [appearance configureWithOpaqueBackground];
        //此处变化----改变裁剪区域--->>>>>
        CGFloat h = get_TOP_NAVIGATION_BAR_HEIGHT +get_TOP_STATUS_BAR_HEIGHT;//记得适配头发帘屏
        //CGImageCreateWithImageInRect 是C的函数，使用的坐标都是像素
        //在iOS中使用的都是点坐标
        //所以在高分辨率的状态下加载了@2x或@3x的图片，而CGImageCreateWithImageInRect还是以@1x的尺寸去进行裁剪，最终只裁剪了部分尺寸的内容
        //[UIScreen mainScreen].scale -> 获取当前屏幕坐标与像素坐标的比例
        CGImageRef part = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, 0, image.size.width * [UIScreen mainScreen].scale, h * [UIScreen mainScreen].scale));
        
        UIImage *back = [UIImage imageWithCGImage:part];
        //这句要写，CGImageCreateWithImageInRect是c的方法要注意内存泄漏
        CGImageRelease(part);
        
        appearance.backgroundImage = back;
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance=self.navigationController.navigationBar.standardAppearance;
    }
    
}
///视图转PNG图片对象
- (UIImage *)convertViewToPNG:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        // 主题发生了变化，进行相应处理
        
//        [self topBackageView];
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // 设置状态栏样式
            self.navigationController.navigationBar.tintColor = [UIColor labelColor];
            [self setNeedsStatusBarAppearanceUpdate];
            // 强制视图重新布局和绘制
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        });
        
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    
    if (self.navigationController.viewControllers.count > 1) {
        CGPoint translation = [gesture translationInView:self.view];
        if (translation.x > 60 && fabs(translation.y) < fabs(translation.x)) {  // 增加垂直方向的限制
            [self back];
        }
    }
}

- (void)back{
    BOOL isModal = [self isModalPresented];
    if(isModal){
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
        
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

//搜索状态下的帖子正文获取标签变色
- (void)setupLabel:(UILabel *)label withKey:(NSString *)key {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label.text];
    UIColor *tagColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
    
    NSRange searchRange = NSMakeRange(0, label.text.length);
    while (searchRange.location < label.text.length) {
        // 使用 NSCaseInsensitiveSearch 选项进行不区分大小写的搜索
        NSRange range = [label.text rangeOfString:key options:NSCaseInsensitiveSearch range:searchRange];
        if (range.location != NSNotFound) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:tagColor range:range];
            searchRange.location = range.location + range.length;
            searchRange.length = label.text.length - searchRange.location;
        } else {
            break;
        }
    }
    label.attributedText = attributedString;
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

@end
