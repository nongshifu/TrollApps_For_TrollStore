//
//  PlistEditorVC.h
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/15.
//

#import <UIKit/UIKit.h>
#import "PlistNode.h"
#import "FileModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlistEditorVC : UITableViewController
@property (nonatomic, strong) FileModel *fileModel;
@property (nonatomic, strong) PlistNode *rootNode;
@property (nonatomic, copy) void (^onSave)(id plistObject);
@property (nonatomic, copy) NSString *filePath;

+ (instancetype)editorWithFile:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
