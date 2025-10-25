//
//  moodStatusViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/21.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "moodStatusViewController.h"
#import "NetworkClient.h"
#import "NewProfileViewController.h"
#import "CustomMoodStatusNavView.h"
@interface moodStatusViewController ()<TemplateSectionControllerDelegate,CustomMoodStatusNavViewDelegate>
// 自定义导航视图
@property (nonatomic, strong) CustomMoodStatusNavView *customNavView;
// 日期选择器
@property (nonatomic, strong) UIDatePicker *datePicker;

@end

@implementation moodStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 添加自定义导航
    [self setupCustomNavigation];
    
    // 调整collectionView约束（下移，给导航留出空间）
    [self.collectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.customNavView.mas_bottom); // 顶部分割到导航下方
        make.left.right.bottom.equalTo(self.view);
    }];
    
    // 初始化时间（默认当前时间）
    self.startTime = [self formattedDateStringFromDate:[NSDate date]];
    self.customNavView.timeText = self.startTime;
    
    [self loadDataWithPage:1];
}

// 设置自定义导航
- (void)setupCustomNavigation {
    self.customNavView = [[CustomMoodStatusNavView alloc] init];
    self.customNavView.delegate = self;
    self.customNavView.titleText = @"状态列表"; // 设置标题
    self.customNavView.isSorted = self.sort; // 初始化排序状态
    [self.view addSubview:self.customNavView];
    
    // 导航视图约束（高度=导航栏44 + 时间行46 + 间距）
    [self.customNavView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@(44 + 46)); // 固定高度
    }];
    
    // 初始化日期选择器
    [self setupDatePicker];
}

// 初始化日期选择器
- (void)setupDatePicker {
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate; // 仅选择日期
    self.datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    self.datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"]; // 中文
}

// 格式化日期为字符串（YYYY-MM-DD）
- (NSString *)formattedDateStringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    return [formatter stringFromDate:date];
}

// 排序按钮点击
- (void)sortButtonTapped {
    // 切换排序状态
    self.sort = !self.sort;
    self.customNavView.isSorted = self.sort;
    
    // 重新加载第一页数据
    self.page = 1;
    [self.dataSource removeAllObjects];
    [self loadDataWithPage:self.page];
}

// 发布按钮点击（根据实际需求实现跳转）
- (void)publishButtonTapped {
    PublishMoodViewController *publishVC = [[PublishMoodViewController alloc] init];
    // 发布成功后刷新列表
    publishVC.publishSuccessBlock = ^{
        // 重新加载第一页数据
        self.page = 1;
        [self.dataSource removeAllObjects];
        [self loadDataWithPage:self.page];
    };
    [self presentPanModal:publishVC];
}

// 时间选择点击
- (void)timeSelectorTapped {
    // 1. 创建弹窗（使用ActionSheet样式，适配底部弹出）
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择开始时间"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 2. 获取弹窗的contentView（用于添加自定义视图，避免直接操作alert.view）
    UIView *contentView = alert.view.subviews.firstObject.subviews.firstObject;
    contentView.backgroundColor = [UIColor systemBackgroundColor]; // 适配主题
    
    // 3. 添加日期选择器到contentView
    [contentView addSubview:self.datePicker];
    
    // 4. 约束日期选择器（关键：底部留足按钮空间，避免重叠）
    [self.datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(contentView).inset(16); // 左右留边
        make.top.equalTo(contentView).offset(10); // 顶部留边
        make.height.equalTo(@200); // 固定选择器高度
        // 底部距离contentView底部留出60pt（给确定/取消按钮预留空间）
        make.bottom.equalTo(contentView).offset(-60);
    }];
    
    // 5. 确定按钮
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSDate *selectedDate = self.datePicker.date;
        self.startTime = [self formattedDateStringFromDate:selectedDate];
        self.customNavView.timeText = self.startTime;
        
        // 重新加载第一页数据
        self.page = 1;
        [self.dataSource removeAllObjects];
        [self loadDataWithPage:self.page];
    }];
    
    // 6. 取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    // 7. 适配iPad（弹窗位置）
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.customNavView;
        alert.popoverPresentationController.sourceRect = CGRectMake(self.customNavView.bounds.size.width/2, self.customNavView.bounds.size.height, 1, 1);
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 子类必须重写的方法

/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page{
    NSDictionary *dic = @{
        @"page": @(self.page),
        @"udid": self.udid ?: @"", // 简化空值判断
        @"sort": @(self.sort),
        @"startTime": self.startTime ?: @"",
        @"keyword": self.keyword ?: @"",
        @"action": @"getMoodList"
    };
    
    // 请求的登录用户udid
    NSString *myudid = [NewProfileViewController sharedInstance].userInfo.udid ?: [NewProfileViewController sharedInstance].idfv;
    NSString *myUdid = [NewProfileViewController sharedInstance].userInfo.udid;
    if(!myUdid || myUdid.length<5){
        [SVProgressHUD showInfoWithStatus:@"UDID获取失败  请先登录"];
        return;
    }
    // 接口地址
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php", localURL];
    
    // 发送请求
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                           urlString:url
                                          parameters:dic
                                               udid:myudid
                                             progress:^(NSProgress *progress) {
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 结束刷新状态
            [self endRefreshing];
            
            // 数据合法性校验
            if (!jsonResult) {
                NSLog(@"返回数据格式错误: %@", stringResult);
                [SVProgressHUD showErrorWithStatus:@"数据格式错误，请重试"];
                [SVProgressHUD dismissWithDelay:2];
                return;
            }
            
            NSLog(@"心情列表数据: %@", jsonResult);
            NSInteger code = [jsonResult[@"code"] integerValue];
            // 关键修改：后端错误提示的键是`msg`，且增加默认值
            NSString *message = jsonResult[@"msg"] ?: @"获取数据失败，请稍后重试";
            
            if (code == 200) { // 建议用宏定义SUCCESS（如200），避免硬编码
                NSDictionary *data = jsonResult[@"data"];
                NSArray *list = data[@"list"] ?: @[]; // 空数组兜底
                
                // 解析数据
                NSMutableArray *newModels = [NSMutableArray array];
                for (NSDictionary *item in list) {
                    MoodStatusModel *model = [MoodStatusModel yy_modelWithDictionary:item];
                    if (model) { // 过滤无效模型
                        [newModels addObject:model];
                    }
                }
                
                // 处理分页
                NSDictionary *pagination = data[@"pagination"] ?: @{};
                BOOL hasMore = [pagination[@"hasMore"] boolValue];
                
                if (self.page == 1) { // 第一页清空旧数据
                    self.dataSource = newModels;
                } else { // 分页加载追加数据
                    [self.dataSource addObjectsFromArray:newModels];
                }
                
                // 更新页码或标记无更多数据
                if (hasMore) {
                    self.page++;
                } else {
                    [self handleNoMoreData];
                }
                
                // 刷新表格
                [self refreshTable];
                
            } else {
                // 错误提示（使用后端返回的msg或默认文案）
                NSLog(@"获取心情列表失败: %@（错误码：%ld）", message, (long)code);
                [SVProgressHUD showErrorWithStatus:message];
                [SVProgressHUD dismissWithDelay:2];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            NSLog(@"网络请求错误: %@", error.localizedDescription);
            // 网络错误提示（更友好的文案）
            [SVProgressHUD showErrorWithStatus:@"网络连接失败，请检查网络"];
            [SVProgressHUD dismissWithDelay:2];
        });
    }];
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    return [[TemplateSectionController alloc] initWithCellClass:[moodStatusCell class] modelClass:[MoodStatusModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 0, 20) usingCacheHeight:NO];
}

#pragma mark - SectionController 代理协议


// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    if([model isKindOfClass:[MoodStatusModel class]]){
        MoodStatusModel *moodStatusModel = (MoodStatusModel *)model;
        NSLog(@"MoodStatusModel：%@",moodStatusModel);
        [self showDeleteAlertWithModel:moodStatusModel atIndex:index];
        
        
    }
    
}
#pragma mark - 弹出删除确认弹窗
- (void)showDeleteAlertWithModel:(MoodStatusModel *)model atIndex:(NSInteger)index {
    // 1. 创建底部弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除心情"
                                                                   message:@"确定要删除这条心情吗？"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 2. 删除按钮
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除"
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
        [self deleteMoodStatusWithId:model.mood_id atIndex:index];
    }];
    
    // 3. 取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    
    
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 调用删除接口
- (void)deleteMoodStatusWithId:(NSInteger)moodId atIndex:(NSInteger)index {
    // 1. 显示加载中
    [SVProgressHUD showWithStatus:@"删除中..."];
    // 2. 获取当前用户UDID（用于权限验证）
    NSString *myUdid = [NewProfileViewController sharedInstance].userInfo.udid;
    if(!myUdid || myUdid.length<5){
        [SVProgressHUD showInfoWithStatus:@"UDID获取失败  请先登录"];
        return;
    }
    // 3. 构建请求参数
    NSDictionary *params = @{
        @"action": @"deleteMood",
        @"udid": myUdid,
        @"mood_id": @(moodId) // 要删除的心情ID
    };
    
    
    if (myUdid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录"];
        return;
    }
    
    // 4. 接口地址
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php", localURL];
    
    // 5. 发送删除请求
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                           urlString:url
                                          parameters:params
                                               udid:myUdid
                                             progress:nil
                                              success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (!jsonResult) {
                [SVProgressHUD showErrorWithStatus:@"删除失败，数据格式错误"];
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] integerValue];
            NSString *message = jsonResult[@"msg"] ?: @"删除失败，请重试";
            
            if (code == 200) {
                [SVProgressHUD showSuccessWithStatus:@"删除成功"];
                
                // 6. 从数据源中移除该模型并刷新列表
                if (index < self.dataSource.count) {
                    [self.dataSource removeObjectAtIndex:index];
                    [self refreshTable]; // 刷新表格
                }
            } else {
                [SVProgressHUD showErrorWithStatus:message];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"删除失败：%@", error.localizedDescription]];
        });
    }];
}
@end
