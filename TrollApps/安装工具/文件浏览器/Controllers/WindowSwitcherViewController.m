//
//  WindowSwitcherViewController.m
//  SandboxFileManager
//
//  窗口切换器视图控制器
//  使用横向滚动的 UICollectionView 显示窗口卡片
//
//

#import "WindowSwitcherViewController.h"
#import "WindowCardCell.h"
#import "FileListTableViewController.h"
#import "WindowManager.h"
#import "FileListViewController.h"
#import "DockFlowLayout.h"

#pragma mark - WindowSwitcherViewController ()

@interface WindowSwitcherViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DockFlowLayoutDelegate, WindowCardCellDelegate>

/// 窗口信息数组（readwrite）
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *windowInfos;

/// 当前索引
@property (nonatomic, assign) NSInteger currentIndex;

/// 集合视图
@property (nonatomic, strong) UICollectionView *collectionView;

/// 背景遮罩视图
@property (nonatomic, strong) UIView *backgroundView;

/// 标题标签
@property (nonatomic, strong) UILabel *titleLabel;

/// 添加新窗口按钮
@property (nonatomic, strong) UIButton *addButton;

/// 记录要关闭的 cell 的索引
@property (nonatomic, strong) NSMutableIndexSet *pendingDeletes;

@end

#pragma mark - WindowSwitcherViewController Implementation

@implementation WindowSwitcherViewController

@synthesize windowInfos = _windowInfos;

- (instancetype)initWithWindowInfos:(NSArray<NSDictionary *> *)infos currentIndex:(NSInteger)currentIndex {
    self = [super init];
    if (self) {
        _windowInfos = [infos mutableCopy];
        _currentIndex = currentIndex;
        _lastContentOffsetX = 0;
    }
    return self;
}

- (instancetype)initWithWindowControllers:(NSArray<FileListTableViewController *> *)controllers currentIndex:(NSInteger)currentIndex {
    NSMutableArray *infos = [NSMutableArray array];
    for (FileListTableViewController *vc in controllers) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        info[@"title"] = vc.currentDirPath.lastPathComponent ?: @"窗口";
        info[@"path"] = vc.currentDirPath ?: @"";
        [infos addObject:info];
    }
    return [self initWithWindowInfos:infos currentIndex:currentIndex];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"窗口切换器");
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 滚动到上次保存的位置（优先），或者当前选中的位置
    if (self.lastContentOffsetX > 0) {
        [self.collectionView setContentOffset:CGPointMake(self.lastContentOffsetX, 0) animated:NO];
    } else if (self.currentIndex >= 0 && self.currentIndex < _windowInfos.count) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 保存滚动位置
    self.lastContentOffsetX = self.collectionView.contentOffset.x;
}

#pragma mark - UI Setup

- (void)setupUI {
    self.view.backgroundColor = [UIColor clearColor];
    
    // 背景遮罩
    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [self.view addSubview:self.backgroundView];
    
    // 点击背景关闭手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeButtonTapped:)];
    [self.backgroundView addGestureRecognizer:tapGesture];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, self.view.bounds.size.width, 30)];
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.titleLabel.text = @"窗口";
    self.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    
    // 创建集合视图布局 - 使用Dock效果
    DockFlowLayout *layout = [[DockFlowLayout alloc] init];
    layout.delegate = self;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 24;
    layout.minimumInteritemSpacing = 24;
    layout.sectionInset = UIEdgeInsetsMake(40, 40, 100, 40);
    
    // 计算卡片宽度（响应式）
    CGFloat availableWidth = self.view.bounds.size.width - 80;
    CGFloat cardWidth = MIN(280, availableWidth / 1.5);
    layout.cardWidth = cardWidth;
    layout.cardBottomHeight = 80;
    
    // 创建集合视图
    CGFloat collectionViewY = 200;
    CGFloat collectionViewHeight = self.view.bounds.size.height - collectionViewY - 100;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, collectionViewY, self.view.bounds.size.width, collectionViewHeight)
                                             collectionViewLayout:layout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[WindowCardCell class] forCellWithReuseIdentifier:@"WindowCardCell"];
    [self.view addSubview:self.collectionView];
    
    // 添加新窗口按钮
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.frame = CGRectMake((self.view.bounds.size.width - 160) / 2, self.view.bounds.size.height - 100, 160, 44);
    self.addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.addButton.backgroundColor = [UIColor systemBackgroundColor];
    self.addButton.layer.cornerRadius = 12;
    [self.addButton setTitle:@"+ 新建窗口" forState:UIControlStateNormal];
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.addButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addButton];
}

#pragma mark - Data Update

- (void)updateWithWindowInfos:(NSArray<NSDictionary *> *)infos currentIndex:(NSInteger)currentIndex {
    _windowInfos = [infos mutableCopy];
    self.currentIndex = currentIndex;
    [self.collectionView reloadData];
}

- (void)updateWithWindowControllers:(NSArray<FileListTableViewController *> *)controllers currentIndex:(NSInteger)currentIndex {
    NSMutableArray *infos = [NSMutableArray array];
    for (FileListTableViewController *vc in controllers) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        info[@"title"] = vc.currentDirPath.lastPathComponent ?: @"窗口";
        info[@"path"] = vc.currentDirPath ?: @"";
        [infos addObject:info];
    }
    [self updateWithWindowInfos:infos currentIndex:currentIndex];
}

#pragma mark - Actions

- (void)closeButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(windowSwitcherDidClose:)]) {
        [self.delegate windowSwitcherDidClose:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(windowSwitcherDidRequestAddNewWindow:)]) {
        [self.delegate windowSwitcherDidRequestAddNewWindow:self];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"窗口数量：%ld",_windowInfos.count);
    return _windowInfos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WindowCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WindowCardCell" forIndexPath:indexPath];
    
    NSDictionary *info = _windowInfos[indexPath.item];
    BOOL isActive = (indexPath.item == self.currentIndex);
    
    // 获取截图
    UIImage *snapshot = info[@"snapshot"];
    
    // 使用带截图的配置方法
    [cell configureWithTitle:info[@"title"] path:info[@"path"] snapshot:snapshot isActive:isActive];
    
    // 设置代理（支持滑动关闭）
    cell.delegate = self;
    
    // 添加长按手势关闭窗口（保留长按作为备用）
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressOnCell:)];
    longPressGesture.minimumPressDuration = 0.5;
//    [cell addGestureRecognizer:longPressGesture];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    DockFlowLayout *layout = (DockFlowLayout *)collectionViewLayout;
    return [layout sizeForItemAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *info = _windowInfos[indexPath.item];
    NSLog(@"UICollectionViewDelegate info:%@",info);
    // 更新当前索引
    self.currentIndex = indexPath.item;
    [collectionView reloadData];
    
    // 获取对应的窗口并切换（直接使用 indexPath.item，因为顺序一致）
    NSArray *allWindows = [[WindowManager sharedManager] allWindows];
    if (indexPath.item >= 0 && indexPath.item < allWindows.count) {
        FileListViewController *selectedWindow = allWindows[indexPath.item];
        NSLog(@"获取对应的窗口并切换selectedWindow:%@",selectedWindow);
        // 切换到该窗口
        [[WindowManager sharedManager] switchToWindow:selectedWindow];
        
        // 调用代理
        if ([self.delegate respondsToSelector:@selector(windowSwitcher:didSelectViewController:atIndex:)]) {
            FileListTableViewController *vc = [selectedWindow currentTableViewController];
            [self.delegate windowSwitcher:self didSelectViewController:vc atIndex:indexPath.item];
        }
    }
    
    // 关闭窗口切换器
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Long Press Handler

- (void)handleLongPressOnCell:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gesture locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        
        if (indexPath) {
            [self showDeleteConfirmationForIndexPath:indexPath];
        }
    }
}

- (void)showDeleteConfirmationForIndexPath:(NSIndexPath *)indexPath {
    // 至少保留一个窗口
    if (_windowInfos.count <= 1) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"关闭窗口"
                                                                   message:@"确定要关闭这个窗口吗？"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self closeWindowAtIndexPath:indexPath];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)closeWindowAtIndexPath:(NSIndexPath *)indexPath {
    // 更新当前索引
    if (self.currentIndex == indexPath.item) {
        self.currentIndex = (indexPath.item > 0) ? indexPath.item - 1 : 0;
    } else if (self.currentIndex > indexPath.item) {
        self.currentIndex--;
    }
    
    // 从数组中移除
    [_windowInfos removeObjectAtIndex:indexPath.item];
    
    // 关闭 WindowManager 中的对应窗口（直接使用 indexPath.item，因为顺序一致）
    [[WindowManager sharedManager] closeWindowAtIndex:indexPath.item];
    
    // 更新视图
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        [self.collectionView reloadData];
    }];
    
    // 调用代理
    if ([self.delegate respondsToSelector:@selector(windowSwitcher:didCloseViewController:atIndex:)]) {
        [self.delegate windowSwitcher:self didCloseViewController:nil atIndex:indexPath.item];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.lastContentOffsetX = scrollView.contentOffset.x;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.lastContentOffsetX = scrollView.contentOffset.x;
}

#pragma mark - DockFlowLayoutDelegate

- (UIImage *)dockFlowLayout:(DockFlowLayout *)layout snapshotForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.windowInfos.count) {
        NSDictionary *info = self.windowInfos[indexPath.item];
        return info[@"snapshot"];
    }
    return nil;
}

#pragma mark - WindowCardCellDelegate

- (void)windowCardCellWillClose:(WindowCardCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        [self closeWindowAtIndexPath:indexPath];
    }
}

@end
