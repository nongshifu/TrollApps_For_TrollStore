//
//  AppVersionHistoryViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/25.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "AppVersionHistoryViewController.h"
#import "loadData.h"
#import "NetworkClient.h"
#import "NewProfileViewController.h"
#import "AppVersionHistoryModel.h"
#import "AppVersionHistoryCell.h"
#import <Masonry/Masonry.h>
#import "FileInstallManager.h"


@interface AppVersionHistoryViewController ()<TemplateSectionControllerDelegate>
@property (nonatomic, strong) NSString * keyword;//搜索关键字

@property (nonatomic, strong) AppVersionHistoryModel * latestAppVersionHistoryModel;//当前最新版本
@property (nonatomic, strong) UIButton *downloadButton ;      // 下载按钮
//UI
@property (nonatomic, strong) UILabel * titleLabel;

@end

@implementation AppVersionHistoryViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
    [self setupViewConstraints];
    [self loadDataWithPage:1];
}

- (void)loadDataWithPage:(NSInteger)page{
    [SVProgressHUD showWithStatus:@"加载中。。。"];
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: [[NewProfileViewController sharedInstance] getIDFV];
    //构建字典
    NSDictionary *dic = @{
        @"page":@(self.page),
        @"pageSize":@20,
        @"udid":udid,
        @"keyword":self.keyword?:@"",
        @"action":@"searchVersions",
    };
    NSString *url = [NSString stringWithFormat:@"%@/admin/app_version_api.php",localURL];
    //执行搜索
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //如果是刷新 重置操作 清空数据源
            if(self.page <=1){
                [self.dataSource removeAllObjects];
            }
            //结束MJ刷新状态
            [self endRefreshing];
            //关闭加载提示
            [SVProgressHUD dismiss];
            //判断数据
            if(!jsonResult){
                NSLog(@"返回字典格式错误:%@",stringResult);
                [SVProgressHUD showErrorWithStatus:stringResult];
                [SVProgressHUD dismissWithDelay:3];
                //调用基类弹出函数
//                [self showAlertFromViewController:self title:@"返回数据错误" message:stringResult];
                return;
            }
            //数据正常 开始解析
            NSDictionary *data =jsonResult[@"data"];
            NSString * msg =jsonResult[@"msg"];
            NSInteger code = [jsonResult[@"code"] intValue];
            if(code != 200){
                //调用基类弹出函数
                NSLog(@"状态码%ld错误信息:%@",code,msg);
                [self showAlertFromViewController:self title:@"错误" message:msg];
                return;
            }
            // 正常 解析数据
            NSArray *versions =data[@"versions"];
            for (NSDictionary *obj in versions) {
                NSLog(@"解析单个版本数据字典：%@",obj);
                AppVersionHistoryModel *appVersionHistoryModel = [AppVersionHistoryModel yy_modelWithDictionary:obj];
                if(appVersionHistoryModel){
                    //读取第一个为最新版本
                    if(!self.latestAppVersionHistoryModel){
                        self.latestAppVersionHistoryModel = appVersionHistoryModel;
                        [self updateLatestAppVersionUI:self.latestAppVersionHistoryModel];
                    }
                    //添加到数据源
                    [self.dataSource addObject:appVersionHistoryModel];
                }
                
            }
            
            //刷新数据表格
            [self refreshTable];
            
            //判断数据量
            NSDictionary *pagination = data[@"pagination"];
            NSInteger totalPages = [pagination[@"totalPages"] intValue];
            NSInteger total = [pagination[@"total"] intValue];
            NSLog(@"返回数据数据量totalPages：%ld   total:%ld",totalPages,total);
            if(totalPages > self.page){
                //还有数据页码加一
                self.page +=1;
            }else{
                //没有数据 结束尾部的MJ加载更新
                [self handleNoMoreData];
            }
        });
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:@"网络读取错误"];
            [SVProgressHUD dismissWithDelay:2];
        });
    }];
    
}

//设置UI
- (void)setupViews{
    //隐藏自定义导航
    self.zx_showSystemNavBar = NO;
    self.zx_hideBaseNavBar = YES;
    [self.collectionView removeFromSuperview];
    [self.view addSubview:self.collectionView];
    //基础UI
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, kWidth - 40, 50)];
    _titleLabel.text = @"版本历史";
    _titleLabel.font = [UIFont boldSystemFontOfSize:25];
    _titleLabel.textColor = [UIColor secondaryLabelColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    _downloadButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 70, kWidth - 100, 50)];
    [_downloadButton setTitle:@"下载最新版" forState:UIControlStateNormal];
    [_downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _downloadButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    _downloadButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
    _downloadButton.layer.cornerRadius = 15;
    _downloadButton.layer.masksToBounds = YES;
    [_downloadButton addTarget:self action:@selector(download:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_downloadButton];
    
    
}

//设置Masonry约束
- (void)setupViewConstraints{
   
    [_downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(kWidth - 100));
        make.top.equalTo(self.view.mas_top).offset(60);//顶部居于标题
        make.centerX.equalTo(self.view);
        //底部始终居于顶部一个总视图高度 self.viewHeight 跟随滚动计算高度
        make.height.equalTo(@50);
        
    }];
    //调整视图高度后 表格根据视图高度更新约束
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(self.downloadButton.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
        //底部始终居于顶部一个总视图高度 self.viewHeight 跟随滚动计算高度
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
}

//更新Masonry约束 基类函数 滚动 等会调用这个更新
- (void)updateViewConstraints{
    [super updateViewConstraints];
    
    //调整视图高度后 表格根据视图高度更新约束
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.top.equalTo(self.downloadButton.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
        //底部始终居于顶部一个总视图高度 self.viewHeight 跟随滚动计算高度
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
    }];
    
}

- (void)download:(UIButton*)button{
    AppVersionHistoryModel *model = (AppVersionHistoryModel*)self.dataSource.firstObject;
    NSURL * URL = [NSURL URLWithString:model.download_url];
    if(!URL){
        [SVProgressHUD showErrorWithStatus:@"连接不合法"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    [[FileInstallManager sharedManager] installFileWithURL:URL completion:^(BOOL success, NSError * _Nullable error) {
        
    }];
    
}

- (void)updateLatestAppVersionUI:(AppVersionHistoryModel*)appVersionHistoryModel {
    // 1. 读取服务端版本信息
    NSInteger latestVersionCode = appVersionHistoryModel.version_code; // 服务器版本号（整数）
    NSString *latestVersionName = appVersionHistoryModel.version_name; // 服务器版本名称（如"1.2.0"）
    NSLog(@"服务器版本 - code:%ld, name:%@", latestVersionCode, latestVersionName);
    
    // 2. 读取本地版本信息（从Info.plist）
    NSString *localVersionCodeStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSInteger localVersionCode = [localVersionCodeStr integerValue]; // 本地版本号（整数）
    NSString *localVersionName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; // 本地版本名称（如"1.1.0"）
    NSLog(@"本地版本 - code:%ld, name:%@", localVersionCode, localVersionName);
    
    // 3. 版本号判断：服务器版本号 > 本地版本号（修复原逻辑的!=问题）
    BOOL isCodeNeedUpdate = (latestVersionCode > localVersionCode);
    
    // 4. 版本名称判断：服务器版本名称 > 本地版本名称（使用新增工具方法）
    BOOL isNameNeedUpdate = [[self class] versionName:localVersionName isLessThan:latestVersionName];
    
    // 5. 最终需要更新的条件：版本号和版本名称均满足更新（确保两者同步）
    BOOL needUpdate = isCodeNeedUpdate || isNameNeedUpdate;
    
    // 6. 更新按钮UI
    if (needUpdate) {
        self.titleLabel.text = @"发现新版";
        [self.downloadButton setTitle:[NSString stringWithFormat:@"当前:%@ 下载新版:%@", localVersionName,latestVersionName] forState:UIControlStateNormal];
        self.downloadButton.enabled = YES;
        self.downloadButton.backgroundColor = [UIColor systemBlueColor];
    } else {
        [self.downloadButton setTitle:[NSString stringWithFormat:@"已是最新版(%@)", localVersionName] forState:UIControlStateNormal];
        self.downloadButton.enabled = NO;
        self.downloadButton.backgroundColor = [UIColor lightGrayColor];
    }
}

// 比较两个版本名称（如"1.0.2"和"1.1.0"），返回YES表示version1 < version2（需要更新）
+ (BOOL)versionName:(NSString *)version1 isLessThan:(NSString *)version2 {
    if (!version1 || !version2) return NO; // 空值不判定为需要更新
    
    // 按"."拆分版本号为数组（如"1.2.3" → @[@"1", @"2", @"3"]）
    NSArray<NSString *> *v1Components = [version1 componentsSeparatedByString:@"."];
    NSArray<NSString *> *v2Components = [version2 componentsSeparatedByString:@"."];
    
    // 取最长的数组长度，短数组缺失部分按0处理
    NSInteger maxCount = MAX(v1Components.count, v2Components.count);
    for (NSInteger i = 0; i < maxCount; i++) {
        // 解析当前段的数字（超出数组范围则为0）
        NSInteger v1 = (i < v1Components.count) ? [v1Components[i] integerValue] : 0;
        NSInteger v2 = (i < v2Components.count) ? [v2Components[i] integerValue] : 0;
        
        // 逐段比较
        if (v1 < v2) {
            return YES; // version1当前段更小，整体版本更低
        } else if (v1 > v2) {
            return NO; // version1当前段更大，整体版本更高
        }
        // 相等则继续比较下一段
    }
    
    return NO; // 所有段都相等，版本相同
}

/**
 返回对应的 SectionController（子类必须实现）
 @param object 数据模型对象
 @return 返回具体的 SectionController 实例
 */
- (IGListSectionController *)templateSectionControllerForObject:(id)object {
    return [[TemplateSectionController alloc] initWithCellClass:[AppVersionHistoryCell class]
                                                     modelClass:[AppVersionHistoryModel class] delegate:self
                                                     edgeInsets:UIEdgeInsetsMake(0, 10, 10, 10)
                                               usingCacheHeight:NO];
}


#pragma mark - HWPanModalPresentable

- (PanModalHeight)shortFormHeight {
    return PanModalHeightMake(PanModalHeightTypeContent, 250);
}

- (PresentationState)originPresentationState {
    return PresentationStateMedium;
}


- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取手势的位置
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    if (CGRectContainsPoint(self.collectionView.frame, loc)) {
        return NO;
    }
    
    // 默认返回 YES，允许拖拽
    return YES;
}

// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    [self updateViewConstraints];
}

@end
