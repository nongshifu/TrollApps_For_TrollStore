#import "AppListController.h"
#import "NSTask.h"
#import "InjectionRecord.h"
#import "CommandExecutor.h"


// 应用信息模型（包含名称和完整路径）
@interface AppInfo : NSObject
@property (nonatomic, copy) NSString *appName;      // 应用名称（如 "TrollApps"）
@property (nonatomic, copy) NSString *fullPath;     // 完整路径（如 "/private/var/containers/.../TrollApps.app/TrollApps"）
@property (nonatomic, copy) NSString *bundlePath;   // 应用Bundle路径（如 "/private/var/containers/.../TrollApps.app"）
@end

@implementation AppInfo
@end

@interface AppListController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<AppInfo *> *appList; // 存储应用信息
@property (nonatomic, strong) NSMutableDictionary<NSString *, InjectionRecord *> *injectedApps;

@end

@implementation AppListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self setupTableView];
    [self refreshAppList];
    [self loadInjectedRecords];
}

#pragma mark - 视图初始化
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 80;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AppCell"];
    [self.view addSubview:self.tableView];
}

#pragma mark - 核心：通过 ps 命令获取用户应用（带路径）
- (void)refreshAppList {
    self.appList = [NSMutableArray array];
    
    // 1. 执行 ps 命令获取进程信息（包含完整路径）
    NSString *psOutput = [self executePSCommand];
    if (!psOutput) {
        NSLog(@"获取进程信息失败");
        return;
    }
    
    // 2. 解析输出，提取用户应用（路径包含 /private/var/containers/Bundle/Application/）
    [self parseAppInfoFromPSOutput:psOutput];
    
    // 3. 排序
    [self sortAppList];
    
    // 4. 刷新表格
    [self.tableView reloadData];
}

#pragma mark - 执行 ps 命令（获取完整路径）
- (NSString *)executePSCommand {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/ps";
    // 参数说明：-ax 显示所有进程，-o comm,args 输出进程名和完整命令行（包含路径）
    task.arguments = @[@"-ax", @"-o", @"comm,args"];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - 解析 ps 输出，提取用户应用信息
- (void)parseAppInfoFromPSOutput:(NSString *)output {
    // 用户应用路径前缀
    NSString *userAppPrefix = @"/var/containers/Bundle/Application/";
    
    // 按行分割输出
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    
    // 过滤标题行和空行
    for (NSString *line in lines) {
        
        // 查找包含用户应用前缀的行

        if ([line containsString:userAppPrefix]) {
            NSLog(@"查找包含用户应用前缀的行:%@",line);
            // 提取应用名称和完整路径
            AppInfo *appInfo = [self extractAppInfoFromLine:line];
            if (appInfo) {
                NSLog(@"最终目标名:%@  路径：%@",appInfo.appName,appInfo.fullPath);
                [self.appList addObject:appInfo];
            }
        }
    }
}

#pragma mark - 从单行数据提取应用信息
- (AppInfo *)extractAppInfoFromLine:(NSString *)line {
    // 示例行格式1："/var/containers/ /var/containers/Bundle/Application/9ED4E1D5-2FCC-4241-AFED-F60B7B19F3FA/Eggplant.app/Eggplant"
    // 示例行格式2："/private/var/con /private/var/containers/Bundle/Application/ADFD4DF5-6DB8-4D5F-94DF-C412C93879BA/WeChat.app/PlugIns/WeChatNotificationServiceExtension.appex/WeChatNotificationServiceExtension -AppleLanguages ("zh-Hans-CN")"
    
    // 移除多余的空格前缀（如 "/var/containers/ "）
    NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 查找第一个空格位置（用于分割前缀和实际路径）
    NSRange spaceRange = [trimmedLine rangeOfString:@" "];
    if (spaceRange.location == NSNotFound) {
        // 如果没有空格，直接使用整行作为路径（理论上不会出现）
        NSLog(@"警告：未找到空格分隔符，行内容：%@", trimmedLine);
        return nil;
    }
    
    // 提取实际路径部分（空格后面的内容）
    NSString *pathPart = [trimmedLine substringFromIndex:spaceRange.location + 1];
    pathPart = [pathPart stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 提取 .app 路径部分（可能包含子路径如 /PlugIns/...）
    NSRange appExtensionRange = [pathPart rangeOfString:@".app"];
    if (appExtensionRange.location == NSNotFound) {
        NSLog(@"警告：未找到 .app 扩展名，路径：%@", pathPart);
        return nil;
    }
    
    // 提取主应用 Bundle 路径（.app 及其之前的部分）
    NSString *bundlePath = [pathPart substringToIndex:appExtensionRange.location + 4];
    
    // 从 Bundle 路径提取应用名称（如 WeChat.app -> WeChat）
    NSString *appName = [bundlePath lastPathComponent];
    appName = [appName stringByDeletingPathExtension];
    
    // 构建完整可执行文件路径（如 /var/containers/.../WeChat.app/WeChat）
    NSString *executablePath = [bundlePath stringByAppendingPathComponent:appName];
    
    // 检查可执行文件是否存在（避免误判插件或扩展）
    if (![[NSFileManager defaultManager] fileExistsAtPath:executablePath]) {
        NSLog(@"警告：可执行文件不存在：%@", executablePath);
        // 尝试使用原始路径中的最后一个组件作为可执行文件（处理插件情况）
        NSString *lastComponent = [pathPart lastPathComponent];
        executablePath = [bundlePath stringByAppendingPathComponent:lastComponent];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:executablePath]) {
            NSLog(@"警告：备用可执行文件仍不存在：%@", executablePath);
            return nil;
        }
    }
    
    // 创建并填充 AppInfo 对象
    AppInfo *appInfo = [[AppInfo alloc] init];
    appInfo.appName = appName;
    appInfo.bundlePath = bundlePath;
    appInfo.fullPath = executablePath;
    
    return appInfo;
}

#pragma mark - 排序应用列表
- (void)sortAppList {
    [self.appList sortUsingComparator:^NSComparisonResult(AppInfo * _Nonnull obj1, AppInfo * _Nonnull obj2) {
        return [obj1.appName caseInsensitiveCompare:obj2.appName];
    }];
}

#pragma mark - 表格数据源（显示应用名称和完整路径）
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppCell" forIndexPath:indexPath];
    AppInfo *appInfo = self.appList[indexPath.row];
    
    cell.textLabel.text = appInfo.appName; // 主标题显示应用名称
    cell.detailTextLabel.text = appInfo.fullPath; // 副标题显示完整路径
    cell.detailTextLabel.numberOfLines = 2; // 允许多行显示路径
    cell.imageView.image = [UIImage systemImageNamed:@"app"]; // 使用默认图标
    
    // 标记已注入的应用（通过路径匹配）
    if ([self isInjectedApp:appInfo.bundlePath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.1];
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
    }
    
    return cell;
}

#pragma mark - 判断应用是否已注入
- (BOOL)isInjectedApp:(NSString *)bundlePath {
    // 从 bundlePath 提取 bundleID（通过解析 Info.plist）
    NSString *infoPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *bundleID = infoPlist[@"CFBundleIdentifier"];
    
    if (bundleID && self.injectedApps[bundleID]) {
        return YES;
    }
    return NO;
}

#pragma mark - 注入逻辑（使用完整路径）
- (void)injectDylibToApp:(AppInfo *)appInfo {
    if (!self.selectedDylibURL) {
        [self showAlertWithTitle:@"提示" message:@"请先选择要注入的动态库"];
        return;
    }
    
    NSString *appPath = appInfo.fullPath; // 应用可执行文件路径
    NSString *bundlePath = appInfo.bundlePath; // 应用Bundle路径
    
    // 1. 拷贝Dylib到APP的Frameworks目录
    NSString *frameworksDir = [bundlePath stringByAppendingPathComponent:@"Frameworks"];
    NSError *error;
    
    // 创建Frameworks目录（如果不存在）
    if (![[NSFileManager defaultManager] fileExistsAtPath:frameworksDir]) {
        BOOL createSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:frameworksDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (!createSuccess) {
            NSLog(@"创建Frameworks目录失败:%@",error.localizedDescription);
            [self showAlertWithTitle:@"错误" message:[NSString stringWithFormat:@"创建Frameworks目录失败: %@", error.localizedDescription]];
            return;
        }
    }
    
    // 拷贝dylib到Frameworks目录
    NSString *targetDylibPath = [frameworksDir stringByAppendingPathComponent:self.selectedDylibURL.lastPathComponent];
   
    BOOL copySuccess = [self copyWithRootFrom:self.selectedDylibURL.path to:targetDylibPath overwrite:YES error:&error];
    if (!copySuccess) {
        NSLog(@"拷贝失败:%@",error.localizedDescription);
        [self showAlertWithTitle:@"拷贝失败" message:error.localizedDescription];
        return;
    }
    
    // 2. 注入动态库到APP的Mach-O文件
    NSString *injectPath = [NSString stringWithFormat:@"@executable_path/%@", self.selectedDylibURL.lastPathComponent];
    BOOL injectSuccess = [[CommandExecutor shared] insertDylib:injectPath intoMachO:appPath weak:NO error:&error];
    if (injectSuccess) {
        [self showAlertWithTitle:@"成功" message:@"动态库注入完成，重启APP生效"];
        
        // 3. 记录注入历史
        [self recordInjectionForApp:appInfo];
        [self.tableView reloadData];
        
        // 4. 同步到历史控制器
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InjectionUpdated" object:nil];
    } else {
        NSLog(@"注入失败:%@",error.localizedDescription);
        [self showAlertWithTitle:@"注入失败" message:error.localizedDescription];
    }
}
// 替换原有的 [[CommandExecutor shared] copyFrom:to:overwrite:error:] 方法
- (BOOL)copyWithRootFrom:(NSString *)source to:(NSString *)destination overwrite:(BOOL)overwrite error:(NSError **)error {
    // 1. 获取 IPA 包内自带的 cp 工具路径（假设工具在应用沙盒的 Frameworks 或 Resources 目录）
    NSString *appBundlePath = [[NSBundle mainBundle] bundlePath];
    // 优先尝试 cp-15，不存在则用 cp
    NSString *cpToolPath = [appBundlePath stringByAppendingPathComponent:@"cp-15"]; // 替换为实际路径
    if (![[NSFileManager defaultManager] fileExistsAtPath:cpToolPath]) {
        cpToolPath = [appBundlePath stringByAppendingPathComponent:@"cp"]; // 备选路径
        if (![[NSFileManager defaultManager] fileExistsAtPath:cpToolPath]) {
            if (error) {
                *error = [NSError errorWithDomain:@"CopyError"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"未找到自带的 cp 工具，请检查 IPA 包资源"}];
            }
            return NO;
        }
    }
    
    // 2. 设置 cp 工具可执行权限（关键步骤，否则无法运行）
    if (![self setExecutablePermission:cpToolPath error:error]) {
        return NO;
    }
    
    // 3. 构建拷贝命令参数（-f 强制覆盖）
    NSMutableArray *arguments = [NSMutableArray array];
    if (overwrite) {
        [arguments addObject:@"-f"]; // 强制覆盖已存在文件
    }
    [arguments addObject:source];   // 源文件路径
    [arguments addObject:destination]; // 目标路径
    
    // 4. 执行 root 命令（使用自带的 cp 工具）
    NSString *output = nil;
    NSString *errorMsg = nil;
    CommandResult result = [[CommandExecutor shared] executeRootCommand:cpToolPath
                                                          arguments:arguments
                                                              output:&output
                                                               error:&errorMsg];
    
    // 5. 处理执行结果
    if (result != CommandResultSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:@"CopyError"
                                        code:result
                                    userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"拷贝失败: %@（工具路径：%@）", errorMsg, cpToolPath]}];
        }
        return NO;
    }
    return YES;
}

// 辅助方法：设置文件可执行权限（chmod +x）
- (BOOL)setExecutablePermission:(NSString *)filePath error:(NSError **)error {
    NSString *chmodPath = [[NSBundle mainBundle] bundlePath];
    chmodPath = [chmodPath stringByAppendingPathComponent:@"chmod"]; // 若 IPA 自带 chmod 工具
    if (![[NSFileManager defaultManager] fileExistsAtPath:chmodPath]) {
        chmodPath = @"/bin/chmod"; // 若没有自带，则用系统 chmod（通常系统自带 chmod 可正常使用）
    }
    
    // 执行 chmod +x 赋予可执行权限
    NSString *output = nil;
    NSString *errorMsg = nil;
    CommandResult result = [[CommandExecutor shared] executeRootCommand:chmodPath
                                                          arguments:@[@"+x", filePath]
                                                              output:&output
                                                               error:&errorMsg];
    
    if (result != CommandResultSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:@"PermissionError"
                                        code:result
                                    userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"设置工具可执行权限失败: %@", errorMsg]}];
        }
        return NO;
    }
    return YES;
}

#pragma mark - 记录注入历史
- (void)recordInjectionForApp:(AppInfo *)appInfo {
    // 解析 Info.plist 获取应用名称和 BundleID
    NSString *infoPlistPath = [appInfo.bundlePath stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *bundleID = infoPlist[@"CFBundleIdentifier"];
    NSString *appName = infoPlist[@"CFBundleDisplayName"] ?: infoPlist[@"CFBundleName"] ?: appInfo.appName;
    
    if (!bundleID) {
        NSLog(@"无法获取应用BundleID，使用路径作为标识");
        bundleID = appInfo.bundlePath;
    }
    
    // 创建注入记录
    InjectionRecord *record = [[InjectionRecord alloc] init];
    record.appName = appName;
    record.appBundleID = bundleID;
    record.dylibPath = self.selectedDylibURL.path;
    record.injectionTime = [NSDate date];
    
    // 保存记录
    self.injectedApps[bundleID] = record;
    [self saveInjectedRecords];
}

#pragma mark - 表格代理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AppInfo *appInfo = self.appList[indexPath.row];
    [self injectDylibToApp:appInfo]; // 传入完整的应用信息
}

#pragma mark - 其他保留方法（与原代码一致）
- (void)loadInjectedRecords {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:@"InjectedRecords"];
    if (data) {
        NSArray *records = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        self.injectedApps = [NSMutableDictionary dictionary];
        for (InjectionRecord *record in records) {
            self.injectedApps[record.appBundleID] = record;
        }
    } else {
        self.injectedApps = [NSMutableDictionary dictionary];
    }
}

- (void)saveInjectedRecords {
    NSArray *records = self.injectedApps.allValues;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:records requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"InjectedRecords"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)shouldRespondToPanModalGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint loc = [panGestureRecognizer locationInView:self.view];
    return !CGRectContainsPoint(self.tableView.frame, loc);
}

@end
