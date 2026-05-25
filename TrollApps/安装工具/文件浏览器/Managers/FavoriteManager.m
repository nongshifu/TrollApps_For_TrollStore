#import "FavoriteManager.h"
#import "FileNotification.h"
#import "RemarkManager.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

static NSString * const kFavoriteFilePathsKey = @"FavoriteFilePaths";

@interface FavoriteManager ()
@property (nonatomic, strong) NSMutableArray<FileModel *> *favoriteModels;
@property (nonatomic, strong) NSMutableArray<NSString *> *favoritePaths;
@property (nonatomic, assign) BOOL isLoaded;
@end

@implementation FavoriteManager

+ (instancetype)sharedManager {
    static FavoriteManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FavoriteManager alloc] init];
        [instance loadFavorites];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _favoriteModels = [NSMutableArray array];
        _favoritePaths = [NSMutableArray array];
        _isLoaded = NO;
    }
    return self;
}

- (void)addFavorite:(FileModel *)model {
    if (!model || [self isFavorite:model.filePath]) {
        return;
    }

    model.isFavorite = YES;
    [self.favoriteModels addObject:model];
    [self.favoritePaths addObject:model.filePath];
    [self saveFavorites];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFavoriteChanged object:nil];
}

- (void)addFavoriteWithPath:(NSString *)path remark:(NSString *)remark {
    if (!path || [self isFavorite:path]) {
        return;
    }

    FileModel *model = [FileModel modelWithFilePath:path];
    if (!model) {
        return;
    }

    if (remark.length > 0) {
        model.remark = remark;
        [[RemarkManager sharedManager] saveRemark:remark forFilePath:path];
    }

    [self addFavorite:model];
}

- (void)removeFavorite:(FileModel *)model {
    if (!model) {
        return;
    }
    [self removeFavoriteWithPath:model.filePath];
}

- (void)removeFavoriteWithPath:(NSString *)path {
    if (!path) {
        return;
    }

    NSInteger indexToRemove = -1;
    for (NSInteger i = 0; i < self.favoritePaths.count; i++) {
        if ([self.favoritePaths[i] isEqualToString:path]) {
            indexToRemove = i;
            break;
        }
    }

    if (indexToRemove >= 0) {
        if (indexToRemove < self.favoriteModels.count) {
            self.favoriteModels[indexToRemove].isFavorite = NO;
        }
        [self.favoritePaths removeObjectAtIndex:indexToRemove];
        [self.favoriteModels removeObjectAtIndex:indexToRemove];
        [self saveFavorites];

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFavoriteChanged object:nil];
    }
}

- (BOOL)isFavorite:(NSString *)path {
    NSLog(@"判断是否收藏：%@",path);
    if (!path) {
        return NO;
    }
    @synchronized(self.favoritePaths) {
        NSLog(@"判断是否收藏self.favoritePaths：%@",self.favoritePaths);
        return [self.favoritePaths containsObject:path];
    }
}

- (NSArray<FileModel *> *)getAllFavorites {
    @synchronized(self.favoriteModels) {
        return [self.favoriteModels copy];
    }
}

- (void)saveFavorites {
    @synchronized(self.favoritePaths) {
        [[NSUserDefaults standardUserDefaults] setObject:[self.favoritePaths copy] forKey:kFavoriteFilePathsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)loadFavorites {
    @synchronized(self.favoritePaths) {
        @synchronized(self.favoriteModels) {
            NSArray *savedPaths = [[NSUserDefaults standardUserDefaults] arrayForKey:kFavoriteFilePathsKey];
            NSLog(@"读取本地收藏:%@",savedPaths);

            [self.favoritePaths removeAllObjects];
            [self.favoriteModels removeAllObjects];

            if (savedPaths) {
                for (NSString *path in savedPaths) {
                    NSLog(@"读取本地收藏遍历path:%@",path);
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        [self.favoritePaths addObject:path];
                        NSLog(@"准备封装模型");
                        
                        // 直接创建 FileModel，绕过 isFavorite 检查避免嵌套调用
                        FileModel *model = [[FileModel alloc] init];
                        model.filePath = path;
                        model.fileName = [path lastPathComponent];
                        model.itemType = FileItemTypeFolder;
                        model.fileSize = 0;
                        model.isFavorite = YES;
                        model.parentDirPath = [path stringByDeletingLastPathComponent];
                        
                        NSLog(@"封装模型model：%@",model);
                        [self.favoriteModels addObject:model];
                    }
                }
            }
        }
    }
}

@end
