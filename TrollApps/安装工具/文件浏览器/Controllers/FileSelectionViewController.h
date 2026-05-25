//
//  FileSelectionViewController.h
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/19.
//

#import <UIKit/UIKit.h>
#import "FileListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileSelectionViewController : UIViewController
@property (nonatomic, strong) FileListViewController *fileListViewController;
@end

NS_ASSUME_NONNULL_END
