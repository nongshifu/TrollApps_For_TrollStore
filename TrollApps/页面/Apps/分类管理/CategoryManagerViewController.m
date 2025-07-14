//
//  CategoryManagerViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/2.
//

#import "CategoryManagerViewController.h"

@interface CategoryManagerViewController ()

@end

@implementation CategoryManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"管理分类";
    if(!_titles){
        // 初始化数据（从主控制器传递过来的分类列表）
        NSArray *lacalTags = [[NSUserDefaults standardUserDefaults] arrayForKey:SAVE_LOCAL_TAGS_KEY];
        if(!lacalTags){
            _titles = [NSMutableArray arrayWithArray:@[@"最新"]];
        }else{
            _titles = [NSMutableArray arrayWithArray:lacalTags];
        }
        
    }
   
    
    
    
    [self setupUI];
    [self setupNavigationBar];
    [self updateViewConstraints];
    
    
    
}

#pragma mark - UI设置

- (void)setupUI {
    // 初始化表格
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = 50;
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

- (void)setupNavigationBar {
   
    // 添加按钮
    [self zx_setLeftBtnWithText:@"返回" clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        [self saveChanges];
    }];
   
    [self zx_setRightBtnWithText:@"添加" clickedBlock:^(ZXNavItemBtn * _Nonnull btn) {
        [self addCategory];
    }];
    //设置分割线
    self.zx_navBar.zx_lineViewHeight = 0.5;
    //分割线透明度
    self.zx_navBar.zx_lineView.alpha = 0.5;
    //移除渐变
    [self zx_removeNavGradientBac];
    //添加悬浮球
    [self.zx_navBar addColorBallsWithCount:10 ballradius:150 minDuration:30 maxDuration:60 UIBlurEffectStyle:UIBlurEffectStyleProminent UIBlurEffectAlpha:0.99 ballalpha:0.5];
    [self zx_setMultiTitle:@"我的分类管理" subTitle:@"左滑可删除 点击可编辑 长按可修改排序" subTitleFont:[UIFont boldSystemFontOfSize:10] subTitleTextColor:[UIColor randomColorWithAlpha:1]];
    
    
}

#pragma mark - 约束
- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    // 表格约束
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.zx_navBar.mas_bottom).offset(10);
        make.bottom.equalTo(self.view).offset(-30);
        make.width.mas_equalTo(kWidth-20);
        make.centerX.equalTo(self.view);
    }];
    
}


// 显示后
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 可以在这里执行一些与视图显示后相关的操作，比如开始动画、启动定时器等。
    self.tabBarController.tabBar.hidden = YES;
}

//消失后
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 在这里可以进行一些清理工作，比如停止动画、取消定时器、保存数据等。
    // 也可以用于记录视图消失的状态，以便在后续的操作中进行判断。
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

#pragma mark - 保存修改并返回

- (void)saveChanges {
    // 通过代理将修改后的分类列表传递给主控制器
    [[NSUserDefaults standardUserDefaults] setObject:self.titles forKey:SAVE_LOCAL_TAGS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_LOCAL_TAGS_KEY object:self.titles];
    
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 长按拖动排序

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {

    
    CGPoint location = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    static UIView *snapshot = nil;
    static NSIndexPath *sourceIndexPath = nil;
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                sourceIndexPath = indexPath;
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                snapshot = [self snapshotOfCell:cell];
                snapshot.center = cell.center;
                [self.tableView addSubview:snapshot];
                cell.alpha = 0.0;
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            snapshot.center = CGPointMake(snapshot.center.x, location.y);
            
            NSIndexPath *currentIndexPath = [self.tableView indexPathForRowAtPoint:location];
            if (currentIndexPath && ![currentIndexPath isEqual:sourceIndexPath]) {
                // 交换数据
                [self.titles exchangeObjectAtIndex:sourceIndexPath.row+3 withObjectAtIndex:currentIndexPath.row+3];
                // 移动单元格
                [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:currentIndexPath];
                sourceIndexPath = currentIndexPath;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
            [UIView animateWithDuration:0.2 animations:^{
                snapshot.center = cell.center;
                cell.alpha = 1.0;
            } completion:^(BOOL finished) {
                [snapshot removeFromSuperview];
                snapshot = nil;
                sourceIndexPath = nil;
            }];
            break;
        }
        default:
            [snapshot removeFromSuperview];
            snapshot = nil;
            sourceIndexPath = nil;
            [self.tableView cellForRowAtIndexPath:sourceIndexPath].alpha = 1.0;
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
    cell.textLabel.text = self.titles[indexPath.row +3];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

// 支持删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.titles removeObjectAtIndex:indexPath.row +3];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

// 编辑时显示删除按钮
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - UITableViewDelegate

// 点击单元格进入修改模式
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *oldName = self.titles[indexPath.row+3];
    
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
            self.titles[indexPath.row+3] = newName;
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

//监听主题变化
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 检查界面模式是否发生变化
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
        
        [self setupNavigationBar];
    }
    
}

@end
