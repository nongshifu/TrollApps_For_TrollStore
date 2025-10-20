//
//  AppListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/1.
//

#import "AppListViewController.h"
#import "AppInfoCell.h"
#import "NewProfileViewController.h"
#import "ShowOneAppViewController.h"
#import "NetworkClient.h"
//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface AppListViewController ()<TemplateSectionControllerDelegate>

@end

@implementation AppListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isTapViewToHideKeyboard = YES;
    
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self.view removeDynamicBackground];
    
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page{
  
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :[[NewProfileViewController sharedInstance] getIDFV];
    NSLog(@"请求的UDID:%@",udid);
    
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getAppList",
        @"sortType":@(self.sortType),
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"pageSize":@(10),
        @"udid":udid,
        @"showMyApp":@(self.showMyApp),
        @"page":@(page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/app_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
    
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!jsonResult && stringResult) {
                    NSLog(@"返回数据类型错误: %@", stringResult);
                    [SVProgressHUD showErrorWithStatus:@"返回数据类型错误"];
                    [SVProgressHUD dismissWithDelay:2 completion:nil];
                    return;
                }
                
                NSLog(@"读取数据jsonResult: %@", jsonResult);
                NSInteger  code = [jsonResult[@"code"] intValue];
                NSString *message = jsonResult[@"msg"];
                
                if(code == 200){
                    NSArray * appInfo_data = jsonResult[@"data"];
                    
                    for (NSDictionary *dic in appInfo_data) {
                        AppInfoModel *model = [AppInfoModel yy_modelWithDictionary:dic];
                        [self.dataSource addObject:model];
                    }
                   
                }else{
                    NSLog(@"数据搜索失败出错: %@", message);
                    [SVProgressHUD showErrorWithStatus:message];
                    [SVProgressHUD dismissWithDelay:2 completion:^{
                        return;
                    }];
                }
                
                [self refreshTable];
                
                BOOL hasMore = [jsonResult[@"hasMore"] boolValue];
                NSLog(@"noMoreData:%@",jsonResult[@"hasMore"]);
                // 如果还有更多数据，增加页码；否则标记为没有更多数据
                if (hasMore) {
                    self.page += 1;
                } else {
                    // 可以显示"没有更多数据"的提示
                    NSLog(@"没有更多评论数据");
                    [self setFooterNoMoreDataWithText:@"读取完毕-发布一个APP吧！\nTrollApps by 十三哥 2026"];
                }
          
            });
        } failure:^(NSError *error) {
            NSLog(@"异步请求Error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"请求错误\n%@",error]];
                [SVProgressHUD dismissWithDelay:2 completion:nil];
                [self refreshTable];
            });
            
        }];
    
    
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if ([object isKindOfClass:[AppInfoModel class]]) {
        
        return [[TemplateSectionController alloc] initWithCellClass:[AppInfoCell class] modelClass:[AppInfoModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10) usingCacheHeight:NO];
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
    if([model isKindOfClass:[AppInfoModel class]]){
        AppInfoModel *appInfo = (AppInfoModel *)model;
        
        ShowOneAppViewController *vc = [ShowOneAppViewController new];
        vc.app_id = appInfo.app_id;
        [self presentPanModal:vc];
        
        
    }
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    

    //是否禁用跟随主题修改背景色
    if(self.disableFollowingBackgroundColor) return;
    
    [self.view removeDynamicBackground];
    
    NSLog(@"首页列表 界面模式发生变化");
    self.view.backgroundColor = [UIColor clearColor];
}


@end
