//
//  InjectionHistoryController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "InjectionHistoryController.h"
#import "InjectionRecord.h"
#import <UserNotifications/UserNotifications.h>

@interface InjectionHistoryController ()

@end

@implementation InjectionHistoryController

- (void)dealloc {
    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // 初始化表格
    [self setupTableView];
    // 加载历史记录
    [self refreshHistory];
    
    // 监听新注入记录（从AppListController发送）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNewInjectionRecord:)
                                                 name:@"InjectionUpdated"
                                               object:nil];
}

#pragma mark - 表格初始化
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80; // 预估行高
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"HistoryCell"];
    [self.view addSubview:self.tableView];
    
    // 添加空数据提示
    UILabel *emptyLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    emptyLabel.text = @"暂无注入记录";
    emptyLabel.textColor = [UIColor lightGrayColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.tableView.backgroundView = emptyLabel;
    self.tableView.backgroundView.hidden = YES; // 默认隐藏（有数据时）
}

#pragma mark - 加载与刷新历史记录
- (void)refreshHistory {
    // 从本地存储（NSUserDefaults）加载记录
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:@"InjectedRecords"];
    if (data) {
        // 反序列化（需InjectionRecord实现NSCoding）
        NSArray *records = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        self.historyList = [NSMutableArray arrayWithArray:records];
        // 按时间倒序排序（最新的在前面）
        [self.historyList sortUsingComparator:^NSComparisonResult(InjectionRecord *a, InjectionRecord *b) {
            return [b.injectionTime compare:a.injectionTime];
        }];
    } else {
        self.historyList = [NSMutableArray array];
    }
    
    // 显示/隐藏空数据提示
    self.tableView.backgroundView.hidden = self.historyList.count > 0;
    // 刷新表格
    [self.tableView reloadData];
}

#pragma mark - 监听新注入记录
- (void)onNewInjectionRecord:(NSNotification *)note {
    InjectionRecord *newRecord = note.object;
    if (newRecord && ![self.historyList containsObject:newRecord]) {
        [self.historyList insertObject:newRecord atIndex:0]; // 插入到首位
        [self.tableView reloadData];
        self.tableView.backgroundView.hidden = YES; // 有数据了，隐藏空提示
    }
}

#pragma mark - 表格数据源
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HistoryCell" forIndexPath:indexPath];
    InjectionRecord *record = self.historyList[indexPath.row];
    
    // 主标题：应用名称
    cell.textLabel.text = record.appName;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
    
    // 副标题：动态库名称 + 注入时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *timeStr = [formatter stringFromDate:record.injectionTime];
    NSString *dylibName = [record.dylibPath lastPathComponent]; // 提取动态库文件名
    cell.detailTextLabel.text = [NSString stringWithFormat:@"注入库：%@\n时间：%@", dylibName, timeStr];
    cell.detailTextLabel.numberOfLines = 2; // 允许两行显示
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    
    // 右侧显示BundleID（次要信息）
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
    return cell;
}

#pragma mark - 表格交互
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    InjectionRecord *record = self.historyList[indexPath.row];
    
    // 点击行显示详情（如应用路径、动态库路径等）
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:record.appName
                                                                   message:[NSString stringWithFormat:@"BundleID：%@\n动态库路径：%@\n注入时间：%@",
                                                                            record.appBundleID,
                                                                            record.dylibPath,
                                                                            [self formatDate:record.injectionTime]]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// 右侧详情按钮点击（可实现删除功能）
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    InjectionRecord *record = self.historyList[indexPath.row];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:[NSString stringWithFormat:@"确定要删除「%@」的注入记录吗？", record.appName]
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.historyList removeObjectAtIndex:indexPath.row];
        [self saveHistoryRecords]; // 保存修改
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.tableView.backgroundView.hidden = self.historyList.count > 0; // 刷新空提示
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 辅助方法
// 格式化日期显示
- (NSString *)formatDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:date];
}

// 保存记录到本地
- (void)saveHistoryRecords {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.historyList requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"InjectedRecords"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 获取手势的位置
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    if (CGRectContainsPoint(self.tableView.frame, loc)) {
        return NO;
    }
    
    // 默认返回 YES，允许拖拽
    return YES;
}

@end
