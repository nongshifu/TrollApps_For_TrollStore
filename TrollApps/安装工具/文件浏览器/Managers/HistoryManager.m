//
//  HistoryManager.m
//  SandboxFileManager
//
//  浏览记录管理器实现
//

#import "HistoryManager.h"

@interface HistoryManager ()

@property (nonatomic, strong) NSMutableArray<FileModel *> *internalHistoryList;

@end

@implementation HistoryManager

+ (instancetype)sharedManager {
    static HistoryManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HistoryManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _internalHistoryList = [NSMutableArray array];
        self.maxHistoryCount = 50;
        [self loadHistoryFromDisk];
    }
    return self;
}

- (NSArray<FileModel *> *)historyList {
    return [_internalHistoryList copy];
}

- (void)addHistory:(FileModel *)model {
    if (!model || !model.filePath.length) {
        return;
    }
    
    // 先移除已存在的相同路径记录
    [self removeHistory:model];
    
    // 更新访问时间为当前时间
    model.lastAccessTime = [NSDate date];
    
    // 插入到最前面
    [_internalHistoryList insertObject:model atIndex:0];
    
    // 超过最大记录数时移除最旧的
    while (_internalHistoryList.count > self.maxHistoryCount) {
        [_internalHistoryList removeLastObject];
    }
    
    [self saveHistoryToDisk];
}

- (void)removeHistory:(FileModel *)model {
    if (!model || !model.filePath.length) {
        return;
    }
    
    // 通过路径查找并移除
    NSInteger indexToRemove = NSNotFound;
    for (NSInteger i = 0; i < _internalHistoryList.count; i++) {
        FileModel *historyModel = _internalHistoryList[i];
        if ([historyModel.filePath isEqualToString:model.filePath]) {
            indexToRemove = i;
            break;
        }
    }
    
    if (indexToRemove != NSNotFound) {
        [_internalHistoryList removeObjectAtIndex:indexToRemove];
        [self saveHistoryToDisk];
    }
}

- (void)clearHistory {
    [_internalHistoryList removeAllObjects];
    [self saveHistoryToDisk];
}

- (BOOL)hasHistory:(FileModel *)model {
    if (!model || !model.filePath.length) {
        return NO;
    }
    
    for (FileModel *historyModel in _internalHistoryList) {
        if ([historyModel.filePath isEqualToString:model.filePath]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<FileModel *> *)recentDirectories {
    NSMutableArray<FileModel *> *directories = [NSMutableArray array];
    for (FileModel *model in _internalHistoryList) {
        if (model.itemType == FileItemTypeFolder) {
            [directories addObject:model];
        }
    }
    return directories;
}

- (NSArray<FileModel *> *)recentFiles {
    NSMutableArray<FileModel *> *files = [NSMutableArray array];
    for (FileModel *model in _internalHistoryList) {
        if (model.itemType == FileItemTypeFile) {
            [files addObject:model];
        }
    }
    return files;
}

#pragma mark - 持久化

- (NSString *)historyFilePath {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docsDir stringByAppendingPathComponent:@"history.plist"];
}

- (void)saveHistoryToDisk {
    NSMutableArray *historyData = [NSMutableArray array];
    for (FileModel *model in _internalHistoryList) {
        NSDictionary *dict = [model toDictionary];
        if (dict) {
            [historyData addObject:dict];
        }
    }
    [historyData writeToFile:[self historyFilePath] atomically:YES];
}

- (void)loadHistoryFromDisk {
    NSString *filePath = [self historyFilePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return;
    }
    
    NSArray *historyData = [NSArray arrayWithContentsOfFile:filePath];
    if (!historyData) {
        return;
    }
    
    [_internalHistoryList removeAllObjects];
    for (NSDictionary *dict in historyData) {
        FileModel *model = [[FileModel alloc] initWithDictionary:dict];
        if (model) {
            [_internalHistoryList addObject:model];
        }
    }
}

@end