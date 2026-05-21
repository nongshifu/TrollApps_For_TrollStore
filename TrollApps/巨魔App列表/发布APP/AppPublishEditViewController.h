//
//  AppPublishEditViewController.h
//  TrollApps
//
//  发布/编辑页面基类 - 同一页面支持发布和编辑两种属性
//

#import <UIKit/UIKit.h>
#import "DemoBaseViewController.h"
#import "AppPublishEditViewModel.h"
#import "MediaItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@class AppPublishEditViewController;

/// 页面模式
typedef NS_ENUM(NSInteger, PublishEditMode) {
    PublishEditModePublish = 0,  // 发布模式
    PublishEditModeEdit = 1      // 编辑模式
};

@protocol AppPublishEditViewControllerDelegate <NSObject>
@optional
/// 发布/编辑成功回调
- (void)publishEditViewController:(AppPublishEditViewController *)controller didSuccessWithAppId:(NSInteger)appId;
/// 取消/关闭回调
- (void)publishEditViewControllerDidCancel:(AppPublishEditViewController *)controller;
@end

@interface AppPublishEditViewController : DemoBaseViewController

/// 当前编辑的应用ID (nil表示新建)
@property (nonatomic, strong, nullable) NSNumber *editingAppId;

/// 页面模式
@property (nonatomic, assign) PublishEditMode mode;

/// 代理
@property (nonatomic, weak) id<AppPublishEditViewControllerDelegate> delegate;

/// 视图模型
@property (nonatomic, strong, readonly) AppPublishEditViewModel *viewModel;


/// 初始化为发布模式
+ (instancetype)publishViewController;

/// 初始化为编辑模式
/// @param appId 要编辑的应用ID
+ (instancetype)editViewControllerWithAppId:(NSInteger)appId;

/// 保存视图数据到视图模型
- (void)saveViewModelData;

/// 用视图模型数据填充UI
- (void)populateUIWithViewModel;

- (void)submitTapped;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
