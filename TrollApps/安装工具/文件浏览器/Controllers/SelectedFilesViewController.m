//
//  SelectedFilesViewController.m
//  SandboxFileManager
//
//  选中文件列表控制器实现
//

#import "SelectedFilesViewController.h"
#import "FileSelectionManager.h"
#import "FileListCell.h"
#import "FileModel.h"

@interface SelectedFilesViewController () <UITableViewDataSource, UITableViewDelegate, FileListCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation SelectedFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupNavigation];
    [self setupTableView];
    [self setupEmptyView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)setupNavigation {
    self.title = @"已选中文件";
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = closeButton;
    
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearAll)];
    clearButton.tintColor = [UIColor systemRedColor];
    self.navigationItem.rightBarButtonItem = clearButton;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView registerClass:[FileListCell class] forCellReuseIdentifier:@"FileListCell"];
    [self.view addSubview:self.tableView];
}

- (void)setupEmptyView {
    self.emptyLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    self.emptyLabel.text = @"暂无选中文件";
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:16];
    self.emptyLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.emptyLabel];
}

- (void)updateUI {
    NSArray *selectedFiles = [[FileSelectionManager sharedManager] selectedFiles];
    
    self.emptyLabel.hidden = selectedFiles.count > 0;
    self.tableView.hidden = selectedFiles.count == 0;
    
    [self.tableView reloadData];
    
    // 更新导航栏标题显示数量
    self.title = [NSString stringWithFormat:@"已选中文件 (%ld)", (long)selectedFiles.count];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clearAll {
    [[FileSelectionManager sharedManager] clearAllSelections];
    [self updateUI];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[FileSelectionManager sharedManager] selectedCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileListCell" forIndexPath:indexPath];
    
    NSArray *selectedFiles = [[FileSelectionManager sharedManager] selectedFiles];
    FileModel *model = selectedFiles[indexPath.row];
    
    cell.cellDelegate = self;
    cell.isBatchEditing = YES;
    
    [cell configWithFileModel:model];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

#pragma mark - FileListCellDelegate

- (void)fileListCell:(FileListCell *)cell didSelectCheckBox:(BOOL)selected forFileModel:(FileModel *)model {
    [[FileSelectionManager sharedManager] toggleFileSelection:model];
    [self updateUI];
}

- (void)fileListCell:(FileListCell *)cell didTapActionButtonForFileModel:(FileModel *)model {
    // 在选中列表中不显示操作按钮
}

@end