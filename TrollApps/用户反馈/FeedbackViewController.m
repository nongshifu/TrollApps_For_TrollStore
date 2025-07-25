//
//  FeedbackViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//

#import "FeedbackViewController.h"
#import "FeedbackCell.h"
#import "UserFeedbackModel.h"
#import "NewProfileViewController.h"
#import "config.h"
#import <Masonry/Masonry.h>
#import <YYModel/YYModel.h>

@interface FeedbackViewController ()<TemplateSectionControllerDelegate, UITextViewDelegate, TemplateListDelegate>

@property (nonatomic, strong) NSString *keyword;//搜索关键词
@property (nonatomic, strong) NSString *udid;//查询用户的UDID
@property (nonatomic, assign) BOOL isAdmin;//是否管理员 显示全部
@property (nonatomic, assign) FeedbackProgressStatus progress_status;//按处理进度
@property (nonatomic, assign) FeedbackType feedback_type;//按反馈类型

// UI组件
@property (nonatomic, strong) UIButton *submitFeedbackButton;//提交反馈按钮
@property (nonatomic, strong) UITextView *feedbackTextView;//反馈内容输入框
@property (nonatomic, strong) UILabel *placeholderLabel;//输入框占位提示
@property (nonatomic, strong) UILabel *typeTitleLabel;//类型选择标题
@property (nonatomic, strong) UIView *typeTabContainer;//类型选项卡容器
@property (nonatomic, strong) NSMutableArray<UIButton *> *typeButtons;//类型按钮数组
@property (nonatomic, strong) UIView *topContainerView;//顶部输入区域容器

@end

@implementation FeedbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"用户反馈";
    self.hidesVerticalScrollIndicator = YES;
    // 初始化默认反馈类型
    self.feedback_type = FeedbackTypeFeatureSuggestion;
    self.templateListDelegate = self;
    // 初始化UI
    [self setupSubviews];
    
    //加载数据
    [self loadDataWithPage:1];
   
    
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
}

#pragma mark - 写UI

- (void)setupSubviews {
    // 先移除父类的表格视图 去除约束
    [self.collectionView removeFromSuperview];
    // 重新添加
    [self.view addSubview:self.collectionView];
    self.collectionView.layer.cornerRadius = 8;
    self.collectionView.backgroundColor = [UIColor clearColor];
    

    // 顶部容器（包含输入框和选项卡）
    self.topContainerView = [[UIView alloc] init];
    
    self.topContainerView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9]
                                                               darkColor:[[UIColor whiteColor] colorWithAlphaComponent:0.1]];
    self.topContainerView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.topContainerView.layer.shadowOpacity = 0.05;
    self.topContainerView.layer.shadowRadius = 4;
    self.topContainerView.layer.cornerRadius = 5;
    self.topContainerView.layer.masksToBounds = YES;
    [self.view addSubview:self.topContainerView];
    
    // 反馈类型标题
    self.typeTitleLabel = [[UILabel alloc] init];
    self.typeTitleLabel.text = @"请选择反馈类型：";
    self.typeTitleLabel.font = [UIFont systemFontOfSize:15];
    self.typeTitleLabel.textColor = UIColor.labelColor;
    [self.topContainerView addSubview:self.typeTitleLabel];
    
    // 类型选项卡容器
    self.typeTabContainer = [[UIView alloc] init];
    self.typeTabContainer.backgroundColor = [UIColor colorWithLightColor:[UIColor systemGray6Color]
                                                               darkColor:[[UIColor whiteColor] colorWithAlphaComponent:0.2]];
    self.typeTabContainer.layer.cornerRadius = 8;
    [self.topContainerView addSubview:self.typeTabContainer];
    
    // 初始化类型按钮
    self.typeButtons = [NSMutableArray array];
    NSArray *typeTitles = @[
        @"功能建议", @"程序Bug", @"界面优化",
        @"内容错误", @"账号问题", @"其他"
    ];
    NSArray *typeValues = @[
        @(FeedbackTypeFeatureSuggestion),
        @(FeedbackTypeProgramBug),
        @(FeedbackTypeInterfaceOptimization),
        @(FeedbackTypeContentError),
        @(FeedbackTypeAccountIssue),
        @(FeedbackTypeOther)
    ];
    
    for (NSInteger i = 0; i < typeTitles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = [typeValues[i] integerValue];
        [button setTitle:typeTitles[i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        button.backgroundColor = UIColor.systemBackgroundColor;
        [button setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];

        button.layer.cornerRadius = 6;
        [button addTarget:self action:@selector(typeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.typeTabContainer addSubview:button];
        [self.typeButtons addObject:button];
    }
    // 默认选中第一个类型
    [self.typeButtons.firstObject setSelected:YES];
    //设置背景色
    [self typeButtonTapped:self.typeButtons.firstObject];
    
    // 反馈输入框
    self.feedbackTextView = [[UITextView alloc] init];
    self.feedbackTextView.font = [UIFont systemFontOfSize:16];
    self.feedbackTextView.textColor = UIColor.labelColor;
    
    self.feedbackTextView.backgroundColor = [UIColor colorWithLightColor:[UIColor systemGray6Color]
                                                               darkColor:[[UIColor whiteColor] colorWithAlphaComponent:0.2]];
    self.feedbackTextView.layer.cornerRadius = 8;
    self.feedbackTextView.layer.masksToBounds = YES;
    self.feedbackTextView.delegate = self;
    self.feedbackTextView.returnKeyType = UIReturnKeyDone;
    self.feedbackTextView.contentInset = UIEdgeInsetsMake(8, 8, 8, 8);
    [self.topContainerView addSubview:self.feedbackTextView];
    
    // 输入框占位符
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = @"请输入您的反馈内容...";
    self.placeholderLabel.font = [UIFont systemFontOfSize:15];
    self.placeholderLabel.textColor = UIColor.labelColor;
    [self.topContainerView addSubview:self.placeholderLabel];
    
    // 提交按钮
    self.submitFeedbackButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.submitFeedbackButton setTitle:@"提交反馈" forState:UIControlStateNormal];
    self.submitFeedbackButton.titleLabel.font = [UIFont systemFontOfSize:16];;
    [self.submitFeedbackButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.submitFeedbackButton.backgroundColor = UIColor.systemBlueColor;
    self.submitFeedbackButton.layer.cornerRadius = 8;
    self.submitFeedbackButton.layer.masksToBounds = YES;
    [self.submitFeedbackButton addTarget:self action:@selector(submitFeedbackAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.topContainerView addSubview:self.submitFeedbackButton];
}

#pragma mark - 设置和更新约束

//设置约束
- (void)setupViewConstraints {
    // 布局顶部容器
    [self.topContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(15);
        make.left.right.equalTo(self.view).inset(15);
    }];
    
    // 布局类型标题
    [self.typeTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.topContainerView).offset(10);
    }];
    
    // 布局类型选项卡容器（高度自适应内容）
    [self.typeTabContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.typeTitleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.topContainerView).inset(10); // 容器左右距离父视图10pt
        make.height.greaterThanOrEqualTo(@40); // 最小高度，实际高度由按钮撑开
    }];
    
    // 调用按钮布局方法（自动换行核心）
    [self setupTypeButtonsLayout];
    
    // 布局占位符
    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.typeTabContainer.mas_bottom).offset(10);
        make.left.equalTo(self.topContainerView.mas_left).offset(10);
    }];
    
    // 布局输入框
    [self.feedbackTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.placeholderLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.topContainerView).inset(10);
        make.height.equalTo(@100);
    }];
    
    
    
    // 布局提交按钮
    [self.submitFeedbackButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.feedbackTextView.mas_bottom).offset(15);
        make.left.right.equalTo(self.topContainerView).inset(10);
        make.height.equalTo(@44);
        make.bottom.equalTo(self.topContainerView).offset(-15);
    }];
    
    // 表格视图约束（合并冲突的旧约束）
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topContainerView.mas_bottom).offset(10);
        make.left.equalTo(self.view.mas_left).offset(15);
        make.right.equalTo(self.view.mas_right).offset(-15);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
    
}

//更新约束 拖动等会调用 适配UI
- (void)updateViewConstraints{
    //调用父类
    [super updateViewConstraints];
    //更新其他适配
    [UIView animateWithDuration:0.5 animations:^{
        if(self.isScrollingUp && self.scrollY >0 && self.scrollY <=100){
            [self.topContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view.mas_top).offset(- 190);
                make.left.equalTo(self.view.mas_left).offset(15);
                make.right.equalTo(self.view.mas_right).offset(-15);
                
            }];

            [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.topContainerView.mas_bottom).offset(10);
                make.left.equalTo(self.view.mas_left).offset(15);
                make.right.equalTo(self.view.mas_right).offset(-15);
                make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
            }];
            
        }else if(!self.isScrollingUp && self.scrollY <=20){
            [self.topContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view.mas_top).offset(0);
                make.left.equalTo(self.view.mas_left).offset(15);
                make.right.equalTo(self.view.mas_right).offset(-15);
                
            }];
            [self.topContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view).offset(20);
                make.left.equalTo(self.view.mas_left).offset(15);
                make.right.equalTo(self.view.mas_right).offset(-15);
                
            }];
        }
        
        // 关键点：添加这行代码强制立即布局
        [self.view layoutIfNeeded];
    }];
    

    
}

// 布局类型按钮（每行3个，自动换行，精确适配父容器）
- (void)setupTypeButtonsLayout {
    CGFloat totalHorizontalPadding = 12; // 容器左右总间距（左右各6pt）
    CGFloat buttonPadding = 8; // 按钮之间的间距
    CGFloat height = 25;
    NSInteger maxColumn = 3; // 每行最大列数
    
    // 先清除所有按钮的旧约束
    for (UIButton *button in self.typeButtons) {
        [button mas_remakeConstraints:^(MASConstraintMaker *make) {}];
    }
    
    // 遍历按钮设置约束
    for (NSInteger i = 0; i < self.typeButtons.count; i++) {
        UIButton *button = self.typeButtons[i];
        NSInteger row = i / maxColumn; // 当前行（0开始）
        NSInteger col = i % maxColumn; // 当前列（0-2）
        
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            // 1. 计算按钮宽度：(容器宽度 - 左右总间距 - 按钮间总间距) / 3
            // 容器宽度 = 父视图宽度 - 左右内边距，这里通过约束动态获取
            make.width.equalTo(self.typeTabContainer).multipliedBy(1.0/maxColumn)
            .offset(-(buttonPadding * (maxColumn - 1) + totalHorizontalPadding) / maxColumn);
            
            make.height.equalTo(@(height)); // 固定高度
            
            // 2. 水平位置：左对齐，扣除总间距
            if (col == 0) {
                // 第一列：距离容器左侧6pt（总间距的一半）
                make.left.equalTo(self.typeTabContainer).offset(totalHorizontalPadding / 2);
            } else {
                // 非第一列：距离前一列按钮右侧8pt
                UIButton *prevButton = self.typeButtons[i - 1];
                make.left.equalTo(prevButton.mas_right).offset(buttonPadding);
            }
            
            // 3. 垂直位置：上对齐
            if (row == 0) {
                // 第一行：距离容器顶部8pt
                make.top.equalTo(self.typeTabContainer).offset(buttonPadding);
            } else {
                // 非第一行：距离上一行同列按钮底部8pt
                UIButton *topButton = self.typeButtons[i - maxColumn];
                make.top.equalTo(topButton.mas_bottom).offset(buttonPadding);
            }
            
            // 4. 最后一行约束容器底部，确保容器高度足够
            if (i == self.typeButtons.count - 1) {
                make.bottom.equalTo(self.typeTabContainer).offset(-buttonPadding);
            }
            
            // 5. 强制最后一列按钮不超出父容器右侧
            if (col == maxColumn - 1) {
                make.right.lessThanOrEqualTo(self.typeTabContainer).offset(-totalHorizontalPadding / 2);
            }
        }];
    }
}

#pragma mark - 子类必须重写的方法 请求数据源
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page{
    self.udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if (!self.udid || self.udid.length < 10) {
        [self showAlertFromViewController:self title:@"提示" message:@"请先登录获取设备信息"];
        return;
    }
    //如果是重置第一页 删除全部数据
    if(self.page <=1){
        [self.dataSource removeAllObjects];
    }
    //封装请求字典 搜索条件
    NSDictionary *dic = @{
        @"action":@"queryFeedback",
        @"page":@(self.page),
        @"progress_status":@(self.progress_status),
        @"feedback_type":@(self.feedback_type),
        @"isAdmin":@(self.isAdmin),
        @"pageSize":@(20),
        @"keyword":self.keyword?:@"",
        @"udid":self.udid,
    };
    //封装URL
    NSString *url = [NSString stringWithFormat:@"%@/user_api.php",localURL];
    //请求的自己UDID
    NSString *myUdid = [NewProfileViewController sharedInstance].userInfo.udid ?:[NewProfileViewController sharedInstance].userInfo.idfv;
    //发送
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:myUdid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //结束刷新
            [self endRefreshing];
            NSLog(@"请求返回字符串:%@",stringResult);
            NSLog(@"请求返回字典:%@",jsonResult);
            if(!jsonResult && stringResult){
                [self showAlertFromViewController:self title:@"请求返回错误" message:stringResult];
                return;
                
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *msg = jsonResult[@"msg"];
            if(code != 200){
                [self showAlertFromViewController:self title:@"请求失败" message:msg];
                return;
            }
            //解析数据
            NSDictionary *data = jsonResult[@"data"];
            if(!data){
                [self showAlertFromViewController:self title:@"解析数据失败" message:@"返回data字典错误"];
                return;
            }
            NSArray *list = data[@"list"];
            for (NSDictionary *obj in list) {
                UserFeedbackModel *model = [UserFeedbackModel yy_modelWithDictionary:obj];
                if(model){
                    [self.dataSource addObject:model];
                }
            }
            //刷新表格
            [self refreshTable];
            
            //解析页码等信息
            NSDictionary *pagination = data[@"pagination"];
            NSInteger pages = [pagination[@"pages"] intValue];
            NSLog(@"返回的pagination：%@",pagination);
            
            //还有数据
            if(pages >self.page){
                //请求页面加1 加载下一页
                self.page+=1;
            }else{
                //结束尾部加载更多
                [self handleNoMoreData];
            }
            
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertFromViewController:self title:@"请求返回错误" message:[NSString stringWithFormat:@"%@",error]];
        });
    }];
    
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[UserFeedbackModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[FeedbackCell class] modelClass:[UserFeedbackModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 10, 0) usingCacheHeight:NO];
    }
    return nil;
}

/**
 * 当滚动视图滚动时调用此方法。
 *
 * @param offset 滚动视图的偏移量
 * @param isScrollingUp 表示滚动方向是否为向上滚动，YES 为向上滚动，NO 为向下滚动
 */
- (void)scrollViewDidScrollWithOffset:(CGFloat)offset isScrollingUp:(BOOL)isScrollingUp {
    if(isScrollingUp){
        NSLog(@"向上滚动:%f",offset);
    }else{
        NSLog(@"向下滚动:%f",offset);
    }
    self.isScrollingUp = isScrollingUp;
    [self updateViewConstraints];
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
    if([model isKindOfClass:[UserFeedbackModel class]]){
        UserFeedbackModel *userFeedbackModel = (UserFeedbackModel *)model;
        NSLog(@"userFeedbackModel_feedback_content：%@",userFeedbackModel.feedback_content);
        
        
    }
    
}


#pragma mark - 事件处理

// 类型按钮点击
- (void)typeButtonTapped:(UIButton *)button {
    // 取消其他按钮选中状态
    for (UIButton *btn in self.typeButtons) {
        btn.selected = NO;
        btn.backgroundColor = UIColor.systemBackgroundColor;
        [btn setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    }
    // 设置当前按钮选中
    button.selected = YES;
    // 更新反馈类型
    self.feedback_type = button.tag;
    button.backgroundColor = UIColor.systemBlueColor;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

// 提交反馈
- (void)submitFeedbackAction:(UIButton *)sender {
    NSLog(@"self.feedbackTextView.text:%@",self.feedbackTextView.text);
    // 验证输入内容
    NSString *content = [self.feedbackTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"content:%@",content);
    if (content.length == 0) {
        [self showAlertFromViewController:self title:@"提示" message:@"请输入反馈内容"];
        return;
    }
    
    // 验证UDID
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if (!udid || udid.length < 10) {
        [self showAlertFromViewController:self title:@"提示" message:@"请先登录获取设备信息"];
        return;
    }
    
    // 封装请求参数
    NSDictionary *params = @{
        @"action": @"submitFeedback",
        @"feedback_content": content,
        @"feedback_type": @(self.feedback_type),
        @"udid": udid
    };
    
    // 显示加载
    [SVProgressHUD showWithStatus:@"提交中..."];
    
    // 发送请求
    NSString *url = [NSString stringWithFormat:@"%@/user_api.php", localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url
                                             parameters:params
                                                   udid:udid
                                               progress:nil
                                                success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if(!jsonResult && stringResult){
                NSLog(@"stringResult:%@",stringResult);
                [self showAlertFromViewController:self title:@"返回数据错误" message:stringResult];
                return;
            }
            
            if ([jsonResult[@"code"] integerValue] == 200) {
                [self showAlertFromViewController:self title:@"成功" message:@"反馈提交成功，我们会尽快处理" confirmHandler:^{
                    // 清空输入框
                    self.feedbackTextView.text = @"";
                    
                    // 重新加载数据
                    [self loadDataWithPage:1];
                }];
            } else {
                [self showAlertFromViewController:self title:@"失败" message:jsonResult[@"msg"]];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self showAlertFromViewController:self title:@"错误" message:error.localizedDescription];
        });
    }];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {


}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];

    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {

    // 点击Done收起键盘
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}


#pragma mark - 辅助方法

// 带确认回调的弹窗
- (void)showAlertFromViewController:(UIViewController *)vc
                              title:(NSString *)title
                            message:(NSString *)message
                      confirmHandler:(void(^)(void))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        if (handler) handler();
    }]];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end
