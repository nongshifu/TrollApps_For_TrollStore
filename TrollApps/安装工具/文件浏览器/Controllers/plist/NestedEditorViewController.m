//
//  NestedEditorViewController.m
//  SandboxFileManager
//
//  嵌套结构编辑器（Array/Dictionary）
//

#import "NestedEditorViewController.h"
#import "ItemEditorViewController.h"

typedef NS_ENUM(NSInteger, EditorType) {
    EditorTypeArray,
    EditorTypeDictionary,
};

@interface NestedEditorViewController () <UITableViewDelegate, UITableViewDataSource, ItemEditorViewControllerDelegate, NestedEditorViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *arrayData;
@property (nonatomic, strong) NSMutableDictionary *dictData;
@property (nonatomic, strong) NSMutableArray *keys;
@property (nonatomic, assign) EditorType editorType;
@property (nonatomic, assign) NSInteger editingRow;

@end

@implementation NestedEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupEditorType];
    [self setupNavigation];
    [self setupTableView];
    [self updateKeys];
}

- (void)setupEditorType {
    if ([self.data isKindOfClass:[NSMutableArray class]]) {
        self.arrayData = self.data;
        self.editorType = EditorTypeArray;
    } else if ([self.data isKindOfClass:[NSArray class]]) {
        self.arrayData = [self.data mutableCopy];
        self.editorType = EditorTypeArray;
    } else if ([self.data isKindOfClass:[NSMutableDictionary class]]) {
        self.dictData = self.data;
        self.editorType = EditorTypeDictionary;
    } else if ([self.data isKindOfClass:[NSDictionary class]]) {
        self.dictData = [self.data mutableCopy];
        self.editorType = EditorTypeDictionary;
    }
}

- (void)setupNavigation {
    self.title = self.itemKey ?: (self.editorType == EditorTypeArray ? @"Array" : @"Dictionary");
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddItemMenu)];
    
    self.navigationItem.rightBarButtonItems = @[doneButton, addButton];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}

- (void)updateKeys {
    if (self.editorType == EditorTypeDictionary) {
        self.keys = [[self.dictData.allKeys sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
    }
    [self.tableView reloadData];
}

- (void)done {
    id result;
    if (self.editorType == EditorTypeArray) {
        result = [self.arrayData copy];
    } else {
        result = [self.dictData copy];
    }
    
    if ([self.delegate respondsToSelector:@selector(nestedEditorViewController:didUpdateData:)]) {
        [self.delegate nestedEditorViewController:self didUpdateData:result];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showAddItemMenu {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加项" message:@"选择添加的项类型" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"String" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showItemEditorForNewItemWithType:PlistItemTypeString];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Number" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showItemEditorForNewItemWithType:PlistItemTypeNumber];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Boolean" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showItemEditorForNewItemWithType:PlistItemTypeBoolean];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Array" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showItemEditorForNewItemWithType:PlistItemTypeArray];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Dictionary" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showItemEditorForNewItemWithType:PlistItemTypeDictionary];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Date" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showItemEditorForNewItemWithType:PlistItemTypeDate];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Data" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showItemEditorForNewItemWithType:PlistItemTypeData];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showItemEditorForNewItemWithType:(PlistItemType)type {
    ItemEditorViewController *editor = [[ItemEditorViewController alloc] init];
    editor.delegate = self;
    
    if (self.editorType == EditorTypeDictionary) {
        editor.itemKey = [NSString stringWithFormat:@"New Item %lu", (unsigned long)(self.dictData.count + 1)];
    }
    
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
    if (self.editorType == EditorTypeArray) {
        return self.arrayData.count;
    }
    return self.keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    id value;
    NSString *key;
    if (self.editorType == EditorTypeArray) {
        value = self.arrayData[indexPath.row];
        key = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    } else {
        key = self.keys[indexPath.row];
        value = self.dictData[key];
    }
    
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
            [boolSwitch addTarget:self action:@selector(boolSwitchChanged:event:) forControlEvents:UIControlEventValueChanged];
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

- (void)boolSwitchChanged:(UISwitch *)sender event:(UIEvent *)event {
    NSInteger row = sender.tag;
    if (self.editorType == EditorTypeArray) {
        self.arrayData[row] = @(sender.isOn);
    } else {
        NSString *key = self.keys[row];
        self.dictData[key] = @(sender.isOn);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id value;
    NSString *key;
    if (self.editorType == EditorTypeArray) {
        value = self.arrayData[indexPath.row];
        key = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    } else {
        key = self.keys[indexPath.row];
        value = self.dictData[key];
    }
    
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
        if (self.editorType == EditorTypeArray) {
            [self.arrayData removeObjectAtIndex:indexPath.row];
        } else {
            NSString *key = self.keys[indexPath.row];
            [self.dictData removeObjectForKey:key];
            [self updateKeys];
        }
        [self.tableView reloadData];
    }
}

#pragma mark - NestedEditorViewControllerDelegate

- (void)nestedEditorViewController:(UIViewController *)controller didUpdateData:(id)data {
    NestedEditorViewController *nestedEditor = (NestedEditorViewController *)controller;
    NSString *key = nestedEditor.itemKey;
    
    NSInteger rowCount = (self.editorType == EditorTypeArray) ? self.arrayData.count : self.keys.count;
    for (NSInteger i = 0; i < rowCount; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        id currentValue;
        NSString *currentKey;
        
        if (self.editorType == EditorTypeArray) {
            currentKey = [NSString stringWithFormat:@"%ld", (long)i];
            currentValue = self.arrayData[i];
        } else {
            currentKey = self.keys[i];
            currentValue = self.dictData[currentKey];
        }
        
        if ([currentKey isEqualToString:key]) {
            if (self.editorType == EditorTypeArray) {
                self.arrayData[i] = data;
            } else {
                self.dictData[key] = data;
            }
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
    }
}

#pragma mark - ItemEditorViewControllerDelegate

- (void)itemEditorViewController:(UIViewController *)controller didSaveItemWithKey:(NSString *)key value:(id)value {
    if (self.editingRow == -1) {
        // 添加新项
        if (self.editorType == EditorTypeArray) {
            [self.arrayData addObject:value];
        } else {
            self.dictData[key] = value;
            [self updateKeys];
        }
    } else {
        // 编辑现有项
        if (self.editorType == EditorTypeArray) {
            self.arrayData[self.editingRow] = value;
        } else {
            NSString *oldKey = self.keys[self.editingRow];
            if (![oldKey isEqualToString:key]) {
                [self.dictData removeObjectForKey:oldKey];
            }
            self.dictData[key] = value;
            [self updateKeys];
        }
    }
    [self.tableView reloadData];
}

- (void)itemEditorViewControllerDidDelete:(UIViewController *)controller {
    if (self.editorType == EditorTypeArray) {
        [self.arrayData removeObjectAtIndex:self.editingRow];
    } else {
        NSString *key = self.keys[self.editingRow];
        [self.dictData removeObjectForKey:key];
        [self updateKeys];
    }
    [self.tableView reloadData];
}

- (void)itemEditorViewControllerDidCancel:(UIViewController *)controller {
}

@end
