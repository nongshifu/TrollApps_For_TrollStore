//
//  LeftViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/20.
//

#import "LeftViewController.h"
#import "WebToolModel.h"
#import "WebToolManager.h"
#import "MinWebToolViewCell.h"
#import "ShowOneToolViewController.h"
#import "config.h"
#import "WebViewController.h"
#import "NewProfileViewController.h"
#import "MiniButtonView.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED NO // .M当前文件单独启用


@interface LeftViewController ()<TemplateSectionControllerDelegate, MiniButtonViewDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) MiniButtonView *miniButtonView;

@end

@implementation LeftViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
    [self setupViewConstraints];
    
}

- (void)setupViews {
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:25];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.text = @"最近使用";
    [self.view addSubview:self.titleLabel];
    //移除约束重新添加
    [self.collectionView removeFromSuperview];
    [self.view addSubview:self.collectionView];
    
    NSArray *titles = @[@"刷新全部",@"删除全部"];
    NSArray *icons = @[@"goforward",@"trash.circle"];
    self.miniButtonView = [[MiniButtonView alloc] initWithStrings:titles icons:icons fontSize:12];
    self.miniButtonView.frame = CGRectMake(0, kHeight - get_BOTTOM_TAB_BAR_HEIGHT - 30, 150, 30);
    self.miniButtonView.buttonDelegate = self;
    [self.view addSubview:self.miniButtonView];
    [self.view bringSubviewToFront:self.miniButtonView];
}

#pragma mark - 约束

- (void)setupViewConstraints {
    //顶头
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.equalTo(@60);
        make.top.equalTo(self.view).offset(get_TOP_NAVIGATION_BAR_HEIGHT);
    }];
    //表格
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.bottom.equalTo(self.view);
    }];
    [self.miniButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.equalTo(@30);
        make.left.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-100);
    }];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.miniButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.equalTo(@30);
        make.left.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-100);
    }];
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self refreshLoadInitialData];
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page {
    if(page <= 1){
        NSArray *array = [[WebToolManager sharedManager] getAllWebTools];
        self.dataSource = [NSMutableArray arrayWithArray:array];
    }
    NSLog(@"self.dataSource :%ld",self.dataSource.count);
    [self refreshTable];
    
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[WebToolModel class]]){
        TemplateSectionController *vc = [[TemplateSectionController alloc] initWithCellClass:[MinWebToolViewCell class] modelClass:[WebToolModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 2, 0) usingCacheHeight:NO];
        vc.dataSource = self.dataSource;
        vc.collectionView = self.collectionView;
        return vc;
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
    if([model isKindOfClass:[WebToolModel class]]){
        [self openHtml:model];
        
    }
    
}


- (void)openHtml:(WebToolModel*)model {
    // 直接初始化，内部会自动判断单例中是否存在
    WebViewController *webVC = [[WebViewController alloc] initWithToolModel:model];
    // 显示控制器（无论新创建还是复用已有实例，直接 present 即可）
    [self presentPanModal:webVC];
    
    
     NSString *udid =[NewProfileViewController sharedInstance].userInfo.udid ?: [[NewProfileViewController sharedInstance] getIDFV];
     // 构建请求参数
     NSDictionary *dic = @{
         @"action": @"incrementToolViewCount",
         @"tool_id": @(model.tool_id),
         @"udid": udid,
        
     };
     
     NSString *url = [NSString stringWithFormat:@"%@/tool/tool_api.php",localURL];
     NSLog(@"请求URL:%@ 参数:%@", url, dic);
    
     [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                               urlString:url
                                              parameters:dic
                                                    udid:udid
                                                progress:^(NSProgress *progress) {
         
     } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {}
                                                 failure:^(NSError *error) {
        
     }];

}

- (void)buttonTappedWithTag:(NSInteger)tag title:(nonnull NSString *)title button:(nonnull UIButton *)button {
    if(tag ==0){
        [SVProgressHUD showWithStatus:@"刷新中"];
        NSArray<WebToolModel *> *array = [[WebToolManager sharedManager] getAllWebTools];
        for (WebToolModel *model in array) {
            [[WebToolManager sharedManager] removeWebToolWithId:model.tool_id];
        }
        [SVProgressHUD dismissWithDelay:0.5 completion:^{
            [SVProgressHUD showImage:[UIImage systemImageNamed:@"goforward"] status:@"刷新完成"];
            [SVProgressHUD dismissWithDelay:1];
        }];
        
    }else{
        [[WebToolManager sharedManager] removeAllWebTools];
        [self loadDataWithPage:1];
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"trash.circle"] status:@"删除完成"];
        [SVProgressHUD dismissWithDelay:1];
        
    }
    
}


@end
