//
//  ItemEditorViewController.h
//  SandboxFileManager
//
//  Plist 项编辑器（类似 Filza）
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PlistItemType) {
    PlistItemTypeString = 0,
    PlistItemTypeNumber,
    PlistItemTypeBoolean,
    PlistItemTypeArray,
    PlistItemTypeDictionary,
    PlistItemTypeDate,
    PlistItemTypeData,
};


@protocol ItemEditorViewControllerDelegate <NSObject>

- (void)itemEditorViewController:(UIViewController *)controller didSaveItemWithKey:(NSString *)key value:(id)value;
- (void)itemEditorViewControllerDidDelete:(UIViewController *)controller;
- (void)itemEditorViewControllerDidCancel:(UIViewController *)controller;

@end

@interface ItemEditorViewController : UIViewController

@property (nonatomic, weak) id<ItemEditorViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *itemKey;
@property (nonatomic, strong) id itemValue;
@property (nonatomic, assign) PlistItemType itemType;


@end

NS_ASSUME_NONNULL_END
