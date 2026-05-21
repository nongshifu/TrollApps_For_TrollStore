//
//  ItemEditorViewController.m
//  SandboxFileManager
//
//  Plist 项编辑器（类似 Filza）
//

#import "ItemEditorViewController.h"
#import "NestedEditorViewController.h"

@interface ItemEditorViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, NestedEditorViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *editingKey;
@property (nonatomic, strong) id editingValue;
@property (nonatomic, assign) PlistItemType editingType;
@property (nonatomic, strong) UITextField *keyTextField;
@property (nonatomic, strong) UITextView *stringTextView;
@property (nonatomic, strong) UITextField *numberTextField;
@property (nonatomic, strong) UISwitch *boolSwitch;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UISegmentedControl *dateTypeSegmentedControl;
@property (nonatomic, strong) UITextField *dataTextField;
@property (nonatomic, strong) UIView *datePickerContainerView;
@property (nonatomic, strong) UIButton *datePickerDoneButton;

@end

@implementation ItemEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupInitialValues];
    [self setupNavigation];
    [self setupTableView];
}

- (void)setupInitialValues {
    self.editingKey = self.itemKey ?: @"";
    self.editingType = self.itemType;
    
    if (self.itemValue) {
        if ([self.itemValue isKindOfClass:[NSString class]]) {
            self.editingType = PlistItemTypeString;
            self.editingValue = self.itemValue;
        } else if ([self.itemValue isKindOfClass:[NSNumber class]]) {
            const char *objCType = [self.itemValue objCType];
            if (strcmp(objCType, @encode(BOOL)) == 0 || strcmp(objCType, "c") == 0 || strcmp(objCType, "B") == 0) {
                self.editingType = PlistItemTypeBoolean;
            } else {
                self.editingType = PlistItemTypeNumber;
            }
            self.editingValue = self.itemValue;
        } else if ([self.itemValue isKindOfClass:[NSArray class]]) {
            self.editingType = PlistItemTypeArray;
            self.editingValue = [self.itemValue mutableCopy];
        } else if ([self.itemValue isKindOfClass:[NSDictionary class]]) {
            self.editingType = PlistItemTypeDictionary;
            self.editingValue = [self.itemValue mutableCopy];
        } else if ([self.itemValue isKindOfClass:[NSDate class]]) {
            self.editingType = PlistItemTypeDate;
            self.editingValue = self.itemValue;
        } else if ([self.itemValue isKindOfClass:[NSData class]]) {
            self.editingType = PlistItemTypeData;
            self.editingValue = self.itemValue;
        }
    } else {
        [self resetValueForType:self.editingType];
    }
}

- (void)resetValueForType:(PlistItemType)type {
    switch (type) {
        case PlistItemTypeString:
            self.editingValue = @"";
            break;
        case PlistItemTypeNumber:
            self.editingValue = @0;
            break;
        case PlistItemTypeBoolean:
            self.editingValue = @NO;
            break;
        case PlistItemTypeArray:
            self.editingValue = [NSMutableArray array];
            break;
        case PlistItemTypeDictionary:
            self.editingValue = [NSMutableDictionary dictionary];
            break;
        case PlistItemTypeDate:
            self.editingValue = [NSDate date];
            break;
        case PlistItemTypeData:
            self.editingValue = [NSData data];
            break;
    }
}

- (void)setupNavigation {
    self.title = @"编辑项";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}

- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(itemEditorViewControllerDidCancel:)]) {
        [self.delegate itemEditorViewControllerDidCancel:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    if ([self.delegate respondsToSelector:@selector(itemEditorViewController:didSaveItemWithKey:value:)]) {
        // 确保从keyTextField获取最新的key
        NSString *finalKey = self.keyTextField.text ?: self.editingKey ?: @"";
        id finalValue = [self getFinalValue];
        [self.delegate itemEditorViewController:self didSaveItemWithKey:finalKey value:finalValue];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (id)getFinalValue {
    // 确保在获取最终值时也从UI控件获取最新的数据
    switch (self.editingType) {
        case PlistItemTypeString:
            return self.stringTextView.text ?: @"";
        case PlistItemTypeNumber:
            if (self.numberTextField.text.length > 0) {
                return @([self.numberTextField.text doubleValue]);
            }
            return @0;
        case PlistItemTypeBoolean:
            return @(self.boolSwitch.isOn);
        case PlistItemTypeArray:
            return [self.editingValue copy];
        case PlistItemTypeDictionary:
            return [self.editingValue copy];
        case PlistItemTypeDate:
            return self.editingValue;
        case PlistItemTypeData:
            if (self.dataTextField.text.length > 0) {
                return [[NSData alloc] initWithBase64EncodedString:self.dataTextField.text options:0];
            }
            return [NSData data];
        default:
            return nil;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 1;
        case 1: return 1;
        case 2: return [self valueRowCount];
        case 3: return 1;
        default: return 0;
    }
}

- (NSInteger)valueRowCount {
    if (self.editingType == PlistItemTypeArray || self.editingType == PlistItemTypeDictionary) {
        id data = self.editingValue;
        NSInteger count = 0;
        if ([data isKindOfClass:[NSArray class]]) {
            count = [(NSArray *)data count];
        } else if ([data isKindOfClass:[NSDictionary class]]) {
            count = [(NSDictionary *)data count];
        }
        return count + 1;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"名称";
        case 1: return @"类型";
        case 2: return @"值";
        case 3: return @"";
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    switch (indexPath.section) {
        case 0:
            [self configureNameCell:cell];
            break;
        case 1:
            [self configureTypeCell:cell];
            break;
        case 2:
            [self configureValueCell:cell atIndexPath:indexPath];
            break;
        case 3:
            [self configureDeleteCell:cell];
            break;
    }
    
    return cell;
}

- (void)configureNameCell:(UITableViewCell *)cell {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    self.keyTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 8, cell.contentView.bounds.size.width - 30, 30)];
    self.keyTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.keyTextField.font = [UIFont systemFontOfSize:14];
    self.keyTextField.placeholder = @"输入名称";
    self.keyTextField.delegate = self;
    self.keyTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [cell.contentView addSubview:self.keyTextField];
    
}

- (void)configureTypeCell:(UITableViewCell *)cell {
    cell.textLabel.text = [self typeNameForType:self.editingType];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureValueCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (self.editingType == PlistItemTypeArray || self.editingType == PlistItemTypeDictionary) {
        [self configureArrayOrDictValueCell:cell atIndexPath:indexPath];
        return;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (self.editingType) {
        case PlistItemTypeString:
            [self configureStringValueCell:cell];
            break;
        case PlistItemTypeNumber:
            [self configureNumberValueCell:cell];
            break;
        case PlistItemTypeBoolean:
            [self configureBooleanValueCell:cell];
            break;
        case PlistItemTypeDate:
            [self configureDateValueCell:cell];
            break;
        case PlistItemTypeData:
            [self configureDataValueCell:cell];
            break;
        default:
            break;
    }
}

- (void)configureArrayOrDictValueCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSInteger count = [self valueRowCount];
    
    if (indexPath.row == count - 1) {
        cell.textLabel.text = @"添加项...";
        cell.textLabel.textColor = [UIColor systemBlueColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return;
    }
    
    id value;
    NSString *key;
    
    if (self.editingType == PlistItemTypeArray) {
        NSArray *array = (NSArray *)self.editingValue;
        value = array[indexPath.row];
        key = [NSString stringWithFormat:@"Item %ld", (long)indexPath.row];
    } else {
        NSDictionary *dict = (NSDictionary *)self.editingValue;
        NSArray *keys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        key = keys[indexPath.row];
        value = dict[key];
    }
    
    cell.textLabel.text = key;
    
    if ([value isKindOfClass:[NSString class]]) {
        cell.detailTextLabel.text = value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        const char *objCType = [value objCType];
        if (strcmp(objCType, @encode(BOOL)) == 0 || strcmp(objCType, "c") == 0 || strcmp(objCType, "B") == 0) {
            cell.detailTextLabel.text = [value boolValue] ? @"YES" : @"NO";
        } else {
            cell.detailTextLabel.text = [value stringValue];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Array (%lu)", (unsigned long)[(NSArray *)value count]];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Dictionary (%lu)", (unsigned long)[(NSDictionary *)value count]];
    } else if ([value isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterMediumStyle;
        cell.detailTextLabel.text = [formatter stringFromDate:(NSDate *)value];
    } else if ([value isKindOfClass:[NSData class]]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Data (%lu bytes)", (unsigned long)[(NSData *)value length]];
    } else {
        cell.detailTextLabel.text = @"Unknown";
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureStringValueCell:(UITableViewCell *)cell {
    self.stringTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.bounds.size.width, 120)];
    self.stringTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.stringTextView.font = [UIFont systemFontOfSize:16];
    self.stringTextView.text = [self.editingValue isKindOfClass:[NSString class]] ? self.editingValue : @"";
    self.stringTextView.delegate = self;
    self.stringTextView.backgroundColor = [UIColor systemGray4Color];
    self.stringTextView.layer.cornerRadius = 15;
    self.stringTextView.layer.borderWidth = 1;
    self.stringTextView.layer.borderColor = [UIColor tertiaryLabelColor].CGColor;
    [cell.contentView addSubview:self.stringTextView];
}

- (void)configureNumberValueCell:(UITableViewCell *)cell {
    self.numberTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 8, cell.contentView.bounds.size.width - 30, 30)];
    self.numberTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.numberTextField.font = [UIFont systemFontOfSize:16];
    self.numberTextField.text = [self.editingValue isKindOfClass:[NSNumber class]] ? [self.editingValue stringValue] : @"0";
    self.numberTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.numberTextField.delegate = self;
    self.numberTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [cell.contentView addSubview:self.numberTextField];
}

- (void)configureBooleanValueCell:(UITableViewCell *)cell {
    cell.textLabel.text = [self.editingValue boolValue] ? @"YES" : @"NO";
    self.boolSwitch = [[UISwitch alloc] init];
    self.boolSwitch.on = [self.editingValue boolValue];
    [self.boolSwitch addTarget:self action:@selector(boolSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.boolSwitch;
}

- (void)configureDateValueCell:(UITableViewCell *)cell {
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    NSDate *date = [self.editingValue isKindOfClass:[NSDate class]] ? self.editingValue : [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;
    cell.textLabel.text = [formatter stringFromDate:date];
    
    cell.detailTextLabel.text = @"点击编辑";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureDataValueCell:(UITableViewCell *)cell {
    self.dataTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 8, cell.contentView.bounds.size.width - 30, 30)];
    self.dataTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.dataTextField.font = [UIFont systemFontOfSize:14];
    self.dataTextField.placeholder = @"Base64 编码数据";
    if ([self.editingValue isKindOfClass:[NSData class]]) {
        self.dataTextField.text = [(NSData *)self.editingValue base64EncodedStringWithOptions:0];
    }
    self.dataTextField.delegate = self;
    self.dataTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [cell.contentView addSubview:self.dataTextField];
}

- (void)configureDeleteCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"删除";
    cell.textLabel.textColor = [UIColor systemRedColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.backgroundColor = [UIColor systemRedColor];
    cell.textLabel.textColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && self.editingType == PlistItemTypeString) {
        return 120;
    }
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 1:
            [self showTypeSelector];
            break;
        case 2:
            [self handleValueRowSelection:indexPath];
            break;
        case 3:
            [self showDeleteConfirmation];
            break;
    }
}

- (void)showTypeSelector {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"变更类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *types = @[
        @{@"type": @(PlistItemTypeString), @"name": @"String"},
        @{@"type": @(PlistItemTypeNumber), @"name": @"Number"},
        @{@"type": @(PlistItemTypeBoolean), @"name": @"Boolean"},
        @{@"type": @(PlistItemTypeArray), @"name": @"Array"},
        @{@"type": @(PlistItemTypeDictionary), @"name": @"Dictionary"},
        @{@"type": @(PlistItemTypeDate), @"name": @"Date"},
        @{@"type": @(PlistItemTypeData), @"name": @"Data"},
    ];
    
    for (NSDictionary *typeInfo in types) {
        [alert addAction:[UIAlertAction actionWithTitle:typeInfo[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            PlistItemType newType = [typeInfo[@"type"] integerValue];
            if (newType != self.editingType) {
                self.editingType = newType;
                [self resetValueForType:newType];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.tableView;
        alert.popoverPresentationController.sourceRect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleValueRowSelection:(NSIndexPath *)indexPath {
    if (self.editingType == PlistItemTypeArray || self.editingType == PlistItemTypeDictionary) {
        NSInteger count = [self valueRowCount];
        
        if (indexPath.row == count - 1) {
            [self showAddItemMenu];
            return;
        }
        
        id value;
        NSString *key;
        
        if (self.editingType == PlistItemTypeArray) {
            NSMutableArray *array = (NSMutableArray *)self.editingValue;
            value = array[indexPath.row];
            key = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
        } else {
            NSMutableDictionary *dict = (NSMutableDictionary *)self.editingValue;
            NSArray *keys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
            key = keys[indexPath.row];
            value = dict[key];
        }
        
        if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
            [self showNestedEditor:value forKey:key atIndexPath:indexPath];
        } else {
            [self showSimpleEditor:value forKey:key atIndexPath:indexPath];
        }
    } else if (self.editingType == PlistItemTypeDate) {
        [self showDatePicker];
    }
}

- (void)showAddItemMenu {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加项" message:@"选择添加的项类型" preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *types = @[
        @{@"type": @(PlistItemTypeString), @"name": @"String"},
        @{@"type": @(PlistItemTypeNumber), @"name": @"Number"},
        @{@"type": @(PlistItemTypeBoolean), @"name": @"Boolean"},
        @{@"type": @(PlistItemTypeArray), @"name": @"Array"},
        @{@"type": @(PlistItemTypeDictionary), @"name": @"Dictionary"},
        @{@"type": @(PlistItemTypeDate), @"name": @"Date"},
        @{@"type": @(PlistItemTypeData), @"name": @"Data"},
    ];
    
    for (NSDictionary *typeInfo in types) {
        [alert addAction:[UIAlertAction actionWithTitle:typeInfo[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            PlistItemType type = [typeInfo[@"type"] integerValue];
            id value = [self createDefaultValueForType:type];
            
            if (self.editingType == PlistItemTypeArray) {
                NSMutableArray *array = (NSMutableArray *)self.editingValue;
                [array addObject:value];
            } else {
                NSMutableDictionary *dict = (NSMutableDictionary *)self.editingValue;
                NSString *newKey = [NSString stringWithFormat:@"New Item %ld", (long)dict.count + 1];
                dict[newKey] = value;
            }
            
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.tableView;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (id)createDefaultValueForType:(PlistItemType)type {
    switch (type) {
        case PlistItemTypeString: return @"";
        case PlistItemTypeNumber: return @0;
        case PlistItemTypeBoolean: return @NO;
        case PlistItemTypeArray: return [NSMutableArray array];
        case PlistItemTypeDictionary: return [NSMutableDictionary dictionary];
        case PlistItemTypeDate: return [NSDate date];
        case PlistItemTypeData: return [NSData data];
        default: return nil;
    }
}

- (void)showSimpleEditor:(id)value forKey:(NSString *)key atIndexPath:(NSIndexPath *)indexPath {
    NSString *title = [self typeNameForType:[self typeForValue:value]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"编辑值" message:key preferredStyle:UIAlertControllerStyleAlert];
    
    if ([value isKindOfClass:[NSString class]]) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = value;
        }];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        const char *objCType = [value objCType];
        if (strcmp(objCType, @encode(BOOL)) == 0 || strcmp(objCType, "c") == 0 || strcmp(objCType, "B") == 0) {
            UISwitch *switchView = [[UISwitch alloc] init];
            switchView.on = [value boolValue];
            [alert.view addSubview:switchView];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self updateValue:@(switchView.isOn) atIndexPath:indexPath];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        } else {
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.text = [value stringValue];
                textField.keyboardType = UIKeyboardTypeDecimalPad;
            }];
        }
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *textValue = alert.textFields.firstObject.text;
        if ([value isKindOfClass:[NSString class]]) {
            [self updateValue:textValue ?: @"" atIndexPath:indexPath];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [self updateValue:@([textValue doubleValue]) atIndexPath:indexPath];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateValue:(id)value atIndexPath:(NSIndexPath *)indexPath {
    if (self.editingType == PlistItemTypeArray) {
        NSMutableArray *array = (NSMutableArray *)self.editingValue;
        array[indexPath.row] = value;
    } else {
        NSMutableDictionary *dict = (NSMutableDictionary *)self.editingValue;
        NSArray *keys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSString *key = keys[indexPath.row];
        dict[key] = value;
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)showNestedEditor:(id)data forKey:(NSString *)key atIndexPath:(NSIndexPath *)indexPath {
    NestedEditorViewController *nestedEditor = [[NestedEditorViewController alloc] init];
    nestedEditor.data = data;
    nestedEditor.itemKey = key;
    nestedEditor.delegate = self;
    [self.navigationController pushViewController:nestedEditor animated:YES];
}

- (void)showDatePicker {
    CGFloat containerHeight = 280;
    CGRect containerFrame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, containerHeight);
    
    self.datePickerContainerView = [[UIView alloc] initWithFrame:containerFrame];
    self.datePickerContainerView.backgroundColor = [UIColor systemBackgroundColor];
    self.datePickerContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.datePickerContainerView.layer.shadowOpacity = 0.1;
    self.datePickerContainerView.layer.shadowOffset = CGSizeMake(0, -2);
    self.datePickerContainerView.layer.shadowRadius = 4;
    
    UIView *toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    toolbar.backgroundColor = [UIColor systemGray5Color];
    [self.datePickerContainerView addSubview:toolbar];
    
    self.datePickerDoneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.datePickerDoneButton setTitle:@"确定" forState:UIControlStateNormal];
    self.datePickerDoneButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.datePickerDoneButton addTarget:self action:@selector(datePickerDone:) forControlEvents:UIControlEventTouchUpInside];
    self.datePickerDoneButton.frame = CGRectMake(self.view.bounds.size.width - 60 - 15, 7, 60, 30);
    [toolbar addSubview:self.datePickerDoneButton];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [cancelButton addTarget:self action:@selector(datePickerCancel:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.frame = CGRectMake(15, 7, 60, 30);
    [toolbar addSubview:cancelButton];
    
    self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 160)];
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    self.datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    if ([self.editingValue isKindOfClass:[NSDate class]]) {
        self.datePicker.date = (NSDate *)self.editingValue;
    }
    [self.datePickerContainerView addSubview:self.datePicker];
    
    UIView *segmentedBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 210, self.view.bounds.size.width, 50)];
    segmentedBackground.backgroundColor = [UIColor systemBackgroundColor];
    [self.datePickerContainerView addSubview:segmentedBackground];
    
    self.dateTypeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"标准日期", @"时间戳"]];
    self.dateTypeSegmentedControl.frame = CGRectMake(20, 220, self.view.bounds.size.width - 40, 30);
    self.dateTypeSegmentedControl.selectedSegmentIndex = 0;
    [self.datePickerContainerView addSubview:self.dateTypeSegmentedControl];
    
    [self.view addSubview:self.datePickerContainerView];
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect newFrame = self.datePickerContainerView.frame;
        newFrame.origin.y = self.view.bounds.size.height - containerHeight;
        self.datePickerContainerView.frame = newFrame;
    }];
}

- (void)datePickerDone:(UIButton *)sender {
    if (self.dateTypeSegmentedControl.selectedSegmentIndex == 0) {
        self.editingValue = self.datePicker.date;
    } else {
        NSTimeInterval timestamp = [self.datePicker.date timeIntervalSince1970];
        self.editingValue = @(timestamp);
    }
    [self hideDatePicker];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)datePickerCancel:(UIButton *)sender {
    [self hideDatePicker];
}

- (void)hideDatePicker {
    [UIView animateWithDuration:0.3 animations:^{
        CGRect newFrame = self.datePickerContainerView.frame;
        newFrame.origin.y = self.view.bounds.size.height;
        self.datePickerContainerView.frame = newFrame;
    } completion:^(BOOL finished) {
        [self.datePickerContainerView removeFromSuperview];
        self.datePickerContainerView = nil;
        self.datePickerDoneButton = nil;
    }];
}

- (void)showDeleteConfirmation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:@"确定要删除此项吗？" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        if ([self.delegate respondsToSelector:@selector(itemEditorViewControllerDidDelete:)]) {
            [self.delegate itemEditorViewControllerDidDelete:self];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)boolSwitchChanged:(UISwitch *)sender {
    self.editingValue = @(sender.isOn);
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.keyTextField) {
        self.editingKey = textField.text ?: @"";
    } else if (textField == self.numberTextField) {
        self.editingValue = @([textField.text doubleValue]);
    } else if (textField == self.dataTextField) {
        if (textField.text.length > 0) {
            self.editingValue = [[NSData alloc] initWithBase64EncodedString:textField.text options:0];
        } else {
            self.editingValue = [NSData data];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.keyTextField) {
        // 实时更新editingKey
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        self.editingKey = newText;
    }
    return YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.stringTextView) {
        self.editingValue = textView.text ?: @"";
    }
}

#pragma mark - NestedEditorViewControllerDelegate

- (void)nestedEditorViewController:(UIViewController *)controller didUpdateData:(id)data {
    NestedEditorViewController *nestedEditor = (NestedEditorViewController *)controller;
    NSString *key = nestedEditor.itemKey;
    
    if (self.editingType == PlistItemTypeArray) {
        NSMutableArray *array = (NSMutableArray *)self.editingValue;
        NSInteger index = [key integerValue];
        if (index < array.count) {
            array[index] = data;
        }
    } else {
        NSMutableDictionary *dict = (NSMutableDictionary *)self.editingValue;
        dict[key] = data;
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSString *)typeNameForType:(PlistItemType)type {
    switch (type) {
        case PlistItemTypeString: return @"String";
        case PlistItemTypeNumber: return @"Number";
        case PlistItemTypeBoolean: return @"Boolean";
        case PlistItemTypeArray: return @"Array";
        case PlistItemTypeDictionary: return @"Dictionary";
        case PlistItemTypeDate: return @"Date";
        case PlistItemTypeData: return @"Data";
        default: return @"Unknown";
    }
}

- (PlistItemType)typeForValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) return PlistItemTypeString;
    if ([value isKindOfClass:[NSNumber class]]) {
        const char *objCType = [value objCType];
        if (strcmp(objCType, @encode(BOOL)) == 0 || strcmp(objCType, "c") == 0 || strcmp(objCType, "B") == 0) {
            return PlistItemTypeBoolean;
        }
        return PlistItemTypeNumber;
    }
    if ([value isKindOfClass:[NSArray class]]) return PlistItemTypeArray;
    if ([value isKindOfClass:[NSDictionary class]]) return PlistItemTypeDictionary;
    if ([value isKindOfClass:[NSDate class]]) return PlistItemTypeDate;
    if ([value isKindOfClass:[NSData class]]) return PlistItemTypeData;
    return PlistItemTypeString;
}

@end
