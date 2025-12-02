//
//  MyFavoritesListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/2.
//


#import "MyFavoritesListViewController.h"
#import "AppInfoModel.h"
#import "AppInfoCell.h"
#import "NewProfileViewController.h"
#import "ShowOneAppViewController.h"
#import "WebToolModel.h"
#import "ToolViewCell.h"
#import "UserModelCell.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED NO // .M当前文件单独启用

@interface MyFavoritesListViewController () <TemplateSectionControllerDelegate>

@end

@implementation MyFavoritesListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isTapViewToHideKeyboard = YES;
    self.viewIsGradientBackground = NO;

}


- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self.collectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}


#pragma mark - 控制器辅助函数
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    if(self.dataSource.count ==0){
        [self loadDataWithPage:1];
    }
   
    
}

#pragma mark - 子类必须重写的方法
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page{
    [SVProgressHUD showWithStatus:nil];
    if(self.selectedIndex==0){
        [self loadUserAppDataWithPage:page];
    }else if(self.selectedIndex==1){
        [self loadToolDataWithPage:page];
    }else if(self.selectedIndex==2){
        [self loadUserFollowerDataWithPage:page type:NO];
    }else if(self.selectedIndex==3){
        [self loadUserFollowerDataWithPage:page type:YES];
    }
    
}

/**
 加载用户APP
 @param page 当前请求的页码
 */
- (void)loadUserAppDataWithPage:(NSInteger)page{
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    
    if (!udid || udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getAppList",
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"pageSize":@(10),
        @"udid":self.target_udid,
        @"showMyApp":@(YES),
        @"sortType":@(self.sort),
        @"page":@(page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/app/app_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self endRefreshing];
                if(self.page <=1){
                    [self.dataSource removeAllObjects];
                }
                if(!jsonResult) {
                    NSLog(@"返回数据类型错误: %@", stringResult);
                    [SVProgressHUD showErrorWithStatus:@"返回数据类型错误"];
                    [SVProgressHUD dismissWithDelay:2 completion:nil];
                    return;
                }
                
                NSLog(@"读取数据jsonResult: %@", jsonResult);
                NSInteger  code = [jsonResult[@"code"] intValue];
                NSInteger total = [jsonResult[@"total"] intValue];
                NSLog(@"共:%ld个APP",total);
                NSString *message = jsonResult[@"msg"];
                
                if(code == 200){
                    NSArray * appInfo_data = jsonResult[@"data"];
                    NSLog(@"返回数量:%ld",appInfo_data.count);
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
                if(!hasMore){
                    [self handleNoMoreData];
                }
            });
        } failure:^(NSError *error) {
            NSLog(@"异步请求Error: %@", error);
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"请求错误\n%@",error]];
            [SVProgressHUD dismissWithDelay:2 completion:nil];
        }];
    
    


}

/**
 加载用户web工具
 @param page 当前请求的页码
 */
- (void)loadToolDataWithPage:(NSInteger)page{
    
    
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if (!udid || udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getUserFavoriteList",
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"udid":self.target_udid,
        @"page":@(self.page),
        @"pageSize":@(20),
        @"sort":@(self.sort),// 排序方式（NO=最新收藏，YES=最早收藏）
    };
    NSString *url = [NSString stringWithFormat:@"%@/tool/tool_api.php",localURL];
    NSLog(@"url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:url parameters:dic
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"stringResult:%@",stringResult);
            [SVProgressHUD dismiss];
            [self endRefreshing];
            if(self.page <=1){
                [self.dataSource removeAllObjects];
            }
            if(!jsonResult){
                [SVProgressHUD showErrorWithStatus:@"返回数据非法"];
                [SVProgressHUD dismissWithDelay:2 completion:^{
                    return;
                }];
            }
            NSLog(@"读取数据jsonResult: %@", jsonResult);
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *message = jsonResult[@"msg"];
            if(code == 200){
                NSDictionary * data = jsonResult[@"data"];
                NSArray *tools = data[@"tools"];
                if(tools && tools.count>0){
                    for (NSDictionary *dic in tools) {
                        NSLog(@"读取关注用户数据dic: %@", dic);
                        WebToolModel *model = [WebToolModel yy_modelWithDictionary:dic];
                        [self.dataSource addObject:model];
                    }
                    [self refreshTable];
                }
                
                
                NSDictionary * pagination = data[@"pagination"];
                BOOL has_more = [pagination[@"has_more"] boolValue];
                if(has_more){
                    NSLog(@"有更多数据");
                    self.page+=1;
                }else{
                    NSLog(@"没有有更多数据");
                    [self handleNoMoreData];
                }
                
                
            }else{
                NSLog(@"数据搜索失败出错: %@", message);
                [SVProgressHUD showErrorWithStatus:message];
                [SVProgressHUD dismissWithDelay:2 completion:^{
                    return;
                }];
            }
            
        });
    } failure:^(NSError *error) {
        NSLog(@"异步请求Error: %@", error);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"请求错误\n%@",error]];
        [SVProgressHUD dismissWithDelay:2 completion:^{
            return;
        }];
    }];
    
}


/**
 加载用户粉丝 isFollower = YES 粉丝列表   isFollower = NO 关注列表
 @param page 当前请求的页码
 */
- (void)loadUserFollowerDataWithPage:(NSInteger)page type:(BOOL)isFollower{
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    
    if (!udid || udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getFollowList",
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"pageSize":@(20),
        @"udid":self.target_udid,
        @"sortType":@(self.sort),
        @"type":@(isFollower),
        @"page":@(page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self endRefreshing];
                if(self.page <=1){
                    [self.dataSource removeAllObjects];
                }
                if(!jsonResult) {
                    NSLog(@"返回数据类型错误: %@", stringResult);
                    [SVProgressHUD showErrorWithStatus:@"返回数据类型错误"];
                    [SVProgressHUD dismissWithDelay:2 completion:nil];
                    return;
                }
                
                NSLog(@"读取数据jsonResult: %@", jsonResult);
                NSInteger  code = [jsonResult[@"code"] intValue];
                
                NSString *message = jsonResult[@"msg"];
                
                if(code == 200){
                    NSDictionary * data = jsonResult[@"data"];
                    NSDictionary * pagination =data[@"pagination"];
                    NSArray *list =data[@"list"];
                    for (NSDictionary *dic in list) {
                        UserModel *model = [UserModel yy_modelWithDictionary:dic];
                        [self.dataSource addObject:model];
                    }
                    [self refreshTable];
                    BOOL hasMore = [pagination[@"hasMore"] boolValue];
                    if(!hasMore){
                        [self handleNoMoreData];
                    }
                    
                    
                }else{
                    NSLog(@"数据搜索失败出错: %@", message);
                    [SVProgressHUD showErrorWithStatus:message];
                    [SVProgressHUD dismissWithDelay:2 completion:^{
                        return;
                    }];
                }
                
            });
        } failure:^(NSError *error) {
            NSLog(@"异步请求Error: %@", error);
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"请求错误\n%@",error]];
            [SVProgressHUD dismissWithDelay:2 completion:nil];
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
    }else if ([object isKindOfClass:[WebToolModel class]]) {
        
        return [[TemplateSectionController alloc] initWithCellClass:[ToolViewCell class] modelClass:[WebToolModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10) usingCacheHeight:NO];
    }else if ([object isKindOfClass:[UserModel class]]) {
        
        return [[TemplateSectionController alloc] initWithCellClass:[UserModelCell class] modelClass:[UserModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10) usingCacheHeight:NO];
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



@end
