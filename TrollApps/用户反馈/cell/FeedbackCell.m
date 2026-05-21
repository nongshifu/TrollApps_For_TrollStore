//
//  FeedbackCell.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/14.
//

#import "FeedbackCell.h"

@interface FeedbackCell ()<UITextViewDelegate>

// UI组件
@property (nonatomic, strong) UILabel *userInfoLabel;       // 用户信息（ID+设备）
@property (nonatomic, strong) UIButton *typeLabel;           // 反馈类型标签
@property (nonatomic, strong) UILabel *contentLabel;        // 反馈内容
@property (nonatomic, strong) UILabel *timeLabel;           // 反馈时间
@property (nonatomic, strong) UIButton *statusLabel;         // 状态标签
@property (nonatomic, strong) UIView *separatorLine;        // 分隔线
@property (nonatomic, strong) UILabel *adminReplyLabel;     // 管理员回复标题
@property (nonatomic, strong) UILabel *replyContentLabel;   // 已回复内容

// 状态选择器
@property (nonatomic, strong) UIView *statusSelectorView;
@property (nonatomic, strong) NSArray<UIButton *> *statusButtons;

@property (nonatomic, strong) UserFeedbackModel *feedback;
@end

@implementation FeedbackCell

#pragma mark - 布局方法（空实现，强制子类重写）

- (void)setupUI {
    
    self.backgroundColor = UIColor.clearColor;
    
    self.contentView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = YES;
    // 用户信息
    _userInfoLabel = [UILabel new];
    _userInfoLabel.font = [UIFont boldSystemFontOfSize:14];
    _userInfoLabel.textColor = UIColor.secondaryLabelColor;
    [self.contentView addSubview:_userInfoLabel];
    
    // 反馈类型标签
    _typeLabel = [UIButton new];
    _typeLabel.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [_typeLabel setTitleColor: UIColor.whiteColor forState:UIControlStateNormal];
    _typeLabel.backgroundColor = UIColor.systemBlueColor;
    _typeLabel.layer.cornerRadius = 4;
    _typeLabel.layer.masksToBounds = YES;
    _typeLabel.contentEdgeInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    [self.contentView addSubview:_typeLabel];
    
    // 反馈内容
    _contentLabel = [UILabel new];
    _contentLabel.font = [UIFont systemFontOfSize:13];
    _contentLabel.textColor = UIColor.labelColor;
    _contentLabel.numberOfLines = 0;
    [self.contentView addSubview:_contentLabel];
    
    // 反馈时间
    _timeLabel = [UILabel new];
    _timeLabel.font = [UIFont systemFontOfSize:13];
    _timeLabel.textColor = UIColor.secondaryLabelColor;
    [self.contentView addSubview:_timeLabel];
    
    // 状态标签
    _statusLabel = [UIButton new];
    _statusLabel.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [_statusLabel setTitleColor: UIColor.whiteColor forState:UIControlStateNormal];
    _statusLabel.backgroundColor = UIColor.systemGrayColor;
    _statusLabel.layer.cornerRadius = 4;
    _statusLabel.layer.masksToBounds = YES;
    _statusLabel.contentEdgeInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    [self.contentView addSubview:_statusLabel];
    
    // 分隔线
    _separatorLine = [UIView new];
    _separatorLine.backgroundColor = UIColor.separatorColor;
    [self.contentView addSubview:_separatorLine];
    
    // 管理员回复标题
    _adminReplyLabel = [UILabel new];
    _adminReplyLabel.font = [UIFont systemFontOfSize:14];
    _adminReplyLabel.textColor = UIColor.labelColor;
    _adminReplyLabel.text = @"管理员回复:";
    [self.contentView addSubview:_adminReplyLabel];
    
    
    // 已回复内容
    _replyContentLabel = [UILabel new];
    _replyContentLabel.font = [UIFont systemFontOfSize:15];
    _replyContentLabel.textColor = UIColor.secondaryLabelColor;
    _replyContentLabel.numberOfLines = 0;
    [self.contentView addSubview:_replyContentLabel];
}

- (void)setupConstraints {
   
    CGFloat padding = 8;
    // 父视图
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(kWidth-30));
    }];
    // 用户ID UDID
    [_userInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(padding);
        make.left.equalTo(self.contentView).offset(padding);
    }];
    // 反馈时间
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_userInfoLabel.mas_bottom).offset(padding/2);
        make.left.equalTo(self.contentView).offset(padding);
    }];
    // 类型
    [_typeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_userInfoLabel);
        make.right.equalTo(self.contentView).offset(-padding);
        make.height.equalTo(@20);
        make.width.greaterThanOrEqualTo(@40);
    }];
    // 反馈内容
    [_contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_timeLabel.mas_bottom).offset(padding/2);
        make.left.equalTo(self.contentView).offset(padding);
        make.right.equalTo(self.contentView).offset(-padding);
    }];
    
    // 状态
    [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentLabel.mas_bottom).offset(padding/2);
        make.right.equalTo(self.contentView).offset(-padding);
        make.height.equalTo(@20);
        make.width.greaterThanOrEqualTo(@40);
        
    }];
    // 分割线
    [_separatorLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_statusLabel.mas_bottom).offset(padding);
        make.left.equalTo(self.contentView);
        make.height.equalTo(@0);
        make.width.equalTo(@(200));
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-padding/2);
    }];

}

#pragma mark - 数据绑定

- (void)configureWithModel:(id)model {
    self.feedback = (UserFeedbackModel*)model;
    
    [self configureWithFeedback:self.feedback];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.feedback = nil;
   
    [self.statusSelectorView removeFromSuperview];
    self.statusSelectorView = nil;
}


#pragma mark - Configuration

- (void)configureWithFeedback:(UserFeedbackModel *)feedback {
    _feedback = feedback;
    
    // 设置用户信息
    _userInfoLabel.text = [NSString stringWithFormat:@"ID: %@ | 设备: %@", feedback.user_id, feedback.udid];
    
    // 设置类型标签
    _typeLabel.backgroundColor = [self colorForFeedbackType:feedback.feedback_type];
    [_typeLabel setTitle:feedback.feedback_type_text forState:UIControlStateNormal];
    
    // 设置内容
    _contentLabel.text = feedback.feedback_content;
    
    // 设置时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    _timeLabel.text = [formatter stringFromDate:feedback.feedback_time];
    
    // 设置状态
    _statusLabel.backgroundColor = [self colorForStatus:feedback.progress_status];
    [_statusLabel setTitle:feedback.progress_status_text forState:UIControlStateNormal];
    
    // 设置管理员回复
    if (feedback.admin_beizhu.length > 0) {
        _replyContentLabel.text = feedback.admin_beizhu;
        _replyContentLabel.hidden = NO;
        _adminReplyLabel.hidden = NO;
        CGFloat padding = 8;
        // 分割线
        [_separatorLine mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_statusLabel.mas_bottom).offset(padding);
            make.left.equalTo(self.contentView);
            make.height.equalTo(@0.5);
            make.width.equalTo(@(200));
            
        }];
        // 管理员提示
        [_adminReplyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_separatorLine.mas_bottom).offset(padding);
            make.left.equalTo(self.contentView).offset(padding);
            make.width.equalTo(@(kWidth - 30));
        }];
        // 管理员回复
        [_replyContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_adminReplyLabel.mas_bottom).offset(padding);
            make.left.equalTo(self.contentView).offset(padding);
    
            make.width.equalTo(@(kWidth - 30));
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-padding);
        }];
    
        
    } else {
        _replyContentLabel.hidden = YES;
        _adminReplyLabel.hidden = YES;
        
    }
}

#pragma mark - Status Selector

- (void)showStatusSelector:(UITapGestureRecognizer *)gesture {
    if (!self.feedback) return;
    
    // 创建状态选择器视图
    if (!_statusSelectorView) {
        _statusSelectorView = [[UIView alloc] initWithFrame:self.bounds];
        _statusSelectorView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
        
        UIView *selectorContent = [[UIView alloc] init];
        selectorContent.backgroundColor = UIColor.systemBackgroundColor;
        selectorContent.layer.cornerRadius = 12;
        selectorContent.layer.masksToBounds = YES;
        [_statusSelectorView addSubview:selectorContent];
        
        [selectorContent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_statusSelectorView);
            make.left.greaterThanOrEqualTo(_statusSelectorView).offset(40);
            make.right.lessThanOrEqualTo(_statusSelectorView).offset(-40);
            make.height.lessThanOrEqualTo(@200);
        }];
        
        // 创建状态按钮
        NSArray *statusTitles = @[@"未处理", @"处理中", @"已解决", @"已关闭"];
        NSMutableArray <UIButton *>*buttons = [NSMutableArray array];
        
        for (NSInteger i = 0; i < statusTitles.count; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:statusTitles[i] forState:UIControlStateNormal];
            [button setTitleColor:UIColor.labelColor forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:16];
            button.tag = i;
            [button addTarget:self action:@selector(statusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [selectorContent addSubview:button];
            [buttons addObject:button];
            
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.equalTo(selectorContent);
                make.height.equalTo(@50);
                if (i == 0) {
                    make.top.equalTo(selectorContent);
                } else {
                    make.top.equalTo(buttons[i-1].mas_bottom);
                }
            }];
            
            // 添加分隔线
            if (i < statusTitles.count - 1) {
                UIView *separator = [[UIView alloc] init];
                separator.backgroundColor = UIColor.separatorColor;
                [selectorContent addSubview:separator];
                
                [separator mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.equalTo(selectorContent);
                    make.top.equalTo(button.mas_bottom);
                    make.height.equalTo(@0.5);
                }];
            }
            
        }
        
        // 取消按钮
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [cancelButton setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal];
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [cancelButton addTarget:self action:@selector(dismissStatusSelector) forControlEvents:UIControlEventTouchUpInside];
        [selectorContent addSubview:cancelButton];
        
        [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(selectorContent);
            make.top.equalTo(buttons.lastObject.mas_bottom);
            make.height.equalTo(@50);
        }];
        
        // 添加到视图
        [self addSubview:_statusSelectorView];
        
        // 动画显示
        selectorContent.transform = CGAffineTransformMakeScale(0.8, 0.8);
        selectorContent.alpha = 0;
        
        [UIView animateWithDuration:0.3 animations:^{
            selectorContent.transform = CGAffineTransformIdentity;
            selectorContent.alpha = 1;
        }];
    }
}

- (void)statusButtonTapped:(UIButton *)button {
    NSInteger newStatus = button.tag;
    if (self.feedbackDelegate && [self.feedbackDelegate respondsToSelector:@selector(feedbackCell:didUpdateStatus:forFeedback:)]) {
        [self.feedbackDelegate feedbackCell:self didUpdateStatus:newStatus forFeedback:self.feedback];
    }
    [self dismissStatusSelector];
}

- (void)dismissStatusSelector {
    [UIView animateWithDuration:0.3 animations:^{
        self.statusSelectorView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.statusSelectorView removeFromSuperview];
        self.statusSelectorView = nil;
    }];
}

#pragma mark - Reply Submission

- (void)submitReply:(UIButton *)sender {
//    NSString *reply = self.replyTextView.text;
//    if (reply.length == 0) {
//        // 显示提示
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"回复内容不能为空" preferredStyle:UIAlertControllerStyleAlert];
//        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
//        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
//        return;
//    }
//
//    if (self.feedbackDelegate && [self.delegate respondsToSelector:@selector(feedbackCell:didSubmitReply:forFeedback:)]) {
//        [self.feedbackDelegate feedbackCell:self didSubmitReply:reply forFeedback:self.feedback];
//    }
}

#pragma mark - Helper Methods

- (UIColor *)colorForStatus:(NSInteger)status {
    switch (status) {
        case 0: return UIColor.systemGrayColor;     // 未处理
        case 1: return UIColor.systemYellowColor;   // 处理中
        case 2: return UIColor.systemGreenColor;    // 已解决
        case 3: return UIColor.systemIndigoColor;   // 已关闭
        default: return UIColor.systemGrayColor;
    }
}

- (UIColor *)colorForFeedbackType:(NSInteger)type {
    switch (type) {
        case 1: return UIColor.systemBlueColor;     // 功能建议
        case 2: return UIColor.systemRedColor;      // 程序Bug
        case 3: return UIColor.systemOrangeColor;   // 界面优化
        case 4: return UIColor.systemPurpleColor;   // 内容错误
        case 5: return UIColor.systemTealColor;     // 账号问题
        case 6: return UIColor.systemGrayColor;     // 其他
        default: return UIColor.systemGrayColor;
    }
}


@end
