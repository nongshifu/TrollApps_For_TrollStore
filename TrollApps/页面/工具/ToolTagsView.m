//
//  ToolTagsView.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/19.
//

#import "ToolTagsView.h"
#import <Masonry/Masonry.h>
@interface ToolTagsView ()

@property (nonatomic, strong) NSMutableArray *tags;
@property (nonatomic, strong) UIView *tagsContainerView;
@property (nonatomic, strong) UITextField *tagInputField;
@property (nonatomic, strong) UIButton *addTagButton;

@end

@implementation ToolTagsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tags = [NSMutableArray array];
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    
    // 标签容器视图
    _tagsContainerView = [[UIView alloc] init];
    _tagsContainerView.backgroundColor = [UIColor clearColor];
    [self addSubview:_tagsContainerView];
    
    // 标签输入框
    _tagInputField = [[UITextField alloc] init];
    _tagInputField.placeholder = @"添加标签";
    _tagInputField.borderStyle = UITextBorderStyleRoundedRect;
//    _tagInputField.delegate = self;s
    _tagInputField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self addSubview:_tagInputField];
    
    // 添加标签按钮
    _addTagButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _addTagButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    _addTagButton.layer.cornerRadius = 5;
    [_addTagButton setTitle:@"+" forState:UIControlStateNormal];
    [_addTagButton addTarget:self action:@selector(onAddTagButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_addTagButton];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupConstraints {
    [self.tagsContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
    }];
    
    [self.tagInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsContainerView.mas_bottom).offset(10);
        make.left.equalTo(self);
        make.height.equalTo(@36);
    }];
    
    [self.addTagButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsContainerView.mas_bottom).offset(10);
        make.left.equalTo(self.tagInputField.mas_right).offset(8);
        make.right.equalTo(self);
        make.height.equalTo(@36);
    }];
}

- (void)setTags:(NSArray *)tags {
    [self.tags removeAllObjects];
    // 使用mutableCopy确保我们得到一个可变数组
    [self.tags addObjectsFromArray:[tags mutableCopy]];
    [self refreshTagsView];
}


- (NSArray *)getTags {
    return [self.tags copy];
}

- (void)addTag:(NSString *)tag {
    if (tag.length > 0 && ![self.tags containsObject:tag]) {
        [self.tags addObject:tag];
        [self refreshTagsView];
        
        if ([self.toolTagsDelegate respondsToSelector:@selector(toolTagsViewDidChangeTags:)]) {
            [self.toolTagsDelegate toolTagsViewDidChangeTags:self];
        }
    }
}

- (void)refreshTagsView {
    // 移除所有现有标签视图
    for (UIView *subview in self.tagsContainerView.subviews) {
        [subview removeFromSuperview];
    }
    
    CGFloat currentX = 0;
    CGFloat currentY = 0;
    CGFloat maxTagHeight = 30;
    CGFloat horizontalSpacing = 8;
    CGFloat verticalSpacing = 8;
    
    // 创建新的标签视图
    for (NSString *tag in self.tags) {
        UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [tagButton setTitle:tag forState:UIControlStateNormal];
        tagButton.titleLabel.font = [UIFont systemFontOfSize:14];
        tagButton.backgroundColor = [UIColor systemBlueColor];
        tagButton.tintColor = [UIColor whiteColor];
        tagButton.layer.cornerRadius = 15;
        tagButton.clipsToBounds = YES;
        [tagButton addTarget:self action:@selector(onTagButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // 计算按钮宽度
        CGSize titleSize = [tag sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
        CGFloat buttonWidth = titleSize.width + 20; // 添加内边距
        
        // 检查是否需要换行
        if (currentX + buttonWidth > self.tagsContainerView.bounds.size.width) {
            currentX = 0;
            currentY += maxTagHeight + verticalSpacing;
        }
        
        // 设置按钮位置
        tagButton.frame = CGRectMake(currentX, currentY, buttonWidth, maxTagHeight);
        [self.tagsContainerView addSubview:tagButton];
        
        // 更新当前位置
        currentX += buttonWidth + horizontalSpacing;
    }
    
    // 更新容器视图高度
    CGFloat containerHeight = currentY + maxTagHeight;
    [self.tagsContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(containerHeight));
    }];
    // 新增：通知父视图更新约束
    [self invalidateIntrinsicContentSize];
   
}

// 新增方法：返回ToolTagsView的内在内容大小
- (CGSize)intrinsicContentSize {
    [self layoutIfNeeded]; // 确保布局完成
    return CGSizeMake(UIViewNoIntrinsicMetric,
                      CGRectGetMaxY(self.addTagButton.frame) + 10); // 底部留出边距
}
#pragma mark - Actions

- (void)onAddTagButtonTapped {
    NSString *tag = [self.tagInputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (tag.length > 0) {
        [self addTag:tag];
        self.tagInputField.text = @"";
    }
}

- (void)onTagButtonTapped:(UIButton *)sender {
    NSString *tag = sender.titleLabel.text;
    [self.tags removeObject:tag];
    [self refreshTagsView];
    
    if ([self.toolTagsDelegate respondsToSelector:@selector(toolTagsViewDidChangeTags:)]) {
        [self.toolTagsDelegate toolTagsViewDidChangeTags:self];
    }
}

@end

#pragma mark - UITextFieldDelegate

@implementation ToolTagsView (UITextFieldDelegate)

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onAddTagButtonTapped];
    return YES;
}

@end
