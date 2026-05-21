//
//  PlistEditDetailVC.h
//  SandboxFileManager
//
//  Created by 十三哥 on 2026/5/15.
//

#import <UIKit/UIKit.h>
#import "PlistNode.h"
NS_ASSUME_NONNULL_BEGIN

@interface PlistEditDetailVC : UITableViewController
@property (nonatomic, strong) PlistNode *node;
@property (nonatomic, copy) void (^onDelete)(void);
@end

NS_ASSUME_NONNULL_END
