//
//  UserAppListViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/16.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "UserListViewController.h"
#import "ShowOneAppViewController.h"
#import "NewProfileViewController.h"
#import "UserModelCell.h"
#import "AppInfoCell.h"
#import "AppInfoModel.h"
#import "CommentInputView.h"
#import "AppCommentCell.h"

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
    }else{
        [self loadUserReplyDataWithPage:self.page];
    }
}
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadUserAppDataWithPage:(NSInteger)page{
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ? [NewProfileViewController sharedInstance].userInfo.udid :[[NewProfileViewController sharedInstance] getIDFV];
    
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
    NSString *url = [NSString stringWithFormat:@"%@/app_api.php",localURL];
    
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
 加载指定页数数据（子类必须实现）
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
    NSString *url = [NSString stringWithFormat:@"%@/user_api.php",localURL];
    
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
                NSInteger  code = [jsonResult[@"code"] intValue];
                NSInteger total = [jsonResult[@"total"] intValue];
                NSLog(@"共:%ld条评论",total);
                NSString *message = jsonResult[@"msg"];
                NSDictionary * data = jsonResult[@"data"];
                
                if(code == 200){
                    NSArray * comments = data[@"comments"];
                    NSLog(@"返回数量:%ld",comments.count);
                    for (NSDictionary *dic in comments) {
                        NSLog(@"赋值前:%@",dic);
                        AppComment *model = [AppComment yy_modelWithDictionary:dic];
                        model.comment_type = Comment_type_UserComment;
                        NSLog(@"赋值后comment_type:%ld",model.comment_type);
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
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[UserModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[UserModelCell class] modelClass:[UserModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
    }else if([object isKindOfClass:[AppInfoModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[AppInfoCell class] modelClass:[AppInfoModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
    }
    else if([object isKindOfClass:[AppComment class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[AppCommentCell class] modelClass:[AppComment class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 20, 10, 20) usingCacheHeight:NO];
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
