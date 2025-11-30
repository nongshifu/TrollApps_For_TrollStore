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



// 顶部容器高度
#define kTopContainerHeight 64
// 间距常量
#define kMargin 15

@interface VipPurchaseHistoryViewController ()<TemplateSectionControllerDelegate, UITextFieldDelegate>
@property (nonatomic, assign) BOOL sort;//排序 默认NO 按最新时间
@property (nonatomic, strong) NSString * keyword;//关键词

// 顶部视图
@property (nonatomic, strong) UIView *topContainer; // 顶部容器
@property (nonatomic, strong) UILabel *titleLabel;  // 标题
@property (nonatomic, strong) UITextField *searchField; // 搜索框

@end

@implementation VipPurchaseHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.page = 1; // 初始化页码
    self.dataSource = [NSMutableArray array];
    
    // 初始化顶部视图
    [self setupTopView];
    
    // 首次加载数据
    [self loadDataWithPage:self.page];
}

#pragma mark - 初始化顶部视图
- (void)setupTopView {
    // 顶部容器
    self.topContainer = [[UIView alloc] init];
    self.topContainer.backgroundColor = [UIColor systemBackgroundColor];
    // 添加顶部阴影（可选）
    self.topContainer.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    self.topContainer.layer.shadowOpacity = 0.1;
    self.topContainer.layer.shadowOffset = CGSizeMake(0, 2);
    [self.view addSubview:self.topContainer];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"VIP购买历史";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = [UIColor labelColor];
    [self.topContainer addSubview:self.titleLabel];
    
    // 搜索框
    self.searchField = [[UITextField alloc] init];
    self.searchField.placeholder = @"搜索订单号/套餐名称";
    self.searchField.font = [UIFont systemFontOfSize:14];
    self.searchField.borderStyle = UITextBorderStyleRoundedRect;
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.delegate = self;
    // 搜索框内边距调整
    self.searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    [self.topContainer addSubview:self.searchField];
    
    //移除父视图约束
    [self.collectionView removeFromSuperview];
    //重新添加
    [self.view addSubview:self.collectionView];
    // 设置顶部视图约束
    [self setupViewConstraints];
}

#pragma mark - 顶部视图约束
- (void)setupViewConstraints {
    // 顶部容器约束
    [self.topContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@(kTopContainerHeight));
    }];
    
    // 标题约束（左侧）
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.topContainer);
        make.left.equalTo(self.topContainer).offset(kMargin);
    }];
    
    // 搜索框约束（右侧）
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.topContainer);
        make.right.equalTo(self.topContainer).offset(-kMargin);
        make.left.greaterThanOrEqualTo(self.titleLabel.mas_right).offset(kMargin); // 与标题保持间距
        make.height.equalTo(@36);
        make.width.greaterThanOrEqualTo(@150); // 最小宽度
        make.width.lessThanOrEqualTo(@250); // 最大宽度
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topContainer.mas_bottom).offset(10); // 表格顶部与顶部容器底部对齐
        make.left.right.equalTo(self.view); // 左右下贴边
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - 10); // 左右下贴边
    }];
}



#pragma mark - 调整表格约束（核心：让表格在顶部视图下方）
- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topContainer.mas_bottom).offset(10); // 表格顶部与顶部容器底部对齐
        make.left.right.equalTo(self.view); // 左右下贴边
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight - 10); // 左右下贴边
    }];
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page{
    NSString *udid = [loadData sharedInstance].userModel.udid;
    if(!udid || udid.length<5){
        [SVProgressHUD showInfoWithStatus:@"获取UDID失败 请先登录"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    
    NSDictionary *dic = @{
        @"page": @(page),
        @"udid": udid,
        @"sort": @(self.sort),
        @"keyword": self.keyword ?: @"",
        @"action": @"getVipPurchaseHistory"
    };
    
    // 接口地址
    NSString *url = [NSString stringWithFormat:@"%@/vip/vip_purchase_history_api.php", localURL];
    
    // 发送请求
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                           urlString:url
                                          parameters:dic
                                               udid:udid
                                             progress:^(NSProgress *progress) {
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            // 结束刷新状态
            [self endRefreshing];
            
            // 数据合法性校验
            if (!jsonResult) {
                NSLog(@"返回数据格式错误: %@", stringResult);
                [SVProgressHUD showErrorWithStatus:@"数据格式错误，请重试"];
                [SVProgressHUD dismissWithDelay:2];
                return;
            }
            
            NSLog(@"订单列表数据: %@", jsonResult);
            NSInteger code = [jsonResult[@"code"] integerValue];
            NSString *message = jsonResult[@"msg"] ?: @"获取数据失败，请稍后重试";
            
            if (code == 200) {
                NSDictionary *data = jsonResult[@"data"];
                NSArray *list = data[@"list"] ?: @[];
                [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"加载了%ld条",list.count]];
                [SVProgressHUD dismissWithDelay:1];
                
                // 解析数据
                NSMutableArray *newModels = [NSMutableArray array];
                for (NSDictionary *item in list) {
                    VipPurchaseHistoryModel *model = [VipPurchaseHistoryModel yy_modelWithDictionary:item];
                    if (model) {
                        [newModels addObject:model];
                    }
                }
                
                // 处理分页
                NSDictionary *pagination = data[@"pagination"] ?: @{};
                BOOL hasMore = [pagination[@"hasMore"] boolValue];
                
                if (page == 1) {
                    self.dataSource = newModels;
                } else {
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
                NSLog(@"获取订单列表失败: %@（错误码：%ld）", message, (long)code);
                [SVProgressHUD showErrorWithStatus:message];
                [SVProgressHUD dismissWithDelay:2];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endRefreshing];
            NSLog(@"网络请求错误: %@", error.localizedDescription);
            [SVProgressHUD showErrorWithStatus:@"网络连接失败，请检查网络"];
            [SVProgressHUD dismissWithDelay:2];
        });
    }];
}

/**
 返回对应的 SectionController
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[VipPurchaseHistoryModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[vip_purchase_historyCell class] modelClass:[VipPurchaseHistoryModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 5, 0) usingCacheHeight:NO];
    }
    return nil;
}

// 点击单元格回调
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    // 可添加点击订单的逻辑（如查看详情）
    if ([model isKindOfClass:[VipPurchaseHistoryModel class]]) {
        VipPurchaseHistoryModel *orderModel = (VipPurchaseHistoryModel *)model;
        NSLog(@"点击了订单: %@", orderModel.mch_orderid);
    }
}


#pragma mark - 搜索框代理（核心搜索逻辑）
// 点击键盘搜索按钮
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self performSearchWithText:textField.text];
    return YES;
}

// 点击清除按钮
- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self performSearchWithText:@""]; // 清空文本时搜索全部
    return YES;
}

// 结束编辑时（如点击空白处），如果内容有变化则触发搜索
- (void)textFieldDidEndEditing:(UITextField *)textField {
    // 避免与return/clear事件重复触发
    if (![textField.text isEqualToString:self.keyword]) {
        [self performSearchWithText:textField.text];
    }
}

#pragma mark - 搜索执行函数（统一处理搜索逻辑）
- (void)performSearchWithText:(NSString *)searchText {
    [self.searchField resignFirstResponder]; // 收起键盘
    
    // 去空格处理
    NSString *trimmedText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 关键词无变化则不重复请求
    if ([trimmedText isEqualToString:self.keyword]) {
        return;
    }
    
    // 赋值关键词
    self.keyword = trimmedText;
    
    // 显示加载状态
    [SVProgressHUD showWithStatus:@"搜索中..."];
    
    // 重置页码并加载数据
    self.page = 1;
    [self loadDataWithPage:self.page];
}


@end
