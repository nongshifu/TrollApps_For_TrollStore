//
//  ShowOnePostViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2026/3/23.
//  Copyright © 2026 iOS_阿玮. All rights reserved.
//

#import "ShowOnePostViewController.h"
#import "NewProfileViewController.h"
#import "TipBarCell.h"
#import "TipBarModel.h"
#import "CommentInputView.h"
#import "PostPublishViewController.h"
#import "ContactHelper.h"
#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@interface ShowOnePostViewController ()<CommentInputViewDelegate>
@property (nonatomic, strong) TipBarModel *tipBarModel;
@property (nonatomic, assign) CGFloat originalInputHeight; // 输入框原始高度（默认40）
@property (nonatomic, assign) CGFloat expandedInputHeight; // 展开后高度（100）

@property (nonatomic, strong) CommentInputView *commentInputView;// 输入框容器（含发送按钮）

@property (nonatomic, strong) UIButton *editButton;//编辑软件更新按钮
@property (nonatomic, strong) UIButton *editAppStatuButton;//删除软件按照
@end

@implementation ShowOnePostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 注册点击评论排序通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tipBarCellTapped:) name:kTipBarCellTappedNotification object:nil];
    
    
    
    self.isTapViewToHideKeyboard = NO;
    self.originalInputHeight = 50;
    self.expandedInputHeight = 80;
    self.keyboardIsShow = NO;
    //注册键盘通知
    [self registerKeyboardNotifications];
    //导航
    [self setupNavigationBar];
    // 创建评论输入框
    [self setupInputView];
    
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    
    [self loadPostData];
    

    
}

/// 创建评论输入框及容器（仅初始化一次约束）
- (void)setupInputView {
    // 创建评论输入视图
    self.commentInputView = [[CommentInputView alloc] initWithOriginalHeight:50 expandedHeight:80];
    self.commentInputView.delegate = self;
    self.commentInputView.frame = CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 50);
    [self.view addSubview:self.commentInputView];

}

- (void)setupNavigationBar {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, kWidth, 40)];
    label.text = @"查看帖子";
    label.font = [UIFont systemFontOfSize:18];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    UIButton *button = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"chevron.compact.down"] target:self action:@selector(close:)];
    button.frame = CGRectMake(kWidth - 45, 10, 30, 30);
    button.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.8];
    button.layer.cornerRadius = 15;
    [self.view addSubview:button];
    
    UIButton *button2 = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"repeat"] target:self action:@selector(refresh:)];
    button2.frame = CGRectMake(kWidth - 95, 10, 40, 30);
    [button2 addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
    button2.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.8];
    button2.layer.cornerRadius = 15;
    [self.view addSubview:button2];
    
    self.editButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.editButton.frame = CGRectMake(15, 10, 50, 30);
    self.editButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.8];
    self.editButton.layer.cornerRadius = 15;
    self.editButton.alpha = 0;
    [self.editButton setTitle:@"更新" forState:UIControlStateNormal];
    [self.editButton addTarget:self action:@selector(updateApp:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.editButton];
    
    self.editAppStatuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.editAppStatuButton.frame = CGRectMake(75, 10, 50, 30);
    self.editAppStatuButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.8];
    self.editAppStatuButton.layer.cornerRadius = 15;
    self.editAppStatuButton.alpha = 0;
    [self.editAppStatuButton setTitle:@"状态" forState:UIControlStateNormal];
    [self.editAppStatuButton addTarget:self action:@selector(editAppStatu:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.editAppStatuButton];
}

/// 注册键盘通知
- (void)registerKeyboardNotifications {
    // 键盘弹出通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    // 键盘收起通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

/// 键盘即将弹出
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardHeight = keyboardFrame.size.height;
    self.keyboardIsShow = YES;
    self.commentInputView.keyboardHeight = keyboardFrame.size.height;
    self.commentInputView.keyboardIsShow = YES;
    [self updateViewConstraints];
}

/// 键盘即将收起
- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    self.keyboardIsShow = NO;
    self.commentInputView.keyboardIsShow = NO;
    [self updateViewConstraints];

}


#pragma mark - 约束相关

- (void)setupViewConstraints {
    // 更新collectionView约束
    self.collectionView.translatesAutoresizingMaskIntoConstraints = YES;
    self.collectionView.frame = CGRectMake(0, 50, kWidth, self.viewHeight - 100);
    
    CGFloat offsHeight = self.keyboardIsShow ? self.keyboardHeight : 0;
    self.commentInputView.frame = CGRectMake(0, self.viewHeight - offsHeight - self.originalInputHeight, kWidth, self.originalInputHeight);
    
    self.commentInputView.textView.frame = CGRectMake(10, 8, kWidth - 90, self.keyboardIsShow ? self.expandedInputHeight -10 : self.originalInputHeight -10);
}

/// 系统布局回调（仅更新约束，不处理动画）
- (void)updateViewConstraints {
    [super updateViewConstraints];
    // 更新collectionView约束
    self.collectionView.translatesAutoresizingMaskIntoConstraints = YES;
    self.collectionView.frame = CGRectMake(0, 50, kWidth, self.viewHeight - 100);
    
    CGFloat offsHeight = self.keyboardIsShow ? self.keyboardHeight : 0;
    self.commentInputView.frame = CGRectMake(0, self.viewHeight - offsHeight - self.originalInputHeight, kWidth, self.originalInputHeight);
    self.commentInputView.textView.frame = CGRectMake(10, 8, kWidth - 90, self.keyboardIsShow ? self.expandedInputHeight -10 : self.originalInputHeight -10);

}

#pragma mark - 加载主帖子数据
- (void)loadPostData{
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    // 修正参数：补充topic_id，修复udid/keyword的空值处理
    
    NSDictionary *dic = @{
        @"action":@"getOnePostData",
        @"udid":udid, // 原代码错误：udid?@"":@"" → 改为直接传udid（空则为空字符串）
        @"post_id":@(self.postModel.post_id),
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/post/post_api.php",localURL]
                                             parameters:dic
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            
            if(!jsonResult){
                [SVProgressHUD showErrorWithStatus:@"返回数据错误"];
                [SVProgressHUD dismissWithDelay:1];
                NSLog(@"返回格式错误：%@",stringResult);
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"] ?: @"";
            
            if(code != 200){
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"返回错误码:%ld\n%@",(long)code,msg]];
                [SVProgressHUD dismissWithDelay:3];
                return;
            }
            
            NSDictionary *data = jsonResult[@"data"] ?: @{};
            NSLog(@"返回帖子data：%@",data);
            PostModel *model = [PostModel yy_modelWithDictionary:data];
            if (model) {
                self.postModel = model;
                self.post_id = model.post_id;
                self.post_uuid = model.post_uuid;
                [self.dataSource insertObject:model atIndex:0];
                
                if(!self.tipBarModel){
                    self.tipBarModel = [[TipBarModel alloc] initWithIconURL:@"https://img2.baidu.com/it/u=4010382319,3987420383&fm=253&fmt=auto&app=138&f=PNG?w=256&h=256" tipText:@"这个帖子怎么样？点评下吧！" leftButtonText:@"New" rightButtonText:@"Hot"];
                    [self.dataSource insertObject:self.tipBarModel atIndex:1];
                }
                
                [self refreshTable];
                
                //显示更新按钮
                BOOL isUpdateAPP = [self.postModel.udid isEqualToString:[NewProfileViewController sharedInstance].userInfo.udid];
                BOOL isAdmin = [NewProfileViewController sharedInstance].userInfo.role;
                self.editButton.alpha = isUpdateAPP || isAdmin;
                
                //加载评论
                [self loadDataWithPage:1];
            }
            
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            NSLog(@"读取错误:%@",error.localizedDescription);
            [SVProgressHUD showErrorWithStatus:@"网络请求失败"];
            [SVProgressHUD dismissWithDelay:1];
        });
    }];
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page {
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    // 修正参数：补充topic_id，修复udid/keyword的空值处理
    
    NSDictionary *dic = @{
        @"action":@"getPostComment",
        @"udid":udid, // 原代码错误：udid?@"":@"" → 改为直接传udid（空则为空字符串）
        @"page":@(page), // 用传入的page，而非self.page（避免页码错乱）
        @"post_id":@(self.postModel.post_id),
        
        @"sort_type":@(self.sort_type)
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/post/post_api.php",localURL]
                                             parameters:dic
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            
            if(!jsonResult){
                [SVProgressHUD showErrorWithStatus:@"返回数据错误"];
                [SVProgressHUD dismissWithDelay:1];
                NSLog(@"返回格式错误：%@",stringResult);
                return;
            }
            NSLog(@"返回stringResult：%@",stringResult);
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"] ?: @"";
            
            if(code != 200){
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"返回错误码:%ld\n%@",(long)code,msg]];
                [SVProgressHUD dismissWithDelay:3];
                return;
            }
            
            NSDictionary *data = jsonResult[@"data"] ?: @{};
            NSLog(@"返回data：%@",data);
            
            if(page <=1){
                [self.dataSource removeAllObjects];
                [self.dataSource addObject:self.postModel];
                [self.dataSource addObject:self.tipBarModel];
            }
            
            NSArray *comments = data[@"comments"] ?: @[];
            NSLog(@"返回comments：%@",comments);
            
            for (NSDictionary *dic in comments) {
                NSLog(@"返回dic：%@",dic);
                CommentModel *model = [CommentModel yy_modelWithDictionary:dic];
                if (model) { // 非空判断：避免nil模型加入数据源
                    model.userInfo = [UserModel yy_modelWithDictionary:dic[@"userInfo"]];
                    [self.dataSource addObject:model];
                }
            }
            
            [self refreshTable];
            
            NSDictionary *pagination = data[@"pagination"] ?: @{};
            BOOL has_more = [pagination[@"has_more"] boolValue];
            if(!has_more){
                [self handleNoMoreData];
            }else{
                self.page = page + 1; // 修正：用当前page+1，而非self.page+=1
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            NSLog(@"读取错误:%@",error.localizedDescription);
            [SVProgressHUD showErrorWithStatus:@"网络请求失败"];
            [SVProgressHUD dismissWithDelay:1];
        });
    }];
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
#pragma mark - 返回SectionController
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[PostModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[PostCell class]
                                                         modelClass:[PostModel class]
                                                           delegate:self
                                                         edgeInsets:UIEdgeInsetsMake(5, 5, 5, 5) // 调整内边距，适配Cell卡片
                                                   usingCacheHeight:YES]; // 开启高度缓存，优化性能
    }else if([object isKindOfClass:[CommentModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[AppCommentCell class]
                                                         modelClass:[CommentModel class]
                                                           delegate:self
                                                         edgeInsets:UIEdgeInsetsMake(5, 5, 5, 5) // 调整内边距，适配Cell卡片
                                                   usingCacheHeight:YES]; // 开启高度缓存，优化性能
    } else if ([object isKindOfClass:[TipBarModel class]]) {
        // 同理，移除 cellHeight
        return [[TemplateSectionController alloc] initWithCellClass:[TipBarCell class]
                                                         modelClass:[TipBarModel class]
                                                          delegate:self
                                                         edgeInsets:UIEdgeInsetsMake(5, 5, 5, 5) // 调整内边距，适配Cell卡片
                                                         cellHeight:50];
    }
    return nil;
}


#pragma mark - SectionController 代理协议

/// 刷新指定Cell
- (void)refreshCell:(UICollectionViewCell *)cell {
    NSLog(@"刷新指定Cell:%@",cell);
}


// 原始索引回调（保留 IGListKit 原生行为）
- (void)templateSectionController:(TemplateSectionController *)sectionController
             didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"点击了index:%ld",index);
}

// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    
    if([model isKindOfClass:[CommentModel class]]){
        CommentModel *commentModel = (CommentModel *)model;
        self.commentInputView.textView.text = [NSString stringWithFormat:@"@%@ ",commentModel.userInfo.nickname];
        self.commentInputView.textPromptLabel.hidden = YES;
        [self.commentInputView highlightAtUserInTextView:self.commentInputView.textView];
        
    }
    
}

#pragma mark - 提示条按钮的点击通知监听
- (void)tipBarCellTapped:(NSNotification *)notification {
    TipBarCell *tipBarCell = (TipBarCell *)notification.object;
    self.tipBarModel = notification.userInfo[@"model"];
    NSNumber *buttonType = notification.userInfo[@"buttonType"];
    
    switch (buttonType.integerValue) {
        case 0:
            NSLog(@"图标被点击，cell: %@，model: %@", tipBarCell, self.tipBarModel);
            //联系作者
            [self continuousAuthor];
            break;
        case 1:
            NSLog(@"文本标签被点击，cell: %@，model: %@", tipBarCell, self.tipBarModel);
            // 选中输入框并弹出键盘
            [self.commentInputView.textView becomeFirstResponder];
            break;
        case 2:
            NSLog(@"左按钮被点击，cell: %@，model: %@", tipBarCell, self.tipBarModel);
            self.sort_type = NO;
            [self refresh];
            break;
        case 3:
            NSLog(@"右按钮被点击，cell: %@，model: %@", tipBarCell, self.tipBarModel);
            self.sort_type = YES;
            [self refresh];
            break;
        default:
            break;
    }
    
}


#pragma mark - Action 操作

///关闭
- (void)close:(UIButton*)button {
    [self dismiss];
}

- (void)refresh:(UIButton*)button {
    self.page = 1;
    [self loadDataWithPage:self.page];
}

///右上角刷新按钮
- (void)refresh {
    
    [self.dataSource removeAllObjects];
    [self loadPostData];
    self.page = 1;
    [self loadDataWithPage:1];
}

//左上角更新按钮
- (void)updateApp:(UIButton *)button {
    
    PostPublishViewController *vc = [PostPublishViewController new];
    vc.postModel = self.postModel;
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nv animated:YES completion:nil];
}

//左上角状态按钮
- (void)editAppStatu:(UIButton *)button {
    
    NSArray *title = @[@"正常发布", @"已失效", @"更新中", @"锁定", @"上传中", @"隐藏软件", @"删除软件"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"操作提示" message:@"修改APP的显示状态" preferredStyle:UIAlertControllerStyleActionSheet];
    for (int i = 0; i<title.count; i++) {
        NSString *actionTitle = title[i];
        UIAlertActionStyle style = UIAlertActionStyleDefault;
        if(i>=1 ){
            style = UIAlertActionStyleDestructive;
        }
        // 添加按钮
        UIAlertAction*action = [UIAlertAction actionWithTitle:actionTitle style:style handler:^(UIAlertAction * _Nonnull action) {
            
            [self editAppInfoStatuWithIndex:i title:actionTitle];
        }];
        [alert addAction:action];
    }
    // 添加按钮
    UIAlertAction*cancel = [UIAlertAction actionWithTitle:@"取消操作" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        
    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)editAppInfoStatuWithIndex:(NSInteger )index title:(NSString *)title{
    
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if(!udid || udid.length<5){
        [SVProgressHUD showInfoWithStatus:@"请先获取UDID进行绑定登录"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
}


// 联系作者
- (void)continuousAuthor {
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    if (!udid || udid.length < 10) {
        [SVProgressHUD showInfoWithStatus:@"请先登录获取UDID绑定设备"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    [UserModel getUserInfoWithUdid:self.postModel.udid success:^(UserModel * _Nonnull userModel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ContactHelper shared] showContactActionSheetWithUserInfo:userModel];
        });
    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertFromViewController:self title:@"错误" message:errorMsg];
        });
    }];
   
}

#pragma mark - CommentInputViewDelegate

- (void)commentInputViewDidSendComment:(NSString *)content {
    if(content.length == 0){
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"smiley.fill"] status:@"请输入评论内容"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    [self.commentInputView.textView resignFirstResponder];
    [self sendComment];
}

/// 发送评论
- (void)sendComment {
    NSLog(@"点击发送按钮");
    NSString *commentContent = [self.commentInputView.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (commentContent.length == 0) {
        [SVProgressHUD showInfoWithStatus:@"评论内容不能为空"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    
    // 隐藏键盘
    [self.commentInputView.textView resignFirstResponder];
    
    NSString *udid =[NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    // 构建请求参数（根据实际接口调整）
    Action_type comment_type = Comment_type_PostComment;
    NSDictionary *params = @{
        @"action": @"comment",
        
        @"to_id": @(self.postModel.post_id),
        @"content": commentContent,
        @"action_type": @(comment_type),
        @"udid": udid
    };
    
    [SVProgressHUD showWithStatus:@"发送中..."];
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/post/post_api.php",localURL]
                                             parameters:params
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"发布评论返回:%@",jsonResult);
        NSLog(@"发布评论stringResult返回:%@",stringResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult || !jsonResult[@"code"]){
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"];
            
            if (code == 200) {
                [SVProgressHUD showSuccessWithStatus:msg];
                self.commentInputView.textView.text = @""; // 清空输入框
                self.commentInputView.textPromptLabel.alpha = 1;
                // 刷新评论列表（重新加载第一页）
                [self loadDataWithPage:1];
                NSString *messageText = [NSString stringWithFormat:@"我评论了你的帖子：\n%@",commentContent];
                [SendMessage sendRCIMTextMessageToUDID:self.postModel.udid messageText:messageText success:^{
                    
                } error:^(NSString * _Nonnull errorMsg) {
                    
                }];
            } else {
                [SVProgressHUD showErrorWithStatus:msg];
            }
            [SVProgressHUD dismissWithDelay:1];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"网络错误，发送失败"];
        [SVProgressHUD dismissWithDelay:2];
    }];
}


#pragma mark - 控制器函数
//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return NO;
}

@end
