//
//  ShowOneOrderViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/12/2.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "ShowOneOrderViewController.h"
#import "config.h"
#import "ContactHelper.h"
#import "NewProfileViewController.h"
#import "VipPurchaseHistoryModel.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <YYModel/YYModel.h> // 用于JSON转模型（若未集成，可替换为手动解析）

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

// 颜色配置（现代化配色，可按需修改）
#define kMainColor [UIColor colorWithRed:0.22 green:0.66 blue:0.96 alpha:1.0]     // 主色（蓝）
#define kSuccessColor [UIColor colorWithRed:0.16 green:0.72 blue:0.32 alpha:1.0]  // 成功色（绿）
#define kFailColor [UIColor colorWithRed:0.95 green:0.20 blue:0.20 alpha:1.0]     // 失败色（红）
#define kRefundColor [UIColor colorWithRed:0.94 green:0.53 blue:0.00 alpha:1.0]   // 退款色（橙）
#define kTitleColor [UIColor labelColor]                                          // 标题色（深灰）
#define kSubtitleColor [UIColor secondaryLabelColor]                              // 副标题色（浅灰）
#define kCardColor [UIColor systemBackgroundColor]                                // 卡片背景色
#define kBgColor [UIColor colorWithRed:0.96 green:0.96 blue:0.98 alpha:1.0]       // 页面背景色
#define kSeparatorColor [UIColor colorWithRed:0.92 green:0.92 blue:0.94 alpha:1.0]// 分隔线色

// 字体配置
#define kTitleFont [UIFont systemFontOfSize:16 weight:UIFontWeightMedium]
#define kContentFont [UIFont systemFontOfSize:15 weight:UIFontWeightRegular]
#define kSmallFont [UIFont systemFontOfSize:13 weight:UIFontWeightLight]

@interface ShowOneOrderViewController ()

/// 订单模型
@property (nonatomic, strong) VipPurchaseHistoryModel *orderModel;

/// UI控件（新增：套餐介绍标签）
@property (nonatomic, strong) UIView *cardView;         // 主卡片视图
@property (nonatomic, strong) UILabel *statusLabel;     // 订单状态标签
@property (nonatomic, strong) UILabel *orderNoLabel;    // 订单号
@property (nonatomic, strong) UILabel *packageLabel;    // 套餐名称
@property (nonatomic, strong) UILabel *vipDescriptionLabel; // 套餐介绍（新增）
@property (nonatomic, strong) UILabel *priceLabel;      // 价格
@property (nonatomic, strong) UILabel *vipLevelLabel;   // VIP等级
@property (nonatomic, strong) UILabel *downloadsLabel;  // 下载次数
@property (nonatomic, strong) UILabel *vipDayLabel;     // VIP天数
@property (nonatomic, strong) UILabel *purchaseTimeLabel;// 购买时间
@property (nonatomic, strong) UILabel *transactionIdLabel;// 交易ID
@property (nonatomic, strong) UILabel *udidLabel;       // UDID
@property (nonatomic, strong) UILabel *idfvLabel;       // IDFV
@property (nonatomic, strong) UIButton *operateOrderButton;        // 操作订单
@property (nonatomic, strong) UIButton *contactHelperButton;       // 联系作者
/// 状态视图
@property (nonatomic, strong) UIActivityIndicatorView *loadingView; // 加载中
@property (nonatomic, strong) UIView *emptyView;        // 空数据/请求失败视图
@property (nonatomic, assign) BOOL isAdmin;        // 是否是管理员

@end

@implementation ShowOneOrderViewController

#pragma mark - 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.isAdmin = [NewProfileViewController sharedInstance].userInfo.role;
    [self setupBaseConfig];
    [self setupUI];
    [self setupConstraints];
    [self fetchOrderData]; // 加载订单数据
}


#pragma mark - 基础配置
- (void)setupBaseConfig {
    self.view.backgroundColor = kBgColor;
    self.title = @"订单详情";
    
    // 导航栏配置
    self.navigationController.navigationBar.barTintColor = [UIColor systemBackgroundColor];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    
    // SVProgressHUD配置
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeNative];
}

#pragma mark - UI搭建
- (void)setupUI {
    // 1. 主卡片视图（带阴影、圆角）
    _cardView = [[UIView alloc] init];
    _cardView.backgroundColor = kCardColor;
    _cardView.layer.cornerRadius = 16;
    _cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    _cardView.layer.shadowOpacity = 0.08;
    _cardView.layer.shadowRadius = 10;
    _cardView.layer.shadowOffset = CGSizeMake(0, 4);
    _cardView.layer.masksToBounds = NO;
    [self.view addSubview:_cardView];
    
    // 2. 订单状态标签（顶部突出显示）
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.layer.cornerRadius = 20;
    _statusLabel.layer.masksToBounds = YES;
    [_cardView addSubview:_statusLabel];
    //操作订单按钮
    _operateOrderButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_operateOrderButton setTitle:@"编辑状态" forState:UIControlStateNormal];
    [_operateOrderButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    [_operateOrderButton setBackgroundColor:[UIColor systemBackgroundColor]];
    _operateOrderButton.layer.cornerRadius = 15;
    _operateOrderButton.hidden = ![NewProfileViewController sharedInstance].userInfo.role;
    [_operateOrderButton addTarget:self action:@selector(operateOrderButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_operateOrderButton];
    // 联系客服
    _contactHelperButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_contactHelperButton setTitle:@"联系客服" forState:UIControlStateNormal];
    [_contactHelperButton addTarget:self action:@selector(contactHelperButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_contactHelperButton];
    
    // 3. 订单信息列表（核心修改：添加套餐介绍，用局部变量中转）
    UILabel *localOrderNoLabel = nil;
    UILabel *localPackageLabel = nil;
    UILabel *localVipDescriptionLabel = nil; // 新增：套餐介绍局部变量
    UILabel *localPriceLabel = nil;
    UILabel *localVipLevelLabel = nil;
    UILabel *localDownloadsLabel = nil;
    UILabel *localVipDayLabel = nil;
    UILabel *localPurchaseTimeLabel = nil;
    UILabel *localTransactionIdLabel = nil;
    UILabel *localUdidLabel = nil;
    UILabel *localIdfvLabel = nil;
    
    // 4. 订单信息列表（标题+内容 成对展示）传递局部变量的地址
    [self addInfoItemWithTitle:@"订单编号" contentLabel:&localOrderNoLabel];
    [self addInfoItemWithTitle:@"套餐名称" contentLabel:&localPackageLabel];
    [self addInfoItemWithTitle:@"套餐介绍" contentLabel:&localVipDescriptionLabel]; // 新增：套餐介绍条目
    [self addInfoItemWithTitle:@"支付金额" contentLabel:&localPriceLabel];
    [self addInfoItemWithTitle:@"VIP等级" contentLabel:&localVipLevelLabel];
    [self addInfoItemWithTitle:@"下载次数" contentLabel:&localDownloadsLabel];
    [self addInfoItemWithTitle:@"VIP有效期" contentLabel:&localVipDayLabel];
    [self addInfoItemWithTitle:@"购买时间" contentLabel:&localPurchaseTimeLabel];
    [self addInfoItemWithTitle:@"交易ID" contentLabel:&localTransactionIdLabel];
    [self addInfoItemWithTitle:@"设备UDID" contentLabel:&localUdidLabel];
    [self addInfoItemWithTitle:@"设备IDFV" contentLabel:&localIdfvLabel];
    
    // 5. 局部变量赋值给实例变量（新增套餐介绍标签赋值）
    self.orderNoLabel = localOrderNoLabel;
    self.packageLabel = localPackageLabel;
    self.vipDescriptionLabel = localVipDescriptionLabel; // 新增
    self.priceLabel = localPriceLabel;
    self.vipLevelLabel = localVipLevelLabel;
    self.downloadsLabel = localDownloadsLabel;
    self.vipDayLabel = localVipDayLabel;
    self.purchaseTimeLabel = localPurchaseTimeLabel;
    self.transactionIdLabel = localTransactionIdLabel;
    self.udidLabel = localUdidLabel;
    self.idfvLabel = localIdfvLabel;
    
    // 6. 加载中视图
    _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _loadingView.color = kMainColor;
    [self.view addSubview:_loadingView];
    
    // 7. 空数据/请求失败视图（默认隐藏）
    [self setupEmptyView];
}

#pragma mark - 添加信息项（通用方法，支持自适应高度）
/// 批量创建「标题+内容」标签组（修改：去掉固定高度，支持多行自适应）
- (void)addInfoItemWithTitle:(NSString *)title contentLabel:(UILabel **)contentLabel {
    // 容器视图（包裹标题和内容）
    UIView *itemView = [[UIView alloc] init];
    [_cardView addSubview:itemView];
    
    // 标题标签
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.textColor = kSubtitleColor;
    titleLabel.font = kSmallFont;
    titleLabel.numberOfLines = 0; // 标题也支持多行（防止标题过长）
    [itemView addSubview:titleLabel];
    
    // 内容标签
    UILabel *contentLbl = [[UILabel alloc] init];
    contentLbl.textColor = kTitleColor;
    contentLbl.font = kContentFont;
    contentLbl.numberOfLines = 0; // 支持多行显示（核心：套餐介绍可能多行）
    contentLbl.lineBreakMode = NSLineBreakByWordWrapping; // 按单词换行，更美观
    [itemView addSubview:contentLbl];
    *contentLabel = contentLbl;
    
    // 约束（标题左对齐，内容右对齐，自适应高度）
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(itemView);
        make.width.mas_equalTo(80);
        make.height.greaterThanOrEqualTo(@20); // 标题最小高度20pt
    }];
    
    [contentLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right).offset(12);
        make.top.right.bottom.equalTo(itemView);
        make.height.greaterThanOrEqualTo(@20); // 内容最小高度20pt
    }];
    
    // 分隔线（最后一个item不显示）
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = kSeparatorColor;
    [itemView addSubview:separator];
    
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel);
        make.right.equalTo(itemView);
        make.bottom.equalTo(itemView);
        make.height.mas_equalTo(1);
    }];
}

#pragma mark - 空数据/请求失败视图
- (void)setupEmptyView {
    _emptyView = [[UIView alloc] init];
    _emptyView.hidden = YES;
    [self.view addSubview:_emptyView];
    
    // 图标（替换为更贴合订单的图标）
    UIImageView *emptyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star"]];
    emptyIcon.tintColor = kSubtitleColor;
    emptyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_emptyView addSubview:emptyIcon];
    
    // 提示文字
    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"暂无订单数据";
    emptyLabel.textColor = kSubtitleColor;
    emptyLabel.font = kContentFont;
    [_emptyView addSubview:emptyLabel];
    
    // 重新加载按钮
    UIButton *reloadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [reloadBtn setTitle:@"重新查询" forState:UIControlStateNormal];
    [reloadBtn setTitleColor:kMainColor forState:UIControlStateNormal];
    reloadBtn.titleLabel.font = kContentFont;
    reloadBtn.layer.borderColor = kMainColor.CGColor;
    reloadBtn.layer.borderWidth = 1;
    reloadBtn.layer.cornerRadius = 8;
    [reloadBtn addTarget:self action:@selector(fetchOrderData) forControlEvents:UIControlEventTouchUpInside];
    [_emptyView addSubview:reloadBtn];
    
    // 约束
    [_emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.mas_equalTo(200);
    }];
    
    [emptyIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.equalTo(_emptyView);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    [emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emptyIcon.mas_bottom).offset(16);
        make.centerX.equalTo(_emptyView);
    }];
    
    [reloadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emptyLabel.mas_bottom).offset(20);
        make.centerX.equalTo(_emptyView);
        make.size.mas_equalTo(CGSizeMake(120, 40));
    }];
}

#pragma mark - 约束布局（修改：支持自适应高度）
- (void)setupConstraints {
    // 主卡片约束（左右留边，顶部距离导航栏20pt，底部自适应）
    [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(50);
        make.bottom.lessThanOrEqualTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.top.greaterThanOrEqualTo(self.view.mas_safeAreaLayoutGuideTop).offset(20); // 最小顶部距离
    }];
    
    // 状态标签约束（顶部居中，宽120，高40）
    [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_cardView).offset(-20);
        make.centerX.equalTo(_cardView);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40);
    }];
    
    // 信息项约束（垂直排列，自适应高度）
    NSArray *itemViews = [_cardView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[UIView class]] && evaluatedObject != self->_statusLabel;
    }]];
    
    // 按添加顺序排序（垂直排列）
    [itemViews enumerateObjectsUsingBlock:^(UIView *itemView, NSUInteger idx, BOOL * _Nonnull stop) {
        [itemView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_cardView).offset(20);
            make.right.equalTo(_cardView).offset(-20);
            
            // 去掉固定高度，让itemView自适应内容高度（核心修改）
            make.height.greaterThanOrEqualTo(@50); // 最小高度50pt，内容多则自动增高
            
            if (idx == 0) {
                // 第一个item在状态标签下方20pt
                make.top.equalTo(_cardView).offset(30);
            } else {
                // 后续item在前面item下方（无缝衔接）
                UIView *prevItem = itemViews[idx-1];
                make.top.equalTo(prevItem.mas_bottom);
            }
            
            // 最后一个item的底部距离卡片底部20pt
            if (idx == itemViews.count - 1) {
                make.bottom.equalTo(_cardView).offset(-20);
            }
        }];
    }];
    
    // 加载中视图约束（居中）
    [_loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    // 状态标签约束（顶部居中，宽120，高40）
    [_contactHelperButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-20);
        make.centerX.equalTo(_cardView);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40);
    }];
    
    // 状态标签约束（顶部居中，宽120，高40）
    [_operateOrderButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView.mas_bottom).offset(20);
        make.centerX.equalTo(_cardView);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40);
    }];
}

#pragma mark - 网络请求：查询订单数据
- (void)fetchOrderData {
    if (!self.targetOrderNo || self.targetOrderNo.length ==0) {
        [SVProgressHUD showErrorWithStatus:@"订单号为空"];
        
        return;
    }
    
    // 显示加载中
    [_loadingView startAnimating];
    _cardView.hidden = YES;
    _emptyView.hidden = YES;
    NSDictionary *dic = @{
        @"action":@"queryOrderDetail",
        @"mch_orderid":self.targetOrderNo
    };
  
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                modules:@"vip"
                                             parameters:dic
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        //返回主线程UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.loadingView stopAnimating];
            
            if (!jsonResult) {
                NSString *message = [NSString stringWithFormat:@"查询失败，返回数据错误\n%@",jsonResult];
               
                [SVProgressHUD showErrorWithStatus:message];
                return;
            }
            NSLog(@"查询订单返回jsonResult：%@",jsonResult);
            // 注意：PHP端成功返回的code是 SUCCESS 200
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code != 200) { // 这里要和PHP端的SUCCESS常量一致（PHP中SUCCESS=0）
                NSString *msg = jsonResult[@"msg"] ?: @"订单不存在";
                [SVProgressHUD showErrorWithStatus:msg];
                
                return;
            }
            
            // JSON转模型（直接映射，包含新增的vipDescription字段）
            NSDictionary *orderData = jsonResult[@"data"];
            NSLog(@"orderData:%@",orderData);
            self.orderModel = [VipPurchaseHistoryModel yy_modelWithDictionary:orderData];
            if (!self.orderModel) {
                [SVProgressHUD showErrorWithStatus:@"订单数据异常"];
                
                return;
            }
            
            // 更新UI
            self.cardView.hidden = NO;
            [self updateOrderUI];
        });
    } failure:^(NSError *error) {
        
    }];
   
    
    
}

#pragma mark - 更新订单UI（新增：填充套餐介绍字段）
- (void)updateOrderUI {
    VipPurchaseHistoryModel *model = self.orderModel;
    NSArray *array = @[@"订单失败", @"订单成功", @"订单退款", @"订单关闭", @"处理中"];
    _statusLabel.text = array[model.status];
    // 1. 订单状态（设置颜色和文字）
    switch (model.status) {
        case OrderStatusTypeSuccess: // 成功
            
            _statusLabel.backgroundColor = kSuccessColor;
            break;
        case OrderStatusTypeFailure: // 待支付（原失败改为待支付，更准确）
            
            _statusLabel.backgroundColor = [UIColor colorWithRed:0.55 green:0.55 blue:0.57 alpha:1.0]; // 灰色
            break;
        case OrderStatusTypeRefund: // 退款
            _statusLabel.backgroundColor = kSubtitleColor;
            break;
        case OrderStatusTypeCLOSED: // 关闭
            _statusLabel.backgroundColor = kSubtitleColor;
            break;
        case OrderStatusTypePROCESSING: // 处理
            _statusLabel.backgroundColor = kSubtitleColor;
            break;
        default:
            
            _statusLabel.backgroundColor = kSubtitleColor;
            break;
    }
    
    // 2. 填充各个字段（处理空值，显示"--"）
    _orderNoLabel.text = model.mch_orderid ?: @"--";
    _packageLabel.text = model.packageTitle ?: @"--";
    _vipDescriptionLabel.text = model.vipDescription ?: @"--"; // 新增：套餐介绍
    _priceLabel.text = model.price ?: @"--";
    _vipLevelLabel.text = model.vipLevel > 0 ? [NSString stringWithFormat:@"%ld级", model.vipLevel] : @"--";
    _downloadsLabel.text = model.downloadsNumber == 0 ? @"无限次" : [NSString stringWithFormat:@"%ld次", model.downloadsNumber];
    _vipDayLabel.text = model.vipDay == 0 ? @"永久" : [NSString stringWithFormat:@"%ld天", model.vipDay];
    _purchaseTimeLabel.text = model.purchaseTime ?: @"--";
    _transactionIdLabel.text = model.transactionId ?: @"--";
    _udidLabel.text = model.udid ?: @"--";
    _idfvLabel.text = model.idfv ?: @"--";
    
    // 日志输出（包含套餐介绍）
    NSLog(@"订单ID：%@",model.mch_orderid);
    NSLog(@"订单标题：%@",model.packageTitle);
    NSLog(@"套餐介绍：%@",model.vipDescription ?: @"无");
    NSLog(@"订单金额：%@",model.price);
    NSLog(@"订单UDID：%@",model.udid);
    NSLog(@"订单创建时间：%@",model.purchaseTime);
    NSLog(@"交易ID：%@",model.transactionId);
    
    // 3. 长按复制功能（套餐介绍也支持复制）
    [self addCopyActionToLabel:_orderNoLabel];
    [self addCopyActionToLabel:_transactionIdLabel];
    [self addCopyActionToLabel:_udidLabel];
    [self addCopyActionToLabel:_vipDescriptionLabel];
    [self addCopyActionToLabel:_purchaseTimeLabel];
    [self addCopyActionToLabel:_orderNoLabel];
}

#pragma mark - 标签长按复制功能
- (void)addCopyActionToLabel:(UILabel *)label {
    label.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(copyLabelText:)];
    tapGesture.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:tapGesture];
}

- (void)copyLabelText:(UITapGestureRecognizer *)gesture {
    
    
    UILabel *label = (UILabel *)gesture.view;
    if (!label.text || [label.text isEqualToString:@"--"]) return;
    
    // 复制到剪贴板
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = label.text;
    
    [SVProgressHUD showSuccessWithStatus:@"已复制"];
    [SVProgressHUD dismissWithDelay:1.5];
}

- (void)contactHelperButtonTap:(UIButton *)button {
    // 1. 获取管理员列表
    [UserModel getAdminListFromNetworkSuccess:^(NSArray<UserModel *> * _Nonnull adminList) {
        //返回主线程UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            // 2. 请求成功 → 弹出底部选择框
            if (adminList.count == 0) {
                [SVProgressHUD showInfoWithStatus:@"暂无在线管理员"];
                [SVProgressHUD dismissWithDelay:2];
                return;
            }
            
            // 创建底部 ActionSheet
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择管理员"
                                                                           message:@"请选择要联系的管理员"
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            // 遍历管理员列表，添加选项
            for (UserModel *admin in adminList) {
                NSString *nickname = admin.nickname.length > 0 ? admin.nickname : @"管理员";
                NSString *udid = admin.udid;
                
                // 跳过无效UDID
                if (udid.length < 5) continue;
                
                // 添加选项：点击 → 传入UDID联系
                UIAlertAction *action = [UIAlertAction actionWithTitle:nickname
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                    // 选中后调用联系方法
                    [[ContactHelper shared] showContactActionSheetWithUserUdid:udid];
                }];
                [alert addAction:action];
            }
            
            // 添加取消按钮
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:nil];
            [alert addAction:cancelAction];
            
            // 弹出
            [self presentViewController:alert animated:YES completion:nil];
        });
        
        
    } failure:^(NSError * _Nonnull error, NSString * _Nonnull errorMsg) {
        //返回主线程UI操作
        dispatch_async(dispatch_get_main_queue(), ^{
            // 3. 请求失败提示
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"获取管理员失败：%@", errorMsg]];
            [SVProgressHUD dismissWithDelay:2];
        });
        
    }];
}

// 1. 按钮点击：弹出状态选择器
- (void)operateOrderButtonTap:(UIButton *)button {
    // 当前状态
    OrderStatusType status = self.orderModel.status;
    
    // 创建 ActionSheet 选择器
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择订单状态"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *array = @[@"订单失败", @"订单成功", @"订单退款", @"订单关闭", @"处理中"];
    
    for (OrderStatusType statusIndex = OrderStatusTypeFailure; statusIndex < array.count; statusIndex++) {
        // 添加所有状态选项
        UIAlertActionStyle style = UIAlertActionStyleDefault;
        if(status == statusIndex) style = UIAlertActionStyleDestructive;
        [alert addAction:[UIAlertAction actionWithTitle:array[statusIndex] style:style handler:^(UIAlertAction * _Nonnull action) {
            [self setNewStatus:statusIndex];
        }]];
    }
    
    // 添加取消按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // 弹出选择器
    [self presentViewController:alert animated:YES completion:nil];
}

// 2. 发送更新状态请求（适配后台接口，传递枚举字符串）
- (void)setNewStatus:(OrderStatusType)newStatus{

    // 接口参数（严格匹配后台要求）
    NSDictionary *params = @{
        @"action":@"updateOrderStatus",
        @"newStatus":@(newStatus),
        @"mch_orderid":self.orderModel.mch_orderid,
        @"target_udid":self.orderModel.udid,
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              modules:@"vip"
                                             parameters:params
                                               progress:nil
                                                success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        // 主线程弹窗：更新成功
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchOrderData];
            if(!jsonResult){
                [self showAlertWithTitle:@"操作失败" message:stringResult];
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"];
            if(code != 200){
                [self showAlertWithTitle:@"操作失败" message:msg];
            }
            [SVProgressHUD showSuccessWithStatus:msg];
            [SVProgressHUD dismissWithDelay:1];
            
        });
    } failure:^(NSError *error) {
        // 主线程弹窗：更新失败
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:@"操作失败" message:[NSString stringWithFormat:@"错误：%@", error.localizedDescription]];
        });
    }];
}


/// 通用结果弹窗
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - 导航栏返回按钮
- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 内存管理
- (void)dealloc {
    [SVProgressHUD dismiss];
}

@end
