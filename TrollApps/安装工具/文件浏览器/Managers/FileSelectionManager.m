//
//  FileSelectionManager.m
//  SandboxFileManager
//
//  文件勾选管理器实现
//

#import "FileSelectionManager.h"

@interface FileSelectionManager ()

@property (nonatomic, strong) NSMutableArray<FileModel *> *selectedFileList;

@end

@implementation FileSelectionManager

+ (instancetype)sharedManager {
    static FileSelectionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FileSelectionManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.selectedFileList = [NSMutableArray array];
    }
    return self;
}

- (NSArray<FileModel *> *)selectedFiles {
    return [self.selectedFileList copy];
}

- (NSInteger)selectedCount {
    return self.selectedFileList.count;
}

- (void)addFile:(FileModel *)file {
    if (!file || [self isFileSelected:file]) {
        return;
    }
    file.isSelected = YES;
    [self.selectedFileList addObject:file];
}

- (void)removeFile:(FileModel *)file {
    if (!file) {
        return;
    }
    
    // 通过文件路径查找并移除
    FileModel *toRemove = [self findFileByPath:file.filePath];
    if (toRemove) {
        toRemove.isSelected = NO;
        [self.selectedFileList removeObject:toRemove];
    }
}

- (BOOL)toggleFileSelection:(FileModel *)file {
    if (!file) {
        return NO;
    }
    
    if ([self isFileSelected:file]) {
        [self removeFile:file];
        return NO;
    } else {
        [self addFile:file];
        return YES;
    }
}

- (BOOL)isFileSelected:(FileModel *)file {
    if (!file) {
        return NO;
    }
    return [self findFileByPath:file.filePath] != nil;
}

// 通过文件路径查找已选中的文件
- (FileModel *)findFileByPath:(NSString *)filePath {
    if (!filePath) {
        return nil;
    }
    
    for (FileModel *file in self.selectedFileList) {
        if ([file.filePath isEqualToString:filePath]) {
            return file;
        }
    }
    return nil;
}

- (void)clearAllSelections {
    for (FileModel *file in self.selectedFileList) {
        file.isSelected = NO;
    }
    [self.selectedFileList removeAllObjects];
}

- (void)selectAllFiles:(NSArray<FileModel *> *)files {
    for (FileModel *file in files) {
        [self addFile:file];
    }
}

- (void)deselectAllFiles:(NSArray<FileModel *> *)files {
    for (FileModel *file in files) {
        [self removeFile:file];
    }
}

@end