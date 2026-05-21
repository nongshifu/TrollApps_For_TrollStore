//
//  PlistEditDetailVC.m
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/15.
//

#import "PlistEditDetailVC.h"
#import "PlistNode.h"

@interface PlistEditDetailVC ()
@property (nonatomic, assign) PlistType currentType;
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UISwitch *boolSwitch;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, assign) BOOL useTimestamp;
@end

@implementation PlistEditDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"编辑项";
    self.currentType = self.node.type;
    self.useTimestamp = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(saveAction)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4; // Key + Type + Value + Delete
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 1;
    if (section == 2) return 1;
    if (section == 3) return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Key 名称";
        self.keyField = [[UITextField alloc] initWithFrame:CGRectMake(120, 0, self.view.bounds.size.width-140, 44)];
        self.keyField.text = self.node.key;
        [cell.contentView addSubview:self.keyField];
    }
    else if (indexPath.section == 1) {
        cell.textLabel.text = @"类型";
        cell.detailTextLabel.text = [self typeString:self.currentType];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if (indexPath.section == 2) {
        [self setupValueCell:cell type:self.currentType];
    }
    else if (indexPath.section == 3) {
        cell.textLabel.text = @"删除该项";
        cell.textLabel.textColor = UIColor.redColor;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        [self showTypePicker];
    }
    if (indexPath.section == 3) {
        [self deleteAction];
    }
}

- (void)setupValueCell:(UITableViewCell *)cell type:(PlistType)type {
    cell.textLabel.text = @"值";
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];
    
    if (type == PlistTypeString) {
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 5, self.view.bounds.size.width-20, 120)];
        self.textView.text = self.node.value;
        self.textView.layer.borderColor = UIColor.lightGrayColor.CGColor;
        self.textView.layer.borderWidth = 1;
        [cell.contentView addSubview:self.textView];
    }
    else if (type == PlistTypeNumber) {
        self.keyField = [[UITextField alloc] initWithFrame:CGRectMake(120, 0, self.view.bounds.size.width-140, 44)];
        self.keyField.keyboardType = UIKeyboardTypeDecimalPad;
        self.keyField.text = [NSString stringWithFormat:@"%@", self.node.value];
        [cell.contentView addSubview:self.keyField];
    }
    else if (type == PlistTypeBool) {
        cell.textLabel.text = @"开关值";
        self.boolSwitch = [[UISwitch alloc] init];
        self.boolSwitch.on = [self.node.value boolValue];
        cell.accessoryView = self.boolSwitch;
    }
    else if (type == PlistTypeDate) {
        self.datePicker = [[UIDatePicker alloc] init];
        self.datePicker.frame = CGRectMake(100, 0, self.view.bounds.size.width-120, 44);
        self.datePicker.date = [self dateFromValue:self.node.value];
        [cell.contentView addSubview:self.datePicker];
        
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"标准日期",@"时间戳"]];
        seg.frame = CGRectMake(10,50,250,30);
        seg.selectedSegmentIndex = self.useTimestamp;
        [seg addAction:[UIAction actionWithHandler:^(UIAction * _Nonnull action) {
            self.useTimestamp = seg.selectedSegmentIndex == 1;
        }] forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:seg];
    }
}

- (void)showTypePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *types = @[@"String",@"Number",@"Bool",@"Date",@"Array",@"Dict"];
    for (int i=0; i<types.count; i++) {
        [alert addAction:[UIAlertAction actionWithTitle:types[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.currentType = i;
            self.node.type = i;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteAction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:@"删除后无法恢复" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (self.onDelete) self.onDelete();
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)typeString:(PlistType)t {
    NSArray *a = @[@"String",@"Number",@"Bool",@"Date",@"Array",@"Dict"];
    return a[t];
}

- (NSDate *)dateFromValue:(id)v {
    if ([v isKindOfClass:NSNumber.class]) {
        return [NSDate dateWithTimeIntervalSince1970:[v doubleValue]];
    }
    NSDateFormatter *f = [NSDateFormatter new];
    f.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [f dateFromString:v] ?: NSDate.date;
}

- (void)saveAction {
    // 保存 Key
    if (self.keyField && self.keyField.text) {
        self.node.key = self.keyField.text;
    }
    
    // 保存 Value 根据类型
    switch (self.currentType) {
        case PlistTypeString:
            if (self.textView) {
                self.node.value = self.textView.text;
            }
            break;
        case PlistTypeNumber:
            if (self.keyField && self.keyField.text) {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                self.node.value = [formatter numberFromString:self.keyField.text];
            }
            break;
        case PlistTypeBool:
            if (self.boolSwitch) {
                self.node.value = @(self.boolSwitch.on);
            }
            break;
        case PlistTypeDate:
            if (self.datePicker) {
                if (self.useTimestamp) {
                    self.node.value = @([self.datePicker.date timeIntervalSince1970]);
                } else {
                    NSDateFormatter *f = [NSDateFormatter new];
                    f.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                    self.node.value = [f stringFromDate:self.datePicker.date];
                }
            }
            break;
        case PlistTypeArray:
            self.node.value = [NSMutableArray array];
            self.node.children = [NSMutableArray array];
            break;
        case PlistTypeDictionary:
            self.node.value = [NSMutableDictionary dictionary];
            self.node.children = [NSMutableArray array];
            break;
    }
    
    self.node.type = self.currentType;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
