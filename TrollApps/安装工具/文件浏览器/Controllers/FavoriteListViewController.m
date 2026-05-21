//
//  FavoriteListViewController.m
//  SandboxFileManager
//
//  收藏列表控制器实现
//

#import "FavoriteListViewController.h"
#import "FavoriteManager.h"
#import "FileModel.h"
#import "FileListViewController.h"
#import "FileEnum.h"
#import "FileListCell.h"
#import "SandboxTool.h"

static NSString * const kFavoriteCellIdentifier = @"FavoriteCell";

@interface FavoriteListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, FileListCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<FileModel *> *favoriteList;
@property (nonatomic, strong) NSMutableArray<FileModel *> *filteredList;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation FavoriteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupSearchController];
    [self loadFavorites];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadFavorites];
}

- (void)setupUI {
    self.title = @"我的收藏";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 60;
    [self.tableView registerClass:[FileListCell class] forCellReuseIdentifier:kFavoriteCellIdentifier];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                                 target:self
                                                                                 action:@selector(closeButtonTapped)];
    UIBarButtonItem *enterButton = [[UIBarButtonItem alloc] initWithTitle:@"管理器"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(enterButtonTapped)];
    
    self.navigationItem.rightBarButtonItem = closeButton;
    self.navigationItem.leftBarButtonItem = enterButton;
}

- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"搜索收藏";
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;
}

- (void)loadFavorites {
    self.favoriteList = [[[FavoriteManager sharedManager] getAllFavorites] mutableCopy];
    for (FileModel *model in self.favoriteList) {
        model.isFavorite = YES;
    }
    self.filteredList = [self.favoriteList mutableCopy];
    [self.tableView reloadData];
}

- (void)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)enterButtonTapped {
    NSString *homePath = [SandboxTool getSandboxDirectoryPath:SandboxDirectoryTypeHome];

    if (self.sourceFileListVC) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.sourceFileListVC navigateToPath:homePath];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            FileListViewController *fileListVC = [[FileListViewController alloc] initWithFullPath:homePath];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fileListVC];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            UIViewController *presenter = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (presenter.presentedViewController) {
                presenter = presenter.presentedViewController;
            }
            [presenter presentViewController:navController animated:YES completion:nil];
        }];
    }
}

- (NSArray<FileModel *> *)currentDataList {
    return self.isSearching ? self.filteredList : self.favoriteList;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    self.isSearching = (searchText.length > 0);

    if (self.isSearching) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileName CONTAINS[cd] %@ OR remark CONTAINS[cd] %@", searchText, searchText];
        self.filteredList = [[self.favoriteList filteredArrayUsingPredicate:predicate] mutableCopy];
    } else {
        self.filteredList = [self.favoriteList mutableCopy];
    }
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentDataList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileListCell *cell = [tableView dequeueReusableCellWithIdentifier:kFavoriteCellIdentifier forIndexPath:indexPath];
    FileModel *model = [self currentDataList][indexPath.row];
    [cell configWithFileModel:model];
    cell.cellDelegate = self;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    FileModel *model = [self currentDataList][indexPath.row];

    NSString *targetPath = (model.itemType == FileItemTypeFolder) ? model.filePath : model.parentDirPath;

    if (self.sourceFileListVC) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.sourceFileListVC navigateToPath:targetPath];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            FileListViewController *fileListVC = [[FileListViewController alloc] initWithFullPath:targetPath];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fileListVC];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            UIViewController *presenter = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (presenter.presentedViewController) {
                presenter = presenter.presentedViewController;
            }
            [presenter presentViewController:navController animated:YES completion:nil];
        }];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        FileModel *model = [self currentDataList][indexPath.row];
        [[FavoriteManager sharedManager] removeFavorite:model];
        [self.favoriteList removeObject:model];
        [self.filteredList removeObject:model];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        completionHandler(YES);
    }];

    deleteAction.backgroundColor = [UIColor systemRedColor];

    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark - FileListCellDelegate

- (void)fileListCell:(FileListCell *)cell didSelectCheckBox:(BOOL)selected forFileModel:(FileModel *)model {
}

- (void)fileListCell:(FileListCell *)cell didTapActionButtonForFileModel:(FileModel *)model {
}

@end
