//
//  UserProfileViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "UserProfileViewController.h"
#import "NewProfileViewController.h"
#import "UserModelCell.h"
#import "AppInfoCell.h"
#import "AppInfoModel.h"
//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface UserProfileViewController ()<TemplateSectionControllerDelegate, UITextViewDelegate, TemplateListDelegate>

@end

@implementation UserProfileViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"用户中心";
    self.hidesVerticalScrollIndicator = YES;
    
    self.templateListDelegate = self;
    // 初始化UI
    [self setupSubviews];
    
    //加载数据
    [self loadDataWithPage:1];
   
    //设置约束
    [self setupViewConstraints];
    //更新约束
    [self updateViewConstraints];
}

#pragma mark - 写UI

- (void)setupSubviews {
    // 先移除父类的表格视图 去除约束
    [self.collectionView removeFromSuperview];
    // 重新添加
    [self.view addSubview:self.collectionView];
    self.collectionView.layer.cornerRadius = 8;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
}

#pragma mark - 设置和更新约束

//设置约束
- (void)setupViewConstraints {
    // 表格视图约束（合并冲突的旧约束）
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
    
}

//更新约束 拖动等会调用 适配UI
- (void)updateViewConstraints{
    //调用父类
    [super updateViewConstraints];
    //更新其他适配
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
}

#pragma mark - 读取用户数据

/// 更新用户模型并刷新UI
- (void)updateWithUserModel:(UserModel *)userModel {
    NSLog(@"更新用户模型并刷新UI：%ld",self.dataSource.count);
    if(self.dataSource.count == 0){
        NSLog(@"里面没数据");
        [self.dataSource addObject:userModel];
    }else if(self.dataSource.count >2){
        id model = [self.dataSource objectAtIndex:0];
        if([model isKindOfClass:[UserModel class]]){
            NSLog(@"里面>2 先删除");
            [self.dataSource removeObject:model];
            NSLog(@"插入第一个");
        }
        
    }
    [self.dataSource insertObject:userModel atIndex:0];
    [self refreshTable];
}

// 请求用户数据
- (void)fetchUserInfoFromServerWithUDID:(NSString *)udid {
    _udid = udid;
    NSDictionary *dic = @{
        @"action":@"getUserInfo",
        @"udid":udid,
        @"type":@"udid"
    };
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user_api.php",localURL]
                                             parameters:dic
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"请求udid用户数据:%@",stringResult);
            if(!jsonResult && stringResult){
                [self showAlertFromViewController:self title:@"请求返回错误" message:stringResult];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *message = jsonResult[@"message"];
            
            if (code == 200) {
                NSDictionary *data =jsonResult[@"data"];
                NSLog(@"读取用户数据字典:%@",data);
                self.userInfo = [UserModel yy_modelWithDictionary:data];
                [self updateWithUserModel:self.userInfo];
            }else{
                [self showAlertFromViewController:self title:@"请求返回错误" message:message];
            }
            [self refreshTable];
        });
    } failure:^(NSError *error) {
        NSLog(@"从服务器获取UDID 读取资料失败：%@",error);
        [self showAlertFromViewController:self title:@"请求返回错误" message:[NSString stringWithFormat:@"%@",error]];
    }];
}

#pragma mark - 子类必须重写的方法 请求数据源
/**
 加载指定页数数据（子类必须实现）
 @param page 当前请求的页码
 */
- (void)loadDataWithPage:(NSInteger)page{
    NSInteger index  =self.tagPageIndex;
    NSArray *array = @[@"newest", @"hottest", @"recommend"];
    //初始化分类为空
    NSString * type = @"";
    //前面三个 使用系统分类
    if(index<3){
        type = array[index];
    }else{
        //超过三个 采用 自定义分类接口和关键字
        type = @"tag";
        self.tag = self.title;
    }
    
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?:[[NewProfileViewController sharedInstance] getIDFV];
    
    NSString * keyword = self.keyword ? self.keyword : @"";
    NSDictionary *dic = @{
        @"action":@"getAppList",
        @"type":type,
        @"keyword":keyword,
        @"tag":self.tag ?:@"",
        @"pageSize":@(20),
        @"udid":udid,
        @"showMyApp":@(self.showMyApp),
        @"page":@(self.page)
        
    };
    NSString *url = [NSString stringWithFormat:@"%@/app_api.php",localURL];
    
    NSLog(@"列表请求url:%@ dic:%@",url,dic);
    
   
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            [self fetchUserInfoFromServerWithUDID:self.udid];
            dispatch_async(dispatch_get_main_queue(), ^{
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
                [self updatePaginationWithCurrentPage:page hasMore:hasMore];
                
            });
        } failure:^(NSError *error) {
            NSLog(@"异步请求Error: %@", error);
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"请求错误\n%@",error]];
            [SVProgressHUD dismissWithDelay:2 completion:nil];
        }];
    
    
}


// 更新分页状态
- (void)updatePaginationWithCurrentPage:(NSInteger)currentPage hasMore:(BOOL)hasMore {
    // 结束刷新控件动画
    [self endRefreshing];
    
    // 如果还有更多数据，增加页码；否则标记为没有更多数据
    if (hasMore) {
        self.page = currentPage + 1;
    } else {
        // 可以显示"没有更多数据"的提示
        NSLog(@"没有更多评论数据");
        
        [self setFooterNoMoreDataWithText:@"读取完毕-发布一个APP吧！\nTrollApps by 十三哥 2026"];
    }
}


/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    if([object isKindOfClass:[UserModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[UserModelCell class] modelClass:[UserModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 10, 0) usingCacheHeight:NO];
    }else if([object isKindOfClass:[AppInfoModel class]]){
        return [[TemplateSectionController alloc] initWithCellClass:[AppInfoCell class] modelClass:[AppInfoModel class] delegate:self edgeInsets:UIEdgeInsetsMake(0, 0, 10, 0) usingCacheHeight:NO];
    }
    return nil;
}

/**
 * 当滚动视图滚动时调用此方法。
 *
 * @param offset 滚动视图的偏移量
 * @param isScrollingUp 表示滚动方向是否为向上滚动，YES 为向上滚动，NO 为向下滚动
 */
- (void)scrollViewDidScrollWithOffset:(CGFloat)offset isScrollingUp:(BOOL)isScrollingUp {
    if(isScrollingUp){
        NSLog(@"向上滚动:%f",offset);
    }else{
        NSLog(@"向下滚动:%f",offset);
    }
    self.isScrollingUp = isScrollingUp;
    [self updateViewConstraints];
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
    if([model isKindOfClass:[UserModel class]]){
        UserModel *userModel = (UserModel *)model;
        NSLog(@"userModel：%@",userModel.nickname);
        
        
    }
    
}


#pragma mark - 事件处理

// 显示之前
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 在这里可以进行一些在视图显示之前的准备工作，比如更新界面元素、加载数据等。
    
}
// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    if(!self.udid)return;
//    [self fetchUserInfoFromServerWithUDID:self.udid];
}

@end
