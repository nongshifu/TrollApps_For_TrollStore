#import "FavoriteManager.h"
#import "FileNotification.h"
#import "RemarkManager.h"

static NSString * const kFavoriteFilePathsKey = @"FavoriteFilePaths";

@interface FavoriteManager ()
@property (nonatomic, strong) NSMutableArray<FileModel *> *favoriteModels;
@property (nonatomic, strong) NSMutableArray<NSString *> *favoritePaths;
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
    if (!path) {
        return NO;
    }
    return [self.favoritePaths containsObject:path];
}

- (NSArray<FileModel *> *)getAllFavorites {
    return [self.favoriteModels copy];
}

- (void)saveFavorites {
    [[NSUserDefaults standardUserDefaults] setObject:[self.favoritePaths copy] forKey:kFavoriteFilePathsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadFavorites {
    NSArray *savedPaths = [[NSUserDefaults standardUserDefaults] arrayForKey:kFavoriteFilePathsKey];

    [self.favoritePaths removeAllObjects];
    [self.favoriteModels removeAllObjects];

    if (savedPaths) {
        for (NSString *path in savedPaths) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [self.favoritePaths addObject:path];
                FileModel *model = [FileModel modelWithFilePath:path];
                model.isFavorite = YES;
                [self.favoriteModels addObject:model];
            }
        }
    }
}

@end