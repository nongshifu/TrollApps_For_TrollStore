//
//  DylibHistoryController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "DylibHistoryController.h"

@interface DylibHistoryController ()

@end

@implementation DylibHistoryController


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // 初始化动态库存储目录（如Documents/Dylibs）
    [self setupDylibStoragePath];
    // 初始化表格
    [self setupTableView];
    // 加载动态库列表
    [self refreshDylibList];
}

#pragma mark - 初始化存储路径
- (void)setupDylibStoragePath {
    // 创建专门的目录存储下载的dylib
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = docPaths.firstObject;
    self.dylibStoragePath = [docPath stringByAppendingPathComponent:@"Dylibs"];
    
    // 确保目录存在
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:self.dylibStoragePath]) {
        [fm createDirectoryAtPath:self.dylibStoragePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - 表格初始化
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 70;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DylibCell"];
    [self.view addSubview:self.tableView];
    
    // 空数据提示
    UILabel *emptyLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    emptyLabel.text = @"暂无动态库文件\n可添加dylib到Documents/Dylibs目录";
    emptyLabel.textColor = [UIColor lightGrayColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.numberOfLines = 2;
    self.tableView.backgroundView = emptyLabel;
    self.tableView.backgroundView.hidden = YES;
}

#pragma mark - 加载与刷新动态库列表
- (void)refreshDylibList {
    // 1. 从本地存储目录读取所有dylib文件
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSArray *files = [fm contentsOfDirectoryAtPath:self.dylibStoragePath error:&error];
    if (!files) {
        NSLog(@"读取动态库目录失败：%@", error.localizedDescription);
        self.dylibList = [NSMutableArray array];
        self.tableView.backgroundView.hidden = NO;
        return;
    }
    
    // 2. 筛选出.dylib文件，并封装成DylibInfo
    self.dylibList = [NSMutableArray array];
    for (NSString *fileName in files) {
        if ([fileName hasSuffix:@".dylib"]) { // 仅保留dylib文件
            NSString *filePath = [self.dylibStoragePath stringByAppendingPathComponent:fileName];
            // 获取文件创建时间（作为下载时间）
            NSDictionary *attrs = [fm attributesOfItemAtPath:filePath error:nil];
            NSDate *createTime = attrs[NSFileCreationDate] ?: [NSDate date];
            
            DylibInfo *info = [[DylibInfo alloc] init];
            info.name = fileName;
            info.filePath = filePath;
            info.downloadTime = createTime;
            [self.dylibList addObject:info];
        }
    }
    
    // 3. 按时间倒序排序（最新的在前面）
    [self.dylibList sortUsingComparator:^NSComparisonResult(DylibInfo *a, DylibInfo *b) {
        return [b.downloadTime compare:a.downloadTime];
    }];
    
    // 4. 更新表格
    self.tableView.backgroundView.hidden = self.dylibList.count > 0;
    [self.tableView reloadData];
}

#pragma mark - 表格数据源
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dylibList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DylibCell" forIndexPath:indexPath];
    DylibInfo *dylib = self.dylibList[indexPath.row];
    
    // 主标题：动态库名称
    cell.textLabel.text = dylib.name;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    
    // 副标题：路径和时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *timeStr = [formatter stringFromDate:dylib.downloadTime];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"路径：%@\n添加时间：%@",
                                 [dylib.filePath lastPathComponent], timeStr];
    cell.detailTextLabel.numberOfLines = 2;
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    // 选中状态标记
    cell.accessoryType = dylib.isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - 表格交互
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DylibInfo *selectedDylib = self.dylibList[indexPath.row];
    
    // 1. 更新选中状态（单选）
    for (DylibInfo *info in self.dylibList) {
        info.isSelected = (info == selectedDylib);
    }
    [self.tableView reloadData];
    
    // 2. 触发回调，通知主控制器选中的dylib（用于注入）
    if (self.onDylibSelected) {
        self.onDylibSelected([NSURL fileURLWithPath:selectedDylib.filePath]);
    }
}

// 滑动删除功能
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DylibInfo *dylib = self.dylibList[indexPath.row];
        // 1. 删除本地文件
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:dylib.filePath]) {
            [fm removeItemAtPath:dylib.filePath error:nil];
        }
        // 2. 从列表中移除
        [self.dylibList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        // 3. 更新空数据提示
        self.tableView.backgroundView.hidden = self.dylibList.count > 0;
    }
}

#pragma mark - 辅助方法
// 格式化时间显示
- (NSString *)formatDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    return [formatter stringFromDate:date];
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
