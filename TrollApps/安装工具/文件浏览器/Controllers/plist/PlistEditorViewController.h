//
//  PlistEditorViewController.h
//  SandboxFileManager
//
//  Plist/XML 编辑器
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "FileModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface PlistEditorViewController : UIViewController 

@property (nonatomic, strong) FileModel *fileModel;
@property (nonatomic, copy) NSString *filePath;

@end

NS_ASSUME_NONNULL_END
