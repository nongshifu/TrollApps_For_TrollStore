//
//  RemarkManager.m
//  SandboxFileManager
//
//  备注管理器实现
//

#import "RemarkManager.h"

#undef MY_NSLog_ENABLED // .M取消 PCH 中的全局宏定义
#define MY_NSLog_ENABLED YES // .M当前文件单独启用

@interface RemarkManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *remarksDict;
@property (nonatomic, copy) NSString *filePath;

@end

@implementation RemarkManager

+ (instancetype)sharedManager {
    static RemarkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadRemarks];
    }
    return self;
}

- (NSString *)filePath {
    if (!_filePath) {
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        _filePath = [docsPath stringByAppendingPathComponent:@"file_remarks.plist"];
    }
    return _filePath;
}

- (void)loadRemarks {
    NSLog(@"加载备注loadRemarks:%@",self.filePath);
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        self.remarksDict = [[NSMutableDictionary alloc] initWithContentsOfFile:self.filePath];
        NSLog(@"判断存在remarksDict:%@",self.remarksDict);
    } else {
        self.remarksDict = [NSMutableDictionary dictionary];
    }
}

- (void)saveRemarks {
    NSLog(@"保存备注saveRemarks:%@",self.remarksDict);
    [self.remarksDict writeToFile:self.filePath atomically:YES];
}

- (void)saveRemark:(NSString *)remark forFilePath:(NSString *)filePath {
    if (!filePath) return;
    
    if (remark && remark.length > 0) {
        self.remarksDict[filePath] = remark;
    } else {
        [self.remarksDict removeObjectForKey:filePath];
    }
    [self saveRemarks];
}

- (NSString *)getRemarkForFilePath:(NSString *)filePath {
    if (!filePath) return @"";
    return self.remarksDict[filePath] ?: @"";
}

- (void)deleteRemarkForFilePath:(NSString *)filePath {
    [self.remarksDict removeObjectForKey:filePath];
    [self saveRemarks];
}

- (void)clearAllRemarks {
    [self.remarksDict removeAllObjects];
    [self saveRemarks];
}

@end
