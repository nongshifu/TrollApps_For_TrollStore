#import "ImageGridSearchViewController.h"
#import "AFNetworking.h"
#import "MJRefresh.h"
#import <Masonry/Masonry.h>


@interface ImageGridSearchViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchBarDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISearchController *searchController; // 导航搜索控制器
@property (nonatomic, strong) NSMutableArray<NSString *> *imageUrls; // 图片URL数组
@property (nonatomic, assign) NSInteger currentPage; // 当前页码
@property (nonatomic, assign) BOOL hasMoreData; // 是否有更多数据
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;


@property (nonatomic, strong) UIButton *confirmButton; // 确认选择按钮（用于触发代理）


// API配置
@property (nonatomic, copy, readonly) NSString *apiId;
@property (nonatomic, copy, readonly) NSString *apiKey;
@property (nonatomic, copy, readonly) NSString *baseUrl;

@property (nonatomic, strong) NSTimer *searchTimer; // 防抖定时器

@end

@implementation ImageGridSearchViewController

#pragma mark - API配置
- (NSString *)apiId {
    return @"10006437";
}

- (NSString *)apiKey {
    return @"0888500b2c87d27d1da2c1050c24076d";
}

- (NSString *)baseUrl {
    return @"https://cn.apihz.cn/api/img/apihzimgbaidu.php";
}


#pragma mark - 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"图片搜索";
    self.currentPage = 1;
    self.imageUrls = [NSMutableArray array];
    self.hasMoreData = YES;
    // 初始化多选数组和集合
    self.selectedImages = [NSMutableArray array];
    self.selectedUrlSet = [NSMutableSet set];
    
    
    [self setupNavigationBarWithSearch]; // 配置导航栏搜索
    [self setupUI];
    [self setupRefresh];
    
    // 初始搜索（如有关键词）
    if (self.searchKeyword.length > 0) {
        self.searchController.searchBar.text = self.searchKeyword;
        [self fetchImageList:YES];
    }
}

#pragma mark - 导航栏配置（核心修改：导航搜索）

- (void)setupNavigationBarWithSearch {
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    
    // 创建搜索控制器
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self; // 实时更新回调
    self.searchController.obscuresBackgroundDuringPresentation = NO; // 不模糊背景
    self.searchController.searchBar.placeholder = @"输入关键词搜索图片";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.returnKeyType = UIReturnKeyDone;
    
    // 配置导航项
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO; // 始终显示搜索框
    
    // 左侧"最近"按钮
    UIBarButtonItem *dismissItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(dismiss:)];
    dismissItem.tintColor = [UIColor labelColor];
   
    
    UIButton * cleanButton= [[UIButton alloc] init];
    [cleanButton setTitle:@"清除" forState:UIControlStateNormal];
    [cleanButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    cleanButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [cleanButton addTarget:self action:@selector(cleanButtonTap) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cleanItem = [[UIBarButtonItem alloc] initWithCustomView:cleanButton];
    
    self.navigationItem.leftBarButtonItems = @[dismissItem, cleanItem]; // 保留原有"最近"按钮
    
    
    // 添加确认选择按钮（导航栏右侧）
    self.confirmButton = [[UIButton alloc] init];
    [self.confirmButton setTitle:@"确认" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.confirmButton addTarget:self action:@selector(confirmSelectedImages) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *confirmItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    
   
    
    self.navigationItem.rightBarButtonItem = confirmItem;
    // 隐藏系统返回按钮，使用自定义左侧按钮
    self.navigationItem.hidesBackButton = YES;
   
}

#pragma mark - 空实现按钮方法（后续自行实现）
- (void)dismiss:(UIBarButtonItem *)sender {
    // 后续实现"我的"功能
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)recently:(UIBarButtonItem *)sender {
    // 后续实现"最近"功能
}
- (void)cleanButtonTap {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"清除全部选择" message:nil preferredStyle:UIAlertControllerStyleAlert];
    // 添加取消按钮
    UIAlertAction*cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        
    }];
    [alert addAction:cancelAction];
    UIAlertAction*confirmAction = [UIAlertAction actionWithTitle:@"清除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.selectedImages removeAllObjects];
        [self.selectedUrlSet removeAllObjects];
        [self.collectionView reloadData];
        [self.confirmButton setTitle:[NSString stringWithFormat:@"确认(%ld)", self.selectedImages.count] forState:UIControlStateNormal];
        UIBarButtonItem *confirmItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
        self.navigationItem.leftBarButtonItem = confirmItem;
    }];
    [alert addAction:confirmAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}
// 确认选择按钮点击事件
- (void)confirmSelectedImages {
    if (self.selectedImages.count == 0) {
        [self showToast:@"请先选择图片"];
        return;
    }
    // 通过代理返回选中的数组
    if ([self.delegate respondsToSelector:@selector(imageGridSearch:didSelectImages:)]) {
        [self.delegate imageGridSearch:self didSelectImages:self.selectedImages];
    }
    
}

#pragma mark - UI布局（网格保持不变）
- (void)setupUI {
    // 网格布局（一行4列）
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat margin = 4;
    CGFloat itemWidth = (self.view.bounds.size.width - margin * 5) / 4;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    
    // 集合视图
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [self.view addSubview:self.collectionView];
    
    // 约束布局（重点修改：顶部从导航栏底部开始）
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 顶部约束：从导航栏底部开始（自动适配导航栏高度）
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        // 左右底部约束不变
        make.left.right.bottom.equalTo(self.view);
    }];
    
    // 加载指示器
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingView.center = self.view.center;
    [self.view addSubview:self.loadingView];
    
}

#pragma mark - UI布局约束
- (void)updateViewConstraints{
    [super updateViewConstraints];
    // 约束布局（重点修改：顶部从导航栏底部开始）
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 顶部约束：从导航栏底部开始（自动适配导航栏高度）
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        // 左右底部约束不变
        make.left.right.bottom.equalTo(self.view);
    }];
}

#pragma mark - 刷新控件
- (void)setupRefresh {
    self.collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    self.collectionView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    self.collectionView.mj_footer.hidden = YES;
}

#pragma mark - 网络请求（搜索图片）
- (void)fetchImageList:(BOOL)refresh {
    if (refresh) {
        self.currentPage = 1;
        [self.loadingView startAnimating];
    } else if (!self.hasMoreData) {
        return;
    }
    
    NSDictionary *params = @{
        @"id": self.apiId,
        @"key": self.apiKey,
        @"page": @(self.currentPage),
        @"words": self.searchKeyword ?: @"iOS图标",
        @"limit":@100,
        @"type": @1
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:self.baseUrl parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [self.loadingView stopAnimating];
        [self.collectionView.mj_header endRefreshing];
        [self.collectionView.mj_footer endRefreshing];
        
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 200) {
            NSArray *newUrls = responseObject[@"res"];
            self.hasMoreData = newUrls.count > 0;
            
            if (refresh) [self.imageUrls removeAllObjects];
            [self.imageUrls addObjectsFromArray:newUrls];
            [self.collectionView reloadData];
            self.collectionView.mj_footer.hidden = !self.hasMoreData;
        } else {
            [self showToast:responseObject[@"msg"] ?: @"搜索失败"];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self.loadingView stopAnimating];
        [self.collectionView.mj_header endRefreshing];
        [self.collectionView.mj_footer endRefreshing];
        [self showToast:@"网络错误，请重试"];
        NSLog(@"请求失败：%@", error.localizedDescription);
    }];
}

#pragma mark - 刷新/加载更多
- (void)refreshData {
    [self fetchImageList:YES];
}

- (void)loadMoreData {
    self.currentPage++;
    [self fetchImageList:NO];
}

#pragma mark - UICollectionView数据源与代理
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageUrls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"ImageCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.layer.cornerRadius = 4;
    cell.clipsToBounds = YES;
    
    // 清除旧子视图（保留勾选按钮）
    for (UIView *subview in cell.contentView.subviews) {
        if (![subview tag]) { // 勾选按钮tag=100，避免被清除
            [subview removeFromSuperview];
        }
    }
    
    // 图片视图（原有代码）
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [cell.contentView addSubview:imageView];
    
    // 加载图片（原有代码）
    NSString *imageUrl = self.imageUrls[indexPath.item];
    imageUrl = [imageUrl stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    [imageView sd_setImageWithURL:[NSURL URLWithString:imageUrl]
                  placeholderImage:[UIImage imageNamed:@"placeholder"]
                         options:SDWebImageRetryFailed | SDWebImageLowPriority
                        progress:nil
                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            imageView.image = [UIImage imageNamed:@"error"];
        }
        
    }];
    
    // 新增：勾选按钮（顶层视图）
    UIButton *selectButton = [cell.contentView viewWithTag:100];
    if (!selectButton) {
        selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        selectButton.tag = 100; // 避免被清除
        selectButton.frame = CGRectMake(cell.contentView.bounds.size.width - 25, 5, 20, 20);
        [selectButton setImage:[UIImage systemImageNamed:@"circle"] forState:UIControlStateNormal];
        [selectButton setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateSelected];
        [selectButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateSelected];
        [selectButton setTintColor:[UIColor whiteColor]];
        [cell.contentView addSubview:selectButton];
    }
    // 更新勾选状态（根据当前url是否在选中集合中）
    selectButton.selected = [self.selectedUrlSet containsObject:imageUrl];
    if(selectButton.selected){
        [selectButton setTintColor:[UIColor greenColor]];
    }else{
        [selectButton setTintColor:[UIColor whiteColor]];
    }
    [selectButton.superview bringSubviewToFront:selectButton];
    
    
    return cell;
}

#pragma mark - 点击图片弹出选项弹窗
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    // 获取当前图片和url
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIImageView *imageView = nil;
    for (UIView *subview in cell.contentView.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            imageView = (UIImageView *)subview;
            break;
        }
    }
    NSString *imageUrl = self.imageUrls[indexPath.item];
    UIImage *selectedImage = imageView.image;
    if (!selectedImage) return;
    ImageModel *model = [ImageModel modelWithImage:selectedImage url:imageUrl];
    
    // 新增：切换选中状态
    UIButton *selectButton = [cell.contentView viewWithTag:100];
    BOOL isSelected = [self.selectedUrlSet containsObject:imageUrl];
    
    if (isSelected) {
        // 取消选中：从数组和集合中移除
        [self.selectedUrlSet removeObject:imageUrl];
        [self.selectedImages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ImageModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([model.url isEqualToString:imageUrl]) {
                [self.selectedImages removeObjectAtIndex:idx];
                model.isSelected = NO; // 更新选中状态
                *stop = YES;
            }
        }];
        selectButton.selected = NO;
        [selectButton setTintColor:[UIColor whiteColor]];
        
    } else {
        // 新增：检查最大选择数量
        if (self.maxiMum > 0 && self.selectedImages.count >= self.maxiMum) {
            [self showToast:[NSString stringWithFormat:@"最多只能选择%ld张图片", (long)self.maxiMum]];
            return; // 超过限制，不执行后续选择逻辑
        }
        
        // 选中：添加到数组和集合
        // 选中：创建并添加模型
        
        model.isSelected = YES; // 更新选中状态
        [self.selectedUrlSet addObject:imageUrl];
        [self.selectedImages addObject:model];
        selectButton.selected = YES;
        
        [selectButton setTintColor:[UIColor greenColor]];
    }
    [selectButton.superview bringSubviewToFront:selectButton];
    
    // 更新确认按钮标题（显示选中数量）
    [self.confirmButton setTitle:[NSString stringWithFormat:@"确认(%ld)", self.selectedImages.count] forState:UIControlStateNormal];
    UIBarButtonItem *confirmItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    self.navigationItem.rightBarButtonItem = confirmItem;
    
    //选择的时候发送点击对象
    BOOL newisSelected = [self.selectedUrlSet containsObject:imageUrl];//读取最新状态
    NSLog(@"选择状态:%d imageUrl:%@  newisSelected:%@",newisSelected,imageUrl,selectedImage);
    if ([self.delegate respondsToSelector:@selector(imageGridSearch:didSelectImage:cell:)]) {
        [self.delegate imageGridSearch:self didSelectImage:model cell:cell];
    }
}


#pragma mark - UISearchBarDelegate（搜索触发）

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.searchKeyword = searchBar.text;
    // 点击搜索按钮时请求数据
    [self fetchImageList:YES];
}



#pragma mark - UISearchResultsUpdating（带防抖）
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.searchKeyword = searchController.searchBar.text;
    
    // 1. 取消上一次的延迟任务（关键：防止频繁触发）
    [self.searchTimer invalidate];
    self.searchTimer = nil;
    
    // 2. 如果搜索词为空，直接清空数据（可选，根据需求）
    if (self.searchKeyword.length == 0) {
        [self.imageUrls removeAllObjects];
        [self.collectionView reloadData];
        return;
    }
    
    // 3. 延迟0.5秒执行搜索（防抖核心）
//    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
//                                                       target:self
//                                                     selector:@selector(performSearch)
//                                                     userInfo:nil
//                                                      repeats:NO];
}

// 实际执行搜索的方法
- (void)performSearch {
    // 确保在主线程执行UI操作
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchImageList:YES]; // 刷新数据
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    // 结束编辑时立即执行搜索（忽略防抖延迟）
    [self.searchTimer invalidate];
    self.searchTimer = nil;
    //自动搜索
    [self performSearch];
}

#pragma mark - 辅助方法
- (void)showToast:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark - 屏幕旋转适配
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout invalidateLayout];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat margin = 4;
    CGFloat itemWidth = (self.view.bounds.size.width - margin * (margin+1)) / margin;
    
    // 刷新所有单元格的勾选按钮位置
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(UICollectionViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *selectButton = [cell.contentView viewWithTag:100];
        selectButton.frame = CGRectMake(itemWidth - 25, 5, 20, 20);
    }];
   
    
    return CGSizeMake(itemWidth, itemWidth);
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    
}


- (void)dealloc {
    [self.searchTimer invalidate];
    self.searchTimer = nil;
}


@end


