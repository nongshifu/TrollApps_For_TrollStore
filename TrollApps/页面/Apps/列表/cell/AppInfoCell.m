//
//  AppInfoCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/1.
//

#import "AppInfoCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/AFNetworking.h>
#import "MiniButtonView.h"
#import "NewProfileViewController.h"
#import "MyFavoritesListViewController.h"
#import "FileUtils.h"
#import "config.h"

//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface AppInfoCell ()<MiniButtonViewDelegate,HXPhotoViewDelegate>

@property (nonatomic, strong) UIImageView *appIconImageView;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, strong) UIButton *appTypeButton;
@property (nonatomic, strong) UIButton *appVersionButton;
@property (nonatomic, strong) UIButton *appUpdateTimeButton;
@property (nonatomic, strong) UILabel *downloadLabel;
@property (nonatomic, strong) UILabel *appDescriptionLabel;
@property (nonatomic, strong) MiniButtonView *statsMiniButtonView; // 统计按钮容器
@property (nonatomic, strong) MiniButtonView *tagMiniButtonView; // 标签容器
@property (nonatomic, strong) UIButton *downloadButton;


//图片选择器
@property (nonatomic, strong) UIView *imageStackView;
@property (nonatomic, strong) HXPhotoView *photoView;
@property (nonatomic, strong) HXPhotoManager *manager;

@property (nonatomic, strong) AppInfoModel *appInfoModel;



@end

@implementation AppInfoCell

#pragma mark - 初始化方法


- (void)setupUI {
    
    // 设置背景色
    self.backgroundColor = [UIColor clearColor];
    
    self.contentView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.6]
                                                          darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.4]
    ];
    self.contentView.layer.cornerRadius = 15;
    
    
    // 应用图标
    self.appIconImageView = [[UIImageView alloc] init];
    self.appIconImageView.layer.cornerRadius = 12.0;
    self.appIconImageView.layer.masksToBounds = YES;
    self.appIconImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    // 应用名称
    self.appNameLabel = [[UILabel alloc] init];
    self.appNameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    self.appNameLabel.textColor = [UIColor labelColor];
    self.appNameLabel.numberOfLines = 1;
    
    UIEdgeInsets edge = UIEdgeInsetsMake(2, 4, 2, 4);
    // 应用类型
    self.appTypeButton = [[UIButton alloc] init];
    self.appTypeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.appTypeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appTypeButton.contentEdgeInsets = edge;
    self.appTypeButton.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.6];
    self.appTypeButton.layer.cornerRadius = 3;
    
    //版本
    self.appVersionButton = [[UIButton alloc] init];
    self.appVersionButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.appVersionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appVersionButton.contentEdgeInsets = edge;
    self.appVersionButton.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.6];
    self.appVersionButton.layer.cornerRadius = 3;
    
    //版本更新时间
    self.appUpdateTimeButton = [[UIButton alloc] init];
    self.appUpdateTimeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.appUpdateTimeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appUpdateTimeButton.contentEdgeInsets = edge;
    self.appUpdateTimeButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.6];
    self.appUpdateTimeButton.layer.cornerRadius = 3;
    
    
    // 应用描述
    self.appDescriptionLabel = [[UILabel alloc] init];
    self.appDescriptionLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    self.appDescriptionLabel.textColor = [UIColor secondaryLabelColor];
    self.appDescriptionLabel.numberOfLines = 3;
    
    // 统计信息按钮堆栈视图
    self.statsMiniButtonView = [[MiniButtonView alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
    self.statsMiniButtonView.buttonDelegate = self;
    self.statsMiniButtonView.buttonSpace = 10;
    self.statsMiniButtonView.buttonBcornerRadius = 5;
    self.statsMiniButtonView.fontSize = 13;
    self.statsMiniButtonView.buttonBackageColorArray = @[
        [[UIColor systemBlueColor] colorWithAlphaComponent:0.5],
        [[UIColor systemPinkColor] colorWithAlphaComponent:0.5],
        [[UIColor systemYellowColor] colorWithAlphaComponent:0.5],
        [[UIColor systemGreenColor] colorWithAlphaComponent:0.5],
        [[UIColor systemTealColor] colorWithAlphaComponent:0.5],
    ];
    self.statsMiniButtonView.tintIconColor = [UIColor whiteColor];
    
    
    // 下载按钮
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    self.downloadButton.backgroundColor = [UIColor systemBlueColor];
    self.downloadButton.layer.cornerRadius = 12.0;
    self.downloadButton.layer.masksToBounds = YES;
    [self.downloadButton addTarget:self action:@selector(downloadButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    self.downloadLabel = [UILabel new];
    self.downloadLabel.font = [UIFont systemFontOfSize:10];
    self.downloadLabel.textColor = [UIColor secondaryLabelColor];
    
    // 标签堆栈视图
    self.tagMiniButtonView = [[MiniButtonView alloc] initWithFrame:CGRectMake(0, 0, kWidth - 130, 20)];
    self.tagMiniButtonView.tag = 0;
    self.tagMiniButtonView.userInteractionEnabled = NO;
    self.tagMiniButtonView.buttonDelegate = self;
    self.tagMiniButtonView.buttonSpace = 5;
    self.tagMiniButtonView.buttonBcornerRadius = 5;
    self.tagMiniButtonView.autoLineBreak = YES;
    self.tagMiniButtonView.fontSize = 10;
    self.tagMiniButtonView.tintIconColor = [UIColor whiteColor];
    self.tagMiniButtonView.buttonBackageColor = [[UIColor orangeColor] colorWithAlphaComponent:0.5];
    
    //照片容器
    self.imageStackView = [[UIView alloc] init];
    
    // 添加子视图
    [self.contentView addSubview:self.appIconImageView];
    [self.contentView addSubview:self.appNameLabel];
    [self.contentView addSubview:self.appTypeButton];
    [self.contentView addSubview:self.appVersionButton];
    [self.contentView addSubview:self.appUpdateTimeButton];
    [self.contentView addSubview:self.appDescriptionLabel];
    [self.contentView addSubview:self.statsMiniButtonView];
    [self.contentView addSubview:self.downloadButton];
    [self.contentView addSubview:self.downloadLabel];
    [self.contentView addSubview:self.tagMiniButtonView];
    [self.contentView addSubview:self.imageStackView];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    // 应用图标约束
    // 正确约束：contentView 撑满 cell，不限制高度
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self); // 仅约束边缘，高度由内容决定
    }];
    
    // 应用图标约束
    [self.appIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.contentView).offset(16);
        make.width.height.equalTo(@60);
    }];
    
    // 下载按钮约束
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.width.equalTo(@72);
        make.height.equalTo(@24);
    }];
    // 下载量
    [self.downloadLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.downloadButton.mas_bottom).offset(5);
        make.centerX.equalTo(self.downloadButton);
        
    }];
    
    // 应用名称约束
    [self.appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.left.equalTo(self.appIconImageView.mas_right).offset(12);
        make.width.equalTo(@200);
    }];

    // 应用类型约束
    [self.appTypeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameLabel.mas_bottom).offset(8);
        make.left.equalTo(self.appIconImageView.mas_right).offset(12);
        make.height.equalTo(@15);
    }];
    
    // 应用版本
    [self.appVersionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameLabel.mas_bottom).offset(8);
        make.left.equalTo(self.appTypeButton.mas_right).offset(6);
        make.height.equalTo(@15);
    }];
    
    // 应用更新时间
    [self.appUpdateTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appNameLabel.mas_bottom).offset(8);
        make.left.equalTo(self.appVersionButton.mas_right).offset(6);
        make.height.equalTo(@15);
    }];
    
    
    // 标签堆栈视图约束
    [self.tagMiniButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appTypeButton.mas_bottom).offset(8);
        make.left.equalTo(self.appIconImageView.mas_right).offset(12);
        make.right.equalTo(self.contentView.mas_right).offset(-12);
        

    }];

    // 应用描述约束
    [self.appDescriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagMiniButtonView.mas_bottom).offset(10);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView.mas_right).offset(-16);
        make.width.equalTo(@(CGRectGetWidth(self.contentView.frame) -32));
    }];
    
    // 统计信息按钮约束
    [self.statsMiniButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appDescriptionLabel.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.height.mas_equalTo(25);
        make.right.equalTo(self.contentView);
        
    }];
    
    // 图片容器
    [self.imageStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsMiniButtonView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView);
        make.bottom.lessThanOrEqualTo(self.contentView).offset(-16);

    }];
    
}

#pragma mark - 数据绑定

- (void)bindViewModel:(id)viewModel {
    if ([viewModel isKindOfClass:[AppInfoModel class]]) {
        AppInfoModel *appInfo = (AppInfoModel *)viewModel;
        self.model = appInfo;
        self.appInfoModel = appInfo;
        // 设置应用名称
        self.appNameLabel.text = appInfo.app_name;
        
        // 设置应用类型
        NSString *type = @"iPA";
        switch (appInfo.app_type) {
            case 0:
                type = @"iPA";
                break;
            case 1:
                type = @"Deb";
                break;
            case 2:
                type = @"Zip";
                break;
            case 3:
                type = @"其他";
                break;
                
            default:
                break;
        }
        //类型
        NSString *appTypeTitle = type;
        [self.appTypeButton setTitle:appTypeTitle forState:UIControlStateNormal];
        //版本
        NSString *appVersionTitle = [NSString stringWithFormat:@"v%ld",appInfo.current_version_code];
        [self.appVersionButton setTitle:appVersionTitle forState:UIControlStateNormal];
        //时间
        NSString *appUpdateTimeTitle = [NSString stringWithFormat:@"更新: %@",[TimeTool getTimeDiyWithString:appInfo.update_date]];
        [self.appUpdateTimeButton setTitle:appUpdateTimeTitle forState:UIControlStateNormal];
        
        // 设置应用描述
        if(appInfo.isShowAll){
            self.appDescriptionLabel.numberOfLines = 0;
        }
        self.appDescriptionLabel.text = appInfo.app_description ?appInfo.app_description:@"暂无介绍";
        
        // 配置统计按钮
        [self configureStatsButtonsWithAppInfo:appInfo];
        
        // 设置应用图标
        NSArray <UIImage *>* images = @[
            [UIImage systemImageNamed:@"applelogo"],
            [UIImage systemImageNamed:@"doc.badge.gearshape.fill"],
            [UIImage systemImageNamed:@"doc.zipper"],
            [UIImage systemImageNamed:@"tray.circle"],
        ];
        self.appIconImageView.image = images[appInfo.app_type];
        NSLog(@"iconURL:%@",appInfo.icon_url);
        
        [self.appIconImageView sd_setImageWithURL:[NSURL URLWithString:appInfo.icon_url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if(image){
                self.appIconImageView.image = image;
            }
            
        }];
        
        // 配置标签
        [self configureTagsWithArray:appInfo.tags];
        
        // 根据应用状态调整下载按钮
        [self updateDownloadButtonForAppStatus:appInfo.app_status];
        
        //图片视频
        NSLog(@"AppInfoModel.fileNames:%@",self.appInfoModel.fileNames);
        if(self.appInfoModel.fileNames.count>1 && self.appInfoModel.isShowAll){
            [self addAssModelToManagerWith:self.appInfoModel.fileNames];
        }else{
            [self.photoView removeFromSuperview];
            self.photoView = nil;
        }
    }
}

// 配置统计按钮
- (void)configureStatsButtonsWithAppInfo:(AppInfoModel *)appInfo {
    // 下载量
    if (appInfo.download_count > 0) {
        self.downloadLabel.text = [NSString stringWithFormat:@"↓ %@", [self formatCount:appInfo.download_count]];
    }
    
    // 创建统计按钮
    NSArray *statsTitles = @[
        appInfo.collect_count > 0 ? [self formatCount:appInfo.collect_count] : @"收藏",
        appInfo.like_count > 0 ? [self formatCount:appInfo.like_count] : @"点赞",
        appInfo.dislike_count > 0 ? [self formatCount:appInfo.dislike_count] : @"踩",
        appInfo.comment_count > 0 ? [self formatCount:appInfo.comment_count] : @"评论",
        appInfo.share_count > 0 ? [self formatCount:appInfo.share_count] : @"分享"
    ];
    NSLog(@"点赞等状态isCollect：%d isLike:%d isDislike:%d",appInfo.isCollect,appInfo.isLike,appInfo.isDislike);
    NSArray *imageNames = @[
        appInfo.isCollect ? @"star.fill" : @"star",
        appInfo.isLike ? @"heart.fill" : @"heart",
        appInfo.isDislike ? @"hand.thumbsdown.fill" : @"hand.thumbsdown",
        @"bubble.right",
        @"square.and.arrow.up"
    ];
    
    [self.statsMiniButtonView updateButtonsWithStrings:statsTitles icons:imageNames];
}

// 配置标签
- (void)configureTagsWithArray:(NSArray<NSString *> *)tags {
    // 清除现有标签
    [self.tagMiniButtonView updateButtonsWithStrings:tags icons:nil];

    [self.tagMiniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.appTypeButton.mas_bottom).offset(8);
        make.height.equalTo(@(self.tagMiniButtonView.refreshHeight)); // 允许高度自适应

    }];
    
    
    
}

// 根据应用状态调整下载按钮
- (void)updateDownloadButtonForAppStatus:(NSInteger)status {
    //软件状态：状态（0正常，1失效 2更新中 3锁定 4上传中 5隐藏）
    switch (status) {
            
        case 0: // 正常
            [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemBlueColor];
            if(self.appInfoModel.download_count > 100){
                [self.downloadButton setTitle:@"🔥 下载" forState:UIControlStateNormal];
                
            }
            break;
        case 1: // 失效
            [self.downloadButton setTitle:@"失效" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
            
            break;
        case 2: // 更新中
            [self.downloadButton setTitle:@"更新中" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemOrangeColor];
            
            break;
            
        case 3: // 锁定禁止下载
            [self.downloadButton setTitle:@"禁止下载" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemRedColor];
            
            break;
        case 4: // 正常
            [self.downloadButton setTitle:@"上传中" forState:UIControlStateNormal];
            
            self.downloadButton.backgroundColor = [UIColor purpleColor];
            
            break;
        default:
            [self.downloadButton setTitle:@"其他" forState:UIControlStateNormal];
            self.downloadButton.backgroundColor = [UIColor systemGrayColor];
            
            break;
    }
}


#pragma mark - 内存管理

- (void)prepareForReuse {
    [super prepareForReuse];
    
    
    // 清除现有标签和统计按钮
    
   
}

#pragma mark - 辅助函数
//重命名数量
- (NSString *)formatCount:(NSInteger)count {
    if (count < 1000) {
        return [NSString stringWithFormat:@"%ld", count];
    } else if (count < 10000) {
        return [NSString stringWithFormat:@"%.2fK", count / 1000.0];
    } else {
        return [NSString stringWithFormat:@"%.2fW", count / 10000.0];
    }
}

#pragma mark - 底部点击代理
- (void)buttonTappedWithTag:(NSInteger)tag title:(nonnull NSString *)title button:(nonnull UIButton *)button {
    NSString *action = nil;
    NSString *successMsg = nil;
    button.tag = tag;
    // 根据按钮tag确定操作类型
    switch (tag) {
        case 0: // 收藏
            action = @"toggle_collect";
            successMsg = @"收藏";
            [self collectButtonTapped:action successMessage:successMsg button:button];
            return;;
            
        case 1: // 点赞
            action = @"toggle_like";
            successMsg = @"点赞";
            break;
            
        case 2: // 踩一踩
            action = @"toggle_dislike";
            successMsg = @"踩一踩";
            break;
            
        case 3: // 评论
            action = @"comment";
            successMsg = @"发布评论";
            [self handleCommentAction];
            return;
            
        case 4: // 分享
            action = @"share";
            successMsg = @"分享";
            [self handleShareAction];
            return;;
            
        default:
            return;
    }
    
    [self performAction:action successMessage:successMsg button:button];
}

#pragma mark - 交互处理
- (void)downloadButtonTapped {
    NSLog(@"点击了右侧下载按钮");
    
    
}

- (void)collectButtonTapped:(NSString *)action successMessage:(NSString *)message button:(UIButton *)button {
    NSLog(@"点击了收藏按钮");
    NSString *actionStr = action;
    //底部弹出选择 查看收藏表 收藏此App
    // 1. 获取当前App的ID（假设从当前页面数据中获取，需根据实际情况修改）
    NSInteger currentAppId = self.appInfoModel.app_id; // 示例：当前App的ID
    if (!currentAppId || currentAppId == 0) {
        [SVProgressHUD showErrorWithStatus:@"未获取到应用信息"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    // 2. 创建底部弹出菜单（UIAlertController 模拟 ActionSheet）
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 3. 添加“收藏此App”选项
    NSString *collectActionTitle = self.appInfoModel.isCollect ? @"取消收藏" : @"收藏此应用";
    UIAlertActionStyle style = self.appInfoModel.isCollect ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
    UIAlertAction *collectAction = [UIAlertAction actionWithTitle:collectActionTitle
                                                            style:style
                                                          handler:^(UIAlertAction * _Nonnull action) {
        // 执行收藏操作（调用API）
        //执行
        [self performAction:actionStr successMessage:message button:button];
    }];
    [actionSheet addAction:collectAction];
    
    // 4. 添加“查看收藏列表”选项
    UIAlertAction *viewFavoritesAction = [UIAlertAction actionWithTitle:@"查看我的收藏"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
        // 跳转到收藏列表页面
        MyFavoritesListViewController *vc = [MyFavoritesListViewController new];
        [[self getviewController] presentPanModal:vc];
        
    }];
    [actionSheet addAction:viewFavoritesAction];
    
    // 5. 添加取消选项
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [actionSheet addAction:cancelAction];
    
    // 6. 适配iPad（避免崩溃）
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        actionSheet.popoverPresentationController.sourceView = button;
        actionSheet.popoverPresentationController.sourceRect = button.bounds;
    }
    
    // 7. 显示菜单
    [[self getviewController] presentViewController:actionSheet animated:YES completion:nil];
    
    
}

- (void)handleCommentAction {
    // 处理评论操作
    NSLog(@"处理评论操作");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"发布评论" message:@"请输入评论内容" preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"请输入评论内容";
    }];
    
    // 添加取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // 取消操作的处理
    }];
    
    // 添加确定按钮
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        // 确定操作的处理，这里可以获取输入框的内容
        NSLog(@"输入的内容：%@", textField.text);
        NSString *udid =[NewProfileViewController sharedInstance].userInfo.udid ?: @"";
        if(textField.text.length==0){
            [SVProgressHUD showErrorWithStatus:@"请输入评论内容"];
            [SVProgressHUD dismissWithDelay:2];
            return;
        }
        if(udid.length==0){
            [SVProgressHUD showErrorWithStatus:@"请先登录绑定哦"];
            [SVProgressHUD dismissWithDelay:2];
            return;
        }
        
        
        // 构建请求参数（根据实际接口调整）
        NSDictionary *params = @{
            @"action": @"comment",
            @"app_id": @(self.appInfoModel.app_id),
            @"content": textField.text,
            @"udid": udid
        };
        
        [SVProgressHUD showWithStatus:@"发送中..."];
        
        [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                                  urlString:[NSString stringWithFormat:@"%@/app_action.php",localURL]
                                                 parameters:params
                                                       udid:udid
                                                   progress:^(NSProgress *progress) {
            
        } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
            NSLog(@"发布评论返回:%@",jsonResult);
            NSLog(@"发布评论stringResult返回:%@",stringResult);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!jsonResult || !jsonResult[@"code"]){
                    return;
                }
                NSInteger code = [jsonResult[@"code"] intValue];
                NSString * msg = jsonResult[@"msg"];
                
                if (code == 200) {
                    [SVProgressHUD showSuccessWithStatus:msg];
                    self.appInfoModel.isComment = YES;
                    self.appInfoModel.isComment+=1;
                } else {
                    [SVProgressHUD showErrorWithStatus:msg];
                }
                [SVProgressHUD dismissWithDelay:1];
                self.model = self.appInfoModel;
                [self bindViewModel:self.model];
            });
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:@"网络错误，发送失败"];
            [SVProgressHUD dismissWithDelay:2];
        }];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [[self getTopViewController] presentViewController:alertController animated:YES completion:nil];
    
}

- (void)handleShareAction {
    // 处理评论操作
    NSLog(@"处理分享操作");
    
    // 确保应用信息有效
    if (!self.appInfoModel || !self.appInfoModel.app_name) {
        [SVProgressHUD showInfoWithStatus:@"暂无应用信息可分享"];
        return;
    }
    
    // 显示加载提示
    [SVProgressHUD showWithStatus:@"准备分享..."];
    
    // 1. 准备分享内容
    NSMutableArray *shareItems = [NSMutableArray array];
    
    // 添加应用名称和描述
    NSString *shareText = [NSString stringWithFormat:@"%@\n%@",
                           self.appInfoModel.app_name,
                           self.appInfoModel.app_description ?: @"快来一起看看吧！"];
    [shareItems addObject:shareText];
    
    // 添加应用URL
    NSString *urlString = [NSString stringWithFormat:@"%@/app_detail.html?app_id=%ld", localURL, self.appInfoModel.app_id];
    NSURL *appURL = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    if (appURL) {
        [shareItems addObject:appURL];
    }
    
    // 处理应用图标（异步下载网络图片）
    __block UIImage *appIcon = nil;
    NSString *iconURL = self.appInfoModel.icon_url;
    if (iconURL && [iconURL length] > 0 && [iconURL hasPrefix:@"http"]) {
        [[UIImageView new] sd_setHighlightedImageWithURL:[NSURL URLWithString:iconURL] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if(image){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentShareControllerWithItems:shareItems appIcon:image];
                });
            }
        }];
        
    } else {
        // 本地图片或无图标，直接显示分享界面
        [self presentShareControllerWithItems:shareItems appIcon:appIcon];
    }
}

- (void)presentShareControllerWithItems:(NSMutableArray *)shareItems appIcon:(UIImage *)appIcon {
    [SVProgressHUD dismiss]; // 隐藏加载提示
    
    // 添加应用图标（如果有）
    if (appIcon) {
        [shareItems addObject:appIcon];
    }
    
    // 2. 创建分享控制器
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
    
    // 3. 排除不需要的分享选项
    activityVC.excludedActivityTypes = @[
//        UIActivityTypePostToFacebook,
//        UIActivityTypePostToTwitter,
//        UIActivityTypePrint,
//        UIActivityTypeCopyToPasteboard,
//        UIActivityTypeAssignToContact,
//        UIActivityTypeSaveToCameraRoll
    ];
    
    // 4. 设置分享完成回调
    activityVC.completionWithItemsHandler = ^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        NSLog(@"设置分享完成回调");
        if(activityError){
            NSLog(@"分享activityError: %@", activityError);
        }
        if (completed) {
            [SVProgressHUD showSuccessWithStatus:@"分享成功"];
            NSLog(@"分享完成，活动类型: %@", activityType);
        } else {
            NSLog(@"分享取消");
        }
        
        if (activityError) {
            NSLog(@"分享错误: %@", activityError.localizedDescription);
        }
    };
    
    // 5. 适配iPad
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(self.bounds.size.width/2, self.bounds.size.height/2, 1, 1);
    }
    
    // 6. 显示分享控制器
    [[self getTopViewController] presentViewController:activityVC animated:YES completion:nil];
}

- (void)performAction:(NSString *)action successMessage:(NSString *)message button:(UIButton *)button {
    if (!self.model || !action) return;
    
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid;
    if(udid.length == 0){
        [SVProgressHUD showImage:[UIImage systemImageNamed:@"smiley"] status:@"请先获取UDID登录后操作"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    
    // 显示加载指示器
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"正在%@...", message]];
    
    // API地址 - 根据实际情况修改
    NSString *urlString = [NSString stringWithFormat:@"%@/app_action.php",localURL];
    
    
    // 准备请求参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"action"] = action;
    params[@"app_id"] = @(self.appInfoModel.app_id);
    
    // 获取设备标识
    params[@"idfv"] = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSLog(@"共享单例udid：%@",udid);
    params[@"udid"] = udid;
    NSLog(@"请求操作字典：%@",params);
   
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:urlString
                                             parameters:params
                                                   udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if(!jsonResult ){
                NSLog(@"请求返回stringResult：%@",stringResult);
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"返回数据错误\n%@",stringResult]];
                [SVProgressHUD dismissWithDelay:1];
                return;
            }
            
            NSLog(@"请求返回字典：%@",jsonResult);
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString *message = jsonResult[@"msg"];
            if (code != 200){
                // 失败
                
                [SVProgressHUD showErrorWithStatus:message];
                [SVProgressHUD dismissWithDelay:1];
                return;
            }
            
            UIImage *image = button.imageView.image;
            [SVProgressHUD showImage:image status:message];
            [SVProgressHUD dismissWithDelay:1];
            // 新增：根据服务器返回的status动态更新计数
            [self updateStatsAfterResponse:jsonResult tag:button.tag];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",error]];
        [SVProgressHUD dismissWithDelay:1];
    }];
    
    
    
}

- (void)updateStatsAfterResponse:(id)response tag:(NSInteger )tag{
    // 获取服务器返回的状态和数量变化
    NSDictionary *data = response[@"data"];
    if(!data) return;
    BOOL newStatus = [data[@"newStatus"] boolValue];
    NSInteger count = [data[@"count"] intValue];
    // 根据按钮tag确定操作类型
    switch (tag) {
        case 0: // 收藏
            self.appInfoModel.isCollect = newStatus;
            self.appInfoModel.collect_count = count;
            break;
            
        case 1: // 点赞
            self.appInfoModel.isLike = newStatus;
            self.appInfoModel.like_count = count;
            break;
            
        case 2: // 踩一踩
            self.appInfoModel.isDislike = newStatus;
            self.appInfoModel.dislike_count = count;
            break;
            
        case 3: // 评论
            self.appInfoModel.isComment = newStatus;
            self.appInfoModel.comment_count = count;
            break;
            
        case 4: // 分享
            self.appInfoModel.isShare = newStatus;
            self.appInfoModel.share_count = count;
            break;
            
        default:
            return;
    }
    
   
    // 更新model并刷新UI
    self.model = self.appInfoModel;
    [self bindViewModel:self.model];
}

#pragma mark - 更新后的HXPhotoManager配置

- (HXPhotoManager *)manager {
    if (!_manager) {
        // 创建弱引用
        // 创建弱引用
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.maxNum = 12;
        _manager.configuration.photoMaxNum = 0;
        _manager.configuration.videoMaxNum = 0;
        _manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit =YES;//视频过大自动跳转编辑
        _manager.configuration.videoMaximumDuration = 60;//视频最大时长
        _manager.configuration.saveSystemAblum = YES;//是否保存系统相册
        _manager.configuration.lookLivePhoto = YES; //是否开启查看LivePhoto功能呢 - 默认 NO
        _manager.configuration.photoCanEdit = YES;
        _manager.configuration.photoCanEdit = YES;
        _manager.configuration.videoCanEdit = YES;
        _manager.configuration.selectTogether = YES;//同时选择视频图片
        _manager.configuration.showOriginalBytes =YES;//原图显示大小
        _manager.configuration.showOriginalBytesLoading =YES;
        _manager.configuration.requestOriginalImage = NO;//默认非圆图
        _manager.configuration.clarityScale = 2.0f;
        _manager.configuration.allowPreviewDirectLoadOriginalImage =NO;//预览大图时允许不先加载小图，直接加载原图
        _manager.configuration.livePhotoAutoPlay =NO;//查看LivePhoto是否自动播放，为NO时需要长按才可播放
        _manager.configuration.replacePhotoEditViewController = NO;
        _manager.configuration.editAssetSaveSystemAblum = YES;
        _manager.configuration.customAlbumName = @"TrollApps";
    }
    return _manager;
}

- (void)addAssModelToManagerWith:(NSArray<NSString *> *)appFileModels {
    Demo9Model *models = [self getAssetModels:appFileModels];
    
    //添加到HXPhotoView 的 manager
    [self addModelToManager:models];
    
    NSLog(@"最后:%@",appFileModels);
    // 计算文件媒体数量
    NSInteger count = 0;
    for (NSString *file in appFileModels) {
        if (![file containsString:@"thumbnail"] && ![file containsString:@"icon.png"]) {
            count++;
        }
    }
    
    NSLog(@"排除后的媒体数量:%ld",count);

    // 最大宽度（左右预留16pt，总32pt）
    CGFloat maxWidth = CGRectGetWidth(self.contentView.frame) - 32;

    // 高度
    CGFloat totalHeight = 0;
    
    CGFloat cellWidth =(maxWidth - 2*3)/3;
    if(count<=3) {
        totalHeight = cellWidth;
    }else if(count > 3 && count<=6) {
        totalHeight = cellWidth *2 + 3;
    }else if(count > 6 && count<=9) {
        totalHeight = cellWidth *3 +6;
    }else{
        totalHeight = cellWidth *4 +9;
    }
    
    [self.photoView removeFromSuperview];
    self.photoView = nil;
    
    // 4. 添加图片视频到模型
//    [self.manager addCustomAssetModel:assets];
    
    //照片选择器
    self.photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(0, 0, maxWidth, totalHeight) manager:self.manager];
    self.photoView.delegate = self;
    self.photoView.layer.cornerRadius = 10;
    self.photoView.layer.masksToBounds = YES;
    self.photoView.outerCamera = YES;
    self.photoView.alpha = 1;
    self.photoView.showAddCell = NO;
    self.photoView.hideDeleteButton = YES;
    self.photoView.layer.borderWidth = 0.5;
    self.photoView.layer.borderColor = [UIColor quaternaryLabelColor].CGColor;
    self.photoView.backgroundColor = [UIColor clearColor];
    [self.photoView setRandomGradientBackgroundWithColorCount:3 alpha:0.1];
    
    // 刷新视图
    [self.photoView refreshView];
    
    [self.imageStackView addSubview:self.photoView];

    // 图片容器
    [self.imageStackView mas_updateConstraints:^(MASConstraintMaker *make) {

        make.width.equalTo(@(maxWidth));
        make.height.equalTo(@(totalHeight));

    }];
    
    
    // 更新布局
    [self layoutIfNeeded];
    
    
    
}


- (Demo9Model *)getAssetModels:(NSArray<NSString *> *)appFileModels{
    NSLog(@"传进来的:%@",appFileModels);
    Demo9Model *Models = [[Demo9Model alloc] init];
    
    NSMutableArray *assetModels = [NSMutableArray array];
    
    // 检测当前网络状态
    BOOL isWiFi = NO;
    AFNetworkReachabilityManager *reachability = [AFNetworkReachabilityManager sharedManager];
    if (reachability.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi) {
        isWiFi = YES;
    }
    
    // 创建文件名到URL的映射，用于快速查找缩略图
    NSMutableDictionary<NSString *, NSString *> *fileNameToURLMap = [NSMutableDictionary dictionary];
    for (NSString *fileName in appFileModels) {
        NSString *urlString = [NSString stringWithFormat:@"%@/%@%@",localURL,self.appInfoModel.save_path,fileName];
        [fileNameToURLMap setObject:urlString forKey:fileName];
    }
    
    for (int i = 0; i < appFileModels.count; i++) {
        NSString *fileName = appFileModels[i];
        //排除主图图标
        if([fileName containsString:@"icon.png"]) continue;
        
        //封装完整URL
        NSString *urlString = [NSString stringWithFormat:@"%@/%@%@",localURL,self.appInfoModel.save_path,fileName];
        NSURL *fileURL = [NSURL URLWithString:urlString];
     
        if (!fileURL) continue;
        
        // 2. 判断是否为媒体文件（图片/视频）
        if (![FileUtils isMediaFileWithURL:fileURL]) {
            NSLog(@"跳过非媒体文件：%@", fileURL);
            continue;
        }
        
        // 排除缩略图文件
        if ([fileName containsString:@"thumbnail"]) {
            NSLog(@"跳过缩略图文件：%@", fileName);
            continue;
        }
        
        if ([FileUtils isImageFileWithURL:fileURL]) {
            // 执行封装模型（图片文件）
            HXCustomAssetModel *assetModel = [HXCustomAssetModel assetWithNetworkImageURL:fileURL networkThumbURL:fileURL selected:YES];
            [assetModels addObject:assetModel];
        }
        else if ([FileUtils isVideoFileWithURL:fileURL]) {
            // 根据视频文件名查找对应的缩略图
            NSString *thumbnailURLString = nil;
            CGFloat videoDuration = 0;
            
            // 获取视频文件名（不含扩展名）
            NSString *videoNameWithoutExt = [fileName stringByDeletingPathExtension];
            
            // 构建可能的缩略图文件名
            NSString *expectedThumbnailName = [NSString stringWithFormat:@"%@_thumbnail", videoNameWithoutExt];
            
            // 在映射中查找匹配的缩略图
            for (NSString *possibleThumbnailName in fileNameToURLMap.keyEnumerator) {
                if ([possibleThumbnailName containsString:expectedThumbnailName] &&
                    [possibleThumbnailName containsString:@"thumbnail"] &&
                    [FileUtils isImageFileWithURL:[NSURL URLWithString:fileNameToURLMap[possibleThumbnailName]]]) {
                    thumbnailURLString = fileNameToURLMap[possibleThumbnailName];
                    
                    // 从缩略图文件名中提取时长信息
                    NSArray *components = [possibleThumbnailName componentsSeparatedByString:@"_thumbnail_"];
                    if (components.count == 2) {
                        NSString *durationPart = [components[1] stringByDeletingPathExtension];
                        videoDuration = [durationPart floatValue];
                        NSLog(@"从文件名提取视频时长: %@ -> %.1f秒", possibleThumbnailName, videoDuration);
                    }
                    break;
                }
            }
            
            // 如果找到缩略图，使用它；否则使用默认值
            NSURL *thumbnailURL = thumbnailURLString ? [NSURL URLWithString:thumbnailURLString] : [NSURL URLWithString:@""];
            
            // 视频（使用找到的缩略图URL和提取的时长）
            HXCustomAssetModel *assetModel = [HXCustomAssetModel assetWithNetworkVideoURL:fileURL
                                                                                videoCoverURL:thumbnailURL
                                                                                videoDuration:videoDuration
                                                                                    selected:YES];
            [assetModels addObject:assetModel];
        }
    }
    
    NSLog(@"最后的媒体数量:%lu", (unsigned long)assetModels.count);
    Models.customAssetModels = assetModels;
    return Models;
}

//填装图片视频文件
- (void)addModelToManager:(Demo9Model *)model {
    
    [self.manager changeAfterCameraArray:model.endCameraList];
    [self.manager changeAfterCameraPhotoArray:model.endCameraPhotos];
    [self.manager changeAfterCameraVideoArray:model.endCameraVideos];
    [self.manager changeAfterSelectedCameraArray:model.endSelectedCameraList];
    [self.manager changeAfterSelectedCameraPhotoArray:model.endSelectedCameraPhotos];
    [self.manager changeAfterSelectedCameraVideoArray:model.endSelectedCameraVideos];
    [self.manager changeAfterSelectedArray:model.endSelectedList];
    [self.manager changeAfterSelectedPhotoArray:model.endSelectedPhotos];
    [self.manager changeAfterSelectedVideoArray:model.endSelectedVideos];
    [self.manager changeICloudUploadArray:model.iCloudUploadArray];
    
    // 这些操作需要放在manager赋值的后面，不然会出现重用..
    self.manager.configuration.albumShowMode = HXPhotoAlbumShowModePopup;
    self.manager.configuration.photoMaxNum = model.customAssetModels.count;
    self.manager.configuration.videoMaxNum = 1;
    if (!model.addCustomAssetComplete && model.customAssetModels.count) {
        [self.manager addCustomAssetModel:model.customAssetModels];
        model.addCustomAssetComplete = YES;
    }
    
    HXWeakSelf
    self.manager.configuration.previewRespondsToLongPress = ^(UILongPressGestureRecognizer *longPress, HXPhotoModel *photoModel, HXPhotoManager *manager, HXPhotoPreviewViewController *previewViewController) {
        HXPhotoBottomViewModel *saveModel = [[HXPhotoBottomViewModel alloc] init];
        saveModel.title = @"保存";
        saveModel.customData = photoModel.tempImage;
        [HXPhotoBottomSelectView showSelectViewWithModels:@[saveModel] selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
            
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                if (photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWork ||
                    photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
                    NSSLog(@"需要自行保存网络图片");
                    
//                    return;
                }
            }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                if (photoModel.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                    NSSLog(@"需要自行保存网络视频");
//                    return;
                }
            }
            [previewViewController.view hx_showLoadingHUDText:@"保存中"];
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                [HXPhotoTools savePhotoToCustomAlbumWithName:weakSelf.manager.configuration.customAlbumName photo:model.customData location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                    [previewViewController.view hx_handleLoading];
                    if (success) {
                        [previewViewController.view hx_showImageHUDText:@"保存成功"];
                    }else {
                        [previewViewController.view hx_showImageHUDText:@"保存失败"];
                    }
                }];
            }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                if (photoModel.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                    [[HXPhotoCommon photoCommon] downloadVideoWithURL:photoModel.videoURL progress:nil downloadSuccess:^(NSURL * _Nullable filePath, NSURL * _Nullable videoURL) {
                        [HXPhotoTools saveVideoToCustomAlbumWithName:nil videoURL:filePath location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                            [previewViewController.view hx_handleLoading];
                            if (success) {
                                [previewViewController.view hx_showImageHUDText:@"保存成功"];
                            }else {
                                [previewViewController.view hx_showImageHUDText:@"保存失败"];
                            }
                        }];
                    } downloadFailure:^(NSError * _Nullable error, NSURL * _Nullable videoURL) {
                        [previewViewController.view hx_handleLoading];
                        [previewViewController.view hx_showImageHUDText:@"保存失败"];
                    }];
                    return;
                }
                [HXPhotoTools saveVideoToCustomAlbumWithName:nil videoURL:photoModel.videoURL location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                    [previewViewController.view hx_handleLoading];
                    if (success) {
                        [previewViewController.view hx_showImageHUDText:@"保存成功"];
                    }else {
                        [previewViewController.view hx_showImageHUDText:@"保存失败"];
                    }
                }];
            }
        } cancelClick:nil];
        
    };
    
}


@end
