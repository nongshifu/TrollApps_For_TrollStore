//
//  UserModelCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//

#import "UserModelCell.h"
#import "UserModel.h"
#import "config.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "NewProfileViewController.h"
#import "ToolMessage.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED NO // .M当前文件单独启用

@interface UserModelCell ()
@property (nonatomic, strong) UserModel *userModel;

// 卡片容器
@property (nonatomic, strong) UIView *cardView;

// 头像
@property (nonatomic, strong) UIImageView *avatarImageView;
// 新增：VIP图标
@property (nonatomic, strong) UIImageView *vipIconView;
// 新增：在线状态容器 (包含绿点和时间)
@property (nonatomic, strong) UILabel *lastSeenLabel;

// 主信息容器
@property (nonatomic, strong) UIView *infoContainer;

// 昵称+VIP标识
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UILabel *vipTagLabel;

// 个人简介
@property (nonatomic, strong) UILabel *bioLabel;

// 辅助信息（下载量+注册时间）
@property (nonatomic, strong) UILabel *statsLabel;

// 分隔线
@property (nonatomic, strong) UIView *separatorView;

// 新增：关注按钮
@property (nonatomic, strong) UIButton *followButton;

@end

@implementation UserModelCell
// 辅助方法：从颜色创建一个1x1的图片
static UIImage *imageWithColor(UIColor *color) {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setupUI {
    
    self.contentView.backgroundColor = [UIColor clearColor];
    

    // 卡片容器
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.7];
    self.cardView.layer.cornerRadius = 12;
    self.cardView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.cardView.layer.shadowOpacity = 0.05;
    self.cardView.layer.shadowRadius = 4;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    [self.contentView addSubview:self.cardView];

    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 30;
    self.avatarImageView.layer.borderWidth = 3;
    self.avatarImageView.layer.borderColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5].CGColor;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.backgroundColor = UIColor.systemGray2Color;
    [self.cardView addSubview:self.avatarImageView];

    // --- 新增：VIP图标 ---
    self.vipIconView = [[UIImageView alloc] init];
    self.vipIconView.image = [UIImage systemImageNamed:@"crown.fill"]; // 使用系统皇冠图标
    self.vipIconView.tintColor = [UIColor systemYellowColor];
    self.vipIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.vipIconView.hidden = YES; // 默认隐藏
    [self.avatarImageView addSubview:self.vipIconView]; // 添加到头像上

    // 最近登录时间
    self.lastSeenLabel = [[UILabel alloc] init];
    self.lastSeenLabel.font = [UIFont systemFontOfSize:8];
    self.lastSeenLabel.textColor = [UIColor whiteColor];
    self.lastSeenLabel.textAlignment = NSTextAlignmentCenter;
    self.lastSeenLabel.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    
    [self.cardView addSubview:self.lastSeenLabel];

    // --- 新增：关注按钮 ---
    self.followButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.followButton setTitle:@"关注" forState:UIControlStateNormal];
    [self.followButton setTitle:@"已关注" forState:UIControlStateSelected];
    self.followButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.followButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.followButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    
    // 关键修改：为不同状态设置背景图片
    [self.followButton setBackgroundImage:imageWithColor(UIColor.systemBlueColor) forState:UIControlStateNormal];
    [self.followButton setBackgroundImage:imageWithColor(UIColor.systemPinkColor) forState:UIControlStateSelected];
    // 为高亮状态设置一个稍暗的颜色，提供更好的交互反馈
    [self.followButton setBackgroundImage:imageWithColor([UIColor.systemBlueColor colorWithAlphaComponent:0.8]) forState:UIControlStateHighlighted];
    [self.followButton setBackgroundImage:imageWithColor([UIColor.systemPinkColor colorWithAlphaComponent:0.8]) forState:UIControlStateSelected | UIControlStateHighlighted];
    
    self.followButton.layer.cornerRadius = 15;
    self.followButton.layer.masksToBounds = YES; // 确保圆角生效
    self.followButton.userInteractionEnabled = YES;
    [self.followButton addTarget:self action:@selector(followButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.followButton];

    // 信息容器
    self.infoContainer = [[UIView alloc] init];
    [self.cardView addSubview:self.infoContainer];

    // 昵称
    self.nicknameLabel = [[UILabel alloc] init];
    self.nicknameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.nicknameLabel.textColor = UIColor.labelColor;
    [self.infoContainer addSubview:self.nicknameLabel];

    // VIP标识 (这个是原来的大标签，可以保留或根据需求调整)
    self.vipTagLabel = [[UILabel alloc] init];
    self.vipTagLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.vipTagLabel.textColor = UIColor.yellowColor;
    self.vipTagLabel.backgroundColor = UIColor.systemOrangeColor;
    self.vipTagLabel.layer.cornerRadius = 10;
    self.vipTagLabel.layer.masksToBounds = YES;
    self.vipTagLabel.textAlignment = NSTextAlignmentCenter;
    [self.infoContainer addSubview:self.vipTagLabel];

    // 个人简介
    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.font = [UIFont systemFontOfSize:13];
    self.bioLabel.textColor = UIColor.secondaryLabelColor;
    self.bioLabel.numberOfLines = 2;
    [self.infoContainer addSubview:self.bioLabel];

    // 统计信息
    self.statsLabel = [[UILabel alloc] init];
    self.statsLabel.font = [UIFont systemFontOfSize:12];
    self.statsLabel.textColor = UIColor.tertiaryLabelColor;
    [self.infoContainer addSubview:self.statsLabel];

    // 分隔线
    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = UIColor.systemGray3Color;
    self.separatorView.alpha = 0.2;
    [self.cardView addSubview:self.separatorView];
    
    
    [self.followButton.superview bringSubviewToFront:self.followButton];
}



- (void)setupConstraints {
    // 卡片容器
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(kWidth-20));
        
    }];
    // 卡片容器
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(self.contentView);
       
    }];
    
    // 头像
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(16);
        make.left.equalTo(self.cardView).offset(16);
        make.width.height.equalTo(@60);
        make.bottom.lessThanOrEqualTo(self.cardView).offset(-16); // 避免内容过短时头像底部溢出
    }];
    // --- 新增：VIP图标约束 ---
    [self.vipIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.avatarImageView).offset(2);
        make.width.height.equalTo(@16);
    }];

    
    [self.lastSeenLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.avatarImageView.mas_bottom).offset(-4);
        make.centerX.equalTo(self.avatarImageView);
    }];

    // --- 新增：关注按钮约束 ---
    [self.followButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.cardView).offset(-16);
        make.width.greaterThanOrEqualTo(@60); // 宽度自适应文字
        make.height.equalTo(@30);
    }];
    
    // 信息容器
    [self.infoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView);
        make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        make.right.equalTo(self.cardView).offset(-16);
        make.bottom.equalTo(self.avatarImageView);
    }];
    
    // 昵称和VIP标签（水平排列）
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.infoContainer);
        make.left.equalTo(self.infoContainer);
    }];
    
    // VIP标签
    [self.vipTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.nicknameLabel);
        make.left.equalTo(self.nicknameLabel.mas_right).offset(6);
        make.height.equalTo(@20);
        make.width.greaterThanOrEqualTo(@36);
        make.right.lessThanOrEqualTo(self.infoContainer);
    }];

    
    // 个人简介（昵称下方）
    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(6);
        make.left.right.equalTo(self.infoContainer);
    }];
    
    // 统计信息（简介下方）
    [self.statsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioLabel.mas_bottom).offset(8);
        make.left.equalTo(self.infoContainer);
        make.right.lessThanOrEqualTo(self.infoContainer);
    }];
    
    // 分隔线（可选，用于区分不同类型的卡片）
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.cardView);
        make.height.equalTo(@0.5);
        make.bottom.equalTo(self.cardView);
    }];
}


#pragma mark - 事件处理

- (void)followButtonTapped:(UIButton *)sender {
    
    // 如果接口失败，需要将按钮状态还原：self.followButtom.selected = !isFollow;
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    // 构建请求参数（根据实际接口调整）
    NSDictionary *params = @{
        @"action": @"followAction",
        @"udid": udid,
        @"target_udid": self.userModel.udid,
        @"isFollow": @(!sender.selected),
        
    };
    
    [SVProgressHUD showWithStatus:sender.selected?@"取关中":@"关注中"];
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                              urlString:[NSString stringWithFormat:@"%@/user/user_api.php",localURL]
                                             parameters:params
                                                   udid:udid
                                               progress:^(NSProgress *progress) {
        
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"关注用户返回jsonResult:%@",jsonResult);
        NSLog(@"关注用户返回stringResult:%@",stringResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult || !jsonResult[@"code"]){
                return;
            }
            NSInteger code = [jsonResult[@"code"] intValue];
            NSString * msg = jsonResult[@"msg"];
            
            if (code == 200) {
                NSDictionary *data = jsonResult[@"data"];
                BOOL isFollow = [data[@"isFollow"] boolValue];
                self.userModel.isFollow = isFollow;
                self.model = self.userModel;
                self.followButton.selected = isFollow;
                [self.followButton setBackgroundColor:isFollow?UIColor.systemPinkColor:UIColor.systemBlueColor];
                if(isFollow){
                    RCTextMessage *messageContent = [RCTextMessage messageWithContent:@"我关注你了"];
                    RCConversationType conversationType = ConversationType_PRIVATE;
                    
                    RCMessage *message = [[RCMessage alloc]
                                          initWithType:conversationType
                                          targetId:self.userModel.udid
                                          direction:MessageDirection_SEND
                                          content:messageContent];
                    
                    
                    [[RCIM sharedRCIM] sendMessage:message
                                       pushContent:messageContent.content
                                          pushData:messageContent.content
                                      successBlock:^(RCMessage * _Nonnull successMessage) {
                        
                    } errorBlock:^(RCErrorCode nErrorCode, RCMessage * _Nonnull errorMessage) {
                        
                    }];
                     
                }
                
                
                
            }
            [SVProgressHUD showSuccessWithStatus:msg];
            [SVProgressHUD dismissWithDelay:1];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"网络错误，发送失败"];
        [SVProgressHUD dismissWithDelay:2];
    }];
}

#pragma mark - 数据绑定

- (void)configureWithModel:(id)model {
    self.userModel = (UserModel *)model;
    [self configureWithUserModel:self.userModel];
}

- (void)configureWithUserModel:(UserModel *)model {
    if (!model) return;
    self.userModel = model;
    NSLog(@"头像地址:%@",model.avatar);

    // 头像设置
    if (model.avatarImage) {
        self.avatarImageView.image = model.avatarImage;
    }
    if (model.avatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:model.avatar]
                              placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    }

    // 昵称
    self.nicknameLabel.text = model.nickname ?: @"未知用户";

    // VIP标签 (原来的大标签)
    BOOL isVipExpired = [UserModel isVIPExpiredWithDate:model.vip_expire_date];
    if (model.vip_level > 0 && !isVipExpired) {
        self.vipTagLabel.text = [NSString stringWithFormat:@"VIP %ld", (long)model.vip_level];
        self.vipTagLabel.hidden = NO;
    } else {
        self.vipTagLabel.hidden = YES;
    }
    
    // --- 新增：头像左上角VIP小图标 ---
    self.vipIconView.hidden = !(model.vip_level > 0 && !isVipExpired);

    // 个人简介
    self.bioLabel.text = model.bio.length>0 ? model.bio : @"该用户未填写简介";

    // 统计信息
    NSString *app_count = [NSString stringWithFormat:@"App: %ld 粉丝: %ld", (long)model.app_count, model.follower_count];
    NSString *registerDate = [TimeTool getTimeformatDateForDay:model.register_time];
    self.statsLabel.text = [NSString stringWithFormat:@"%@ · 注册于 %@", app_count, registerDate];

    // --- 新增：关注按钮状态 ---
    self.followButton.selected = model.isFollow;
   
    [self.followButton setBackgroundColor:model.isFollow?UIColor.systemPinkColor:UIColor.systemBlueColor];
    

    // --- 新增：在线状态和最近登录时间 ---
    if (model.is_online) {
       
        self.lastSeenLabel.text = @"在线";
        self.lastSeenLabel.textColor = [UIColor greenColor];
        self.avatarImageView.layer.borderColor = [UIColor greenColor].CGColor;
    } else {
       
        self.avatarImageView.layer.borderColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5].CGColor;
        // 格式化最近登录时间
        if (model.login_time > 0) {
            // 假设 TimeTool 有一个格式化更短时间的方法，例如 "HH:mm"
            self.lastSeenLabel.text = [TimeTool getTimeAgoStringFromPostDate:model.login_time];
        } else {
            self.lastSeenLabel.text = @"离线";
            self.lastSeenLabel.textColor = [UIColor labelColor];
            
        }
    }
    
    
    
    // 强制更新布局
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
