//
//  SystemViewController.m
//  TrollApps
//
//  Created by 十三哥 on 2025/7/24.
//  Copyright © 2025 iOS_阿玮. All rights reserved.
//

#import "SystemViewController.h"
#import "ConfigItem.h"
#import "ConfigField.h"
#import "config.h"
#import "NetworkClient.h"
#import "NewProfileViewController.h"
#import "loadData.h"

@interface SystemViewController ()<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<ConfigItem *> *configItems; // 所有配置项
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<NSMutableArray<ConfigField *> *> *> *sectionData;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UIButton *submitButton;
@end

@implementation SystemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"系统配置管理";
    
    [self setupViews];
    [self updateViewConstraints];
    [self loadConfigData];
    
}

#pragma mark - 视图初始化
- (void)setupViews {
    //标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWidth, 50)];
    titleLabel.text = @"系统信息修改";
    titleLabel.font = [UIFont systemFontOfSize:17];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    // 表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.1];
    self.tableView.rowHeight = 60;
    self.tableView.sectionHeaderHeight = 40;
    self.tableView.sectionFooterHeight = 10;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ConfigCell"];
    [self.view addSubview:self.tableView];
    
    //左侧刷新按钮
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    refreshButton.frame = CGRectMake(10, 5, 40, 40);
    [refreshButton setImage:[UIImage systemImageNamed:@"arrow.2.circlepath"] forState:UIControlStateNormal];
    refreshButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [refreshButton setBackgroundColor:[UIColor clearColor]];
    [refreshButton setTitleColor:[UIColor systemBackgroundColor] forState:UIControlStateNormal];
    refreshButton.layer.cornerRadius = 8;
    [refreshButton addTarget:self action:@selector(loadConfigData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:refreshButton];
    
    //右侧关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) -50, 5, 40, 40);
    [closeButton setImage:[UIImage systemImageNamed:@"chevron.down.circle"] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [closeButton setBackgroundColor:[UIColor clearColor]];
    [closeButton setTitleColor:[UIColor systemBackgroundColor] forState:UIControlStateNormal];
    closeButton.layer.cornerRadius = 8;
    [closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    
    
    // 底部操作栏
    self.footerView = [[UIView alloc] init];
    self.footerView.backgroundColor = [UIColor systemBackgroundColor];
    self.footerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.footerView.layer.shadowOpacity = 0.1;
    self.footerView.layer.shadowOffset = CGSizeMake(0, -2);
    [self.view addSubview:self.footerView];
    
    // 添加按钮
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addButton setTitle:@"添加配置" forState:UIControlStateNormal];
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.addButton setBackgroundColor:[UIColor systemBlueColor]];
    [self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.addButton.layer.cornerRadius = 8;
    [self.addButton addTarget:self action:@selector(addConfigAction) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:self.addButton];
    
    // 提交按钮
    self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.submitButton setTitle:@"提交修改" forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.submitButton setBackgroundColor:[UIColor systemGreenColor]];
    [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitButton.layer.cornerRadius = 8;
    [self.submitButton addTarget:self action:@selector(submitChangesAction) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:self.submitButton];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    CGFloat footerHeight = 60;
    self.tableView.frame = CGRectMake(0, 50, self.view.bounds.size.width, self.viewHeight - footerHeight - 50);
    self.footerView.frame = CGRectMake(0, self.viewHeight - footerHeight, self.view.bounds.size.width, footerHeight);
    
    CGFloat btnWidth = (self.footerView.bounds.size.width - 30) / 2;
    self.addButton.frame = CGRectMake(10, 10, btnWidth, 40);
    self.submitButton.frame = CGRectMake(btnWidth + 20, 10, btnWidth, 40);
}

#pragma mark - 数据加载
- (void)loadConfigData {
    [SVProgressHUD showWithStatus:@"加载中"];
    
    NSString *url = [NSString stringWithFormat:@"%@/admin/system_api.php",localURL];
    NSString *udid = [loadData sharedInstance].userModel.udid?:@"";
    NSDictionary *dic =@{
        @"action":@"getAllConfigs",
        @"udid":udid,
        @"type":@(0)
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:dic udid:udid progress:^(NSProgress *progress) {
        // 进度处理
    } success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        [SVProgressHUD dismiss];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!jsonResult && stringResult){
                NSLog(@"读取配置错误：%@",stringResult);
                [SVProgressHUD showErrorWithStatus:stringResult];
                [SVProgressHUD dismissWithDelay:5];
                return;
            }
           
            
            // 检查响应状态
            NSInteger code = [jsonResult[@"code"] integerValue];
            if (code == 200 && [jsonResult[@"data"] isKindOfClass:[NSArray class]]) {
                // 使用YYModel将JSON数组转换为ConfigItem数组
                NSArray *configArray = jsonResult[@"data"];
                NSLog(@"configArray:%@",configArray);
                self.configItems = [NSMutableArray array];
                
                for (NSDictionary *itemDict in configArray) {
                    ConfigItem *item = [ConfigItem yy_modelWithDictionary:itemDict];
                    if (item) {
                        [self.configItems addObject:item];
                    }
                }
                
                [self processSectionData];
                [self.tableView reloadData];
            } else {
                NSString *errorMsg = jsonResult[@"msg"] ?: @"获取配置失败";
                [SVProgressHUD showErrorWithStatus:errorMsg];
                [SVProgressHUD dismissWithDelay:5];
            }
        });
        
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"网络错误: %@", error.localizedDescription]];
        [SVProgressHUD dismissWithDelay:5];
        
    }];
}

// 处理分组数据（按configType分组，每组包含该类型下的所有配置项）
- (void)processSectionData {
    self.sectionData = [NSMutableDictionary dictionary];
    
    for (ConfigItem *item in self.configItems) {
        NSNumber *typeKey = @(item.config_type);
        // 若分组不存在，初始化（存储该类型下的所有配置项）
        if (!self.sectionData[typeKey]) {
            self.sectionData[typeKey] = [NSMutableArray array];
        }
        
        // 为当前配置项创建一个字段数组（作为一个"子项"）
        NSMutableArray<ConfigField *> *itemFields = [NSMutableArray array];
        [itemFields addObject:[self createFieldWithName:@"配置键" key:@"config_key" value:item.config_key editable:YES]];
        [itemFields addObject:[self createFieldWithName:@"配置值" key:@"config_value" value:item.config_value editable:YES]];
        [itemFields addObject:[self createFieldWithName:@"配置类型" key:@"typeTextForType" value:[self typeTextForType:item.config_type] editable:YES]];
        [itemFields addObject:[self createFieldWithName:@"配置说明" key:@"db_description" value:item.db_description editable:YES]];
        [itemFields addObject:[self createFieldWithName:@"是否必填" key:@"is_required" value:item.is_required ? @"是" : @"否" editable:YES]];
        [itemFields addObject:[self createFieldWithName:@"排序权重" key:@"sort" value:[NSString stringWithFormat:@"%ld", (long)item.sort] editable:YES]];
        
        // 将当前配置项的字段数组添加到分组中（而非覆盖）
        [self.sectionData[typeKey] addObject:itemFields];
    }
}

// 创建字段模型
- (ConfigField *)createFieldWithName:(NSString *)name key:(NSString *)key value:(NSString *)value editable:(BOOL)editable {
    ConfigField *field = [[ConfigField alloc] init];
    field.fieldName = name;
    field.fieldKey = key;
    field.value = value ?: @"";
    field.editable = editable;
    return field;
}

// 配置类型文本转换
- (NSString *)typeTextForType:(NSInteger)type {
    switch (type) {
        case 0: return @"基础信息";
        case 1: return @"功能开关";
        case 2: return @"版本信息";
        case 3: return @"管理员配置";
        case 4: return @"其他";
        default: return @"未知类型";
    }
}

#pragma mark - UITableView数据源
// 分组数 = 不同config_type的数量
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionData.allKeys.count;
}

// 每组的行数 = 该类型下的配置项数量
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sortedTypes = [self.sectionData.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSNumber *typeKey = sortedTypes[section];
    // 每组数据是"配置项的字段数组"的数组，行数即配置项数量
    return self.sectionData[typeKey].count;
}

// 每行显示一个配置项的信息（可简化为显示"配置键"作为行标题，或自定义单元格展示更多信息）
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 推荐使用重用机制（取消重用会影响性能），注册并复用单元格
    static NSString *cellId = @"ConfigCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    
    // 获取当前配置项数据
    NSArray *sortedTypes = [self.sectionData.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSNumber *typeKey = sortedTypes[indexPath.section];
    NSArray<NSMutableArray<ConfigField *> *> *typeItems = self.sectionData[typeKey];
    NSArray<ConfigField *> *itemFields = typeItems[indexPath.row];
    
    // 显示配置键和配置值
    ConfigField *keyField = itemFields[0]; // 配置键
    ConfigField *valueField = itemFields[1]; // 配置值
    cell.textLabel.text = keyField.value;
    cell.detailTextLabel.text = valueField.value;
    cell.detailTextLabel.textColor = [UIColor systemBlueColor];
    
    // 关键：根据配置项的isModified状态设置背景色
    NSString *configKey = keyField.value;
    for (ConfigItem *item in self.configItems) {
        if ([item.config_key isEqualToString:configKey]) {
            // 半透明绿色（alpha=0.2），未修改则为白色
            cell.backgroundColor = item.isModified ?
                [[UIColor greenColor] colorWithAlphaComponent:0.2] :
                [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.5];
            break;
        }
    }
    
    return cell;
}

#pragma mark - UITableView代理
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *sortedTypes = [self.sectionData.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSNumber *typeKey = sortedTypes[section];
    return [self typeTextForType:typeKey.integerValue];
}

// 点击行进入该配置项的详情编辑页
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 获取当前配置项的字段数组
    NSArray *sortedTypes = [self.sectionData.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSNumber *typeKey = sortedTypes[indexPath.section];
    NSArray *typeItems = self.sectionData[typeKey];
    NSArray<ConfigField *> *itemFields = typeItems[indexPath.row];
    
    // 弹出编辑框（或跳转编辑页），展示该配置项的所有字段
    [self showItemEditAlertWithFields:itemFields indexPath:indexPath];
}

// 左滑删除（删除当前配置项）
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        NSArray *sortedTypes = [self.sectionData.allKeys sortedArrayUsingSelector:@selector(compare:)];
        NSNumber *typeKey = sortedTypes[indexPath.section];
        NSMutableArray *typeItems = self.sectionData[typeKey];
        
        // 从分组中删除该配置项
        [typeItems removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // 若分组为空，删除整个分组
        if (typeItems.count == 0) {
            [self.sectionData removeObjectForKey:typeKey];
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        // 同时从原始数据中删除（用于提交时的数据一致性）
        [self.configItems removeObjectAtIndex:indexPath.row];
    }];
    return @[deleteAction];
}

// 编辑配置项的所有字段（修改后）
- (void)showItemEditAlertWithFields:(NSArray<ConfigField *> *)itemFields indexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"编辑配置项" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    // 为每个可编辑字段添加输入框
    NSMutableDictionary *textFields = [NSMutableDictionary dictionary];
    for (ConfigField *field in itemFields) {
        if (field.editable) {
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = field.fieldName;
                textField.text = field.value;
                textFields[field.fieldKey] = textField;
            }];
        }
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        BOOL hasChanges = NO;
        
        // 1. 先找到对应的ConfigItem（用于后续同步更新）
        ConfigItem *targetItem = nil;
        ConfigField *keyField = itemFields[0]; // 配置键字段（用于匹配ConfigItem）
        NSString *configKey = keyField.value;
        for (ConfigItem *item in self.configItems) {
            if ([item.config_key isEqualToString:configKey]) {
                targetItem = item;
                break;
            }
        }
        if (!targetItem) return; // 找不到对应项，直接返回
        
        // 2. 更新字段值，并同步到ConfigItem
        for (ConfigField *field in itemFields) {
            if (field.editable) {
                UITextField *textField = textFields[field.fieldKey];
                NSString *newValue = textField.text ?: @"";
                
                if (![newValue isEqualToString:field.value]) {
                    field.value = newValue;
                    hasChanges = YES;
                    
                    // 关键：同步更新ConfigItem的对应字段
                    if ([field.fieldKey isEqualToString:@"config_key"]) {
                        targetItem.config_key = newValue;
                    } else if ([field.fieldKey isEqualToString:@"config_value"]) {
                        targetItem.config_value = newValue; // 这里是你修改的字段，必须同步
                    } else if ([field.fieldKey isEqualToString:@"typeTextForType"]) {
                        targetItem.config_type = [self typeForText:newValue]; // 类型文本转数值
                    } else if ([field.fieldKey isEqualToString:@"db_description"]) {
                        targetItem.db_description = newValue;
                    } else if ([field.fieldKey isEqualToString:@"is_required"]) {
                        targetItem.is_required = [newValue isEqualToString:@"是"];
                    } else if ([field.fieldKey isEqualToString:@"sort"]) {
                        targetItem.sort = [newValue integerValue];
                    }
                }
            }
        }
        
        // 3. 如果有变化，标记修改并刷新
        if (hasChanges) {
            targetItem.isModified = YES; // 标记为已修改
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 底部提交按钮事件
- (void)submitChangesAction {
    // 收集所有修改过的配置项
    NSMutableArray<ConfigItem *> *modifiedItems = [NSMutableArray array];
    for (ConfigItem *item in self.configItems) {
        if (item.isModified) {
            [modifiedItems addObject:item];
        }
    }
    
    if (modifiedItems.count == 0) {
        [SVProgressHUD showInfoWithStatus:@"没有需要提交的修改"];
        [SVProgressHUD dismissWithDelay:1];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"提交中..."];
    
    // 逐个提交修改的配置项
    [self submitModifiedItems:modifiedItems index:0 successCount:0 failureCount:0];
}

// 递归提交修改的配置项
- (void)submitModifiedItems:(NSMutableArray<ConfigItem *> *)items index:(NSInteger)index successCount:(NSInteger)successCount failureCount:(NSInteger)failureCount {
    if (index >= items.count) {
        // 所有项提交完成
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (failureCount == 0) {
               
                [self showAlertWithConfirmationFromViewController:self title:@"提交成功" message:[NSString stringWithFormat:@"全部提交成功 (%ld项)", (long)successCount] confirmTitle:@"确定" cancelTitle:@"取消" onConfirmed:^{
                    
                     
                     // 重置所有修改标记
                     for (ConfigItem *item in self.configItems) {
                         item.isModified = NO;
                     }
                     
                     // 重新加载数据（可选，根据后端是否返回完整数据决定）
                     [self loadConfigData];
                } onCancelled:^{
                
                }];
               
            } else {
               
                [self showAlertFromViewController:self title:@"部分失败" message:[NSString stringWithFormat:@"部分提交失败 (%ld成功, %ld失败)", (long)successCount, (long)failureCount]];
            }
        });
        return;
    }
    
    ConfigItem *item = items[index];
    // 调用后端单个更新接口
    NSString *url = [NSString stringWithFormat:@"%@/admin/system_api.php", localURL];
    NSString *udid = [loadData sharedInstance].userModel.udid ?: @"";
    // 构建单个配置项的数据
    NSDictionary *params = @{
        @"action": @"updateConfig",
        @"udid": udid,
        
        @"config_key": item.config_key ?: @"",
        @"config_value": item.config_value ?: @"",
        @"config_type": @(item.config_type),
        @"db_description": item.db_description ?: @"",
        @"is_required": @(item.is_required),
        @"sort": @(item.sort)
    };
    
    [[NetworkClient sharedClient] sendRequestWithMethod:NetworkRequestMethodPOST urlString:url parameters:params udid:udid progress:nil success:^(NSDictionary *jsonResult, NSString *stringResult, NSData *dataResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger newSuccessCount = successCount;
            NSInteger newFailureCount = failureCount;
            
            if(!jsonResult && stringResult){
                NSLog(@"stringResult:%@", stringResult);
                newFailureCount++;
            } else {
                NSInteger code = [jsonResult[@"code"] integerValue];
                if (code == 200) {
                    newSuccessCount++;
                    
                    // 更新成功后，更新时间戳（可选）
                    item.update_time = [self currentTimeString];
                } else {
                    newFailureCount++;
                }
            }
            
            // 继续提交下一个
            [self submitModifiedItems:items index:index+1 successCount:newSuccessCount failureCount:newFailureCount];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"提交失败: %@", error.localizedDescription);
            [self submitModifiedItems:items index:index+1 successCount:successCount failureCount:failureCount+1];
        });
    }];
}

#pragma mark - 工具方法
- (NSString *)currentTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:[NSDate date]];
}

#pragma mark - 添加按钮

- (void)addConfigAction {
    // 创建新配置项（初始化为空值）
    ConfigItem *newItem = [[ConfigItem alloc] init];
    newItem.key_id = self.configItems.count + 1;
    newItem.config_type = 0; // 默认类型：基础信息
    newItem.is_required = NO;
    newItem.sort = 0;
    newItem.create_time = [self currentTimeString];
    newItem.update_time = [self currentTimeString];
    newItem.isModified = YES; // 新添加的项默认为已修改
    
    // 构建配置项的字段数组（用于弹窗显示）
    NSMutableArray<ConfigField *> *fields = [NSMutableArray array];
    [fields addObject:[self createFieldWithName:@"配置键" key:@"config_key" value:@"" editable:YES]];
    [fields addObject:[self createFieldWithName:@"配置值" key:@"config_value" value:@"" editable:YES]];
    [fields addObject:[self createFieldWithName:@"配置类型" key:@"config_type" value:[self typeTextForType:newItem.config_type] editable:YES]];
    [fields addObject:[self createFieldWithName:@"配置说明" key:@"db_description" value:@"" editable:YES]];
    [fields addObject:[self createFieldWithName:@"是否必填" key:@"is_required" value:@"否" editable:YES]];
    [fields addObject:[self createFieldWithName:@"排序权重" key:@"sort" value:@"0" editable:YES]];
    
    // 弹出添加配置的弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加配置项" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    // 为每个可编辑字段添加输入框
    NSMutableDictionary *textFields = [NSMutableDictionary dictionary];
    for (ConfigField *field in fields) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = field.fieldName;
            textField.text = field.value;
            textFields[field.fieldKey] = textField;
            
            // 配置类型和是否必填使用选择器
            if ([field.fieldKey isEqualToString:@"config_type"]) {
                textField.inputView = [self createTypePickerWithTextField:textField];
            } else if ([field.fieldKey isEqualToString:@"is_required"]) {
                textField.inputView = [self createRequiredPickerWithTextField:textField];
            }
        }];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // 获取用户输入
        NSString *configKey = ((UITextField *)textFields[@"config_key"]).text ?: @"";
        NSString *configValue = ((UITextField *)textFields[@"config_value"]).text ?: @"";
        NSString *typeText = ((UITextField *)textFields[@"config_type"]).text ?: @"基础信息";
        NSString *description = ((UITextField *)textFields[@"db_description"]).text ?: @"";
        NSString *isRequiredText = ((UITextField *)textFields[@"is_required"]).text ?: @"否";
        NSString *sortText = ((UITextField *)textFields[@"sort"]).text ?: @"0";
        
        // 验证输入
        if (![self validateConfigInputWithKey:configKey value:configValue]) {
            return;
        }
        
        // 转换输入值
        NSInteger configType = [self typeForText:typeText];
        BOOL isRequired = [isRequiredText isEqualToString:@"是"];
        NSInteger sort = [sortText integerValue];
        
        // 更新新配置项的值
        newItem.config_key = configKey;
        newItem.config_value = configValue;
        newItem.config_type = configType;
        newItem.db_description = description;
        newItem.is_required = isRequired;
        newItem.sort = sort;
        
        // 添加到数据源并刷新表格
        [self.configItems addObject:newItem];
        [self processSectionData];
        [self.tableView reloadData];
        
        // 滚动到新添加的配置项
        NSInteger section = [self sectionForConfigType:configType];
        NSInteger row = [self rowForConfigItem:newItem inSection:section];
        if (section != NSNotFound && row != NSNotFound) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                                     atScrollPosition:UITableViewScrollPositionMiddle
                                             animated:YES];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 验证配置输入
- (BOOL)validateConfigInputWithKey:(NSString *)key value:(NSString *)value {
    if (key.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"配置键不能为空"];
        return NO;
    }
    
    // 检查配置键是否已存在
    for (ConfigItem *item in self.configItems) {
        if ([item.config_key isEqualToString:key]) {
           
            [SVProgressHUD showErrorWithStatus:@"配置键已存在"];
            return NO;
        }
    }
    
    // 其他验证规则...
    
    return YES;
}

// 创建配置类型选择器
- (UIPickerView *)createTypePickerWithTextField:(UITextField *)textField {
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.delegate = self;
    picker.dataSource = self;
    picker.tag = 1; // 标记为配置类型选择器
    
    // 设置当前选中值
    NSInteger selectedRow = [self rowForTypeText:textField.text];
    [picker selectRow:selectedRow inComponent:0 animated:NO];
    
    // 添加完成按钮
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    [toolbar setItems:@[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(dismissPicker:)]
    ]];
    [toolbar sizeToFit];
    
    textField.inputAccessoryView = toolbar;
    return picker;
}

// 创建是否必填选择器
- (UIPickerView *)createRequiredPickerWithTextField:(UITextField *)textField {
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.delegate = self;
    picker.dataSource = self;
    picker.tag = 2; // 标记为是否必填选择器
    
    // 设置当前选中值
    NSInteger selectedRow = [textField.text isEqualToString:@"是"] ? 0 : 1;
    [picker selectRow:selectedRow inComponent:0 animated:NO];
    
    // 添加完成按钮
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    [toolbar setItems:@[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(dismissPicker:)]
    ]];
    [toolbar sizeToFit];
    
    textField.inputAccessoryView = toolbar;
    return picker;
}

// 关闭选择器
- (void)dismissPicker:(id)sender {
    [self.view endEditing:YES];
}

// 获取配置类型的文本对应的行号
- (NSInteger)rowForTypeText:(NSString *)text {
    if ([text isEqualToString:@"基础信息"]) return 0;
    if ([text isEqualToString:@"功能开关"]) return 1;
    if ([text isEqualToString:@"版本信息"]) return 2;
    if ([text isEqualToString:@"管理员配置"]) return 3;
    if ([text isEqualToString:@"其他"]) return 4;
    return 0;
}

// 获取配置类型文本对应的数值
- (NSInteger)typeForText:(NSString *)text {
    if ([text isEqualToString:@"基础信息"]) return 0;
    if ([text isEqualToString:@"功能开关"]) return 1;
    if ([text isEqualToString:@"版本信息"]) return 2;
    if ([text isEqualToString:@"管理员配置"]) return 3;
    if ([text isEqualToString:@"其他"]) return 4;
    return 0;
}

// 获取配置类型对应的分区索引
- (NSInteger)sectionForConfigType:(NSInteger)configType {
    NSArray *sortedTypes = [self.sectionData.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSInteger i = 0; i < sortedTypes.count; i++) {
        if ([sortedTypes[i] integerValue] == configType) {
            return i;
        }
    }
    return NSNotFound;
}

// 获取配置项在指定分区中的行号
- (NSInteger)rowForConfigItem:(ConfigItem *)item inSection:(NSInteger)section {
    NSArray *sortedTypes = [self.sectionData.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSNumber *typeKey = sortedTypes[section];
    NSArray<NSMutableArray<ConfigField *> *> *typeItems = self.sectionData[typeKey];
    
    // 查找配置项的索引
    for (NSInteger i = 0; i < typeItems.count; i++) {
        NSArray<ConfigField *> *itemFields = typeItems[i];
        ConfigField *keyField = itemFields[0];
        if ([keyField.value isEqualToString:item.config_key]) {
            return i;
        }
    }
    return NSNotFound;
}

#pragma mark - UIPickerView数据源和代理
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView.tag == 1) { // 配置类型选择器
        return 5; // 5种类型
    } else { // 是否必填选择器
        return 2; // 是/否
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView.tag == 1) { // 配置类型选择器
        return [self typeTextForType:row];
    } else { // 是否必填选择器
        return row == 0 ? @"是" : @"否";
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // 获取当前关联的文本框
    UITextField *textField = nil;
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UITextField class]] && [(UITextField *)view.inputView isEqual:pickerView]) {
            textField = (UITextField *)view;
            break;
        }
    }
    
    if (textField) {
        if (pickerView.tag == 1) { // 配置类型选择器
            textField.text = [self typeTextForType:row];
        } else { // 是否必填选择器
            textField.text = row == 0 ? @"是" : @"否";
        }
    }
}

@end
