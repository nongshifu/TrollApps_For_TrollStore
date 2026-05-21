//
//  VipPurchaseHistoryViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/10/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "VipPurchaseHistoryViewController.h"
#import "vip_purchase_historyCell.h"
#import "VipPurchaseHistoryModel.h"
#import "loadData.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <IGListKit/IGListKit.h>
#import "ShowOneOrderViewController.h"
#import "NewProfileViewController.h"

#undef MY_NSLog_ENABLED
#define MY_NSLog_ENABLED YES

#define kTopContainerHeight 160
#define kMargin 15

@interface VipPurchaseHistoryViewController ()<TemplateSectionControllerDelegate, UITextFieldDelegate>
@property (nonatomic, assign) BOOL sort;
@property (nonatomic, strong) NSString *keyword;
@property (nonatomic, copy) NSString *startTime;
@property (nonatomic, copy) NSString *endTime;
@property (nonatomic, assign) BOOL isAdmin;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) UISwitch *orderSwitch;
@property (nonatomic, assign) BOOL isShowAllOrder;

// 🔥 新增：订单状态筛选
@property (nonatomic, assign) OrderStatusType selectStatus;
@property (nonatomic, strong) UIButton *statusFilterBtn;

// 顶部视图
@property (nonatomic, strong) UIView *topContainer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UITextField *startTimeField;
@property (nonatomic, strong) UITextField *endTimeField;

@end

@implementation VipPurchaseHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.page = 1;
    self.dataSource = [NSMutableArray array];
    self.isLoading = NO;
    self.selectStatus = -1; // 默认：全部状态
    
    self.isAdmin = [loadData sharedInstance].userModel.role == 1;
    self.isShowAllOrder = NO;
    
    [self setupTopView];
    [self setupTimePickers];
    [self loadDataWithPage:self.page];
}

- (void)setupTopView {
    self.topContainer = [[UIView alloc] init];
    self.topContainer.backgroundColor = [UIColor systemBackgroundColor];
    self.topContainer.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    self.topContainer.layer.shadowOpacity = 0.1;
    self.topContainer.layer.shadowOffset = CGSizeMake(0, 2);
    [self.view addSubview:self.topContainer];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"VIP购买历史";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = [UIColor labelColor];
    [self.topContainer addSubview:self.titleLabel];
    
    self.orderSwitch = [[UISwitch alloc] init];
    [self.orderSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.orderSwitch.hidden = ![NewProfileViewController sharedInstance].userInfo.role;
    [self.topContainer addSubview:self.orderSwitch];
    
    self.startTimeField = [[UITextField alloc] init];
    self.startTimeField.placeholder = @"起始时间(yyyy-MM-dd)";
    self.startTimeField.font = [UIFont systemFontOfSize:13];
    self.startTimeField.borderStyle = UITextBorderStyleRoundedRect;
    self.startTimeField.delegate = self;
    self.startTimeField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    self.startTimeField.leftViewMode = UITextFieldViewModeAlways;
    [self.topContainer addSubview:self.startTimeField];
    
    self.endTimeField = [[UITextField alloc] init];
    self.endTimeField.placeholder = @"截止时间(yyyy-MM-dd)";
    self.endTimeField.font = [UIFont systemFontOfSize:13];
    self.endTimeField.borderStyle = UITextBorderStyleRoundedRect;
    self.endTimeField.delegate = self;
    self.endTimeField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    self.endTimeField.leftViewMode = UITextFieldViewModeAlways;
    [self.topContainer addSubview:self.endTimeField];
    
    // 搜索框
    self.searchField = [[UITextField alloc] init];
    self.searchField.placeholder = @"搜索订单号/UDID/套餐名称";
    self.searchField.font = [UIFont systemFontOfSize:14];
    self.searchField.borderStyle = UITextBorderStyleRoundedRect;
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.delegate = self;
    self.searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    [self.topContainer addSubview:self.searchField];
    
    // 🔥 新增：状态筛选按钮
    self.statusFilterBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.statusFilterBtn setTitle:@"筛选" forState:UIControlStateNormal];
    [self.statusFilterBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.statusFilterBtn.backgroundColor = [UIColor systemBlueColor];
    self.statusFilterBtn.layer.cornerRadius = 6;
    self.statusFilterBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.statusFilterBtn addTarget:self action:@selector(showStatusFilterAction) forControlEvents:UIControlEventTouchUpInside];
    [self.topContainer addSubview:self.statusFilterBtn];
    
    [self.collectionView removeFromSuperview];
    [self.view addSubview:self.collectionView];
    [self setupViewConstraints];
}

// 🔥 显示筛选菜单
- (void)showStatusFilterAction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"筛选订单状态" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *titles = @[@"全部", @"支付成功", @"已退款", @"已关闭", @"处理中"];
    NSArray *values = @[@(-1), @(1), @(2), @(3), @(4)];
    
    for (int i=0; i<titles.count; i++) {
        [alert addAction:[UIAlertAction actionWithTitle:titles[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.selectStatus = [values[i] integerValue];
            [self.statusFilterBtn setTitle:titles[i] forState:UIControlStateNormal];
            [self refreshWithResetPage:YES];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.statusFilterBtn;
        alert.popoverPresentationController.sourceRect = self.statusFilterBtn.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setupTimePickers {
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    datePicker.datePickerMode = UIDatePickerModeDate;
    if (@available(iOS 13.4, *) ) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPickTime)];
    UIBarButtonItem *spaceBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *confirmBtn = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(confirmPickTime:)];
    toolbar.items = @[cancelBtn, spaceBtn, confirmBtn];
    
    self.startTimeField.inputView = datePicker;
    self.startTimeField.inputAccessoryView = toolbar;
    self.endTimeField.inputView = datePicker;
    self.endTimeField.inputAccessoryView = toolbar;
}

- (void)cancelPickTime {
    [self.view endEditing:YES];
}

- (void)confirmPickTime:(UIBarButtonItem *)sender {
    UIDatePicker *picker = (UIDatePicker *)self.startTimeField.inputView;
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    NSString *timeStr = [fmt stringFromDate:picker.date];
    
    if (self.startTimeField.isFirstResponder) {
        self.startTimeField.text = timeStr;
        self.startTime = timeStr;
    } else if (self.endTimeField.isFirstResponder) {
        self.endTimeField.text = timeStr;
        self.endTime = timeStr;
    }
    [self.view endEditing:YES];
    [self refreshWithResetPage:YES];
}

- (void)switchValueChanged:(UISwitch *)sender {
    self.isShowAllOrder = sender.isOn;
    [self refreshWithResetPage:YES];
    NSString *tip = sender.isOn ? @"已切换：全网订单" : @"已切换：我的订单";
    [SVProgressHUD showSuccessWithStatus:tip];
    [SVProgressHUD dismissWithDelay:1];
}

- (void)setupViewConstraints {
    [self.topContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@(kTopContainerHeight));
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topContainer).offset(15);
        make.left.equalTo(self.topContainer).offset(kMargin);
    }];
    
    [self.orderSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.right.equalTo(self.topContainer.mas_right).offset(-kMargin);
    }];
    
    CGFloat timeUiWidth = (kWidth - kMargin *3)/2;
    [self.startTimeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
        make.left.equalTo(self.topContainer).offset(kMargin);
        make.width.equalTo(@(timeUiWidth));
        make.height.equalTo(@36);
    }];
    
    [self.endTimeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.startTimeField);
        make.left.equalTo(self.startTimeField.mas_right).offset(kMargin);
        make.width.equalTo(@(timeUiWidth));
        make.height.equalTo(@36);
    }];
    
    // 筛选按钮
    [self.statusFilterBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.searchField);
        make.right.equalTo(self.topContainer).offset(-kMargin);
        make.width.equalTo(@80);
        make.height.equalTo(@36);
    }];
    
    //搜索框
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.endTimeField.mas_bottom).offset(kMargin);
        make.left.equalTo(self.topContainer).offset(kMargin);
        make.right.equalTo(self.statusFilterBtn.mas_left).offset(-kMargin);
        make.height.equalTo(@36);
    }];
    
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topContainer.mas_bottom).offset(10);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)refreshWithResetPage:(BOOL)reset {
    if (reset) self.page = 1;
    [self loadDataWithPage:self.page];
}

- (void)loadDataWithPage:(NSInteger)page{
    if (self.isLoading) return;
    self.isLoading = YES;
    
    NSString *udid = [loadData sharedInstance].userModel.udid;
    if((!udid || udid.length<5) && !self.isAdmin){
        [SVProgressHUD showInfoWithStatus:@"获取UDID失败 请先登录"];
        [SVProgressHUD dismissWithDelay:1];
        self.isLoading = NO;
        return;
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    dic[@"page"] = @(page);
    dic[@"sort"] = @(self.sort);
    dic[@"keyword"] = self.keyword ?: @"";
    dic[@"action"] = @"getVipPurchaseHistory";
    dic[@"startTime"] = self.startTime ?: @"";
    dic[@"endTime"] = self.endTime ?: @"";
    
    // 🔥 新增：状态筛选
    if (self.selectStatus >= 0) {
        dic[@"status"] = @(self.selectStatus);
    }
    
    if (self.isAdmin && self.isShowAllOrder) {
        dic[@"target_udid"] = @"";
    } else {
        dic[@"target_udid"] = udid;
    }
    
    [SVProgressHUD showWithStatus:@"加载中..."];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                             modules:@"vip"
                                            parameters:dic
                                               progress:^(NSProgress *progress) {
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self endRefreshing];
            self.isLoading = NO;
            
            if (!jsonResult) {
                [SVProgressHUD showErrorWithStatus:@"数据格式错误"];
                return;
            }
            
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code == 200) {
                NSDictionary *data = jsonResult[@"data"];
                NSArray *list = data[@"list"] ?: @[];
                
                NSMutableArray *newModels = [NSMutableArray array];
                for (NSDictionary *item in list) {
                    VipPurchaseHistoryModel *model = [VipPurchaseHistoryModel yy_modelWithDictionary:item];
                    if (model) [newModels addObject:model];
                }
                
                self.hasMore = [data[@"pagination"][@"hasMore"] boolValue];
                if (page <= 1) {
                    self.dataSource = newModels;
                } else {
                    [self.dataSource addObjectsFromArray:newModels];
                }
                
                [self refreshTable];
                
            } else {
                [SVProgressHUD showErrorWithStatus:jsonResult[@"msg"]];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            self.isLoading = NO;
            [SVProgressHUD showErrorWithStatus:@"网络请求失败"];
        });
    }];
}

- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[VipPurchaseHistoryModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[vip_purchase_historyCell class] modelClass:[VipPurchaseHistoryModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 15, 10, 15) usingCacheHeight:NO];
    }
    return nil;
}

- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    if ([model isKindOfClass:[VipPurchaseHistoryModel class]]) {
        VipPurchaseHistoryModel *orderModel = (VipPurchaseHistoryModel *)model;
        ShowOneOrderViewController *vc = [ShowOneOrderViewController new];
        vc.targetOrderNo = orderModel.mch_orderid;
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self performSearchWithText:textField.text];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self performSearchWithText:@""];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (![textField.text isEqualToString:self.keyword]) {
        [self performSearchWithText:textField.text];
    }
}

- (void)performSearchWithText:(NSString *)searchText {
    [self.searchField resignFirstResponder];
    NSString *trimmedText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([trimmedText isEqualToString:self.keyword]) return;
    self.keyword = trimmedText;
    [self refreshWithResetPage:YES];
}

@end
