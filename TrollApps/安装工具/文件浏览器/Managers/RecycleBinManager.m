//
//  RecycleBinManager.m
//  SandboxFileManager
//
//  回收站管理器实现
//

#import "RecycleBinManager.h"
#import "FileNotification.h"

@interface RecycleBinItem ()

@property (nonatomic, strong) NSMutableDictionary *dictionary;

@end

@implementation RecycleBinItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dictionary = [NSMutableDictionary dictionary];
        
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.fileModel) {
        dict[@"fileModel"] = [self.fileModel toDictionary];
    }
    if (self.deletedDate) {
        dict[@"deletedDate"] = @([self.deletedDate timeIntervalSince1970]);
    }
    if (self.originalPath) {
        dict[@"originalPath"] = self.originalPath;
    }
    return dict;
}

+ (instancetype)itemWithDictionary:(NSDictionary *)dict {
    if (!dict) return nil;
    
    RecycleBinItem *item = [[RecycleBinItem alloc] init];
    
    NSDictionary *modelDict = dict[@"fileModel"];
    if (modelDict) {
        item.fileModel = [[FileModel alloc] initWithDictionary:modelDict];
    }
    
    NSNumber *dateNum = dict[@"deletedDate"];
    if (dateNum) {
        item.deletedDate = [NSDate dateWithTimeIntervalSince1970:dateNum.doubleValue];
    }
    
    item.originalPath = dict[@"originalPath"];
    
    return item;
}

@end

@interface RecycleBinManager ()



@end

@implementation RecycleBinManager

+ (instancetype)sharedManager {
    static RecycleBinManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RecycleBinManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.recycleBinItems = [NSMutableArray array];
        self.recycleBinEnabled = YES;
        [self ensureRecycleBinDirectory];
        [self loadRecycleBinFromDisk];
    }
    return self;
}

- (NSMutableArray<RecycleBinItem *> *)recycleBinItems {
    if (!_recycleBinItems) {
        _recycleBinItems = [NSMutableArray array];
    }
    return _recycleBinItems;
}

- (NSArray<RecycleBinItem *> *)allRecycleBinItems {
    return [self.recycleBinItems copy];
}

- (NSInteger)itemCount {
    return self.recycleBinItems.count;
}

- (unsigned long long)totalSize {
    unsigned long long size = 0;
    for (RecycleBinItem *item in self.recycleBinItems) {
        if (item.fileModel) {
            size += item.fileModel.fileSize;
        }
    }
    return size;
}

- (NSString *)recycleBinPath {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docsDir stringByAppendingPathComponent:@".Trash"];
}

- (void)ensureRecycleBinDirectory {
    NSString *path = [self recycleBinPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)moveFileModelsToRecycleBin:(NSArray <FileModel *>*)models {
    for (FileModel *model in models) {
        [self moveToRecycleBin:model];
    }
}

- (BOOL)moveToRecycleBin:(FileModel *)model {
    if (!model || !model.filePath.length) {
        return NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *originalPath = model.filePath;
    
    if (![fm fileExistsAtPath:originalPath]) {
        return NO;
    }
    
    // 创建回收站项目
    RecycleBinItem *item = [[RecycleBinItem alloc] init];
    item.fileModel = model;
    item.deletedDate = [NSDate date];
    item.originalPath = originalPath;
    
    // 生成唯一文件名（避免冲突）
    NSString *fileName = [originalPath lastPathComponent];
    NSString *extension = [fileName pathExtension];
    NSString *baseName = [fileName stringByDeletingPathExtension];
    
    NSString *targetPath = [self.recycleBinPath stringByAppendingPathComponent:fileName];
    NSInteger counter = 1;
    while ([fm fileExistsAtPath:targetPath]) {
        NSString *newFileName = [NSString stringWithFormat:@"%@_%ld%@", baseName, (long)counter, extension.length > 0 ? [NSString stringWithFormat:@".%@", extension] : @""];
        targetPath = [self.recycleBinPath stringByAppendingPathComponent:newFileName];
        counter++;
    }
    
    // 移动文件到回收站
    NSError *error = nil;
    BOOL success = [fm moveItemAtPath:originalPath toPath:targetPath error:&error];
    
    if (success) {
        // 更新文件模型的路径
        model.filePath = targetPath;
        [self.recycleBinItems addObject:item];
        [self saveRecycleBinToDisk];
    }
    
    return success;
}

- (BOOL)restoreItem:(RecycleBinItem *)item {
    if (!item || !item.originalPath.length || !item.fileModel) {
        return NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentPath = item.fileModel.filePath;
    NSString *targetPath = item.originalPath;
    
    if (![fm fileExistsAtPath:currentPath]) {
        return NO;
    }
    
    // 确保目标目录存在
    NSString *targetDir = [targetPath stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:targetDir]) {
        [fm createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 处理目标路径已存在的情况
    if ([fm fileExistsAtPath:targetPath]) {
        NSString *fileName = [targetPath lastPathComponent];
        NSString *extension = [fileName pathExtension];
        NSString *baseName = [fileName stringByDeletingPathExtension];
        
        NSInteger counter = 1;
        while ([fm fileExistsAtPath:targetPath]) {
            NSString *newFileName = [NSString stringWithFormat:@"%@_%ld%@", baseName, (long)counter, extension.length > 0 ? [NSString stringWithFormat:@".%@", extension] : @""];
            targetPath = [[targetPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
            counter++;
        }
    }
    
    NSError *error = nil;
    BOOL success = [fm moveItemAtPath:currentPath toPath:targetPath error:&error];
    
    if (success) {
        item.fileModel.filePath = targetPath;
        [self.recycleBinItems removeObject:item];
        [self saveRecycleBinToDisk];
        
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
    }
    
    return success;
}

- (NSInteger)restoreAllItems {
    NSInteger count = 0;
    for (RecycleBinItem *item in [self.recycleBinItems copy]) {
        if ([self restoreItem:item]) {
            count++;
        }
    }
    return count;
}

- (NSString *)checkRestoreConflictForItem:(RecycleBinItem *)item {
    if (!item || !item.originalPath.length || !item.fileModel) {
        return nil;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentPath = item.fileModel.filePath;
    NSString *targetPath = item.originalPath;
    
    if (![fm fileExistsAtPath:currentPath]) {
        return nil;
    }
    
    if ([fm fileExistsAtPath:targetPath]) {
        return targetPath;
    }
    
    return nil;
}

- (BOOL)restoreItem:(RecycleBinItem *)item withConflictHandler:(RecycleBinRestoreConflictHandler)conflictHandler {
    if (!item || !item.originalPath.length || !item.fileModel) {
        return NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentPath = item.fileModel.filePath;
    NSString *targetPath = item.originalPath;
    
    if (![fm fileExistsAtPath:currentPath]) {
        return NO;
    }
    
    if (![fm fileExistsAtPath:targetPath]) {
        return [self restoreItem:item];
    }
    
    if (conflictHandler) {
        __weak typeof(self) weakSelf = self;
        conflictHandler(item, targetPath, ^(RecycleBinRestoreConflictOption option) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            if (option == RecycleBinRestoreConflictOptionOverwrite) {
                [strongSelf overwriteAndRestoreItem:item toPath:targetPath];
            } else {
                [strongSelf renameAndRestoreItem:item];
            }
        });
        return YES;
    }
    
    return [self restoreItem:item];
}

- (void)overwriteAndRestoreItem:(RecycleBinItem *)item toPath:(NSString *)targetPath {
    if (!item || !targetPath.length) {
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentPath = item.fileModel.filePath;
    
    [fm removeItemAtPath:targetPath error:nil];
    
    NSError *error = nil;
    BOOL success = [fm moveItemAtPath:currentPath toPath:targetPath error:&error];
    
    if (success) {
        item.fileModel.filePath = targetPath;
        [self.recycleBinItems removeObject:item];
        [self saveRecycleBinToDisk];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
    }
}

- (void)renameAndRestoreItem:(RecycleBinItem *)item {
    if (!item || !item.originalPath.length || !item.fileModel) {
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentPath = item.fileModel.filePath;
    NSString *targetPath = item.originalPath;
    
    NSString *fileName = [targetPath lastPathComponent];
    NSString *extension = [fileName pathExtension];
    NSString *baseName = [fileName stringByDeletingPathExtension];
    
    NSInteger counter = 1;
    while ([fm fileExistsAtPath:targetPath]) {
        NSString *newFileName = [NSString stringWithFormat:@"%@_%ld%@", baseName, (long)counter, extension.length > 0 ? [NSString stringWithFormat:@".%@", extension] : @""];
        targetPath = [[targetPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        counter++;
    }
    
    NSError *error = nil;
    BOOL success = [fm moveItemAtPath:currentPath toPath:targetPath error:&error];
    
    if (success) {
        item.fileModel.filePath = targetPath;
        [self.recycleBinItems removeObject:item];
        [self saveRecycleBinToDisk];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFileListChanged object:nil];
    }
}

- (BOOL)deleteItem:(RecycleBinItem *)item {
    if (!item || !item.fileModel) {
        return NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = item.fileModel.filePath;
    
    if (![fm fileExistsAtPath:path]) {
        return NO;
    }
    
    NSError *error = nil;
    BOOL success = [fm removeItemAtPath:path error:&error];
    
    if (success) {
        [self.recycleBinItems removeObject:item];
        [self saveRecycleBinToDisk];
    }
    
    return success;
}

- (NSInteger)emptyRecycleBin {
    NSInteger count = 0;
    for (RecycleBinItem *item in [self.recycleBinItems copy]) {
        if ([self deleteItem:item]) {
            count++;
        }
    }
    return count;
}

#pragma mark - 持久化

- (NSString *)recycleBinInfoPath {
    return [[self recycleBinPath] stringByAppendingPathComponent:@"info.plist"];
}

- (void)saveRecycleBinToDisk {
    NSMutableArray *itemsData = [NSMutableArray array];
    for (RecycleBinItem *item in self.recycleBinItems) {
        [itemsData addObject:[item toDictionary]];
    }
    [itemsData writeToFile:[self recycleBinInfoPath] atomically:YES];
}

- (void)loadRecycleBinFromDisk {
    NSString *filePath = [self recycleBinInfoPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return;
    }
    
    NSArray *itemsData = [NSArray arrayWithContentsOfFile:filePath];
    if (!itemsData) {
        return;
    }
    
    [self.recycleBinItems removeAllObjects];
    for (NSDictionary *dict in itemsData) {
        RecycleBinItem *item = [RecycleBinItem itemWithDictionary:dict];
        if (item && item.fileModel && [[NSFileManager defaultManager] fileExistsAtPath:item.fileModel.filePath]) {
            [self.recycleBinItems addObject:item];
        }
    }
}

@end
