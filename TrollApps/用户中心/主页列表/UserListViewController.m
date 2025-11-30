//
//  UserAppListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/16.
//

#import "UserListViewController.h"
#import "ShowOneAppViewController.h"
#import "NewProfileViewController.h"
#import "UserModelCell.h"
#import "AppInfoCell.h"
#import "AppInfoModel.h"
#import "CommentInputView.h"
#import "AppCommentCell.h"
#import "WebToolModel.h"
#import "MoodStatusModel.h"
#import "moodStatusCell.h"
#import "ToolViewCell.h"

@interface UserListViewController ()<TemplateSectionControllerDelegate>

@end

@implementation UserListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self.collectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}


#pragma mark - 子类必须重写的方法 请求数据源
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page {
    if(self.selectedIndex ==0){
        [self loadUserAppDataWithPage:self.page];
    }else if(self.selectedIndex ==1){
        [self loadUserToolDataWithPage:self.page];
    }else if(self.selectedIndex ==2){
        [self loadUserReplyDataWithPage:self.page];
    }else if(self.selectedIndex ==3){
        [self loadUserMoodDataWithPage:self.page];
    }
    
}
/**
 获取用户发布的APP
 @param page 当前请求的页码
 */
- (void)loadUserAppDataWithPage:(NSInteger)page{
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :[[NewProfileViewController sharedInstance] getIDFV];
    
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getAppList",
        @"type":self.typeString?:@"newest",
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"pageSize":@(20),
        @"udid":self.user_udid,
        @"showMyApp":@(YES),
        @"page":@(self.page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/app/app_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self endRefreshing];
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
 获取用户发布的工具
 @param page 当前请求的页码
 */
- (void)loadUserToolDataWithPage:(NSInteger)page{
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :[[NewProfileViewController sharedInstance] getIDFV];
    
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getToolList",
        @"sortType":@(self.sort),
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"pageSize":@(20),
        @"udid":self.user_udid,
        @"isMyTool":@(YES),
        @"page":@(self.page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/tool/tool_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self endRefreshing];
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
                    NSDictionary *data = jsonResult[@"data"];
                    NSDictionary *pagination =data[@"pagination"];
                    int total =[pagination[@"total"] intValue];
                    if(total>0){
                        NSArray *tools = data[@"tools"];
                        for (NSDictionary *dic in tools) {
                            WebToolModel *model = [WebToolModel yy_modelWithDictionary:dic];
                            [self.dataSource addObject:model];
                        }
                        [self refreshTable];
                        BOOL hasMore = [jsonResult[@"hasMore"] boolValue];
                        NSLog(@"noMoreData:%@",jsonResult[@"hasMore"]);
                        if(!hasMore){
                            [self handleNoMoreData];
                        }else{
                            self.page+=1;
                        }
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
 获取用户收到的评论
 @param page 当前请求的页码
 */
- (void)loadUserReplyDataWithPage:(NSInteger)page{
    
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :[[NewProfileViewController sharedInstance] getIDFV];
    
    NSString *to_id = self.user_udid?:@"";
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"get_user_comment",
        @"sort":@(self.sort),
        @"keyword":keyword,
        
        @"pageSize":@(30),
        @"to_id":to_id,
        
        @"page":@(self.page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/user/user_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self endRefreshing];
                if(!jsonResult) {
                    NSLog(@"返回数据类型错误: %@", stringResult);
                    [self showAlertFromViewController:self title:@"返回数据类型错误" message:stringResult];
                    return;
                }
                
                NSLog(@"读取数据jsonResult: %@", jsonResult);
                
                
                NSString *message = jsonResult[@"msg"];
                NSDictionary * data = jsonResult[@"data"];
                NSInteger total = [data[@"pagination"][@"total"] intValue];
                NSLog(@"共:%ld条评论",total);
                NSArray * comments = data[@"comments"];
                if(comments.count >0){
                   
                    NSLog(@"返回数量:%ld",comments.count);
                    for (NSDictionary *dic in comments) {
                        NSLog(@"赋值前:%@",dic);
                        CommentModel *model = [CommentModel yy_modelWithDictionary:dic];
                        model.action_type = Comment_type_UserComment;//标记为用户评论
                        NSLog(@"赋值后comment_type:%ld",model.action_type);
                        [self.dataSource addObject:model];
                    }
                    
                }else{
                    NSLog(@"数据搜索失败出错: %@", message);
                    [SVProgressHUD showSuccessWithStatus:message];
                    [SVProgressHUD dismissWithDelay:2 completion:^{
                        return;
                    }];
                }
                [self refreshTable];
                
                NSDictionary * pagination = data[@"pagination"];
                NSLog(@"读取数据pagination: %@", pagination);
                BOOL hasMore = [pagination[@"hasMore"] boolValue];
                NSLog(@"hasMore:%d",hasMore);
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
 获取用户心情
 @param page 当前请求的页码
 */
- (void)loadUserMoodDataWithPage:(NSInteger)page{
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if(!udid || udid.length<5){
        [SVProgressHUD showInfoWithStatus:@"获取UDID失败 请先登录"];
        return;
    }
    
    NSDictionary *dic = @{
        @"page": @(self.page),
        @"udid": udid, // 简化空值判断
        @"sort": @(self.sort),
        
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
    if([object isKindOfClass:[UserModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[UserModelCell class] modelClass:[UserModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
    }else if([object isKindOfClass:[AppInfoModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[AppInfoCell class] modelClass:[AppInfoModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
    }else if([object isKindOfClass:[WebToolModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[ToolViewCell class] modelClass:[WebToolModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
    }
    else if([object isKindOfClass:[CommentModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[AppCommentCell class] modelClass:[CommentModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
    }else if([object isKindOfClass:[MoodStatusModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[moodStatusCell class] modelClass:[MoodStatusModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
    }
    return nil;
}

#pragma mark - SectionController 代理协议


// 扩展回调：传递模型和 Cell
- (void)templateSectionController:(TemplateSectionController *)sectionController
                    didSelectItem:(id)model
                          atIndex:(NSInteger)index
                             cell:(UICollectionViewCell *)cell {
    NSLog(@"点击了model:%@  index:%ld cell:%@",model,index,cell);
    if([model isKindOfClass:[AppInfoModel class]]){
        AppInfoModel *appInfoModel = (AppInfoModel *)model;
        NSLog(@"appInfoModel：%@",appInfoModel.app_name);
        ShowOneAppViewController *vc = [ShowOneAppViewController new];
        vc.app_id = appInfoModel.app_id;
        [self presentPanModal:vc];
        
        
    }
    
}



//禁用键盘遮挡动画
- (BOOL)isAutoHandleKeyboardEnabled{
    return NO;
}


//侧滑手势
- (BOOL)allowScreenEdgeInteractive{
    return NO;
}


- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取手势的位置
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    if (CGRectContainsPoint(self.collectionView.frame, loc)) {
        return NO;
    }
    // 遍历所有子视图，检查手势是否发生在滚动视图上
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]] && CGRectContainsPoint(subview.frame, loc)) {
            // 如果手势发生在滚动视图上，返回 NO，禁止拖拽
            
            return NO;
        }
    }

    // 默认返回 YES，允许拖拽
    return YES;
}



@end
