//
//  NestedEditorViewController.h
//  SandboxFileManager
//
//  嵌套结构编辑器（Array/Dictionary）
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@protocol NestedEditorViewControllerDelegate <NSObject>

- (void)nestedEditorViewController:(UIViewController *)controller didUpdateData:(id)data;

@end

@interface NestedEditorViewController : UIViewController

@property (nonatomic, weak) id<NestedEditorViewControllerDelegate> delegate;
@property (nonatomic, strong) id data;
@property (nonatomic, copy) NSString *itemKey;

@end

NS_ASSUME_NONNULL_END
