//
//  CategoryManagerViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/2.
//
#import "MiniButtonView.h"
#import "CategoryManagerViewController.h"

@interface CategoryManagerViewController ()<MiniButtonViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) NSMutableArray <NSString *>*systemTags;//系统预标签
@property (nonatomic, strong) MiniButtonView *miniButtonView;

@end

@implementation CategoryManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"管理分类";
    
    // 初始化系统预标签
    self.systemTags = [NSMutableArray arrayWithArray:[loadData sharedInstance].tags];
    
    // 初始化数据（从主控制器传递过来的分类列表）
    if(!_titles){
        NSArray *lacalTags = [[NSUserDefaults standardUserDefaults] arrayForKey:SAVE_LOCAL_TAGS_KEY];
        if(!lacalTags){
            _titles = [NSMutableArray arrayWithArray:@[@"最新"]];
        }else{
            _titles = [NSMutableArray arrayWithArray:lacalTags];
        }
    }
   
    [self setupUI];
}

#pragma mark - UI设置

- (void)setupUI {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"分类管理";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textColor = [UIColor randomColorWithAlpha:1];
    [self.view addSubview:self.titleLabel];
    
    self.subTitleLabel = [[UILabel alloc]  init];
    self.subTitleLabel.text = @"左滑可删除 点击可编辑 长按可修改排序";
    self.subTitleLabel.font = [UIFont boldSystemFontOfSize:12];
    self.subTitleLabel.textColor = [UIColor secondaryLabelColor];
    [self.view addSubview:self.subTitleLabel];
    
    self.tagLabel = [[UILabel alloc]  init];
    self.tagLabel.text = @"系统预留分类 双击可以添加";
    self.tagLabel.font = [UIFont boldSystemFontOfSize:12];
    self.tagLabel.textColor = [UIColor secondaryLabelColor];
    [self.view addSubview:self.tagLabel];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
    self.saveButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    self.saveButton.layer.cornerRadius = 15;
    [self.saveButton addTarget:self action:@selector(saveChanges) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addButton setTitle:@"添加" forState:UIControlStateNormal];
    self.addButton.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.9];
    self.addButton.layer.cornerRadius = 15;
    [self.addButton addTarget:self action:@selector(addCategory) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addButton];
    
    self.miniButtonView = [[MiniButtonView alloc] initWithFrame:CGRectMake(20, 400, kWidth - 40, 300)];
    self.miniButtonView.autoLineBreak = YES;
    self.miniButtonView.fontSize = 15;
    self.miniButtonView.buttonDelegate = self;
    self.miniButtonView.space = 6;
    self.miniButtonView.buttonBcornerRadius = 8;
    [self.view addSubview:self.miniButtonView];
    [self.miniButtonView updateButtonsWithStrings:self.systemTags icons:nil];
   
    
    // 初始化表格
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.3];
    self.tableView.rowHeight = 45;
    self.tableView.layer.cornerRadius = 10;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CategoryCell"];
    
    // 支持长按拖动排序
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleLongPress:)];
    [self.tableView addGestureRecognizer:longPress];
    
    [self.view addSubview:self.tableView];
    
    //隐藏底部导航
    self.tabBarController.tabBar.hidden = YES;
    
}


#pragma mark - 约束
- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);
        make.left.equalTo(self.view).offset(20);
    }];
    [self.subTitleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(5);
        make.left.equalTo(self.view).offset(20);
        make.height.mas_equalTo(15);
    }];
    [self.saveButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(35);
        make.width.mas_equalTo(50);
    }];
    [self.addButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(10);;
        make.right.equalTo(self.saveButton.mas_left).offset(-20);
        make.height.mas_equalTo(35);
        make.width.mas_equalTo(50);
    }];
    
    
    //按钮约束
    [self.miniButtonView refreshLayout];
    
    [self.miniButtonView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_top).offset(self.viewHeight);
        make.width.mas_equalTo(kWidth-40);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@(self.miniButtonView.refreshHeight));
    }];
    
    [self.tagLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.miniButtonView.mas_top).offset(-15);;
        make.left.equalTo(self.view.mas_left).offset(20);
        
    }];
    
    // 表格约束
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(20);
        make.bottom.equalTo(self.tagLabel.mas_top).offset(-20);
        make.width.mas_equalTo(kWidth-40);
        make.centerX.equalTo(self.view);
    }];
    
}


// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
    [self updateViewConstraints];
}

//消失后
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.tabBarController.tabBar.hidden = NO;
}


#pragma mark - 添加分类

- (void)addCategory {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"添加分类"
        message:@"请输入新分类名称"
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"分类名称";
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyDone;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction
        actionWithTitle:@"取消"
        style:UIAlertActionStyleCancel
        handler:nil];
    
    UIAlertAction *addAction = [UIAlertAction
        actionWithTitle:@"添加"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        NSString *categoryName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (categoryName.length > 0 && ![self.titles containsObject:categoryName]) {
            [self.titles addObject:categoryName];
            [self.tableView reloadData];
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:addAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 长按拖动排序

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    static UIView *snapshot = nil;
    static NSIndexPath *sourceIndexPath = nil;
    static BOOL isSystemTag = NO; // 标记是否为系统标签
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                sourceIndexPath = indexPath;
                NSString *category = self.titles[indexPath.row + 3];
                isSystemTag = [self.systemTags containsObject:category];
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                snapshot = [self snapshotOfCell:cell];
                snapshot.center = cell.center;
                [self.tableView addSubview:snapshot];
                cell.alpha = 0.0;
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (!sourceIndexPath) break;
            
            snapshot.center = CGPointMake(snapshot.center.x, location.y);
            
            NSIndexPath *currentIndexPath = [self.tableView indexPathForRowAtPoint:location];
            if (currentIndexPath && ![currentIndexPath isEqual:sourceIndexPath]) {
                NSString *targetCategory = self.titles[currentIndexPath.row + 3];
                BOOL targetIsSystemTag = [self.systemTags containsObject:targetCategory];
                
                // 仅允许系统标签与系统标签交换，普通标签与普通标签交换
                if (isSystemTag != targetIsSystemTag) {
                    break;
                }
                
                // 交换数据
                [self.titles exchangeObjectAtIndex:sourceIndexPath.row + 3 withObjectAtIndex:currentIndexPath.row + 3];
                // 移动单元格
                [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:currentIndexPath];
                sourceIndexPath = currentIndexPath;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (sourceIndexPath) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
                [UIView animateWithDuration:0.2 animations:^{
                    snapshot.center = cell.center;
                    cell.alpha = 1.0;
                } completion:^(BOOL finished) {
                    [snapshot removeFromSuperview];
                    snapshot = nil;
                    sourceIndexPath = nil;
                }];
            }
            break;
        }
        default:
            [snapshot removeFromSuperview];
            snapshot = nil;
            sourceIndexPath = nil;
            if (sourceIndexPath) {
                [self.tableView cellForRowAtIndexPath:sourceIndexPath].alpha = 1.0;
            }
            break;
    }
}

// 创建单元格快照（用于拖动动画）
- (UIView *)snapshotOfCell:(UITableViewCell *)cell {
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0.0);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIView *snapshot = [[UIView alloc] initWithFrame:cell.bounds];
    snapshot.layer.contents = (__bridge id)snapshotImage.CGImage;
    snapshot.layer.shadowColor = [UIColor blackColor].CGColor;
    snapshot.layer.shadowOffset = CGSizeMake(0, 2);
    snapshot.layer.shadowOpacity = 0.3;
    snapshot.layer.shadowRadius = 4;
    return snapshot;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titles.count - 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell" forIndexPath:indexPath];
    cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    
    NSString *category = self.titles[indexPath.row + 3];
    cell.textLabel.text = category;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    
    // 系统标签添加特殊标识（可拖动但不可编辑）
    if ([self.systemTags containsObject:category]) {
        cell.textLabel.textColor = [UIColor systemBlueColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
        cell.accessoryType = UITableViewCellAccessoryNone; // 系统标签不显示箭头
        
        // 添加可拖动提示（添加拖拽图标）
        UIImageView *dragIndicator = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"]];
        dragIndicator.tintColor = [UIColor secondaryLabelColor];
        cell.accessoryView = dragIndicator;
    } else {
        cell.textLabel.textColor = [UIColor labelColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
    }
    
    if(indexPath.row == self.titles.count - 1){
        cell.layer.cornerRadius = 10;
    }
    return cell;
}

// 支持删除（仅非系统标签）
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *category = self.titles[indexPath.row + 3];
        // 系统标签不允许删除
        if ([self.systemTags containsObject:category]) {
            return;
        }
        
        [self.titles removeObjectAtIndex:indexPath.row + 3];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

// 编辑时显示删除按钮（仅非系统标签）
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *category = self.titles[indexPath.row + 3];
    return [self.systemTags containsObject:category] ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
}

#pragma mark - UITableViewDelegate

// 点击单元格进入修改模式（仅非系统标签）
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *oldName = self.titles[indexPath.row + 3];
    // 系统标签不允许编辑
    if ([self.systemTags containsObject:oldName]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"系统预留标签不允许编辑"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"修改分类"
        message:@"请输入新名称"
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = oldName;
        textField.delegate = self;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction
        actionWithTitle:@"取消"
        style:UIAlertActionStyleCancel
        handler:nil];
    
    UIAlertAction *saveAction = [UIAlertAction
        actionWithTitle:@"保存"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        NSString *newName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (newName.length > 0 && ![newName isEqualToString:oldName]) {
            // 检查新名称是否与系统标签冲突
            if ([self.systemTags containsObject:newName]) {
                UIAlertController *conflictAlert = [UIAlertController
                    alertControllerWithTitle:@"错误"
                    message:@"分类名称不能与系统标签重复"
                    preferredStyle:UIAlertControllerStyleAlert];
                [conflictAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:conflictAlert animated:YES completion:nil];
                return;
            }
            
            self.titles[indexPath.row + 3] = newName;
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:saveAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

// 限制输入长度
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return newText.length <= 10; // 最多10个字符
}

#pragma mark - 底部按钮点击
// 双击系统标签添加到自定义分类
- (void)buttonDoubleTappedWithTag:(NSInteger)tag title:(nonnull NSString *)title button:(nonnull UIButton *)button {
    // 检查是否已存在该分类
    if ([self.titles containsObject:title]) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"提示"
            message:@"该分类已存在"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 添加到分类列表
    [self.titles addObject:title];
    [self.tableView reloadData];
    
    // 提示添加成功
    UIAlertController *successAlert = [UIAlertController
        alertControllerWithTitle:@"成功"
        message:[NSString stringWithFormat:@"已添加分类: %@", title]
        preferredStyle:UIAlertControllerStyleAlert];
    [successAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:successAlert animated:YES completion:nil];
}

#pragma mark - 保存修改并返回
- (void)saveChanges {
    // 通过代理将修改后的分类列表传递给主控制器
    [[NSUserDefaults standardUserDefaults] setObject:self.titles forKey:SAVE_LOCAL_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_LOCAL_TAGS_KEY object:self.titles];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
