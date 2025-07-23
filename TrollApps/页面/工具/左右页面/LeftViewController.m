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


@interface LeftViewController ()<TemplateSectionControllerDelegate>

@property (nonatomic, strong) UILabel *titleLabel;

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
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
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
        return [[TemplateSectionController alloc] initWithCellClass:[MinWebToolViewCell class] modelClass:[WebToolModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 2, 0) usingCacheHeight:NO];
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
        
        WebToolModel * webToolModel = (WebToolModel *)model;
        ShowOneToolViewController *vc = [ShowOneToolViewController new];
        vc.tool_id = webToolModel.tool_id;
        [self presentPanModal:vc];
    }
    
}


@end
