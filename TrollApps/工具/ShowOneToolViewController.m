//
//  ShowOneToolViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/20.
//

#import "ShowOneToolViewController.h"
#import "NewToolViewController.h"
#import "CommentInputView.h"
#import "AppCommentCell.h"
#import "TipBarCell.h"
#import "loadData.h"
#import "NewProfileViewController.h"
#import "ToolViewCell.h"
#import "AppCommentCell.h"
#import "CommentModel.h"
#import "ContactHelper.h"

@interface ShowOneToolViewController ()<TemplateSectionControllerDelegate, UITextViewDelegate, UICollectionViewDelegate, CommentInputViewDelegate>
@property (nonatomic, assign) BOOL sort;//搜索排序 0 按最新时间 1 按最热门评论
@property (nonatomic, strong) CommentInputView *commentInputView;// 输入框容器（含发送按钮）
@property (nonatomic, assign) CGFloat originalInputHeight; // 输入框原始高度（默认40）
@property (nonatomic, assign) CGFloat expandedInputHeight; // 展开后高度（100）

@property (nonatomic, strong) UIButton *editButton;//编辑软件更新按钮
@property (nonatomic, strong) UIButton *editAppStatuButton;//删除软件按照

@end

@implementation ShowOneToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isTapViewToHideKeyboard = NO;
    self.originalInputHeight = 50;
    self.expandedInputHeight = 80;
    self.keyboardIsShow = NO;
    
    //导航
    [self setupNavigationBar];
    // 创建评论输入框
    [self setupInputView];
    // 注册键盘通知
    [self registerKeyboardNotifications];
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
    
    // 注册点击评论排序通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tipBarCellTapped:) name:kTipBarCellTappedNotification object:nil];
   
    [self refreshLoadInitialData];
}


- (void)setupNavigationBar {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, kWidth, 40)];
    label.text = @"查看工具";
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

/// 创建评论输入框及容器（仅初始化一次约束）
- (void)setupInputView {
    // 创建评论输入视图
    self.commentInputView = [[CommentInputView alloc] initWithOriginalHeight:50 expandedHeight:80];
    self.commentInputView.delegate = self;
    self.commentInputView.frame = CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 50);
    [self.view addSubview:self.commentInputView];

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


#pragma mark - Action 操作

///关闭
- (void)close:(UIButton*)button {
    [DemoBaseViewController triggerVibration];
    [self dismiss];
}

- (void)refresh:(UIButton*)button {
    [DemoBaseViewController triggerVibration];
    self.page = 1;
    [self loadDataWithPage:self.page];
}

///右上角刷新按钮
- (void)refresh {
    [self.dataSource removeAllObjects];
    self.page = 1;
    [self loadDataWithPage:1];
}

//左上角更新按钮
- (void)updateApp:(UIButton *)button {
    [DemoBaseViewController triggerVibration];
    NSLog(@"点击更新按钮 准备更新工具:%@",self.webToolModel.tool_name);
    NewToolViewController *vc = [NewToolViewController new];
    vc.isUpdating = YES;
    vc.webToolModel = self.webToolModel;
    [self presentPanModal:vc];
}

//左上角状态按钮
- (void)editAppStatu:(UIButton *)button {
    NSLog(@"点击删除按钮 准备更新软件:%@",self.webToolModel.tool_name);
    NSArray *title = @[@"正常发布", @"已失效", @"更新中", @"锁定", @"上传中", @"隐藏工具"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"操作提示" message:@"修改APP的显示状态" preferredStyle:UIAlertControllerStyleActionSheet];
    for (int i = 0; i<title.count; i++) {
        NSString *actionTitle = title[i];
        UIAlertActionStyle style = UIAlertActionStyleDefault;
        if(i>=1 && i<=4){
            style = UIAlertActionStyleDestructive;
        }
        // 添加按钮
        UIAlertAction*action = [UIAlertAction actionWithTitle:actionTitle style:style handler:^(UIAlertAction * _Nonnull action) {
            
            [self editAppInfoStatuWithIndex:i title:actionTitle];
        }];
        [alert addAction:action];
    }
    // 添加按钮
    UIAlertAction*cancel = [UIAlertAction actionWithTitle:@"取消操作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        
    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)editAppInfoStatuWithIndex:(NSInteger )index title:(NSString *)title{
    NSString *udid = [loadData sharedInstance].userModel.udid;
    if(!udid || udid.length<5){
        [SVProgressHUD showInfoWithStatus:@"请先获取UDID进行绑定登录"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    NSDictionary *dic = @{
        @"action":@"updateAppStatus",
        @"status_index":@(index),
        @"tool_id":@(self.webToolModel.tool_id),
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/tool_api.php",localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url
                                             parameters:dic
                                                   udid:udid progress:^(NSProgress *progress) {
        
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult && stringResult){
                [self showAlertFromViewController:[self.view getTopViewController] title:@"返回解析错误" message:stringResult];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSInteger new_status = [jsonResult[@"new_status"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if(code == 200){
               
                [self showAlertWithConfirmationFromViewController:[self.view getTopViewController] title:@"操作完成" message:[NSString stringWithFormat:@"已成功修改为\n%@",title] confirmTitle:@"确定" cancelTitle:@"取消" onConfirmed:^{
                    self.webToolModel.tool_status = new_status;
                    [self refreshLoadInitialData];
                } onCancelled:^{
                    
                }];
            }else{
                [self showAlertFromViewController:[self.view getTopViewController] title:@"操作失败" message:msg];
            }
        });
        
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertFromViewController:[self.view getTopViewController] title:@"错误" message:[NSString stringWithFormat:@"%@",error]];
        });
    }];
}


// 联系作者
- (void)continuousAuthor {
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    if (!udid || udid.length < 10) {
        [SVProgressHUD showInfoWithStatus:@"请先登录获取UDID绑定设备"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
    NSDictionary *dic = @{
        @"action": @"getUserInfo",
        @"type": @"user_id",
        @"queryValue":self.webToolModel.udid,
    };
    NSString *url = [NSString stringWithFormat:@"%@/user_api.php", localURL];
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url
                                             parameters:dic
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!jsonResult && stringResult) {
                [self showAlertFromViewController:self title:@"请求错误" message:stringResult];
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if (code == 200) {
                UserModel *userInfo = [UserModel yy_modelWithDictionary:jsonResult[@"data"]];
                [[ContactHelper shared] showContactActionSheetWithUserInfo:userInfo];
            } else {
                [self showAlertFromViewController:self title:@"错误" message:msg];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertFromViewController:self title:@"请求错误" message:error.localizedDescription];
        });
    }];
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



#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page {
    // 记录当前页码（避免多线程问题）
    NSInteger currentPage = page;
    
    // 第一页时清空数据源
    if (currentPage <= 1) {
        [self.dataSource removeAllObjects];
    }
    NSString *udid =[NewProfileViewController sharedInstance].userInfo.udid ?: [[NewProfileViewController sharedInstance] getIDFV];
    // 构建请求参数
    NSDictionary *dic = @{
        @"action": @"getToolDetail",
        @"sort": @(self.sort),
        @"tool_id": @(self.tool_id),
        @"pageSize": @(30),
        @"udid": udid,
        @"page": @(currentPage)
    };
    
    NSString *url = [NSString stringWithFormat:@"%@/tool_api.php",localURL];
    NSLog(@"请求URL:%@ 参数:%@", url, dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url
                                             parameters:dic
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"请求成功，返回数据stringResult: %@", stringResult);
            [self endRefreshing];
            // 验证返回数据格式
            if (!jsonResult) {
                NSLog(@"返回数据格式错误: %@", stringResult);
                [self handleErrorWithMessage:@"返回数据格式错误"];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSLog(@"请求成功，返回数据: %@", stringResult);
            
            NSString *message = jsonResult[@"msg"];
            if(code == 200){
                // 解析数据
                NSDictionary *data = jsonResult[@"data"];
                
                // 解析应用信息（始终放在数据源的第一个位置）
                NSDictionary *tool_info = data[@"tool"];
                NSLog(@"请求查看成功，tool_info: %@", tool_info);
                self.webToolModel = [WebToolModel yy_modelWithDictionary:tool_info];
                NSLog(@"请求查看工具成功，返回数据self.webToolModel: %@", self.webToolModel);
                // 确保应用信息有效
                if (self.webToolModel && self.webToolModel.tool_name) {
                    NSLog(@"确保应用信息有效tool_name: %@", self.webToolModel.tool_name);
                    
                    // 如果是第一页，替换原有应用信息；否则忽略（避免重复添加）
                    if (currentPage <= 1) {
                        if (self.dataSource.count > 0 && [self.dataSource[0] isKindOfClass:[WebToolModel class]]) {
                            [self.dataSource replaceObjectAtIndex:0 withObject:self.webToolModel];
                        } else {
                            [self.dataSource insertObject:self.webToolModel atIndex:0];
                        }
                    }
                    //显示更新按钮
                    BOOL isUpdateAPP = [self.webToolModel.udid isEqualToString:[NewProfileViewController sharedInstance].userInfo.udid];
                    self.editButton.alpha = isUpdateAPP;
                    self.editAppStatuButton.alpha = isUpdateAPP;
                    if(isUpdateAPP){
                        NSLog(@"显示更新按钮 准备更新软件:%@",self.webToolModel.tool_name);
                    }
                    
                }
                
                
                // 解析评论数据
                NSDictionary *commentsData = data[@"commentsData"];
                NSLog(@"请求查看帖子成功，commentsData: %@", commentsData);
                if(commentsData){
                    NSArray * comments = commentsData[@"comments"];
                    for (NSDictionary *commentDic in comments) {
                        NSLog(@"评论数据:%@",commentDic);
                        CommentModel *comment = [CommentModel yy_modelWithDictionary:commentDic];
                        comment.userInfo = [UserModel yy_modelWithDictionary:commentDic[@"userInfo"]];
                        NSLog(@"评论用户数据nickname:%@",comment.userInfo.nickname);
                        if (comment) {
                            [self.dataSource  addObject:comment];
                        }
                    }
                    TipBarModel *tipBarModel = [[TipBarModel alloc] initWithIconURL:@"message" tipText:@"这个应用怎么样？点评下吧！" leftButtonText:@"New" rightButtonText:@"Hot"];
                    
                    if(self.dataSource.count > 2){
                        id model = [self.dataSource objectAtIndex:1];
                        if (![model isKindOfClass:[TipBarModel class]]){
                            [self.dataSource insertObject:tipBarModel atIndex:1];
                        }
                    }else if(self.dataSource.count == 1){
                        
                        [self.dataSource insertObject:tipBarModel atIndex:1];
                    }
                    
                    [self refreshTable];
                    NSDictionary *pagination = commentsData[@"pagination"];
                    BOOL hasMore = [pagination[@"hasMore"] boolValue];
                    if(!hasMore || comments.count ==0){
                        [self handleNoMoreData];
                        
                    }else{
                        self.page +=1;
                    }
                }else{
                    [self refreshTable];
                }
                
            } else {
                [self handleErrorWithMessage:[NSString stringWithFormat:@"请求失败: %@", message]];
            }
        });
    }
                                                failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"网络请求失败: %@", error);
            [self handleErrorWithMessage:[NSString stringWithFormat:@"网络错误\n%@", error.localizedDescription]];
        });
    }];
}

// 处理错误信息
- (void)handleErrorWithMessage:(NSString *)message {
    [SVProgressHUD showErrorWithStatus:message];
    [SVProgressHUD dismissWithDelay:2];
    
    // 重置刷新状态
    [self endRefreshing];
}


/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if ([object isKindOfClass:[WebToolModel class]]) {
        // 移除 cellHeight 参数，启用高度缓存
        return [[TemplateSectionController alloc] initWithCellClass:[ToolViewCell class]
                                                         modelClass:[WebToolModel class]
                                                          delegate:self
                                                        edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10)
                                                   usingCacheHeight:YES];
    } else if ([object isKindOfClass:[CommentModel class]]) {
        // 同理，移除 cellHeight
        return [[TemplateSectionController alloc] initWithCellClass:[AppCommentCell class]
                                                         modelClass:[CommentModel class]
                                                          delegate:self
                                                        edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10)
                                                  usingCacheHeight:YES];
    } else if ([object isKindOfClass:[TipBarModel class]]) {
        // 同理，移除 cellHeight
        return [[TemplateSectionController alloc] initWithCellClass:[TipBarCell class]
                                                         modelClass:[TipBarModel class]
                                                          delegate:self
                                                        edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10) cellHeight:50];
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
    
    if([model isKindOfClass:[WebToolModel class]]){
        WebToolModel *tool_info = (WebToolModel *)model;
        if(tool_info.tool_id != self.tool_id){
            ShowOneToolViewController *vc = [ShowOneToolViewController new];
            vc.tool_id = tool_info.tool_id;
            [self presentPanModal:vc];
        }
        
    }
    
}

#pragma mark - CommentInputViewDelegate
- (void)commentInputViewDidSendComment:(NSString *)content {
    // 处理评论发送逻辑（替换原sendComment方法）
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
    Action_type comment_type = Comment_type_AppComment;
    NSDictionary *params = @{
        @"action": @"addComment",
        @"type": @(comment_type),
        @"tool_id": @(self.tool_id),
        @"content": commentContent,
        @"sort": @(self.sort),
        @"udid": udid
    };
    
    [SVProgressHUD showWithStatus:@"发送中..."];
    
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/tool_api.php",localURL]
                                             parameters:params
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"发布评论返回:%@",jsonResult);
        NSLog(@"发布评论stringResult返回:%@",stringResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [DemoBaseViewController triggerVibration];
            
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


//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return NO;
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self updateViewConstraints];
}


#pragma mark - 提示条按钮的点击通知监听

- (void)tipBarCellTapped:(NSNotification *)notification {
    TipBarCell *tipBarCell = (TipBarCell *)notification.object;
    TipBarModel *model = notification.userInfo[@"model"];
    NSNumber *buttonType = notification.userInfo[@"buttonType"];
    
    switch (buttonType.integerValue) {
        case 0:
            NSLog(@"图标被点击，cell: %@，model: %@", tipBarCell, model);
            //联系作者
            [self continuousAuthor];
            break;
        case 1:
            NSLog(@"文本标签被点击，cell: %@，model: %@", tipBarCell, model);
            
            break;
        case 2:
            NSLog(@"左按钮被点击，cell: %@，model: %@", tipBarCell, model);
            self.sort = NO;
            [self refresh];
            break;
        case 3:
            NSLog(@"右按钮被点击，cell: %@，model: %@", tipBarCell, model);
            self.sort = YES;
            [self refresh];
            break;
        default:
            break;
    }
    
}


@end
