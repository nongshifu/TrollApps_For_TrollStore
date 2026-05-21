//
//  PlistEditorViewController.m
//  SandboxFileManager
//
//  Plist/XML 编辑器
//

#import "PlistEditorViewController.h"
#import "FileNotification.h"
#import "NestedEditorViewController.h"
#import "ItemEditorViewController.h"

@interface PlistEditorViewController () <UITableViewDelegate, UITableViewDataSource, NestedEditorViewControllerDelegate, ItemEditorViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary *editingData;
@property (nonatomic, strong) NSMutableArray *keys;
@property (nonatomic, assign) NSInteger editingRow;

@end

@implementation PlistEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupNavigation];
    [self setupTableView];
    [self loadPlistFile];
}

- (void)setupNavigation {
    self.title = self.fileModel.fileName;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveFile)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddItemMenu)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItems = @[saveButton, addButton];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}

- (void)loadPlistFile {
    NSData *data = [NSData dataWithContentsOfFile:self.filePath];
    if (!data) {
        self.editingData = [NSMutableDictionary dictionary];
        self.keys = [NSMutableArray array];
        [self.tableView reloadData];
        return;
    }
    
    NSError *error = nil;
    id plistObject = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:nil error:&error];
    
    if (error || !plistObject) {
        [self showAlert:@"文件加载失败" message:error ? error.localizedDescription : @"无法解析文件"];
        self.editingData = [NSMutableDictionary dictionary];
        self.keys = [NSMutableArray array];
        [self.tableView reloadData];
        return;
    }
    
    if ([plistObject isKindOfClass:[NSMutableDictionary class]]) {
        self.editingData = plistObject;
    } else if ([plistObject isKindOfClass:[NSDictionary class]]) {
        self.editingData = [plistObject mutableCopy];
    } else {
        self.editingData = [NSMutableDictionary dictionary];
    }
    
    [self updateKeys];
    [self.tableView reloadData];
}

- (void)updateKeys {
    self.keys = [[self.editingData.allKeys sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
}

- (void)cancel {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveFile {
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.editingData
                                                             format:NSPropertyListXMLFormat_v1_0
                                                            options:0
                                                              error:&error];
    
    if (error) {
        [self showAlert:@"保存失败" message:error.localizedDescription];
        return;
    }
    
    BOOL success = [data writeToFile:self.filePath atomically:YES];
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self showAlert:@"保存失败" message:@"无法写入文件"];
    }
}

- (void)showAddItemMenu {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加项" message:@"选择添加的项类型" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"String" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddItemWithType:PlistItemTypeString];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Number" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddItemWithType:PlistItemTypeNumber];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Boolean" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddItemWithType:PlistItemTypeBoolean];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Array" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddItemWithType:PlistItemTypeArray];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Dictionary" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddItemWithType:PlistItemTypeDictionary];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Date" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddItemWithType:PlistItemTypeDate];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Data" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddItemWithType:PlistItemTypeData];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAddItemWithType:(PlistItemType)type {
    ItemEditorViewController *editor = [[ItemEditorViewController alloc] init];
    editor.delegate = self;
    editor.itemKey = [NSString stringWithFormat:@"New Item %lu", (unsigned long)(self.editingData.count + 1)];
    editor.itemType = type;
    
    switch (type) {
        case PlistItemTypeString:
            editor.itemValue = @"";
            break;
        case PlistItemTypeNumber:
            editor.itemValue = @0;
            break;
        case PlistItemTypeBoolean:
            editor.itemValue = @NO;
            break;
        case PlistItemTypeArray:
            editor.itemValue = [NSMutableArray array];
            break;
        case PlistItemTypeDictionary:
            editor.itemValue = [NSMutableDictionary dictionary];
            break;
        case PlistItemTypeDate:
            editor.itemValue = [NSDate date];
            break;
        case PlistItemTypeData:
            editor.itemValue = [NSData data];
            break;
    }
    
    self.editingRow = -1; // 标记为添加新模式
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)isBooleanNumber:(NSNumber *)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        const char *objCType = [value objCType];
        if (strcmp(objCType, @encode(BOOL)) == 0 || strcmp(objCType, "c") == 0 || strcmp(objCType, "B") == 0) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    NSString *key = self.keys[indexPath.row];
    id value = self.editingData[key];
    
    UIImageView *typeIcon = [[UIImageView alloc] init];
    typeIcon.contentMode = UIViewContentModeScaleAspectFit;
    typeIcon.frame = CGRectMake(15, (70 - 30) / 2, 30, 30);
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.frame = CGRectMake(55, 12, cell.contentView.bounds.size.width - 130, 22);
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.font = [UIFont systemFontOfSize:13];
    subtitleLabel.textColor = [UIColor secondaryLabelColor];
    subtitleLabel.frame = CGRectMake(55, 36, cell.contentView.bounds.size.width - 130, 18);
    
    titleLabel.text = key;
    
    if ([value isKindOfClass:[NSString class]]) {
        typeIcon.image = [UIImage systemImageNamed:@"textformat"];
        typeIcon.tintColor = [UIColor systemBlueColor];
        subtitleLabel.text = value;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if ([self isBooleanNumber:value]) {
            typeIcon.image = [UIImage systemImageNamed:@"switch.2"];
            typeIcon.tintColor = [UIColor systemGreenColor];
            subtitleLabel.text = [value boolValue] ? @"YES" : @"NO";
            
            UISwitch *boolSwitch = [[UISwitch alloc] init];
            boolSwitch.on = [value boolValue];
            boolSwitch.tag = indexPath.row;
            [boolSwitch addTarget:self action:@selector(boolSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = boolSwitch;
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            typeIcon.image = [UIImage systemImageNamed:@"number"];
            typeIcon.tintColor = [UIColor systemOrangeColor];
            subtitleLabel.text = [value stringValue];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        typeIcon.image = [UIImage systemImageNamed:@"square.stack.3d.up"];
        typeIcon.tintColor = [UIColor systemPurpleColor];
        subtitleLabel.text = [NSString stringWithFormat:@"Array (%lu items)", (unsigned long)[value count]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        typeIcon.image = [UIImage systemImageNamed:@"doc.text"];
        typeIcon.tintColor = [UIColor systemTealColor];
        subtitleLabel.text = [NSString stringWithFormat:@"Dictionary (%lu items)", (unsigned long)[value count]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([value isKindOfClass:[NSDate class]]) {
        typeIcon.image = [UIImage systemImageNamed:@"clock"];
        typeIcon.tintColor = [UIColor systemRedColor];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterMediumStyle;
        subtitleLabel.text = [formatter stringFromDate:value];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([value isKindOfClass:[NSData class]]) {
        typeIcon.image = [UIImage systemImageNamed:@"doc"];
        typeIcon.tintColor = [UIColor systemYellowColor];
        subtitleLabel.text = [NSString stringWithFormat:@"Data (%lu bytes)", (unsigned long)[value length]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        typeIcon.image = [UIImage systemImageNamed:@"questionmark.circle"];
        typeIcon.tintColor = [UIColor systemGrayColor];
        subtitleLabel.text = @"Unknown";
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell.contentView addSubview:typeIcon];
    [cell.contentView addSubview:titleLabel];
    [cell.contentView addSubview:subtitleLabel];
    
    return cell;
}

- (void)boolSwitchChanged:(UISwitch *)sender {
    NSInteger row = sender.tag;
    NSString *key = self.keys[row];
    self.editingData[key] = @(sender.isOn);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = self.keys[indexPath.row];
    id value = self.editingData[key];
    
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
        [self showNestedEditor:value forKey:key atIndexPath:indexPath];
    } else {
        [self showItemEditorForValue:value forKey:key atIndexPath:indexPath];
    }
}

- (void)showItemEditorForValue:(id)value forKey:(NSString *)key atIndexPath:(NSIndexPath *)indexPath {
    self.editingRow = indexPath.row;
    
    ItemEditorViewController *editor = [[ItemEditorViewController alloc] init];
    editor.delegate = self;
    editor.itemKey = key;
    editor.itemValue = value;
    
    // 自动检测类型
    if ([value isKindOfClass:[NSString class]]) {
        editor.itemType = PlistItemTypeString;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        const char *objCType = [value objCType];
        if (strcmp(objCType, @encode(BOOL)) == 0 || strcmp(objCType, "c") == 0 || strcmp(objCType, "B") == 0) {
            editor.itemType = PlistItemTypeBoolean;
        } else {
            editor.itemType = PlistItemTypeNumber;
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        editor.itemType = PlistItemTypeArray;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        editor.itemType = PlistItemTypeDictionary;
    } else if ([value isKindOfClass:[NSDate class]]) {
        editor.itemType = PlistItemTypeDate;
    } else if ([value isKindOfClass:[NSData class]]) {
        editor.itemType = PlistItemTypeData;
    }
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showNestedEditor:(id)data forKey:(NSString *)key atIndexPath:(NSIndexPath *)indexPath {
    NestedEditorViewController *nestedEditor = [[NestedEditorViewController alloc] init];
    nestedEditor.data = data;
    nestedEditor.itemKey = key;
    nestedEditor.delegate = self;
    [self.navigationController pushViewController:nestedEditor animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *key = self.keys[indexPath.row];
        [self.editingData removeObjectForKey:key];
        [self updateKeys];
        [self.tableView reloadData];
    }
}

#pragma mark - NestedEditorViewControllerDelegate

- (void)nestedEditorViewController:(UIViewController *)controller didUpdateData:(id)data {
    NestedEditorViewController *nestedEditor = (NestedEditorViewController *)controller;
    NSString *key = nestedEditor.itemKey;
    
    for (NSInteger i = 0; i < self.keys.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        if ([self.keys[i] isEqualToString:key]) {
            self.editingData[key] = data;
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
    }
}

#pragma mark - ItemEditorViewControllerDelegate

- (void)itemEditorViewController:(UIViewController *)controller didSaveItemWithKey:(NSString *)key value:(id)value {
    if (self.editingRow == -1) {
        // 添加新项
        self.editingData[key] = value;
        [self updateKeys];
    } else {
        // 编辑现有项
        NSString *oldKey = self.keys[self.editingRow];
        
        if (![oldKey isEqualToString:key]) {
            [self.editingData removeObjectForKey:oldKey];
        }
        
        self.editingData[key] = value;
        [self updateKeys];
    }
    [self.tableView reloadData];
}

- (void)itemEditorViewControllerDidDelete:(UIViewController *)controller {
    NSString *key = self.keys[self.editingRow];
    [self.editingData removeObjectForKey:key];
    [self updateKeys];
    [self.tableView reloadData];
}

- (void)itemEditorViewControllerDidCancel:(UIViewController *)controller {
}

@end
