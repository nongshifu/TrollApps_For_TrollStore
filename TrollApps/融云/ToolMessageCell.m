#import "ToolMessageCell.h"
#import "config.h"
#import "ShowOneToolViewController.h"
#import <Masonry/Masonry.h> // 确保导入Masonry（布局依赖）
//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}
// 固定配置（按需求定义）
static const CGFloat kBubbleFixedWidth = 250;    // 气泡固定宽度
static const CGFloat kInnerPadding = 10;         // 气泡内部上下左右间隔
static const CGFloat kImageSize = 80;            // 左侧图片尺寸（80*80）
static const CGFloat kTextSpacing = 10;           // 工具名与简介的间距
static const CGFloat kRightContentWidth = kBubbleFixedWidth - kImageSize - kInnerPadding * 2 - kInnerPadding; // 右侧文字区域宽度（250-80-10-10-10=150）

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
    _avaImageView.contentMode = UIViewContentModeScaleAspectFit; // 图片适配模式
    _avaImageView.clipsToBounds = YES;
    _avaImageView.layer.cornerRadius = 20; // 图片圆角（可选）
    _avaImageView.layer.masksToBounds = YES;
    [self.messageContentView addSubview:_avaImageView];
    
    // 3. 创建右侧工具名Label
    _ToolNameLabel = [[UILabel alloc] init];
    _ToolNameLabel.font = [UIFont boldSystemFontOfSize:13];
    _ToolNameLabel.textColor = [UIColor labelColor];
    _ToolNameLabel.numberOfLines = 0; // 工具名1行显示
    _ToolNameLabel.lineBreakMode = NSLineBreakByTruncatingTail; // 超出截断
    [self.messageContentView addSubview:_ToolNameLabel];
    
    // 4. 创建右侧简介Label
    _ToolsuLabel = [[UILabel alloc] init];
    _ToolsuLabel.font = [UIFont systemFontOfSize:11];
    _ToolsuLabel.textColor = [[UIColor tertiaryLabelColor] colorWithAlphaComponent:0.8];
    _ToolsuLabel.numberOfLines = 0; // 简介多行自适应
    _ToolsuLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.messageContentView addSubview:_ToolsuLabel];
    
    // 5. 添加工具条点击手势（可选，按需求保留）
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
    
    if (!model) return;
    
    ToolMessage *toolMessage = (ToolMessage *)model.content;
    self.webToolModel = toolMessage.webToolModel;
    if (!self.webToolModel) return;
    
    // 有数据时再赋值
    [self loadAvatarImage];
    [self setTextContent];
    [self setupAutoLayout];
}

#pragma mark - 加载左侧工具图片
- (void)loadAvatarImage {
    // 图片URL拼接（按项目配置）
    NSString *iconUrlString = [NSString stringWithFormat:@"%@/%@/icon.png", localURL, self.webToolModel.tool_path];
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
- (void)setTextContent {
    // 工具名（非空判断）
    self.ToolNameLabel.text = self.webToolModel.tool_name ?: @"未知工具";
    
    // 简介（非空判断）
    self.ToolsuLabel.text = self.webToolModel.tool_description ?: @"暂无简介";
}


#pragma mark - 核心布局（Masonry实现）
- (void)setupAutoLayout {

    // 1. 左侧图片布局（固定80*80，上下左间隔10）
    [self.avaImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.messageContentView).offset(kInnerPadding/2);
        make.top.equalTo(self.messageContentView).offset(kInnerPadding);
        make.bottom.lessThanOrEqualTo(self.messageContentView).offset(-kInnerPadding); // 底部不超过间隔（内容不够时靠上）
        make.width.height.mas_equalTo(kImageSize);
        make.bottom.greaterThanOrEqualTo(self.messageContentView).offset(-kInnerPadding); // 确保底部至少有间隔
    }];
    
    // 2. 右侧工具名布局（左接图片右间隔10，右间隔10，上间隔10）
    [self.ToolNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avaImageView.mas_right).offset(kInnerPadding/2);
        make.right.equalTo(self.messageContentView).offset(-kInnerPadding);
        make.top.equalTo(self.messageContentView).offset(kInnerPadding);
        make.width.mas_equalTo(kRightContentWidth); // 固定右侧文字宽度
    }];
    
    // 3. 右侧简介布局（左接工具名，下间隔10，上间隔5）
    [self.ToolsuLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.ToolNameLabel); // 与工具名左右对齐
        make.top.equalTo(self.ToolNameLabel.mas_bottom).offset(kTextSpacing/2);
        make.bottom.equalTo(self.messageContentView).offset(-kInnerPadding); // 底部贴间隔（高度自适应）
        make.width.mas_equalTo(kRightContentWidth); // 固定右侧文字宽度
    }];
}

#pragma mark - 父类要求：计算气泡背景尺寸（固定宽度250，高度自适应）
+ (CGSize)getBubbleBackgroundViewSize:(ToolMessage *)message {
    if (!message || !message.webToolModel) {
        return CGSizeMake(kBubbleFixedWidth, kImageSize + kInnerPadding * 2); // 空数据时默认高度
    }
    
    // 1. 计算工具名高度（1行，固定宽度）
    NSString *toolName = message.webToolModel.tool_name ?: @"未知工具";
    CGSize nameSize = [self calculateTextSize:toolName font:[UIFont boldSystemFontOfSize:13] width:kRightContentWidth];
    
    // 2. 计算简介高度（多行，固定宽度）
    NSString *toolDesc = message.webToolModel.tool_description ?: @"暂无简介";
    CGSize descSize = [self calculateTextSize:toolDesc font:[UIFont systemFontOfSize:11] width:kRightContentWidth];
    
    // 3. 计算总高度（上下间隔10*2 + 工具名高度 + 间距5 + 简介高度）
    CGFloat totalHeight = kInnerPadding * 2 + nameSize.height + kTextSpacing + descSize.height;
    
    // 4. 确保高度不小于图片高度（80 + 上下间隔10*2 = 100）
    CGFloat minHeight = kImageSize + kInnerPadding * 2;
    if (totalHeight < minHeight) {
        totalHeight = minHeight;
    }
    
    // 5. 返回固定宽度250，自适应高度
    return CGSizeMake(kBubbleFixedWidth, totalHeight);
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
    if (self.webToolModel) {
        NSLog(@"点击工具：%@，路径：%@", self.webToolModel.tool_name, self.webToolModel.tool_path);
        // 这里可添加跳转逻辑（如通知代理、Block回调等）
        ShowOneToolViewController *vc = [ShowOneToolViewController new];
        vc.tool_id = self.webToolModel.tool_id;
        
        [[self getTopViewController] presentPanModal:vc];
    }
}

@end
