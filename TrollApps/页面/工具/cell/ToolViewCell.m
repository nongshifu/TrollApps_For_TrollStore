//
//  ToolViewCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/6.
//

#import "ToolViewCell.h"
#import "config.h"
#import "MiniButtonView.h"
#import "ToolViewCell.h"
#import "Masonry.h"
#import "WebToolManager.h"
#import "WebViewController.h"
#import "loadData.h"
#import "LikeModel.h"

@interface ToolViewCell ()<MiniButtonViewDelegate>

// 左侧头像
@property (nonatomic, strong) UIImageView *avatarImgView;

// 右侧内容区
@property (nonatomic, strong) UILabel *toolNameLabel;      // 工具名称（最多2行）
@property (nonatomic, strong) UILabel *updateTimeLabel;    // 更新日期
@property (nonatomic, strong) MiniButtonView *tagsContainerView;   // 标签按钮容器（预留）
@property (nonatomic, strong) UILabel *descLabel;          // 简介（最多4行）
@property (nonatomic, strong) MiniButtonView *statsContainerView;  // 统计数据容器（预留）
@property (nonatomic, strong) UIButton *useButton;         // 使用按钮

@property (nonatomic, strong) NSString *commentContent;
@end

@implementation ToolViewCell

#pragma mark - 初始化


#pragma mark - UI设置

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.6]
                                                          darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.4]];
    self.contentView.layer.cornerRadius = 15;
    self.contentView.clipsToBounds = YES; // 确保子视图不超出圆角范围
    
    // 1. 左侧头像
    self.avatarImgView = [[UIImageView alloc] init];
    self.avatarImgView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImgView.clipsToBounds = YES;
    self.avatarImgView.layer.cornerRadius = 15; // 圆角15
    self.avatarImgView.backgroundColor = [UIColor lightGrayColor]; // 占位背景
    [self.contentView addSubview:self.avatarImgView];
    
    // 2. 工具名称（最多2行）
    self.toolNameLabel = [[UILabel alloc] init];
    self.toolNameLabel.font = [UIFont boldSystemFontOfSize:16];
    self.toolNameLabel.textColor = [UIColor labelColor];
    self.toolNameLabel.numberOfLines = 2; // 最多2行
    self.toolNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.toolNameLabel];
    
    // 3. 更新日期
    self.updateTimeLabel = [[UILabel alloc] init];
    self.updateTimeLabel.font = [UIFont systemFontOfSize:12];
    self.updateTimeLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.updateTimeLabel];
    
    // 4. 标签容器（预留，用户后期实现）
    self.tagsContainerView = [[MiniButtonView alloc] initWithFrame:CGRectMake(0, 0, kWidth - 100, 25)];
    self.tagsContainerView.buttonBcornerRadius  = 7;
    self.tagsContainerView.autoLineBreak = YES;
    self.tagsContainerView.space = 3;
    self.tagsContainerView.buttonSpace = 7;
    self.tagsContainerView.buttonBackgroundColorAlpha = 0.5;
    [self.contentView addSubview:self.tagsContainerView];
    
    // 5. 简介（最多4行）
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = [UIFont systemFontOfSize:14];
    self.descLabel.textColor = [UIColor secondaryLabelColor];
    self.descLabel.numberOfLines = 4; // 最多4行
    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.descLabel];
    
    // 6. 统计容器（预留，用户后期实现）
    self.statsContainerView = [[MiniButtonView alloc] initWithFrame:CGRectMake(0, 0, kWidth - 100, 25)];
    self.statsContainerView.buttonDelegate = self;
    self.statsContainerView.buttonBcornerRadius  =3;
    self.statsContainerView.autoLineBreak = YES;
    self.statsContainerView.space = 3;
    self.statsContainerView.buttonSpace = 10;
    self.statsContainerView.tintIconColor = [UIColor whiteColor];
    self.statsContainerView.buttonBackageColorArray = @[
        [[UIColor systemOrangeColor] colorWithAlphaComponent:0.5],
        [[UIColor systemBlueColor] colorWithAlphaComponent:0.5],
        [[UIColor systemPinkColor] colorWithAlphaComponent:0.5],
        [[UIColor systemYellowColor] colorWithAlphaComponent:0.5],
        [[UIColor systemGreenColor] colorWithAlphaComponent:0.5],
        [[UIColor systemTealColor] colorWithAlphaComponent:0.5],
    ];
    [self.contentView addSubview:self.statsContainerView];
    
    // 7. 使用按钮
    self.useButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.useButton setTitle:@"使用" forState:UIControlStateNormal];
    self.useButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.useButton.backgroundColor = [UIColor systemBlueColor];
    self.useButton.layer.cornerRadius = 15;
    [self.useButton addTarget:self action:@selector(openHtml:) forControlEvents:UIControlEventTouchUpInside];
    [self.useButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.contentView addSubview:self.useButton];
}

#pragma mark - 约束设置

- (void)setupConstraints {
    
    // 正确约束：contentView 撑满 cell，不限制高度
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self); // 仅约束边缘，高度由内容决定
        make.width.equalTo(@(kWidth -20));
//        make.height.greaterThanOrEqualTo(@100); // 确保最小高度
    }];
    // 左侧头像：固定宽高60，左、上、下有间距
    [self.avatarImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.top.equalTo(self.contentView).offset(15);
        make.width.height.equalTo(@60); // 头像大小60x60（圆角15，视觉上更协调）
    }];
    
    // 使用按钮：固定宽高30，右侧间距15，与头像顶部对齐
    [self.useButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-15);
        make.top.equalTo(self.avatarImgView);
        make.width.equalTo(@60);
        make.height.equalTo(@30);
    }];
    
    // 工具名称：左接头像，右接使用按钮，顶部与头像对齐
    [self.toolNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImgView.mas_right).offset(15);
        make.right.equalTo(self.useButton.mas_left).offset(-10);
        make.top.equalTo(self.avatarImgView);
    }];
    
    // 更新日期：在名称下方，左、右与名称对齐
    [self.updateTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.toolNameLabel);
        make.top.equalTo(self.toolNameLabel.mas_bottom).offset(5);
    }];
    
    // 标签容器：在日期下方，左、右与名称对齐，高度固定30（用户可后期调整）
    [self.tagsContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImgView.mas_right).offset(15);
        make.right.equalTo(self.contentView).offset(-45);
        make.top.equalTo(self.updateTimeLabel.mas_bottom).offset(8);
        make.height.equalTo(@25);
        
    }];
    
    // 简介：左接contentView左侧，右接contentView右侧（占满宽度），在标签下方
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.right.equalTo(self.contentView).offset(-15);
        make.top.equalTo(self.tagsContainerView.mas_bottom).offset(10);
    }];

    // 统计容器：在简介下方，左、右与简介对齐，高度固定25（用户可后期调整）
    [self.statsContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.right.equalTo(self.contentView).offset(-15);
        make.top.equalTo(self.descLabel.mas_bottom).offset(8);
        make.height.equalTo(@25);
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).offset(-15); // 底部与contentView底部间距15
    }];
}

#pragma mark - 数据绑定

- (void)bindViewModel:(id)viewModel {
    if (![viewModel isKindOfClass:[WebToolModel class]]) return;
    self.toolModel = (WebToolModel *)viewModel;
    
    // 绑定数据到UI
    self.toolNameLabel.text = self.toolModel.tool_name;
    self.updateTimeLabel.text = [NSString stringWithFormat:@"更新于：%@", self.toolModel.update_time];
    self.descLabel.text = self.toolModel.tool_description;
    
    // 头像占位（实际项目中替换为工具图标URL）
    self.avatarImgView.image = [UIImage systemImageNamed:@"doc.text.fill"]; // 系统占位图
    NSString *iconUrlString = [NSString stringWithFormat:@"%@/%@/icon.png",localURL,self.toolModel.tool_path];
    [self.avatarImgView sd_setImageWithURL:[NSURL URLWithString:iconUrlString]];
    
    
    // 标签容器和统计容器：用户后期自行实现数据绑定
    [self.tagsContainerView updateButtonsWithStrings:self.toolModel.tags icons:nil];
   
    // 标签容器：在日期下方，左、右与名称对齐，高度固定30（用户可后期调整）
    [self.tagsContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
       
        make.height.equalTo(@(self.tagsContainerView.refreshHeight));
        
    }];
    
    [self.descLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15);
        make.right.equalTo(self.contentView).offset(-15);
        make.top.equalTo(self.tagsContainerView.mas_bottom).offset(10);
    }];
    
    //更新统计信息
    [self configureStatsButtonsWithAppInfo:self.toolModel];
    
    [self.statsContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(25));
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).offset(-15); // 底部与contentView底部间距15
    }];
    
    // 更新按钮状态
    [self configuseButtonWithStatus:self.toolModel.tool_status];
    
    // 更新约束
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    // 使用异步布局更新，避免在主线程中阻塞
    [UIView setAnimationsEnabled:NO];
    [self layoutIfNeeded];
    [UIView setAnimationsEnabled:YES];
}

// 配置统计按钮
- (void)configureStatsButtonsWithAppInfo:(WebToolModel *)model {
    // 下载量
    
    // 创建统计按钮
    NSArray *statsTitles = @[
        model.view_count > 0 ? [self formatCount:model.view_count] : @"使用",
        model.collect_count > 0 ? [self formatCount:model.collect_count] : @"收藏",
        model.like_count > 0 ? [self formatCount:model.like_count] : @"点赞",
        model.dislike_count > 0 ? [self formatCount:model.dislike_count] : @"踩",
        model.comment_count > 0 ? [self formatCount:model.comment_count] : @"评论",
        model.share_count > 0 ? [self formatCount:model.share_count] : @"分享"
    ];
    
    NSArray *imageNames = @[
        @"wand.and.stars.inverse",
        model.isCollect ? @"star.fill" : @"star",
        model.isLike ? @"heart.fill" : @"heart",
        model.isDislike ? @"hand.thumbsdown.fill" : @"hand.thumbsdown",
        @"bubble.right",
        @"square.and.arrow.up"
    ];
    
    [self.statsContainerView updateButtonsWithStrings:statsTitles icons:imageNames];
}

// 更新使用按钮状态
- (void)configuseButtonWithStatus:(NSInteger)status{
    switch (status) {
        case 0:
            [self.useButton setTitle:@"使用" forState:UIControlStateNormal];
            self.useButton.backgroundColor = [UIColor systemBlueColor];
            
            break;
        case 1:
            [self.useButton setTitle:@"已失效" forState:UIControlStateNormal];
            self.useButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
            break;
        case 2:
            [self.useButton setTitle:@"更新中" forState:UIControlStateNormal];
            self.useButton.backgroundColor = [[UIColor systemPinkColor] colorWithAlphaComponent:0.5];
            break;
        case 3:
            [self.useButton setTitle:@"锁定" forState:UIControlStateNormal];
            self.useButton.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.5];
            break;
        case 4:
            [self.useButton setTitle:@"上传中" forState:UIControlStateNormal];
            self.useButton.backgroundColor = [UIColor purpleColor];
            break;
        case 5:
            [self.useButton setTitle:@"已隐藏" forState:UIControlStateNormal];
            self.useButton.backgroundColor = [UIColor grayColor];
            break;
            
        default:
            [self.useButton setTitle:@"使用" forState:UIControlStateNormal];
            self.useButton.backgroundColor = [UIColor systemBlueColor];
            break;
    }
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

#pragma mark - 布局更新

// 确保内容变化时刷新布局（自动高度关键）
- (void)layoutSubviews {
    [super layoutSubviews];
    
}

#pragma mark - 底部按钮点击

- (void)buttonTappedWithTag:(NSInteger)tag title:(nonnull NSString *)title button:(nonnull UIButton *)button {
    NSString *action;
    switch (tag) {
        case 0:
            action = @"";
            return;
        case 1:
            action = @"collect";
            break;
        case 2:
            action = @"toggleToolLike";
            break;
        case 3:
            action = @"toggleToolDisLike";
            break;
        case 4:
            action = @"addComment";
            [self addComment:action button:button];
            return;
        case 5:
            action = @"shareTool";
            [self handleShareAction];
            return;
        
        default:
            break;
    }
    [self buttonActionWith:action button:button];
}

#pragma mark - action
- (void)addComment:(NSString *)action button:(UIButton *)button{
    NSString *addComment = action;
    UIButton *commentButton = button;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"评论" message:@"请输入评论内容" preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"输入内容";
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
        if(textField.text.length == 0 ){
            [SVProgressHUD showInfoWithStatus:@"您输入为空"];
            [SVProgressHUD dismissWithDelay:1];
            return;
        }
        self.commentContent = textField.text;
        [self buttonActionWith:addComment button:commentButton];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [[self getTopViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)openHtml:(UIButton*)button {
    // 直接初始化，内部会自动判断单例中是否存在
    WebViewController *webVC = [[WebViewController alloc] initWithToolModel:self.toolModel];
    // 显示控制器（无论新创建还是复用已有实例，直接 present 即可）
//    [[self getTopViewController] presentViewController:webVC animated:YES completion:nil];
    [[self getTopViewController] presentPanModal:webVC];
}

- (void)buttonActionWith:(NSString *)action button:(UIButton *)button{
    NSString *udid = [loadData sharedInstance].userModel.udid;
    if(!udid || udid.length<5){
        [SVProgressHUD showErrorWithStatus:@"请先获取UDID绑定设备登录"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    NSDictionary *dic = @{
        @"action" : action,
        @"udid" : udid,
        @"action_type" : @(Like_type_ToolCommentLike),
        @"tool_id" : @(self.toolModel.tool_id),
        @"content":self.commentContent?:@""
    };
    NSString *url = [NSString stringWithFormat:@"%@/tool_api.php",localURL];
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"点赞返回:%@",stringResult);
            if(!jsonResult){
                [SVProgressHUD showErrorWithStatus:stringResult];
                [SVProgressHUD dismissWithDelay:3];
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"];
            if(code ==200){
                NSDictionary *data = jsonResult[@"data"];
                BOOL status = [data[@"status"] boolValue];
                NSInteger tag = button.tag;
                NSLog(@"查看点赞回复:%d",status);
                UIImage *iconImage = [UIImage new];
                switch (tag) {
                    case 1:
                        //收藏
                        iconImage = status ? [UIImage systemImageNamed:@"star.fill"] : [UIImage systemImageNamed:@"star"];
                        self.toolModel.collect_count = status ? self.toolModel.collect_count+1 : self.toolModel.collect_count -1;
                        self.toolModel.isCollect = status;
                        break;
                    case 2:
                        //点赞
                        iconImage = status ? [UIImage systemImageNamed:@"heart.fill"] : [UIImage systemImageNamed:@"heart"];
                        self.toolModel.like_count = status ? self.toolModel.like_count+1 : self.toolModel.like_count -1;
                        self.toolModel.isLike = status;
                        break;
                    case 3:
                        //踩一踩
                        iconImage = status ? [UIImage systemImageNamed:@"hand.thumbsdown.fill"] : [UIImage systemImageNamed:@"hand.thumbsdown"];
                        self.toolModel.dislike_count = status ? self.toolModel.dislike_count+1 : self.toolModel.dislike_count -1;
                        self.toolModel.isDislike = status;
                        break;
                        
                    default:
                        break;
                }
                
                [button setImage:iconImage forState:UIControlStateNormal];
                [SVProgressHUD showImage:iconImage status:msg];
                [SVProgressHUD dismissWithDelay:1];
                //重新调用赋值
                [self configureStatsButtonsWithAppInfo:self.toolModel];
                
                
            }else{
                [SVProgressHUD showErrorWithStatus:msg];
                [SVProgressHUD dismissWithDelay:2];
            }
            
        });
        
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",error]];
        [SVProgressHUD dismissWithDelay:2];
    }];
}


- (void)handleShareAction {
    // 处理评论操作
    NSLog(@"处理分享操作");
    
    // 确保应用信息有效
    if (!self.toolModel || !self.toolModel.tool_name) {
        [SVProgressHUD showInfoWithStatus:@"暂无工具信息可分享"];
        return;
    }
    
    // 显示加载提示
    [SVProgressHUD showWithStatus:@"准备分享..."];
    
    // 1. 准备分享内容
    NSMutableArray *shareItems = [NSMutableArray array];
    
    
    
    // 添加应用URL
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/index.html?shareUser_id=%ld", localURL,self.toolModel.tool_path ,[loadData sharedInstance].userModel.user_id];
    NSLog(@"分享的工具URL：%@",urlString);
    NSURL *appURL = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSLog(@"分享的工具appURL：%@",appURL);
    if (appURL) {
        [shareItems addObject:appURL];
    }
    
    // 添加应用名称和描述
    NSString *shareText = [NSString stringWithFormat:@"%@\n%@",
                           self.toolModel.tool_name,
                           self.toolModel.tool_description ?: @"快来一起看看吧！"];
    [shareItems addObject:shareText];
    
    NSString *iconURL = [NSString stringWithFormat:@"%@/%@/icon.png", localURL,self.toolModel.tool_path];
    NSLog(@"分享的工具图标URL：%@",iconURL);
    [[UIImageView new] sd_setHighlightedImageWithURL:[NSURL URLWithString:iconURL] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if(image){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentShareControllerWithItems:shareItems appIcon:image];
            });
        }else{
            [self presentShareControllerWithItems:shareItems appIcon:[UIImage systemImageNamed:@"wand.and.stars.inverse"]];
        }
    }];
}

- (void)presentShareControllerWithItems:(NSMutableArray *)shareItems appIcon:(UIImage *)appIcon {
    [SVProgressHUD dismiss]; // 隐藏加载提示
    
    // 添加应用图标（如果有）
    if (appIcon) {
        [shareItems addObject:appIcon];
    }
    
    NSLog(@"分享的工具shareItems：%@",shareItems);
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
            [SVProgressHUD dismissWithDelay:1];
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

@end
