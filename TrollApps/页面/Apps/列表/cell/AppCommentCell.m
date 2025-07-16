#import "AppCommentCell.h"
#import "UserModel.h" // 引入用户信息模型
#import "NewProfileViewController.h"
#import "UserProfileViewController.h"
#import "LikeModel.h"
//是否打印
#define MY_NSLog_ENABLED NO

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@interface AppCommentCell ()
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, copy) void(^likeButtonClicked)(AppComment *comment, BOOL isLiked);
@end

@implementation AppCommentCell

#pragma mark - 懒加载UI元素

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        _avatarImageView.clipsToBounds = YES;
        _avatarImageView.backgroundColor = [UIColor systemGray5Color]; // 默认灰色背景
        // 设置圆角（圆形头像）
        _avatarImageView.layer.cornerRadius = 20; // 半径为宽高的一半（宽高50）
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapped:)];
        tapGesture.cancelsTouchesInView = NO; // 确保不影响其他控件的事件
        _avatarImageView.userInteractionEnabled = YES;
        [_avatarImageView addGestureRecognizer:tapGesture];
        
        
    }
    return _avatarImageView;
}

- (UIImageView *)likeImageView {
    if (!_likeImageView) {
        _likeImageView = [[UIImageView alloc] init];
        _likeImageView.contentMode = UIViewContentModeScaleAspectFill;
        _likeImageView.clipsToBounds = YES;
        _likeImageView.backgroundColor = [UIColor clearColor]; // 默认灰色背景
        // 设置圆角（圆形头像）
        _likeImageView.image = [UIImage systemImageNamed:@"heart"];
        
        _likeImageView.layer.cornerRadius = 10; // 半径为宽高的一半（宽高50）
        
        // 开启用户交互
        _likeImageView.userInteractionEnabled = YES;
        // 添加点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(likeButtonTapped:)];
        [_likeImageView addGestureRecognizer:tap];
    }
    return _likeImageView;
}

- (UILabel *)nicknameLabel {
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc] init];
        _nicknameLabel.font = [UIFont boldSystemFontOfSize:12];
        _nicknameLabel.textColor = [UIColor randomColorWithAlpha:1]; // 跟随系统主题色
    }
    return _nicknameLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor secondaryLabelColor]; // 次要文本色
    }
    return _timeLabel;
}

- (UILabel *)likeCountLabel {
    if (!_likeCountLabel) {
        _likeCountLabel = [[UILabel alloc] init];
        _likeCountLabel.font = [UIFont systemFontOfSize:11];
        
        _likeCountLabel.textColor = [UIColor colorWithLightColor:[UIColor systemRedColor] darkColor:[UIColor labelColor]];
    }
    return _likeCountLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:13];
        _contentLabel.textColor = [UIColor colorWithLightColor:[UIColor systemBlueColor] darkColor:[UIColor systemBlueColor]];
        _contentLabel.numberOfLines = 0; // 自动换行
        _contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return _contentLabel;
}


#pragma mark - 子类必须重写的方法
/**
 配置UI元素
 */
- (void)setupUI {
    // 开启自动布局
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentView.backgroundColor = [UIColor colorWithLightColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.6]
                                                                     darkColor:[[UIColor systemBackgroundColor] colorWithAlphaComponent:0.4]];;
    self.contentView.layer.cornerRadius = 15;
    // 添加子视图
    [self.contentView addSubview:self.avatarImageView];
    [self.contentView addSubview:self.likeImageView];
    [self.contentView addSubview:self.likeCountLabel];
    [self.contentView addSubview:self.nicknameLabel];
    [self.contentView addSubview:self.timeLabel];
    [self.contentView addSubview:self.contentLabel];
    
}

/**
 配置布局约束
 */
- (void)setupConstraints {
    // 关闭 autoresizingMask 转换为约束
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.nicknameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    // 使用 Masonry 布局（也可使用系统 NSLayoutConstraint）
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15); // 左间距15
        make.top.equalTo(self.contentView).offset(12); // 上间距12
        make.width.height.equalTo(@40); // 头像大小50x50
    }];
    
    [self.likeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-15); // 左间距15
        make.top.equalTo(self.contentView).offset(12); // 上间距12
        make.width.height.equalTo(@20); // 头像大小50x50
    }];
    
    [self.likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-15); // 左间距15
        make.top.equalTo(self.likeImageView.mas_bottom).offset(8); // 上间距12
        
    }];
    
    
    
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(12); // 与头像间距12
        make.top.equalTo(self.avatarImageView); // 与头像顶部对齐
        
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameLabel); // 与昵称顶部对齐
        make.left.equalTo(self.nicknameLabel.mas_right).offset(15); // 右间距15
    }];
    
    
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nicknameLabel); // 与昵称左对齐
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(8); // 与昵称间距8

        make.right.lessThanOrEqualTo(self.likeCountLabel.mas_left).offset(-12); // 与分隔线间距12
        make.bottom.lessThanOrEqualTo(self.contentView.mas_bottom).offset(-12); // 与分隔线间距12
    }];
   
}

/**
 数据绑定方法
 */
- (void)configureWithModel:(id)model {
    self.model = model;
    self.appComment = (AppComment *)model;
    
    // 1. 绑定用户信息
    UserModel *userInfo = self.appComment.userInfo;
    if (userInfo) {
        self.nicknameLabel.text = userInfo.nickname ?: @"匿名用户"; // 默认显示匿名
        
        // 加载头像（这里用占位图示例，实际项目中可使用SDWebImage加载网络图片）
        if (userInfo.avatar.length > 0) {
            NSString *url = [NSString stringWithFormat:@"%@/%@",localURL,userInfo.avatar];
            NSLog(@"评论用户数据url:%@",url);
             [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
        } else {
            self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"]; // 系统默认头像
        }
    } else {
        self.nicknameLabel.text = @"匿名用户";
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    }
    
    // 2. 绑定评论内容
    self.contentLabel.text = self.appComment.content ?: @"";
    
    // 3. 格式化评论时间（将NSDate转换为友好显示，如"2小时前"、"今天 14:30"）
    
    self.timeLabel.text = [TimeTool getTimeDiyWithString:self.appComment.create_time];
    
    // 恢复点赞状态
    [self updateLikeStatus];
    
}

#pragma mark - 辅助方法

/**
 格式化点赞数显示
 @param count 原始点赞数
 @return 格式化后的字符串
 */
- (NSString *)formatLikeCount:(NSInteger)count {
    if (count < 1000) {
        return [NSString stringWithFormat:@"%ld", (long)count];
    } else if (count < 1000000) {
        // 显示为 X.Xk 格式（保留一位小数）
        float value = count / 1000.0;
        return [NSString stringWithFormat:@"%.1fk", value];
    } else {
        // 显示为 X.Xm 格式（保留一位小数）
        float value = count / 1000000.0;
        return [NSString stringWithFormat:@"%.1fm", value];
    }
}

#pragma mark - 点赞相关方法


/**
 检查评论是否已点赞
 @param commentId 评论ID
 @return 是否点赞
 */
- (BOOL)isCommentLiked:(NSInteger)commentId {

    // 若不想依赖YYCache，可使用NSUserDefaults
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     return [defaults boolForKey:[NSString stringWithFormat:@"like_%ld", (long)commentId]];
}

/**
 保存点赞状态到本地
 @param commentId 评论ID
 @param isLiked 是否点赞
 */
- (void)saveCommentLikeStatus:(NSInteger)commentId isLiked:(BOOL)isLiked {
  
    // NSUserDefaults版本
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     [defaults setBool:isLiked forKey:[NSString stringWithFormat:@"like_%ld", (long)commentId]];
     [defaults synchronize];
}
/**
 点赞按钮点击事件
 */
- (void)likeButtonTapped:(UITapGestureRecognizer *)tap {
    if (!self.appComment) return;
    
    // 防止重复点击
    self.likeImageView.userInteractionEnabled = NO;
    [SVProgressHUD showWithStatus: @"处理中..."];
    
    // 获取当前本地缓存的点赞状态（用于对比服务器返回结果）
    BOOL currentLocalStatus = [self isCommentLiked:self.appComment.comment_id];
    BOOL targetStatus = !currentLocalStatus; // 目标状态（点赞/取消点赞）
    
    // 发起服务器请求
    [self requestSyncLikeToServer:self.appComment.comment_id
                          isLiked:targetStatus
                   currentLocalStatus:currentLocalStatus];
}

/**
 同步点赞状态到服务器
 @param commentId 评论ID
 @param isLiked 目标点赞状态（true为点赞，false为取消）
 @param currentLocalStatus 当前本地缓存的状态（用于错误恢复）
 */
- (void)requestSyncLikeToServer:(NSInteger)commentId
                        isLiked:(BOOL)isLiked
                 currentLocalStatus:(BOOL)currentLocalStatus {
    // 验证UDID
    NSString *udid = [NewProfileViewController sharedInstance].userInfo.udid ?: @"";
    if (udid.length <= 5) {
        [SVProgressHUD showErrorWithStatus:@"请先登录并绑定设备UDID"];
        [SVProgressHUD dismissWithDelay:3];
        return;
    }
    
    // 构建请求参数
    NSString *url = [NSString stringWithFormat:@"%@/app_action.php", localURL];
    NSDictionary *params = @{
        @"action": @"toggle_comment_like",
        @"type": @(self.appComment.comment_type),
        @"to_id": @(self.appComment.comment_id),
        @"to_udid": self.appComment.user_udid
       
    };
    
    // 发送请求
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST
                                            urlString:url
                                            parameters:params
                                                udid:udid
                                              progress:^(NSProgress *progress) {
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        NSLog(@"点赞返回:%@",stringResult);
        dispatch_async(dispatch_get_main_queue(), ^{
            // 恢复交互
            self.likeImageView.userInteractionEnabled = YES;
            [SVProgressHUD dismiss];
            
            // 解析服务器返回
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code == 200) {
                // 假设SUCCESS是服务器定义的成功状态码（如200）
                // 从服务器返回数据中获取最新状态和点赞数
                BOOL serverStatus = [jsonResult[@"data"][@"newStatus"] boolValue];
                NSInteger newRating = [jsonResult[@"data"][@"like_count"] integerValue];
                
                // 1. 更新本地缓存状态
                [self saveCommentLikeStatus:commentId isLiked:serverStatus];
                
                // 2. 更新数据模型
                self.appComment.like_count = newRating;
                
                // 3. 更新UI显示
                [self updateLikeStatus];
                
                // 4. 回调通知外部
                if (self.likeButtonClicked) {
                    self.likeButtonClicked(self.appComment, serverStatus);
                }
                
                // 显示操作结果
                [SVProgressHUD showSuccessWithStatus:serverStatus ? @"点赞成功" : @"取消点赞成功"];
                [SVProgressHUD dismissWithDelay:1.5];
                
            } else {
                // 服务器返回失败（如参数错误、权限问题）
                NSString *errorMsg = jsonResult[@"msg"] ?: @"操作失败，请重试";
                [self handleLikeFailedWithError:errorMsg
                              needRestoreStatus:YES
                               originalStatus:currentLocalStatus];
            }
        });
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 网络请求失败（如无网络、超时）
            self.likeImageView.userInteractionEnabled = YES;
            [SVProgressHUD dismiss];
            
            [self handleLikeFailedWithError:@"网络异常，请检查网络后重试"
                          needRestoreStatus:YES
                           originalStatus:currentLocalStatus];
        });
    }];
}

/**
 处理点赞失败逻辑
 @param errorMsg 错误提示信息
 @param needRestoreStatus 是否需要恢复到原始状态
 @param originalStatus 原始点赞状态（用于恢复）
 */
- (void)handleLikeFailedWithError:(NSString *)errorMsg
              needRestoreStatus:(BOOL)needRestoreStatus
               originalStatus:(BOOL)originalStatus {
    // 恢复交互
    self.likeImageView.userInteractionEnabled = YES;
    
    // 显示错误提示
    [SVProgressHUD showErrorWithStatus:errorMsg];
    [SVProgressHUD dismissWithDelay:2];
    
    // 如果需要，恢复到原始状态（避免本地与服务器不一致）
    if (needRestoreStatus) {
        [self saveCommentLikeStatus:self.appComment.comment_id isLiked:originalStatus];
        [self updateLikeStatus];
    }
}

/**
 更新点赞UI状态
 */
- (void)updateLikeStatus {
    BOOL isLiked = [self isCommentLiked:self.appComment.comment_id];
    
    // 更新点赞图标
    self.likeImageView.image = isLiked ?
        [UIImage systemImageNamed:@"heart.fill"] :
        [UIImage systemImageNamed:@"heart"];
    self.likeImageView.tintColor = isLiked ? [UIColor systemRedColor] : [UIColor secondaryLabelColor];
    
    // 更新点赞数显示
    NSString *formattedCount = [self formatLikeCount:self.appComment.like_count];
    if (self.appComment.like_count == 0) {
        formattedCount = @"点赞";
    }else if (self.appComment.like_count < 50 && self.appComment.like_count > 0) {
        formattedCount = [NSString stringWithFormat:@"点赞:%@", formattedCount];
    } else {
        formattedCount = [NSString stringWithFormat:@"🔥 %@", formattedCount];
    }
    self.likeCountLabel.text = formattedCount;
}

// 头像点击
- (void)labelTapped:(UITapGestureRecognizer *)gestureRecognizer {
    UIImageView *view= (UIImageView *)gestureRecognizer.view;
    // 在这里处理标签被点击的逻辑
    NSLog(@"view tapped: %ld", view.tag);
    UserProfileViewController *vc = [UserProfileViewController new];
    vc.user_udid = self.appComment.user_udid;
    [[self getTopViewController] presentPanModal:vc];
}

@end
