#import "vip_purchase_historyCell.h"
#import "VipPurchaseHistoryModel.h"
#import <Masonry/Masonry.h>

@interface vip_purchase_historyCell ()

// 主容器视图（用于统一管理内边距）
@property (nonatomic, strong) UIView *contentContainer;

// 订单信息视图
@property (nonatomic, strong) UILabel *packageTitleLabel;  // 套餐名称
@property (nonatomic, strong) UILabel *priceLabel;         // 价格
@property (nonatomic, strong) UILabel *timeLabel;          // 购买时间
@property (nonatomic, strong) UILabel *vipLevelLabel;      // VIP等级
@property (nonatomic, strong) UILabel *nicknameLabel;      // 用户昵称 ✅ 新增
@property (nonatomic, strong) UILabel *udidLabel;          // UDID ✅ 新增
@property (nonatomic, strong) UILabel *downloadsLabel;     // 下载次数
@property (nonatomic, strong) UILabel *statusLabel;        // 订单状态

// 分割线
@property (nonatomic, strong) UIView *separatorLine;

@end

@implementation vip_purchase_historyCell

#pragma mark - 子类必须重写的方法

/**
 配置UI元素
 */
- (void)setupUI {
    // 主容器（添加内边距，避免内容贴边）
    _contentContainer = [[UIView alloc] init];
    _contentContainer.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    _contentContainer.layer.cornerRadius = 10;
    [self.contentView addSubview:_contentContainer];
    
    // 套餐名称（主标题）
    _packageTitleLabel = [[UILabel alloc] init];
    _packageTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    _packageTitleLabel.textColor = [UIColor secondaryLabelColor];
    _packageTitleLabel.numberOfLines = 1;
    [_contentContainer addSubview:_packageTitleLabel];
    
    // 价格（突出显示）
    _priceLabel = [[UILabel alloc] init];
    _priceLabel.font = [UIFont boldSystemFontOfSize:16];
    _priceLabel.textColor = [UIColor colorWithRed:230/255.0 green:46/255.0 blue:46/255.0 alpha:1]; // 红色
    _priceLabel.textAlignment = NSTextAlignmentRight;
    [_contentContainer addSubview:_priceLabel];
    
    // 购买时间
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:13];
    _timeLabel.textColor = [UIColor grayColor];
    [_contentContainer addSubview:_timeLabel];
    
    // VIP等级
    _vipLevelLabel = [[UILabel alloc] init];
    _vipLevelLabel.font = [UIFont systemFontOfSize:13];
    _vipLevelLabel.textColor = [UIColor colorWithRed:255/255.0 green:153/255.0 blue:0/255.0 alpha:1]; // 橙色
    [_contentContainer addSubview:_vipLevelLabel];
    
    // ✅ 用户昵称（新增）
    _nicknameLabel = [[UILabel alloc] init];
    _nicknameLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _nicknameLabel.textColor = [UIColor tertiaryLabelColor];
    [_contentContainer addSubview:_nicknameLabel];
    
    // ✅ UDID（新增）
    _udidLabel = [[UILabel alloc] init];
    _udidLabel.font = [UIFont systemFontOfSize:12];
    _udidLabel.textColor = [UIColor tertiaryLabelColor];
    _udidLabel.textAlignment = NSTextAlignmentLeft;
    [_contentContainer addSubview:_udidLabel];
    
    // 下载次数
    _downloadsLabel = [[UILabel alloc] init];
    _downloadsLabel.font = [UIFont systemFontOfSize:13];
    _downloadsLabel.textColor = [UIColor tertiaryLabelColor];
    [_contentContainer addSubview:_downloadsLabel];
    
    // 订单状态
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _statusLabel.textAlignment = NSTextAlignmentRight;
    [_contentContainer addSubview:_statusLabel];
    
    // 分割线
    _separatorLine = [[UIView alloc] init];
    _separatorLine.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:0.2]; // 浅灰
    [_contentContainer addSubview:_separatorLine];
}

/**
 配置布局约束
 */
- (void)setupConstraints {
    // 主容器约束（左右留边15，上下留边10）
    [_contentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).inset(0);
    }];
    
    // 套餐名称和价格（第一行）
    [_packageTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_contentContainer).offset(10);
        make.right.lessThanOrEqualTo(_priceLabel.mas_left).offset(-10);
    }];
    
    [_priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_packageTitleLabel);
        make.right.equalTo(_contentContainer).offset(-10);
        make.width.lessThanOrEqualTo(@100);
    }];
    
    // 时间
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_packageTitleLabel.mas_bottom).offset(8);
        make.left.equalTo(_packageTitleLabel);
        make.right.lessThanOrEqualTo(_vipLevelLabel.mas_left).offset(-15);
    }];
    
    // 和VIP等级（第二行）
    [_vipLevelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_timeLabel);
        make.right.equalTo(_contentContainer).offset(-10);
    }];
    // udid
    [_udidLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_packageTitleLabel);
        make.top.equalTo(_timeLabel.mas_bottom).offset(10);
        make.right.equalTo(_contentContainer).offset(-10);
    }];
    
    // 下载次数和状态（第四行）
    [_downloadsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_udidLabel.mas_bottom).offset(8); // 绑定昵称底部
        make.left.equalTo(_packageTitleLabel);
        make.bottom.equalTo(_separatorLine.mas_top).offset(-8);
    }];
    
    // ✅ 昵称 + UDID（第三行 新增布局）
    [_nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_downloadsLabel);
        make.left.equalTo(_downloadsLabel.mas_right).offset(8);
        
    }];
    
    [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_downloadsLabel);
        make.right.equalTo(_contentContainer).offset(-10);
        make.bottom.equalTo(_downloadsLabel);
    }];
    
    // 分割线（底部）
    [_separatorLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_contentContainer);
        make.width.equalTo(@200);
        make.left.equalTo(_contentContainer.mas_left).offset(_contentContainer.layer.cornerRadius);
        make.height.equalTo(@0.5);
    }];
}

/**
 数据绑定方法
 */
- (void)configureWithModel:(id)model {
    if (![model isKindOfClass:[VipPurchaseHistoryModel class]]) return;
    
    VipPurchaseHistoryModel *historyModel = (VipPurchaseHistoryModel *)model;
    
    // 1. 套餐名称
    self.packageTitleLabel.text = historyModel.packageTitle;
    
    // 2. 价格
    self.priceLabel.text = [NSString stringWithFormat:@"￥ %@",historyModel.price];
    
    // 3. 购买时间
    self.timeLabel.text = [self formatTime:historyModel.purchaseTime];
    
    // 4. VIP等级
    self.vipLevelLabel.text = [NSString stringWithFormat:@"VIP等级：%ld", (long)historyModel.vipLevel];
    
    // ✅ 5. 用户昵称（空值默认显示未知用户）
    self.nicknameLabel.text = [NSString stringWithFormat:@"用户:%@",historyModel.nickname.length > 0 ? historyModel.nickname : @"未知用户"];
    
    // ✅ 6. UDID（空值默认显示无）
    self.udidLabel.text = [NSString stringWithFormat:@"UDID：%@", historyModel.udid.length > 0 ? historyModel.udid : @"无"];
    
    // 7. 下载次数
    if (historyModel.downloadsNumber == 0) {
        self.downloadsLabel.text = @"下载次数：无限次";
    } else {
        self.downloadsLabel.text = [NSString stringWithFormat:@"下载次数：%ld次", (long)historyModel.downloadsNumber];
    }
    
    // 8. 订单状态（适配你全部枚举：0成功/1失败/2退款/3关闭/4处理中）
    [self setupStatus:historyModel.status];
}

#pragma mark - 辅助方法

/**
 格式化时间字符串
 */
- (NSString *)formatTime:(NSString *)originalTime {
    if (originalTime.length == 0) return @"";
    
    NSRange range = [originalTime rangeOfString:@":" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        return [originalTime substringToIndex:range.location];
    }
    return originalTime;
}

/**
 设置订单状态文字和颜色（✅ 适配你完整的枚举状态）
 */
- (void)setupStatus:(NSInteger)status {
    switch (status) {
        case OrderStatusTypeSuccess: // 0 成功
            self.statusLabel.text = @"支付成功";
            self.statusLabel.textColor = [UIColor systemGreenColor];
            break;
        case OrderStatusTypeFailure: // 1 失败
            self.statusLabel.text = @"支付失败";
            self.statusLabel.textColor = [UIColor systemRedColor];
            break;
        case OrderStatusTypeRefund: // 2 退款
            self.statusLabel.text = @"已退款";
            self.statusLabel.textColor = [UIColor systemOrangeColor];
            break;
        case OrderStatusTypeCLOSED: // 3 关闭
            self.statusLabel.text = @"已关闭";
            self.statusLabel.textColor = [UIColor systemGrayColor];
            break;
        case OrderStatusTypePROCESSING: // 4 处理中
            self.statusLabel.text = @"处理中";
            self.statusLabel.textColor = [UIColor systemBlueColor];
            break;
        default:
            self.statusLabel.text = @"未知状态";
            self.statusLabel.textColor = [UIColor grayColor];
            break;
    }
}

@end
