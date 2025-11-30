
#import "ToolMessageCell.h"
#import "config.h"
#import "ShowOneToolViewController.h"
#import "ShowOneAppViewController.h"
#import "UserProfileViewController.h"
#import <Masonry/Masonry.h> // 确保导入Masonry（布局依赖）

// 固定配置（按需求定义）
static const CGFloat kBubbleFixedWidth = 250;    // 气泡固定宽度
static const CGFloat kInnerPadding = 10;         // 气泡内部上下左右间隔
static const CGFloat kImageSize = 60;            // 左侧图片尺寸（80*80）
static const CGFloat kNameFontSize = 13;         //名字文字大小
static const CGFloat kIntroductionFontSize = 12; //简介文字大小
static const CGFloat kVersionHeight = 20;        //按钮大小
// 先修正顶部常量：文字区域宽度（气泡总宽 - 图片宽 - 3个间隔）
static const CGFloat kRightContentWidth = kBubbleFixedWidth - kImageSize - kInnerPadding * 3;

@implementation ToolMessageCell

#pragma mark - 父类要求：计算Cell总尺寸
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    // 1. 获取气泡内容尺寸（固定宽度250，高度自适应）
    ToolMessage *message = (ToolMessage *)model.content;
    CGSize bubbleSize = [self getBubbleBackgroundViewSize:message];
    
    // 2. 确保Cell高度不小于头像高度（融云默认逻辑）
    CGFloat cellHeight = bubbleSize.height;
    CGFloat minHeight = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    if (cellHeight < minHeight) {
        cellHeight = minHeight;
    }
    
    // 3. 加上额外高度（如时间、已读标签等）
    cellHeight += extraHeight;
    
    return CGSizeMake(collectionViewWidth, cellHeight);
}

#pragma mark - 初始化（创建子视图+基础样式）
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // 1. 气泡基础配置
    [self showBubbleBackgroundView:YES];
    self.bubbleBackgroundView.alpha = 0.9;
    self.messageContentView.clipsToBounds = YES;
    self.messageContentView.layer.cornerRadius = 8;
    self.messageContentView.backgroundColor = [[UIColor tertiarySystemBackgroundColor] colorWithAlphaComponent:0.1];
    
    // 2. 创建左侧图片视图
    _avaImageView = [[UIImageView alloc] init];
    _avaImageView.layer.cornerRadius = 10; // 图片圆角（可选）
    _avaImageView.layer.masksToBounds = YES;
    _avaImageView.contentMode = UIViewContentModeScaleAspectFill; // 关键：按比例填充，不拉伸
    _avaImageView.clipsToBounds = YES; // 裁剪超出部分，保证图片完整
    [self.messageContentView addSubview:_avaImageView];
    
    // 3. 创建右侧工具名Label
    _ToolNameLabel = [[UILabel alloc] init];
    _ToolNameLabel.font = [UIFont boldSystemFontOfSize:kNameFontSize];
    _ToolNameLabel.textColor = [UIColor labelColor];
    _ToolNameLabel.numberOfLines = 2; // 工具名1行显示
    _ToolNameLabel.lineBreakMode = NSLineBreakByTruncatingTail; // 超出截断
    [self.messageContentView addSubview:_ToolNameLabel];
    
    // 4. 创建右侧工具名Label
    _versionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _versionButton.titleLabel.font = [UIFont boldSystemFontOfSize:kIntroductionFontSize];
    _versionButton.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.3];
    _versionButton.layer.cornerRadius = 5;
    [_versionButton setContentEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self.messageContentView addSubview:_versionButton];
    
    // 5. 创建右侧简介Label
    _ToolsuLabel = [[UILabel alloc] init];
    _ToolsuLabel.font = [UIFont systemFontOfSize:kIntroductionFontSize];
    _ToolsuLabel.textColor = [[UIColor tertiaryLabelColor] colorWithAlphaComponent:0.8];
    _ToolsuLabel.numberOfLines = 0; // 简介多行自适应
    _ToolsuLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.messageContentView addSubview:_ToolsuLabel];
    
    // 6. 添加工具条点击手势（可选，按需求保留）
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textLabelTapped:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.messageContentView addGestureRecognizer:tapGesture];
}

#pragma mark - 父类要求：设置数据模型（触发布局更新）
- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    // 无论是否有数据，先重置子视图
    self.avaImageView.image = [UIImage systemImageNamed:@"photo"];
    self.ToolNameLabel.text = @"";
    self.ToolsuLabel.text = @"";
    [self.versionButton setTitle:@"v1.0.0" forState:UIControlStateNormal];
    
    
    if (!model) return;
    
    ToolMessage *toolMessage = (ToolMessage *)model.content;
    NSLog(@"cell解析消息内容messageForType：%ld extra:%@",toolMessage.messageForType,toolMessage.extra);
    
    self.messageForType = toolMessage.messageForType;
    
    if(toolMessage.messageForType == MessageForTypeTool){
        
        self.webToolModel = toolMessage.webToolModel;
        [self.versionButton setTitle:self.webToolModel.version forState:UIControlStateNormal];
    }else if(toolMessage.messageForType == MessageForTypeApp){
        
        self.appInfoModel = toolMessage.appInfoModel;
        [self.versionButton setTitle:self.appInfoModel.version_name forState:UIControlStateNormal];
    }else if(toolMessage.messageForType == MessageForTypeUser){
        
        self.userModel = toolMessage.userModel;
        [self.versionButton setTitle:self.userModel.bio forState:UIControlStateNormal];
    }
    
    
    // 有数据时再赋值
    [self loadAvatarImage:toolMessage];
    [self setTextContent:toolMessage];
    [self setupAutoLayout];
}

#pragma mark - 加载左侧工具图片
- (void)loadAvatarImage:(ToolMessage *)toolMessage {
    // 图片URL拼接（按项目配置）
    NSString *iconUrlString = @"";
    if(toolMessage.messageForType == MessageForTypeTool){
        iconUrlString = [NSString stringWithFormat:@"%@/%@/icon.png", localURL, self.webToolModel.tool_path];
    }else if(toolMessage.messageForType == MessageForTypeApp){
        iconUrlString = self.appInfoModel.icon_url;
    }else if(toolMessage.messageForType == MessageForTypeUser){
        iconUrlString = self.userModel.avatar;
    }
    
    NSURL *iconUrl = [NSURL URLWithString:iconUrlString];
    if (!iconUrl) {
        self.avaImageView.image = [UIImage systemImageNamed:@"photo"]; // 占位图
        return;
    }
    
    // SDWebImage加载（带占位图+错误处理）
    [self.avaImageView sd_setImageWithURL:iconUrl
                          placeholderImage:[UIImage systemImageNamed:@"photo"]
                                 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error) {
            self.avaImageView.image = [UIImage systemImageNamed:@"photo"]; // 错误占位图
        }
    }];
}

#pragma mark - 设置右侧文字内容
- (void)setTextContent:(ToolMessage *)toolMessage {
    if(toolMessage.messageForType == MessageForTypeTool){
        // 工具名（非空判断）
        self.ToolNameLabel.text = self.webToolModel.tool_name ?: @"未知工具";
        
        // 简介（非空判断）
        self.ToolsuLabel.text = self.webToolModel.tool_description ?: @"暂无简介";
        
    }else if(toolMessage.messageForType == MessageForTypeApp){
        // 工具名（非空判断）
        self.ToolNameLabel.text = self.appInfoModel.app_name ?: @"未知软件";
        
        // 简介（非空判断）
        self.ToolsuLabel.text = self.appInfoModel.app_description ?: @"暂无简介";
    }else if(toolMessage.messageForType == MessageForTypeApp){
        // 工具名（非空判断）
        self.ToolNameLabel.text = self.userModel.nickname ?: @"未知用户";
        
        // 简介（非空判断）
        self.ToolsuLabel.text = self.userModel.bio ?: @"暂无简介";
    }
    
}


#pragma mark - 核心布局（Masonry实现）

- (void)setupAutoLayout {
    // 1. 左侧图片约束（关键：固定正方形+垂直居中，不随文字高度变形）
    [self.avaImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.messageContentView).offset(kInnerPadding); // 左间隔：10
        make.width.height.mas_equalTo(kImageSize); // 固定宽度：kImageSize（如50）
        
    }];
    
    // 2. 右侧工具名Label（顶部对齐气泡，自适应高度）
    [self.ToolNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avaImageView.mas_right).offset(kInnerPadding); // 图片与文字间隔：10
        make.right.equalTo(self.messageContentView).offset(-kInnerPadding); // 右间隔：10
        make.top.equalTo(self.messageContentView).offset(kInnerPadding); // 顶部对齐气泡：10
        make.width.mas_equalTo(kRightContentWidth); // 固定文字宽度（避免换行异常）
    }];
    
    // 3. 版本按钮
    [self.versionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.ToolNameLabel); // 与工具名左右对齐
        make.bottom.equalTo(self.avaImageView.mas_bottom);
        make.height.mas_equalTo(kVersionHeight);
    }];

    // 4. 右侧简介Label（底部对齐气泡，自适应高度，撑起cell）
    [self.ToolsuLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.messageContentView).inset(kInnerPadding); // 与工具名左右对齐
        make.top.equalTo(self.versionButton.mas_bottom).offset(kInnerPadding); // 文字间距：10
        make.bottom.equalTo(self.messageContentView).offset(-kInnerPadding); // 底部对齐气泡：10（核心：文字自适应高度，撑起气泡）
        make.width.mas_equalTo(kRightContentWidth); // 固定文字宽度
    }];
}

#pragma mark - 父类要求：计算气泡高度（文字自适应+不小于图片高度）
+ (CGSize)getBubbleBackgroundViewSize:(ToolMessage *)message {
    // 空数据时，气泡高度默认等于图片高度
    if (!message) {
        return CGSizeMake(kBubbleFixedWidth, kImageSize);
    }
    
    // 1. 提取文字内容（工具名/简介）
    NSString *toolName = @"未知名称";
    NSString *toolDesc = @"暂无简介";
    if (message.messageForType == MessageForTypeTool && message.webToolModel) {
        toolName = message.webToolModel.tool_name ?: toolName;
        toolDesc = message.webToolModel.tool_description ?: toolDesc;
    } else if (message.messageForType == MessageForTypeApp && message.appInfoModel) {
        toolName = message.appInfoModel.app_name ?: toolName;
        toolDesc = message.appInfoModel.app_description ?: toolDesc;
    } else if (message.messageForType == MessageForTypeUser && message.userModel) {
        toolName = message.userModel.nickname ?: toolName;
        toolDesc = message.userModel.bio ?: toolDesc;
    }
    
    // 2. 计算文字所需的总高度（上下间隔+工具名+文字间距+简介）
    CGSize nameSize = [self calculateTextSize:toolName
                                        font:[UIFont boldSystemFontOfSize:kNameFontSize]
                                        width:kRightContentWidth];
    CGSize descSize = [self calculateTextSize:toolDesc
                                        font:[UIFont systemFontOfSize:kIntroductionFontSize]
                                        width:kRightContentWidth];
    CGFloat textRequiredHeight = kInnerPadding * 2 + nameSize.height + kInnerPadding + descSize.height;
    
    // 3. 气泡高度规则：文字所需高度 ≥ 图片高度 → 用文字高度；否则 → 用图片高度 + 上下间隔
    CGFloat finalBubbleHeight = MAX(textRequiredHeight, kImageSize + kInnerPadding * 4 + kVersionHeight);
    
    // 4. 返回固定宽度+自适应高度（不小于图片高度）
    return CGSizeMake(kBubbleFixedWidth, finalBubbleHeight);
}
#pragma mark - 辅助：计算文字尺寸
+ (CGSize)calculateTextSize:(NSString *)text font:(UIFont *)font width:(CGFloat)fixedWidth {
    if (!text || text.length == 0) {
        return CGSizeZero;
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGRect textRect = [text boundingRectWithSize:CGSizeMake(fixedWidth, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attributes
                                         context:nil];
    
    // 向上取整（避免文字截断）
    return CGSizeMake(ceilf(textRect.size.width), ceilf(textRect.size.height));
}

#pragma mark - 父类要求：消息类型标识（不可修改）
+ (NSString *)getObjectName {
    return RCDPostMessageTypeIdentifier; // 确保与ToolMessage的objectName一致
}

#pragma mark - 可选：工具条点击事件（按需求实现）
- (void)textLabelTapped:(UITapGestureRecognizer *)gesture {
    // 点击气泡后的逻辑（如跳转工具详情页）
    if (self.messageForType == MessageForTypeTool) {
        NSLog(@"点击工具：%@，路径：%@", self.webToolModel.tool_name, self.webToolModel.tool_path);
        // 这里可添加跳转逻辑（如通知代理、Block回调等）
        ShowOneToolViewController *vc = [ShowOneToolViewController new];
        vc.tool_id = self.webToolModel.tool_id;
        
        [[self getTopViewController] presentPanModal:vc];
    }else if (self.messageForType == MessageForTypeApp) {
        NSLog(@"点击软件：%@，路径：%@", self.appInfoModel.app_name, self.appInfoModel.save_path);
        // 这里可添加跳转逻辑（如通知代理、Block回调等）
        ShowOneAppViewController *vc = [ShowOneAppViewController new];
        vc.app_id = self.appInfoModel.app_id;
        
        [[self getTopViewController] presentPanModal:vc];
    }else if (self.messageForType == MessageForTypeUser) {
        NSLog(@"点击用户：%@", self.userModel.nickname);
        // 这里可添加跳转逻辑（如通知代理、Block回调等）
        UserProfileViewController *vc = [UserProfileViewController new];
        vc.user_udid = self.userModel.udid;
        
        [[self getTopViewController] presentPanModal:vc];
    }
}

@end
