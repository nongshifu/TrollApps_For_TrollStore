//
//  PlistEditorVC.m
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/15.
//

#import "PlistEditorVC.h"
#import "PlistEditDetailVC.h"
#import "PlistNode.h"

@interface PlistEditorVC ()
@end

@implementation PlistEditorVC

+ (instancetype)editorWithFile:(NSString *)filePath {
    PlistEditorVC *vc = [[PlistEditorVC alloc] init];
    vc.filePath = filePath;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Plist 编辑器";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(saveAction)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self loadPlistFile];
}

- (void)loadPlistFile {
    if (!self.filePath) {
        self.rootNode = [PlistNode buildNodeWithKey:@"root" value:[NSMutableDictionary dictionary]];
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:self.filePath];
    if (!data) {
        self.rootNode = [PlistNode buildNodeWithKey:@"root" value:[NSMutableDictionary dictionary]];
        [self.tableView reloadData];
        return;
    }
    
    NSError *error = nil;
    id plistObject = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:nil error:&error];
    
    if (error || !plistObject) {
        self.rootNode = [PlistNode buildNodeWithKey:@"root" value:[NSMutableDictionary dictionary]];
        [self.tableView reloadData];
        return;
    }
    
    self.rootNode = [PlistNode buildNodeWithKey:@"root" value:plistObject];
    self.rootNode.isExpanded = YES;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self flattenedNodes:self.rootNode].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    PlistNode *node = [self flattenedNodes:self.rootNode][indexPath.row];
    
    NSString *typeStr = [self typeString:node.type];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ | %@", node.key, typeStr];
    cell.accessoryView = [self accessoryButtonWithNode:node];
    
    BOOL hasChildren = node.children.count > 0;
    if (hasChildren) {
        cell.imageView.image = node.isExpanded ? [UIImage systemImageNamed:@"chevron.down"] : [UIImage systemImageNamed:@"chevron.right"];
    } else {
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PlistNode *node = [self flattenedNodes:self.rootNode][indexPath.row];
    if (node.children.count > 0) {
        node.isExpanded = !node.isExpanded;
        [self.tableView reloadData];
        return;
    }
    PlistEditDetailVC *vc = [[PlistEditDetailVC alloc] init];
    vc.node = node;
    vc.onDelete = ^{
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSArray *)flattenedNodes:(PlistNode *)node {
    NSMutableArray *arr = [NSMutableArray array];
    if (!node) return arr;
    [arr addObject:node];
    if (node.isExpanded) {
        for (PlistNode *child in node.children) {
            [arr addObjectsFromArray:[self flattenedNodes:child]];
        }
    }
    return arr;
}

- (UIView *)accessoryButtonWithNode:(PlistNode *)node {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [btn addAction:[UIAction actionWithHandler:^(UIAction * _Nonnull action) {
        PlistEditDetailVC *vc = [[PlistEditDetailVC alloc] init];
        vc.node = node;
        [self.navigationController pushViewController:vc animated:YES];
    }] forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (NSString *)typeString:(PlistType)type {
    switch (type) {
        case PlistTypeString: return @"String";
        case PlistTypeNumber: return @"Number";
        case PlistTypeBool: return @"Bool";
        case PlistTypeDate: return @"Date";
        case PlistTypeArray: return @"Array";
        case PlistTypeDictionary: return @"Dict";
        default: return @"Unknown";
    }
}

- (void)saveAction {
    if (self.onSave) {
        self.onSave([self plistFromNode:self.rootNode]);
    }
    
    if (self.filePath) {
        id plistObject = [self plistFromNode:self.rootNode];
        NSError *error = nil;
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:plistObject format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if (error) {
            NSLog(@"保存失败: %@", error);
        } else {
            [data writeToFile:self.filePath atomically:YES];
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (id)plistFromNode:(PlistNode *)node {
    if (node.type == PlistTypeDictionary) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (PlistNode *child in node.children) {
            dict[child.key] = [self plistFromNode:child];
        }
        return dict;
    }
    if (node.type == PlistTypeArray) {
        NSMutableArray *arr = [NSMutableArray array];
        for (PlistNode *child in node.children) {
            [arr addObject:[self plistFromNode:child]];
        }
        return arr;
    }
    return node.value;
}
@end
